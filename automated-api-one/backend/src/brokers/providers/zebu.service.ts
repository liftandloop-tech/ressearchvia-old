import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import {
  BrokerClient,
  OrderRequest,
  OrderResponse,
  SessionResponse,
  PositionResponse,
  HoldingResponse,
  FundsResponse,
  BrokerHealthResponse,
  BrokerCapabilities,
  BrokerTrade,
  BrokerLtp,
  ProfileResponse,
  BrokerCallbackData,
  BrokerSession,
} from '../interfaces/broker-client.interface';
import { BrokerAdapter } from '../interfaces/broker-adapter.interface';
import { ZebuEndpoints } from './zebu-endpoints';
import { firstValueFrom } from 'rxjs';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { BrokerRateLimiterService } from '../../infrastructure/redis/broker-rate-limiter.service';
import { createHash } from 'crypto';
import { PrismaService } from '../../prisma.service';
import { HttpsProxyAgent } from 'https-proxy-agent';
import { EgressService } from '../../egress/egress.service';
import { Optional } from '@nestjs/common';

@Injectable()
export class ZebuService extends BrokerAdapter implements BrokerClient {
  private readonly logger = new Logger(ZebuService.name);
  private readonly isMock: boolean;
  private readonly baseUrl: string;

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    private readonly redisService: RedisService,
    private readonly metrics: MetricsService,
    private readonly circuitBreaker: CircuitBreakerService,
    private readonly rateLimiter: BrokerRateLimiterService,
    private readonly prisma: PrismaService,
    @Optional() private readonly egressService?: EgressService,
  ) {
    super();
    const mockVal = this.configService.get<any>('MOCK_BROKERS', true);
    this.isMock = mockVal === true || mockVal === 'true';
    this.baseUrl =
      this.configService.get<string>('ZEBU_BASE_URL') ||
      'https://go.mynt.in/NorenWClientAPI';
  }

  // ---------------------------------------------------------------------------
  // Centralized Outbound Broker Post with Proxy Routing
  // ---------------------------------------------------------------------------

  private async executeBrokerPost(
    token: string | null,
    clientCode: string | null,
    endpoint: string,
    body: string,
    timeoutMs: number = 8000,
    providedHttpsAgent?: any,
  ): Promise<any> {
    const requestId = `req_${Date.now().toString(36)}_${Math.random().toString(36).substring(2, 7)}`;
    let httpsAgent = providedHttpsAgent;
    let proxyIp = 'DIRECT';
    let networkMode = 'DIRECT';

    // 1. Resolve userId and proxy credentials if not provided externally
    if (!httpsAgent) {
      let userBroker: any = null;
      if (token) {
        userBroker = await this.prisma.userBroker.findFirst({
          where: { accessToken: token },
          include: { proxyCredential: true },
        });
      } else if (clientCode) {
        userBroker = await this.prisma.userBroker.findFirst({
          where: { brokerClientId: clientCode },
          include: { proxyCredential: true },
        });
      }

      if (userBroker) {
        const userId = userBroker.userId;
        if (this.egressService) {
          try {
            httpsAgent = await this.egressService.getProxyAgentForUser(userId);
            if (httpsAgent) {
              networkMode = 'EGRESS_PROXY';
              proxyIp = httpsAgent.proxy?.hostname || 'EGRESS_PROXY';
              this.logger.log(`[Proxy Routing] requestId=${requestId} Routing outbound broker call via Egress Proxy for user ${userId} [endpoint: ${endpoint}]`);
            }
          } catch (eErr: any) {
            this.logger.warn(`[Proxy Routing] EgressService proxy notice for user ${userId}: ${eErr.message}`);
          }
        }

        if (!httpsAgent) {
          const proxy = userBroker.proxyCredential;
          if (proxy && proxy.ip && proxy.port && proxy.ip_userid && proxy.ip_password) {
            networkMode = 'DEDICATED_PROXY';
            const isExpired = proxy.expiresAt && new Date(proxy.expiresAt) < new Date();
            if (isExpired || (proxy.status !== 'ACTIVE' && proxy.status !== 'PENDING' && proxy.status !== 'RENEWING')) {
              this.logger.error(`[Proxy Violation] requestId=${requestId} Dedicated proxy for user ${userId} is ${proxy.status} (isExpired=${!!isExpired}). Aborting to prevent direct IP leakage.`);
              throw new Error(`[Proxy Error] Dedicated proxy is ${proxy.status}${isExpired ? ' (EXPIRED)' : ''}. Aborting broker request to prevent direct IP leakage.`);
            }

            proxyIp = proxy.ip;
            const auth = Buffer.from(`${proxy.ip_userid}:${proxy.ip_password}`).toString('base64');
            httpsAgent = new HttpsProxyAgent(`http://${proxy.ip}:${proxy.port}`, {
              headers: {
                'Proxy-Authorization': `Basic ${auth}`,
              },
            });
            this.logger.log(`[Proxy Routing] requestId=${requestId} Routing outbound broker call via Dedicated Proxy ${proxy.ip}:${proxy.port} (user: ${proxy.ip_userid}) for user ${userId} [endpoint: ${endpoint}]`);
          }
        }
      }
    } else {
      networkMode = 'FORWARDED_PROXY';
      proxyIp = 'FORWARDED';
    }

    this.logger.log(`[Broker Outbound] requestId=${requestId} networkMode=${networkMode} proxyIp=${proxyIp} endpoint=${endpoint}`);
    const start = Date.now();

    const headers: Record<string, string> = {
      'Content-Type': 'text/plain',
    };
    if (token && endpoint !== ZebuEndpoints.GEN_ACCESS_TOKEN && endpoint !== ZebuEndpoints.REFRESH_TOKEN) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    try {
      const response = await firstValueFrom(
        this.httpService.post(`${this.baseUrl}${endpoint}`, body, {
          headers,
          ...(httpsAgent ? { httpsAgent } : {}),
          timeout: timeoutMs,
        }),
      );

      const durationMs = Date.now() - start;
      let data = response.data;
      if (typeof data === 'string') {
        try {
          data = JSON.parse(data);
        } catch {
          // Keep as raw string
        }
      }

      this.logger.log(`[Broker Outbound Response] requestId=${requestId} endpoint=${endpoint} httpStatus=${response.status} stat=${data?.stat || 'N/A'} duration=${durationMs}ms`);

      if (data && data.stat === 'Not_Ok' && typeof data.emsg === 'string' && (data.emsg.includes('Session Expired') || data.emsg.includes('Invalid Session Key'))) {
        this.logger.warn(`[Zebu Auth] Session expired on broker (${data.emsg}). Updating connection status.`);
        if (token) {
          await this.prisma.userBroker.updateMany({
            where: { accessToken: token },
            data: { status: 'INACTIVE' },
          });
        }
      }

      if (response.status === 404 && endpoint === ZebuEndpoints.REFRESH_TOKEN) {
        return { stat: 'Not_Ok', emsg: 'RefreshToken endpoint not supported by Zebu server (tokens are 90-day long lived)' };
      }

      if (response.status >= 400 && (!data || !data.stat)) {
        const errMsg = data?.emsg || data?.message || (typeof data === 'string' ? data : `HTTP ${response.status}`);
        throw new Error(`Zebu Error (${response.status}): ${errMsg}`);
      }

      return data;
    } catch (err: any) {
      const durationMs = Date.now() - start;
      this.logger.error(`[Broker Outbound Failed] requestId=${requestId} endpoint=${endpoint} proxyIp=${proxyIp} duration=${durationMs}ms error=${err.message}`);
      throw err;
    }
  }

  // ---------------------------------------------------------------------------
  // BrokerAdapter interface
  // ---------------------------------------------------------------------------

  capabilities(): BrokerCapabilities {
    return {
      positions: true,
      holdings: true,
      funds: true,
      gtt: false,
      margin: true,
    };
  }

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  async healthCheck(): Promise<BrokerHealthResponse> {
    const start = Date.now();
    if (this.isMock) {
      return { reachable: true, responseTimeMs: 10 };
    }
    try {
      const response: any = await firstValueFrom(
        this.httpService.request({
          method: 'OPTIONS',
          url: this.baseUrl,
          timeout: 3000,
        }),
      );
      return {
        reachable: response.status < 500,
        responseTimeMs: Date.now() - start,
      };
    } catch {
      return { reachable: false, responseTimeMs: Date.now() - start };
    }
  }

  // ---------------------------------------------------------------------------
  // Session & OAuth management
  // ---------------------------------------------------------------------------

  async generateSession(credentials: {
    clientCode: string;
    password: string;
    totpKey: string;
    apiKey?: string;
    vendorCode?: string;
  }): Promise<SessionResponse> {
    throw new BadRequestException('Zebu OAuth system enabled. Please use the redirection OAuth flow instead.');
  }

  async getAuthorizationUrl(state: string): Promise<string> {
    if (this.isMock) {
      return `http://localhost:3000/brokers/zebu/callback?code=mock_code&state=${state}&client_id=mock_client_id`;
    }

    const authState = await this.prisma.brokerAuthState.findFirst({
      where: { state },
    });
    if (!authState) {
      throw new BadRequestException('Invalid authorization state');
    }
    const userBroker = await this.prisma.userBroker.findFirst({
      where: { userId: authState.userId, broker: { code: 'ZEBU' } },
    });
    if (!userBroker) {
      throw new BadRequestException('Please link your Zebu broker details first');
    }
    let clientId = userBroker.apiKey || userBroker.brokerClientId || '';
    if (clientId && !clientId.includes('_')) {
      clientId = `${clientId}_U`;
    }
    return `https://go.mynt.in/OAuthlogin/authorize/oauth?client_id=${clientId}&state=${state}`;
  }

  async completeAuthorization(callbackData: BrokerCallbackData): Promise<BrokerSession> {
    this.logger.log(`Completing Zebu OAuth authorization`);
    const authCode = callbackData.params.code;
    const queryClientId = callbackData.params.client_id;
    if (!authCode) {
      throw new BadRequestException('Authorization code (code) is missing in callback data');
    }

    if (this.isMock) {
      this.logger.log(`[SANDBOX MOCK] Generating session using authCode: ${authCode}`);
      return {
        accessToken: `mock_zebu_token_${Date.now()}`,
        refreshToken: `mock_zebu_refresh_${Date.now()}`,
        expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 90 days
        brokerUserId: queryClientId || 'mock_zebu_client',
      };
    }

    // Resolve UserBroker by queryClientId to fetch apiSecret
    let cleanClient = queryClientId || '';
    if (cleanClient.endsWith('_U')) {
      cleanClient = cleanClient.slice(0, -2);
    }

    const userBroker = await this.prisma.userBroker.findFirst({
      where: {
        OR: [
          { brokerClientId: cleanClient },
          { apiKey: queryClientId },
        ],
      },
    });

    if (!userBroker) {
      throw new BadRequestException(`Linked Zebu broker config not found for client_id: ${queryClientId}`);
    }

    let oauthAppId = userBroker.apiKey || userBroker.brokerClientId || '';
    if (oauthAppId && !oauthAppId.includes('_')) {
      oauthAppId = `${oauthAppId}_U`;
    }
    const apiSecret = userBroker.apiSecret || '';

    // Generate SHA-256 Checksum for GenAcsTok:
    // SHA256(client_id + api_secret + code)
    const hashString = `${oauthAppId}${apiSecret}${authCode}`;
    const checkSum = createHash('sha256').update(hashString).digest('hex');

    const payload = {
      code: authCode,
      checksum: checkSum,
    };

    const body = `jData=${JSON.stringify(payload)}`;

    try {
      const responseData = await this.executeBrokerPost(
        null,
        userBroker.brokerClientId,
        ZebuEndpoints.GEN_ACCESS_TOKEN,
        body,
        10000,
      );

      const accessToken = responseData?.access_token || responseData?.susertoken;
      if (responseData?.stat !== 'Ok' || !accessToken) {
        const errorMsg = responseData?.emsg || responseData?.message || 'Failed to get access token';
        throw new Error(errorMsg);
      }

      const refreshToken = responseData?.refresh_token || userBroker.refreshToken || '';
      const brokerUserId = responseData.actid || responseData.uid || responseData.USERID || userBroker.brokerClientId;

      return {
        accessToken,
        refreshToken,
        expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // Zebu tokens are 90 days valid
        brokerUserId,
      };
    } catch (err: any) {
      this.logger.error(`Zebu OAuth token exchange failed: ${err.message}`);
      throw new BadRequestException(`Zebu OAuth token exchange failed: ${err.message}`);
    }
  }

  async validateSession(token: string): Promise<boolean> {
    if (this.isMock) {
      return token.startsWith('mock_zebu_token_');
    }
    if (!token || token.length === 0) return false;
    
    // Check if the token matches a valid UserBroker session that hasn't expired
    const userBroker = await this.prisma.userBroker.findFirst({
      where: { accessToken: token },
    });
    if (!userBroker || !userBroker.tokenExpiry) return false;
    return new Date() < userBroker.tokenExpiry;
  }

  async refreshSession(token: string, refreshToken: string): Promise<SessionResponse> {
    if (this.isMock) {
      return {
        accessToken: `mock_zebu_token_refreshed_${Date.now()}`,
        refreshToken: `mock_zebu_refresh_refreshed_${Date.now()}`,
        tokenExpiry: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
      };
    }

    try {
      const userBroker = await this.prisma.userBroker.findFirst({
        where: { accessToken: token },
      });
      if (!userBroker) {
        throw new Error('UserBroker session config not found for refresh');
      }

      const body = `jData=${JSON.stringify({ refresh_token: refreshToken || userBroker.refreshToken })}` ;
      const responseData = await this.executeBrokerPost(
        token,
        userBroker.brokerClientId,
        ZebuEndpoints.REFRESH_TOKEN,
        body,
        8000,
      );

      const newAccessToken = responseData?.access_token || responseData?.susertoken;
      if (responseData?.stat !== 'Ok' || !newAccessToken) {
        throw new Error(responseData?.emsg || 'Failed to refresh token');
      }

      return {
        accessToken: newAccessToken,
        refreshToken: responseData?.refresh_token || refreshToken,
        tokenExpiry: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
      };
    } catch (error: any) {
      this.logger.error(`[Zebu] refreshSession failed: ${error.message}`);
      // Fall back to returning current session parameters
      return {
        accessToken: token,
        refreshToken,
        tokenExpiry: new Date(Date.now() + 24 * 60 * 60 * 1000),
      };
    }
  }

  // ---------------------------------------------------------------------------
  // User / Account
  // ---------------------------------------------------------------------------

  async getProfile(token: string, clientCode?: string): Promise<ProfileResponse> {
    if (this.isMock) {
      return {
        clientcode: 'ZB123456',
        name: 'ZEBU USER',
        email: 'user@example.com',
        mobileno: '919876543210',
        exchanges: ['INTRADAY', 'NSE', 'BSE', 'NFO', 'MCX'],
        products: ['CNC', 'MIS', 'NRML'],
        lastlogintime: new Date().toISOString(),
        brokerid: 'ZEBU',
        activeStatus: 'ACTIVE',
      };
    }

    try {
      const uid = clientCode || '';
      const body = `jData=${JSON.stringify({ uid, actid: uid })}&jKey=${token}`;
      const data = await this.executeBrokerPost(token, uid, ZebuEndpoints.CLIENT_DETAILS, body);

      if (data && data.stat === 'Ok') {
        return {
          clientcode: data.actid || '',
          name: data.cliname || '',
          email: data.email || '',
          mobileno: data.m_num || '',
          exchanges: data.exarr || [],
          products: data.prarr || [],
          lastlogintime: data.lastlogintime || '',
          brokerid: 'ZEBU',
          activeStatus: 'ACTIVE',
        };
      }
      throw new Error(data?.emsg || 'Failed to fetch profile from Zebu');
    } catch (error: any) {
      this.logger.error(`[Zebu] getProfile failed: ${error.message}`);
      throw error;
    }
  }

  async getFunds(token: string, clientCode: string): Promise<FundsResponse> {
    if (this.isMock) {
      return {
        availableMargin: 150000.0,
        usedMargin: 0.0,
        totalMargin: 150000.0,
      };
    }

    try {
      const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode })}&jKey=${token}`;
      const data = await this.executeBrokerPost(token, clientCode, ZebuEndpoints.LIMITS, body);

      if (data && data.stat === 'Ok') {
        const available = parseFloat(data.cash || data.net || '0');
        const used = parseFloat(data.marginused || '0');
        return {
          availableMargin: available,
          usedMargin: used,
          totalMargin: available + used,
        };
      }
      return { availableMargin: 0, usedMargin: 0, totalMargin: 0 };
    } catch (error: any) {
      this.logger.error(`[Zebu] getFunds failed: ${error.message}`);
      return { availableMargin: 0, usedMargin: 0, totalMargin: 0 };
    }
  }

  async getMargin(token: string, clientCode: string): Promise<number> {
    const funds = await this.getFunds(token, clientCode);
    return funds.availableMargin;
  }

  // ---------------------------------------------------------------------------
  // Portfolio
  // ---------------------------------------------------------------------------

  async getPositions(token: string, clientCode: string): Promise<PositionResponse[]> {
    if (this.isMock) {
      return [
        {
          symbol: 'SBIN-EQ',
          quantity: 10,
          avgPrice: 750.25,
          currentPrice: 752.4,
          unrealizedPnl: 21.5,
          realizedPnl: 0.0,
        },
      ];
    }

    return this.circuitBreaker.execute('zebu-positions', async () => {
      await this.rateLimiter.throttle('zebu', 'market');
      const start = Date.now();
      try {
        const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode })}&jKey=${token}`;
        const data = await this.executeBrokerPost(token, clientCode, ZebuEndpoints.POSITION_BOOK, body);

        this.metrics.incrementBrokerCalls('zebu', 'getPositions', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const positions: any[] = Array.isArray(data) ? data : data?.stat === 'Ok' ? data.data || [] : [];
        return positions.map((p: any) => ({
          symbol: p.tsym || p.tradingsymbol || '',
          quantity: parseInt(p.netqty || '0', 10),
          avgPrice: parseFloat(p.netupldprc || p.avgprc || '0'),
          currentPrice: parseFloat(p.lp || p.ltp || '0'),
          unrealizedPnl: parseFloat(p.urmtom || '0'),
          realizedPnl: parseFloat(p.rpnl || '0'),
        }));
      } catch (error: any) {
        this.metrics.incrementBrokerCalls('zebu', 'getPositions', 'failure');
        this.logger.error(`[Zebu] getPositions failed: ${error.message}`);
        return [];
      }
    });
  }

  async getHoldings(token: string, clientCode: string): Promise<HoldingResponse[]> {
    if (this.isMock) {
      return [
        {
          symbol: 'TATASTEEL-EQ',
          quantity: 100,
          avgPrice: 140.5,
          currentPrice: 142.1,
          unrealizedPnl: 160.0,
        },
      ];
    }

    return this.circuitBreaker.execute('zebu-holdings', async () => {
      await this.rateLimiter.throttle('zebu', 'market');
      const start = Date.now();
      try {
        const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode, prd: 'C' })}&jKey=${token}`;
        const data = await this.executeBrokerPost(token, clientCode, ZebuEndpoints.HOLDINGS, body);

        this.metrics.incrementBrokerCalls('zebu', 'getHoldings', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const holdings: any[] = Array.isArray(data) ? data : data?.stat === 'Ok' ? data.data || [] : [];
        return holdings.map((h: any) => ({
          symbol: h.tsym || h.tradingsymbol || '',
          quantity: parseInt(h.holdqty || h.quantity || '0', 10),
          avgPrice: parseFloat(h.avgprc || h.averageprice || '0'),
          currentPrice: parseFloat(h.lp || h.ltp || '0'),
          unrealizedPnl: parseFloat(h.upldpnl || h.pnl || '0'),
        }));
      } catch (error: any) {
        this.metrics.incrementBrokerCalls('zebu', 'getHoldings', 'failure');
        this.logger.error(`[Zebu] getHoldings failed: ${error.message}`);
        return [];
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------

  async placeOrder(
    token: string,
    clientCode: string,
    order: OrderRequest,
    httpsAgent?: any,
  ): Promise<OrderResponse> {
    if (this.isMock) {
      const mockId = `mock_zebu_order_${Math.floor(100000 + Math.random() * 900000)}`;
      this.logger.log(
        `[SANDBOX MOCK] Placed Zebu order ${mockId} for ${clientCode}: ${order.side} ${order.quantity} x ${order.symbol}`,
      );
      return { brokerOrderId: mockId, status: 'EXECUTED', message: 'Mock execution successful' };
    }

    return this.circuitBreaker.execute('zebu-place-order', async () => {
      await this.rateLimiter.throttle('zebu', 'trading');
      const start = Date.now();
      try {
        const exch = order.exchange || 'NSE';
        let prd = 'I'; // Default to MIS ('I') for Equity Cash
        if (
          exch === 'NFO' ||
          exch === 'MCX' ||
          exch === 'CDS' ||
          exch === 'BFO' ||
          exch === 'BCD'
        ) {
          prd = 'M'; // NRML for Derivatives/Commodities/Currencies
        }

        let tsym = order.symbol;
        if ((exch === 'NSE' || exch === 'BSE') && !tsym.endsWith('-EQ')) {
          tsym = `${tsym}-EQ`;
        }

        const jData: Record<string, unknown> = {
          uid: clientCode,
          actid: clientCode,
          exch,
          tsym,
          qty: order.quantity.toString(),
          prc: (order.price ?? 0).toString(),
          trgprc: (order.triggerPrice ?? 0).toString(),
          dscqty: '0',
          prd,
          trantype: order.side === 'BUY' ? 'B' : 'S',
          prctyp: this.mapOrderType(order.orderType),
          ret: 'DAY',
          remarks: 'AutoTrade',
          ordersource: 'API',
        };

        if (order.squareoff) {
          jData['bprc'] = order.squareoff.toString();
        }
        if (order.stoploss) {
          jData['blprc'] = order.stoploss.toString();
        }

        this.logger.log(
          `[Zebu Mynt API] Sending PlaceOrder request to ${ZebuEndpoints.PLACE_ORDER}:\n` +
          `jData Payload: ${JSON.stringify(jData, null, 2)}`
        );

        const body = `jData=${JSON.stringify(jData)}&jKey=${token}`;
        const data = await this.executeBrokerPost(
          token,
          clientCode,
          ZebuEndpoints.PLACE_ORDER,
          body,
          8000,
          httpsAgent,
        );

        this.metrics.incrementBrokerCalls('zebu', 'placeOrder', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        if (data && data.stat === 'Ok' && data.norenordno) {
          return { brokerOrderId: data.norenordno, status: 'PENDING' };
        }
        return { brokerOrderId: '', status: 'REJECTED', message: data?.emsg || 'Order rejected by Zebu' };
      } catch (error: any) {
        this.metrics.incrementBrokerCalls('zebu', 'placeOrder', 'failure');
        this.metrics.incrementBrokerFailures('zebu', 'placeOrder');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);
        this.logger.error(`[Zebu] placeOrder failed: ${error.message}`);
        return { brokerOrderId: '', status: 'REJECTED', message: error.message };
      }
    });
  }

  async modifyOrder(
    token: string,
    clientCode: string,
    orderId: string,
    _variety: string,
    order: { quantity: number; price?: number; ordertype?: string; producttype?: string; duration?: string },
  ): Promise<OrderResponse> {
    if (this.isMock) {
      this.logger.log(`[SANDBOX MOCK] Modifying Zebu order ${orderId}`);
      return { brokerOrderId: orderId, status: 'PENDING', message: 'Mock modification successful' };
    }

    return this.circuitBreaker.execute('zebu-modify-order', async () => {
      await this.rateLimiter.throttle('zebu', 'trading');
      const start = Date.now();
      try {
        const jData: Record<string, unknown> = {
          uid: clientCode,
          norenordno: orderId,
          qty: order.quantity.toString(),
          prc: (order.price ?? 0).toString(),
          prctyp: order.ordertype ? this.mapOrderType(order.ordertype) : 'LMT',
          ret: order.duration || 'DAY',
        };

        const body = `jData=${JSON.stringify(jData)}&jKey=${token}`;
        const data = await this.executeBrokerPost(token, clientCode, ZebuEndpoints.MODIFY_ORDER, body);

        this.metrics.incrementBrokerCalls('zebu', 'modifyOrder', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        if (data && data.stat === 'Ok' && data.result) {
          return { brokerOrderId: data.result, status: 'PENDING' };
        }
        return { brokerOrderId: '', status: 'REJECTED', message: data?.emsg || 'Modify rejected by Zebu' };
      } catch (error: any) {
        this.metrics.incrementBrokerCalls('zebu', 'modifyOrder', 'failure');
        this.metrics.incrementBrokerFailures('zebu', 'modifyOrder');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);
        return { brokerOrderId: '', status: 'REJECTED', message: error.message };
      }
    });
  }

  async cancelOrder(
    token: string,
    clientCode: string,
    orderId: string,
    _variety: string,
  ): Promise<OrderResponse> {
    if (this.isMock) {
      this.logger.log(`[SANDBOX MOCK] Cancelling Zebu order ${orderId}`);
      return { brokerOrderId: orderId, status: 'CANCELLED', message: 'Mock cancellation successful' };
    }

    return this.circuitBreaker.execute('zebu-cancel-order', async () => {
      await this.rateLimiter.throttle('zebu', 'trading');
      const start = Date.now();
      try {
        const jData = { uid: clientCode, norenordno: orderId };
        const body = `jData=${JSON.stringify(jData)}&jKey=${token}`;
        const data = await this.executeBrokerPost(token, clientCode, ZebuEndpoints.CANCEL_ORDER, body);

        this.metrics.incrementBrokerCalls('zebu', 'cancelOrder', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        if (data && data.stat === 'Ok' && data.result) {
          return { brokerOrderId: data.result, status: 'CANCELLED' };
        }
        return { brokerOrderId: '', status: 'REJECTED', message: data?.emsg || 'Cancel rejected by Zebu' };
      } catch (error: any) {
        this.metrics.incrementBrokerCalls('zebu', 'cancelOrder', 'failure');
        this.metrics.incrementBrokerFailures('zebu', 'cancelOrder');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);
        return { brokerOrderId: '', status: 'REJECTED', message: error.message };
      }
    });
  }

  async getOrderStatus(
    token: string,
    clientCode: string,
    brokerOrderId: string,
  ): Promise<OrderResponse> {
    if (this.isMock) {
      return { brokerOrderId, status: 'EXECUTED', message: 'Mock execution successful' };
    }

    try {
      const body = `jData=${JSON.stringify({ uid: clientCode })}&jKey=${token}`;
      const data = await this.executeBrokerPost(token, clientCode, ZebuEndpoints.ORDER_BOOK, body);

      const orders: any[] = Array.isArray(data) ? data : [];
      const found = orders.find((o) => o.norenordno === brokerOrderId);
      if (found) {
        return {
          brokerOrderId: found.norenordno,
          status: this.mapOrderStatus(found.status),
          message: found.rejreason || found.status,
        };
      }
      throw new NotFoundException(`Order ${brokerOrderId} not found in Zebu order book`);
    } catch (error: any) {
      this.logger.error(`[Zebu] getOrderStatus failed: ${error.message}`);
      throw error;
    }
  }

  async getOrders(token: string, clientCode: string): Promise<any[]> {
    if (this.isMock) {
      return [
        {
          brokerOrderId: 'mock_zebu_order_123',
          symbol: 'SBIN-EQ',
          quantity: 10,
          price: 750.0,
          side: 'BUY',
          status: 'COMPLETE',
          rejreason: '',
        },
      ];
    }

    return this.circuitBreaker.execute('zebu-orders', async () => {
      await this.rateLimiter.throttle('zebu', 'market');
      const start = Date.now();
      try {
        const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode })}&jKey=${token}`;
        const data = await this.executeBrokerPost(token, clientCode, ZebuEndpoints.ORDER_BOOK, body);

        this.metrics.incrementBrokerCalls('zebu', 'getOrders', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const orders: any[] = Array.isArray(data) ? data : [];
        return orders.map((o) => ({
          brokerOrderId: o.norenordno || '',
          symbol: o.tsym || o.tradingsymbol || '',
          quantity: parseInt(o.qty || '0', 10),
          price: parseFloat(o.prc || '0'),
          side: o.trantype || '',
          status: this.mapOrderStatus(o.status),
          rejreason: o.rejreason || '',
        }));
      } catch (error: any) {
        this.metrics.incrementBrokerCalls('zebu', 'getOrders', 'failure');
        this.logger.error(`[Zebu] getOrders failed: ${error.message}`);
        return [];
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Trade book
  // ---------------------------------------------------------------------------

  async getTradeBook(token: string, clientCode: string): Promise<BrokerTrade[]> {
    if (this.isMock) {
      return [
        {
          tradeId: 'mock_zebu_trade_1',
          orderId: 'mock_zebu_order_1',
          symbol: 'SBIN-EQ',
          quantity: 10,
          price: 750.0,
          side: 'BUY',
          executedAt: new Date(),
        },
      ];
    }

    return this.circuitBreaker.execute('zebu-trade-book', async () => {
      await this.rateLimiter.throttle('zebu', 'market');
      const start = Date.now();
      try {
        const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode })}&jKey=${token}`;
        const data = await this.executeBrokerPost(token, clientCode, ZebuEndpoints.TRADE_BOOK, body);

        this.metrics.incrementBrokerCalls('zebu', 'getTradeBook', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const trades: any[] = Array.isArray(data) ? data : [];
        return trades.map((t: any) => ({
          tradeId: t.flfilledtm || t.tradeid || '',
          orderId: t.norenordno || '',
          symbol: t.tsym || '',
          quantity: parseInt(t.flqty || '0', 10),
          price: parseFloat(t.flprc || '0'),
          side: t.trantype === 'B' ? 'BUY' : 'SELL',
          executedAt: t.flfilledtm ? new Date(t.flfilledtm) : new Date(),
        }));
      } catch (error: any) {
        this.metrics.incrementBrokerCalls('zebu', 'getTradeBook', 'failure');
        this.metrics.incrementBrokerFailures('zebu', 'getTradeBook');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);
        throw error;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Market data
  // ---------------------------------------------------------------------------

  async getLtp(
    exchange: string,
    symbol: string,
    token?: string,
    _symbolToken?: string,
  ): Promise<{ ltp: number; close: number; open: number; high: number; low: number } | null> {
    if (this.isMock) {
      const base = 500 + Math.random() * 2000;
      return {
        ltp: parseFloat(base.toFixed(2)),
        close: parseFloat((base * 0.99).toFixed(2)),
        open: parseFloat((base * 0.98).toFixed(2)),
        high: parseFloat((base * 1.02).toFixed(2)),
        low: parseFloat((base * 0.97).toFixed(2)),
      };
    }

    try {
      const body = `jData=${JSON.stringify({ uid: '', exch: exchange.toUpperCase(), token: _symbolToken || symbol })}&jKey=${token || ''}`;
      const data = await this.executeBrokerPost(token || null, null, ZebuEndpoints.GET_QUOTES, body);

      if (data && data.stat === 'Ok') {
        return {
          ltp: parseFloat(data.lp || '0'),
          close: parseFloat(data.c || '0'),
          open: parseFloat(data.o || '0'),
          high: parseFloat(data.h || '0'),
          low: parseFloat(data.l || '0'),
        };
      }
      this.logger.warn(`[Zebu] getLtp returned non-ok: ${JSON.stringify(data)}`);
      return null;
    } catch (error: any) {
      this.logger.error(`[Zebu] getLtp failed for ${symbol}@${exchange}: ${error.message}`);
      return null;
    }
  }

  async getLtpData(
    token: string,
    exchange: string,
    symbol: string,
    symbolToken: string,
  ): Promise<BrokerLtp> {
    if (this.isMock) {
      return { exchange, symbol, token: symbolToken, ltp: 752.4, timestamp: new Date() };
    }

    const cacheKey = `broker:ltp:zebu:${exchange}:${symbolToken}`;
    if (this.redisService.isHealthy()) {
      try {
        const cached = await this.redisService.getClient().get(cacheKey);
        if (cached) return JSON.parse(cached);
      } catch (err: any) {
        this.logger.error(`[Zebu] Error reading LTP cache: ${err.message}`);
      }
    }

    const ltpVal = await this.circuitBreaker.execute('zebu-ltp', async () => {
      await this.rateLimiter.throttle('zebu', 'market');
      const start = Date.now();
      try {
        const body = `jData=${JSON.stringify({ uid: '', exch: exchange.toUpperCase(), token: symbolToken })}&jKey=${token}`;
        const data = await this.executeBrokerPost(token, null, ZebuEndpoints.GET_QUOTES, body);

        this.metrics.incrementBrokerCalls('zebu', 'getLtpData', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        if (data && data.stat === 'Ok') {
          return {
            exchange,
            symbol: data.tsym || symbol,
            token: symbolToken,
            ltp: parseFloat(data.lp || '0'),
            timestamp: new Date(),
          };
        }
        throw new Error(data?.emsg || 'Failed to fetch LTP from Zebu');
      } catch (error: any) {
        this.metrics.incrementBrokerCalls('zebu', 'getLtpData', 'failure');
        this.metrics.incrementBrokerFailures('zebu', 'getLtpData');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);
        throw error;
      }
    });

    if (this.redisService.isHealthy()) {
      try {
        await this.redisService.getClient().set(cacheKey, JSON.stringify(ltpVal), 'EX', 1);
      } catch (err: any) {
        this.logger.error(`[Zebu] Error saving LTP cache: ${err.message}`);
      }
    }

    return ltpVal;
  }

  // ---------------------------------------------------------------------------
  // Order details
  // ---------------------------------------------------------------------------

  async getOrderDetails(
    token: string,
    clientCode: string,
    orderId: string,
  ): Promise<OrderResponse> {
    if (this.isMock) {
      return { brokerOrderId: orderId, status: 'EXECUTED', message: 'Mock details successful' };
    }
    return this.getOrderStatus(token, clientCode, orderId);
  }

  // ---------------------------------------------------------------------------
  // Private utilities
  // ---------------------------------------------------------------------------

  private mapOrderType(orderType?: string): string {
    switch ((orderType || '').toUpperCase()) {
      case 'MARKET': return 'MKT';
      case 'LIMIT':  return 'LMT';
      case 'SL':     return 'SL-LMT';
      case 'SL-M':   return 'SL-MKT';
      default:       return 'LMT';
    }
  }

  private mapOrderStatus(
    brokerStatus: string,
  ): 'PENDING' | 'EXECUTED' | 'REJECTED' | 'CANCELLED' {
    const s = (brokerStatus || '').toUpperCase();
    if (s === 'COMPLETE' || s === 'FILLED' || s === 'EXECUTED') return 'EXECUTED';
    if (s === 'REJECTED') return 'REJECTED';
    if (s === 'CANCELLED' || s === 'CANCELED') return 'CANCELLED';
    return 'PENDING';
  }
}
