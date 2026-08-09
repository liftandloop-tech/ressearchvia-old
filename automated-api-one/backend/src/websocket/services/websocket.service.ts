import { Injectable, Logger } from '@nestjs/common';
import { TradingGateway } from '../gateway/trading.gateway';
import { WebsocketEvent } from '../enums/websocket-event.enum';
import { WebsocketEnvelope } from '../interfaces/websocket-events.interface';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';

const ADMIN_EVENT_WHITELIST: string[] = [
  'dlq.job.failed',
  'redis.down',
  'broker.circuit.open',
  'queue.backpressure',
  'segment.risk.locked',
];

@Injectable()
export class WebsocketService {
  private readonly logger = new Logger(WebsocketService.name);

  constructor(
    private readonly gateway: TradingGateway,
    private readonly redisService: RedisService,
    private readonly metrics: MetricsService,
  ) {}

  /**
   * Broadcasts a versioned event to a specified room.
   * Ensures event idempotency via Redis and validates admin room broadcasts.
   */
  async broadcast<T>(
    eventId: string,
    event: WebsocketEvent,
    room: string,
    payload: T,
  ): Promise<boolean> {
    // 1. Admin Broadcast Safeguard
    if (room === 'admin' && !ADMIN_EVENT_WHITELIST.includes(event)) {
      this.logger.error(`Security violation: Rejected non-whitelisted admin room event "${event}"`);
      this.metrics.incrementWsMessagesFailed();
      return false;
    }

    // 2. Event Idempotency Check (24 Hours TTL)
    const isUnique = await this.acquireEventLock(eventId);
    if (!isUnique) {
      this.logger.warn(`Websocket event ${eventId} already broadcasted (idempotency skip)`);
      return false;
    }

    try {
      // 3. Envelope Wrapping
      const envelope: WebsocketEnvelope<T> = {
        version: 1,
        event,
        timestamp: new Date().toISOString(),
        payload,
      };

      // 4. Gateway Emit
      this.gateway.server.to(room).emit(event, envelope);
      this.metrics.incrementWsMessagesSent();

      this.logger.debug(`Broadcasted event ${event} to room ${room} (eventId=${eventId})`);
      return true;
    } catch (err: any) {
      this.logger.error(`Failed to broadcast event ${event} to room ${room}: ${err.message}`);
      this.metrics.incrementWsMessagesFailed();
      return false;
    }
  }

  private async acquireEventLock(eventId: string): Promise<boolean> {
    if (!this.redisService.isHealthy()) return true; // Fail open if Redis is down

    const redisKey = `ws:event:${eventId}`;
    try {
      const client = this.redisService.getClient();
      const isNew = await client.set(redisKey, '1', 'EX', 86400, 'NX'); // 24 hours expiry
      return isNew === 'OK' || isNew === true || isNew === 1;
    } catch (err: any) {
      this.logger.error(`Idempotency check failed for WebSocket event ${eventId}: ${err.message}`);
      return true;
    }
  }
}
