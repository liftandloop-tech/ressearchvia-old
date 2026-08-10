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

/**
 * ZebuService — BrokerAdapter implementation for the Zebu Base API.
 *
 * Authentication flow (no OAuth):
 *  1. SHA-256 hash the user's password (pwd).
 *  2. User provides the current 6-digit TOTP code as `totpKey`.
 *  3. POST to /QuickAuth — receive `susertoken`.
 *  4. All subsequent calls pass `jKey=<susertoken>` in the URL-encoded body.
 *
 * Request format for authenticated calls:
 *   POST <baseUrl><endpoint>
 *   Content-Type: application/x-www-form-urlencoded
 *   Body: jData=<JSON-string>&jKey=<susertoken>
 *
 * Session validity: susertoken expires daily at midnight IST.
 */
@Injectable()
export class ZebuService extends BrokerAdapter implements BrokerClient {
  private readonly logger = new Logger(ZebuService.name);
  private readonly isMock: boolean;
  private readonly authUrl: string;
  private readonly baseUrl: string;
  private readonly tokenToUidMap = new Map<string, string>();

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    private readonly redisService: RedisService,
    private readonly metrics: MetricsService,
    private readonly circuitBreaker: CircuitBreakerService,
    private readonly rateLimiter: BrokerRateLimiterService,
  ) {
    super();
    const mockVal = this.configService.get<any>('MOCK_BROKERS', true);
    this.isMock = mockVal === true || mockVal === 'true';
    this.authUrl =
      this.configService.get<string>('ZEBU_AUTH_URL') ||
      'https://go.mynt.in/NorenWClientTP';
    this.baseUrl =
      this.configService.get<string>('ZEBU_BASE_URL') ||
      'https://go.mynt.in/NorenWClientTP';
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /**
   * Build the URL-encoded body expected by every Zebu Base API call.
   *   jData=<JSON>&jKey=<susertoken>
   */
  private buildBody(data: Record<string, unknown>, susertoken: string): string {
    return `jData=${JSON.stringify(data)}&jKey=${susertoken}`;
  }

  /** Headers for authenticated POST requests to Zebu */
  private getHeaders() {
    return {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  /** SHA-256 hash of the password, hex-encoded — required by Zebu QuickAuth */
  private hashPassword(pwd: string): string {
    return createHash('sha256').update(pwd).digest('hex');
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
  // Session management
  // ---------------------------------------------------------------------------

  /**
   * Login using Zebu QuickAuth (no OAuth redirect).
   *
   * Credentials:
   *  - clientCode: Zebu User ID (uid)
   *  - mpin:       Plain-text password — will be SHA-256 hashed before sending
   *  - totpKey:    Current 6-digit TOTP code (same as Angel One flow — user provides the live OTP)
   */
  async generateSession(credentials: {
    clientCode: string;
    password: string;
    totpKey: string;
    apiKey?: string;
    vendorCode?: string;
  }): Promise<SessionResponse> {
    this.logger.log(`[Zebu] Generating session for UID: ${credentials.clientCode}`);

    if (this.isMock) {
      this.logger.log(`[SANDBOX MOCK] Generating Zebu session for ${credentials.clientCode}`);
      return {
        accessToken: `mock_zebu_token_${credentials.clientCode}_${Date.now()}`,
        refreshToken: '',
        tokenExpiry: this.midnightIst(),
      };
    }

    try {
      // Per-user credentials stored in the UserBroker record at link time
      const apiKey = credentials.apiKey;
      const vendorCode = credentials.vendorCode;

      if (!apiKey || !vendorCode) {
        throw new BadRequestException(
          'Zebu API key and vendor code are required. Please re-link your Zebu account and provide your appkey and vendor code.',
        );
      }

      const hashedPwd = this.hashPassword(credentials.password);
      // User supplies the live 6-digit TOTP code directly (mirrors Angel One flow)
      const otpCode = credentials.totpKey;

      // Noren/Zebu API expects appkey to be SHA-256 of "userid|vendor_key"
      const hashedAppkey = this.hashPassword(`${credentials.clientCode}|${apiKey}`);

      /**
       * QuickAuth body has jData — only jData (no jKey yet, since we are
       * obtaining the token here).
       */
      const jData = {
        apkversion: '1.0',
        uid: credentials.clientCode,
        pwd: hashedPwd,
        factor2: otpCode,
        vc: vendorCode,
        appkey: hashedAppkey,
        imei: 'abc1234',
        source: 'API',
      };

      const body = `jData=${JSON.stringify(jData)}`;

      const response = await firstValueFrom(
        this.httpService.post(`${this.authUrl}${ZebuEndpoints.QUICK_AUTH}`, body, {
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        }),
      );

      const data = response.data;

      // Zebu returns `stat: 'Ok'` on success
      if (data && (data.stat === 'Ok' || data.susertoken)) {
        this.logger.log(`[Zebu] Session generated successfully for ${credentials.clientCode}`);
        this.tokenToUidMap.set(data.susertoken, credentials.clientCode);
        return {
          accessToken: data.susertoken,
          refreshToken: '',             // Zebu Base API has no refresh token
          tokenExpiry: this.midnightIst(),
        };
      }

      throw new BadRequestException(data?.emsg || 'Zebu login failed');
    } catch (error: any) {
      const detail = error.response?.data;
      this.logger.error(`[Zebu] Session generation error: ${error.message}`, error.stack);
      if (detail) {
        this.logger.error(`[Zebu] Error details: ${JSON.stringify(detail)}`);
      }
      const errMessage = detail?.emsg || error.message;
      throw new BadRequestException(`Zebu broker authentication error: ${errMessage}`);
    }
  }


  /**
   * Zebu Base API does not use OAuth — these methods are no-ops.
   */
  async getAuthorizationUrl(_state: string): Promise<string> {
    throw new BadRequestException('Zebu Base API does not use OAuth — use generateSession() instead');
  }

  async completeAuthorization(_callbackData: BrokerCallbackData): Promise<BrokerSession> {
    throw new BadRequestException('Zebu Base API does not use OAuth callbacks');
  }

  /**
   * Validate session by checking that the token exists and that we are still
   * before midnight IST (Zebu tokens expire daily at midnight IST).
   */
  async validateSession(token: string): Promise<boolean> {
    if (this.isMock) {
      return token.startsWith('mock_zebu_token_');
    }
    if (!token || token.length === 0) return false;
    // Token expires at midnight IST; check if now < midnight IST today
    return Date.now() < this.midnightIst().getTime();
  }

  /**
   * Zebu Base tokens cannot be refreshed — a new login is required.
   * Return the existing token so callers do not fail; the session service
   * should re-login when validateSession() returns false.
   */
  async refreshSession(token: string, _refreshToken: string): Promise<SessionResponse> {
    if (this.isMock) {
      return {
        accessToken: `mock_zebu_token_refreshed_${Date.now()}`,
        refreshToken: '',
        tokenExpiry: this.midnightIst(),
      };
    }
    this.logger.warn('[Zebu] refreshSession called — Zebu tokens expire at midnight IST; re-login is required');
    return {
      accessToken: token,
      refreshToken: '',
      tokenExpiry: this.midnightIst(),
    };
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
        exchanges: ['NSE', 'BSE', 'NFO', 'MCX'],
        products: ['CNC', 'MIS', 'NRML'],
        lastlogintime: new Date().toISOString(),
        brokerid: 'ZEBU',
        activeStatus: 'ACTIVE',
      };
    }

    try {
      const uid = clientCode || this.tokenToUidMap.get(token) || '';
      const body = this.buildBody({ uid, actid: uid }, token);
      const response = await firstValueFrom(
        this.httpService.post(`${this.baseUrl}${ZebuEndpoints.CLIENT_DETAILS}`, body, {
          headers: this.getHeaders(),
        }),
      );

      const data = response.data;
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
      const body = this.buildBody({ uid: clientCode, actid: clientCode }, token);
      const response = await firstValueFrom(
        this.httpService.post(`${this.baseUrl}${ZebuEndpoints.LIMITS}`, body, {
          headers: this.getHeaders(),
        }),
      );

      const data = response.data;
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
        const body = this.buildBody({ uid: clientCode, actid: clientCode }, token);
        const response = await firstValueFrom(
          this.httpService.post(`${this.baseUrl}${ZebuEndpoints.POSITION_BOOK}`, body, {
            headers: this.getHeaders(),
          }),
        );

        this.metrics.incrementBrokerCalls('zebu', 'getPositions', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const data = response.data;
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
        const body = this.buildBody({ uid: clientCode, actid: clientCode, prd: 'C' }, token);
        const response = await firstValueFrom(
          this.httpService.post(`${this.baseUrl}${ZebuEndpoints.HOLDINGS}`, body, {
            headers: this.getHeaders(),
          }),
        );

        this.metrics.incrementBrokerCalls('zebu', 'getHoldings', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const data = response.data;
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
          `[Zebu Mynt API] Sending PlaceOrder request to ${this.baseUrl}${ZebuEndpoints.PLACE_ORDER}:\n` +
          `jData Payload: ${JSON.stringify(jData, null, 2)}`
        );

        const body = this.buildBody(jData, token);
        const response = await firstValueFrom(
          this.httpService.post(`${this.baseUrl}${ZebuEndpoints.PLACE_ORDER}`, body, {
            headers: this.getHeaders(),
            ...(httpsAgent ? { httpsAgent } : {}),
          }),
        );

        const data = response.data;
        this.logger.log(
          `[Zebu Mynt API] PlaceOrder response received from ${this.baseUrl}${ZebuEndpoints.PLACE_ORDER}:\n` +
          `Response: ${JSON.stringify(data, null, 2)}`
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

        const body = this.buildBody(jData, token);
        const response = await firstValueFrom(
          this.httpService.post(`${this.baseUrl}${ZebuEndpoints.MODIFY_ORDER}`, body, {
            headers: this.getHeaders(),
          }),
        );

        this.metrics.incrementBrokerCalls('zebu', 'modifyOrder', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const data = response.data;
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
        const body = this.buildBody(jData, token);
        const response = await firstValueFrom(
          this.httpService.post(`${this.baseUrl}${ZebuEndpoints.CANCEL_ORDER}`, body, {
            headers: this.getHeaders(),
          }),
        );

        this.metrics.incrementBrokerCalls('zebu', 'cancelOrder', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const data = response.data;
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
      const jData = { uid: clientCode };
      const body = this.buildBody(jData, token);
      const response = await firstValueFrom(
        this.httpService.post(`${this.baseUrl}${ZebuEndpoints.ORDER_BOOK}`, body, {
          headers: this.getHeaders(),
        }),
      );

      const data = response.data;
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
        const jData = { uid: clientCode, actid: clientCode };
        const body = this.buildBody(jData, token);
        const response = await firstValueFrom(
          this.httpService.post(`${this.baseUrl}${ZebuEndpoints.ORDER_BOOK}`, body, {
            headers: this.getHeaders(),
          }),
        );

        this.metrics.incrementBrokerCalls('zebu', 'getOrders', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const data = response.data;
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
        const jData = { uid: clientCode, actid: clientCode };
        const body = this.buildBody(jData, token);
        const response = await firstValueFrom(
          this.httpService.post(`${this.baseUrl}${ZebuEndpoints.TRADE_BOOK}`, body, {
            headers: this.getHeaders(),
          }),
        );

        this.metrics.incrementBrokerCalls('zebu', 'getTradeBook', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const data = response.data;
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
      const uid = this.tokenToUidMap.get(token || '') || '';
      // Zebu GetQuotes uses exchange|token format — symbol acts as token here
      const jData = {
        uid,
        exch: exchange.toUpperCase(),
        token: _symbolToken || symbol,
      };
      const body = this.buildBody(jData, token || '');
      const response = await firstValueFrom(
        this.httpService.post(`${this.baseUrl}${ZebuEndpoints.GET_QUOTES}`, body, {
          headers: this.getHeaders(),
        }),
      );

      const data = response.data;
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
        const jData = { uid: '', exch: exchange.toUpperCase(), token: symbolToken };
        const body = this.buildBody(jData, token);
        const response = await firstValueFrom(
          this.httpService.post(`${this.baseUrl}${ZebuEndpoints.GET_QUOTES}`, body, {
            headers: this.getHeaders(),
          }),
        );

        this.metrics.incrementBrokerCalls('zebu', 'getLtpData', 'success');
        this.metrics.observeBrokerLatency('zebu', Date.now() - start);

        const data = response.data;
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
  // Order details (Zebu has no dedicated single-order endpoint — scan order book)
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


  /**
   * Compute midnight IST (UTC+5:30) for the current day.
   * Zebu session tokens expire at midnight IST regardless of server timezone.
   */
  private midnightIst(): Date {
    const now = new Date();
    // IST offset: +5:30 = +330 minutes
    const istOffsetMs = 5.5 * 60 * 60 * 1000;
    const istNow = new Date(now.getTime() + istOffsetMs);
    const midnightIst = new Date(
      Date.UTC(istNow.getUTCFullYear(), istNow.getUTCMonth(), istNow.getUTCDate() + 1),
    );
    // Convert back to UTC
    return new Date(midnightIst.getTime() - istOffsetMs);
  }

  /**
   * Map canonical order type to Zebu's prctyp values:
   *   LMT = Limit, MKT = Market, SL-LMT = Stop-Limit, SL-MKT = Stop-Market
   */
  private mapOrderType(orderType?: string): string {
    switch ((orderType || '').toUpperCase()) {
      case 'MARKET': return 'MKT';
      case 'LIMIT':  return 'LMT';
      case 'SL':     return 'SL-LMT';
      case 'SL-M':   return 'SL-MKT';
      default:       return 'LMT';
    }
  }




  /**
   * Map Zebu order status strings to the canonical platform statuses.
   */
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
