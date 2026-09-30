import {
  Injectable,
  Logger,
  OnModuleDestroy,
  Inject,
  forwardRef,
  OnApplicationBootstrap,
} from '@nestjs/common';
import WebSocket from 'ws';
import { OrderMonitoringService } from '../../trading/services/order-monitoring.service';
import { PrismaService } from '../../prisma.service';

@Injectable()
export class ZebuWebSocketService implements OnModuleDestroy, OnApplicationBootstrap {
  private readonly logger = new Logger(ZebuWebSocketService.name);
  private readonly wsUrl = 'wss://go.mynt.in/NorenWSAPI/';
  private readonly sockets = new Map<string, WebSocket>();
  private readonly reconnectTimers = new Map<string, NodeJS.Timeout>();
  private readonly heartbeatTimers = new Map<string, NodeJS.Timeout>();
  private readonly activeCredentials = new Map<
    string,
    { accessToken: string; clientCode: string }
  >();

  constructor(
    @Inject(forwardRef(() => OrderMonitoringService))
    private readonly orderMonitoringService: OrderMonitoringService,
    private readonly prisma: PrismaService,
  ) {}

  /**
   * On application startup, automatically connect WebSocket stream for all active Zebu sessions
   */
  async onApplicationBootstrap() {
    try {
      const zebuBroker = await this.prisma.broker.findFirst({
        where: { code: 'ZEBU' },
      });
      if (!zebuBroker) return;

      const activeSessions = await this.prisma.userBroker.findMany({
        where: {
          brokerId: zebuBroker.id,
          accessToken: { not: null },
          tokenExpiry: { gt: new Date() },
        },
      });

      this.logger.log(
        `[Zebu WebSocket] Found ${activeSessions.length} active Zebu user session(s) in database to initialize`,
      );

      for (const s of activeSessions) {
        if (s.brokerClientId && s.accessToken) {
          this.logger.log(
            `[Zebu WebSocket] Auto-connecting real-time stream for ${s.brokerClientId}`,
          );
          this.connectUser(s.brokerClientId, s.accessToken);
        }
      }
    } catch (err: any) {
      this.logger.error(
        `[Zebu WebSocket] Failed during bootstrap session restoration: ${err.message}`,
      );
    }
  }

  /**
   * Connect to Zebu real-time Order Update WebSocket stream for a specific client.
   * Payload format: {"accesstoken":"...","t":"a","actid":"...","uid":"...","source":"API"}
   */
  connectUser(clientCode: string, accessToken: string): void {
    if (!clientCode || !accessToken) return;

    this.activeCredentials.set(clientCode, { clientCode, accessToken });

    // Close existing socket if already open
    const existing = this.sockets.get(clientCode);
    if (existing && existing.readyState === WebSocket.OPEN) {
      this.logger.log(`[Zebu WebSocket] Stream already active and connected for ${clientCode}`);
      return;
    }

    try {
      this.logger.log(
        `[Zebu WebSocket] Opening connection to ${this.wsUrl} for client ${clientCode}...`,
      );
      const ws = new WebSocket(this.wsUrl);
      this.sockets.set(clientCode, ws);

      ws.on('open', () => {
        this.logger.log(
          `[Zebu WebSocket] Connected to ${this.wsUrl} for ${clientCode}. Sending authentication handshake...`,
        );

        // Authentication handshake payload matching Zebu specification:
        // {"accesstoken":"...","t":"a","actid":"...","uid":"...","source":"API"}
        const authPayload = {
          accesstoken: accessToken,
          t: 'a',
          actid: clientCode,
          uid: clientCode,
          source: 'API',
        };
        ws.send(JSON.stringify(authPayload));

        // Start heartbeat keep-alive every 25 seconds
        this.startHeartbeat(clientCode, ws);
      });

      ws.on('message', async (raw: WebSocket.Data) => {
        try {
          const text = raw.toString();
          const rawParsed = JSON.parse(text);
          const messages = Array.isArray(rawParsed) ? rawParsed : [rawParsed];

          for (const msg of messages) {
            // 1. Authentication response ('ck' or 'ak')
            if (msg.t === 'ck' || msg.t === 'ak') {
              if (msg.s === 'Ok' || msg.stat === 'Ok') {
                this.logger.log(
                  `[Zebu WebSocket] Auth handshake verified for ${clientCode}. Subscribing to order updates...`,
                );
                // Send Order Update Subscription: {"t":"o","actid": clientCode}
                ws.send(JSON.stringify({ t: 'o', actid: clientCode }));
              } else {
                this.logger.warn(
                  `[Zebu WebSocket] Auth failed for ${clientCode}: ${text}`,
                );
              }
              continue;
            }

            // 2. Order subscription acknowledgment ('ok')
            if (msg.t === 'ok') {
              this.logger.log(
                `[Zebu WebSocket] Real-time order stream subscribed successfully for ${clientCode}`,
              );
              continue;
            }

            // 3. Heartbeat response ('h')
            if (msg.t === 'h') {
              this.logger.debug(`[Zebu WebSocket] Heartbeat ack from ${clientCode}`);
              continue;
            }

            // 4. Real-time Order Update Feed ('om')
            if (msg.t === 'om' || msg.norenordno || (msg.orderid && msg.status)) {
              this.logger.log(
                `[Zebu WebSocket] Live order update for ${clientCode}: ${JSON.stringify(msg)}`,
              );
              const brokerOrderId = msg.norenordno || msg.orderid;
              const status = msg.status || msg.orderstatus;
              const averagePrice = msg.avgprc ? parseFloat(msg.avgprc) : undefined;
              const filledQuantity = msg.fillshares ? parseInt(msg.fillshares, 10) : undefined;
              const rejectionReason = msg.rejreason || msg.reason;

              if (brokerOrderId && status) {
                await this.orderMonitoringService.processBrokerWebhookOrderUpdate({
                  brokerOrderId,
                  status,
                  averagePrice,
                  filledQuantity,
                  rejectionReason,
                });
              }
              continue;
            }

            // Other socket notifications
            this.logger.debug(`[Zebu WebSocket] Received message for ${clientCode}: ${text}`);
          }
        } catch (err: any) {
          this.logger.error(
            `[Zebu WebSocket] Error parsing message for ${clientCode}: ${err.message}`,
          );
        }
      });

      ws.on('error', (err) => {
        this.logger.error(
          `[Zebu WebSocket] Socket error for ${clientCode}: ${err.message}`,
        );
      });

      ws.on('close', (code, reason) => {
        this.logger.warn(
          `[Zebu WebSocket] Stream closed for ${clientCode} (code: ${code}, reason: ${reason}). Scheduling reconnect...`,
        );
        this.stopHeartbeat(clientCode);
        this.sockets.delete(clientCode);
        this.scheduleReconnect(clientCode);
      });
    } catch (err: any) {
      this.logger.error(
        `[Zebu WebSocket] Failed to create socket for ${clientCode}: ${err.message}`,
      );
      this.scheduleReconnect(clientCode);
    }
  }

  private startHeartbeat(clientCode: string, ws: WebSocket) {
    this.stopHeartbeat(clientCode);
    const timer = setInterval(() => {
      if (ws.readyState === WebSocket.OPEN) {
        try {
          ws.send(JSON.stringify({ t: 'h' }));
        } catch (_) {}
      }
    }, 25000);
    this.heartbeatTimers.set(clientCode, timer);
  }

  private stopHeartbeat(clientCode: string) {
    const timer = this.heartbeatTimers.get(clientCode);
    if (timer) {
      clearInterval(timer);
      this.heartbeatTimers.delete(clientCode);
    }
  }

  private scheduleReconnect(clientCode: string) {
    if (this.reconnectTimers.has(clientCode)) return;

    const creds = this.activeCredentials.get(clientCode);
    if (!creds) return;

    const timer = setTimeout(() => {
      this.reconnectTimers.delete(clientCode);
      this.logger.log(`[Zebu WebSocket] Reconnecting stream for ${clientCode}...`);
      this.connectUser(creds.clientCode, creds.accessToken);
    }, 10000); // Reconnect attempt after 10s

    this.reconnectTimers.set(clientCode, timer);
  }

  disconnectUser(clientCode: string): void {
    const timer = this.reconnectTimers.get(clientCode);
    if (timer) {
      clearTimeout(timer);
      this.reconnectTimers.delete(clientCode);
    }
    this.stopHeartbeat(clientCode);
    this.activeCredentials.delete(clientCode);

    const ws = this.sockets.get(clientCode);
    if (ws) {
      try {
        ws.close();
      } catch (_) {}
      this.sockets.delete(clientCode);
    }
    this.logger.log(`[Zebu WebSocket] Disconnected stream for client ${clientCode}`);
  }

  isUserConnected(clientCode: string): boolean {
    const ws = this.sockets.get(clientCode);
    return ws?.readyState === WebSocket.OPEN;
  }

  onModuleDestroy() {
    for (const [code] of this.sockets) {
      this.disconnectUser(code);
    }
  }
}
