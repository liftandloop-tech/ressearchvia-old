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
import { AngelOneEndpoints } from './angel-one-endpoints';
import { firstValueFrom } from 'rxjs';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { BrokerRateLimiterService } from '../../infrastructure/redis/broker-rate-limiter.service';

import { InstrumentsService } from '../../instruments/instruments.service';

@Injectable()
export class AngelOneService extends BrokerAdapter implements BrokerClient {
  private readonly logger = new Logger(AngelOneService.name);
  private readonly isMock: boolean;
  private readonly baseUrl = 'https://apiconnect.angelone.in';

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
    private readonly redisService: RedisService,
    private readonly metrics: MetricsService,
    private readonly circuitBreaker: CircuitBreakerService,
    private readonly rateLimiter: BrokerRateLimiterService,
    private readonly instrumentsService: InstrumentsService,
  ) {
    super();
    const mockVal = this.configService.get<any>('MOCK_BROKERS', true);
    this.isMock = mockVal === true || mockVal === 'true';
  }

  private getHeaders(token?: string, proxyIp?: string) {
    const apiKey = this.configService.get<string>('ANGEL_ONE_API_KEY') || '';
    const headers: any = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-UserType': 'USER',
      'X-SourceID': 'WEB',
      'X-PrivateKey': apiKey,
      'X-ClientLocalIP': '192.168.1.100',
      'X-ClientPublicIP': proxyIp || '106.193.147.98',
      'X-MACaddress': '02:00:00:00:00:00',
    };
    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }
    return headers;
  }

  capabilities(): BrokerCapabilities {
    return {
      positions: true,
      holdings: true,
      funds: true,
      gtt: false,
      margin: true,
    };
  }

  async healthCheck(): Promise<BrokerHealthResponse> {
    const start = Date.now();
    if (this.isMock) {
      return { reachable: true, responseTimeMs: 10 };
    }
    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}/health`, { timeout: 3000 }),
      );
      return {
        reachable: response.status === 200,
        responseTimeMs: Date.now() - start,
      };
    } catch {
      try {
        const response: any = await firstValueFrom(
          this.httpService.request({ method: 'OPTIONS', url: this.baseUrl, timeout: 3000 }),
        );
        return {
          reachable: response.status < 500,
          responseTimeMs: Date.now() - start,
        };
      } catch {
        return {
          reachable: false,
          responseTimeMs: Date.now() - start,
        };
      }
    }
  }

  async generateSession(credentials: {
    clientCode: string;
    password: string;
    totpKey: string;
  }): Promise<SessionResponse> {
    this.logger.log(
      `Generating session for Client Code: ${credentials.clientCode}`,
    );

    if (this.isMock) {
      this.logger.log(
        `[SANDBOX MOCK] Generating session for ${credentials.clientCode}`,
      );
      return {
        accessToken: `mock_angel_one_access_token_${credentials.clientCode}_${Date.now()}`,
        refreshToken: `mock_angel_one_refresh_token_${credentials.clientCode}`,
        tokenExpiry: new Date(Date.now() + 12 * 60 * 60 * 1000), // Valid for 12 hours
      };
    }

    try {
      const apiKey = this.configService.get<string>('ANGEL_ONE_API_KEY');
      if (!apiKey) {
        throw new BadRequestException(
          'Angel One API Key is missing in environment variables',
        );
      }

      const response = await firstValueFrom(
        this.httpService.post(
          `${this.baseUrl}${AngelOneEndpoints.LOGIN}`,
          {
            clientcode: credentials.clientCode,
            password: credentials.password,
            totp: credentials.totpKey,
          },
          {
            headers: {
              'Content-Type': 'application/json',
              Accept: 'application/json',
              'X-UserType': 'USER',
              'X-SourceID': 'WEB',
              'X-PrivateKey': apiKey,
              'X-ClientLocalIP': '192.168.1.100',
              'X-ClientPublicIP': '106.193.147.98',
              'X-MACaddress': '02:00:00:00:00:00',
            },
          },
        ),
      );

      if (response.data && response.data.status === true) {
        const data = response.data.data;
        return {
          accessToken: data.jwtToken,
          refreshToken: data.refreshToken,
          tokenExpiry: new Date(Date.now() + 18 * 60 * 60 * 1000),
        };
      }

      throw new BadRequestException(
        response.data.message || 'Angel One login failed',
      );
    } catch (error: any) {
      const detail = error.response?.data;
      this.logger.error(`Angel One session generation error: ${error.message}`, error.stack);
      if (detail) {
        this.logger.error(`Angel One error details: ${JSON.stringify(detail)}`);
      }
      const errMessage = detail?.message || error.message;
      throw new BadRequestException(
        `Broker authentication error: ${errMessage}`,
      );
    }
  }

  async getAuthorizationUrl(state: string): Promise<string> {
    const apiKey = this.configService.get<string>('ANGEL_ONE_API_KEY') || '';
    const redirectUrl = this.configService.get<string>('ANGEL_ONE_REDIRECT_URL') || '';
    if (!apiKey) {
      throw new BadRequestException('Angel One API Key is not configured');
    }
    return `https://smartapi.angelone.in/publisher-login?api_key=${apiKey}&redirect_url=${encodeURIComponent(
      redirectUrl,
    )}&state=${state}`;
  }

  async completeAuthorization(callbackData: BrokerCallbackData): Promise<BrokerSession> {
    this.logger.log(`Completing authorization flow for Angel One`);
    const authToken = callbackData.params.auth_token;
    if (!authToken) {
      throw new BadRequestException('Authorization token (auth_token) is missing in callback data');
    }

    if (this.isMock) {
      this.logger.log(`[SANDBOX MOCK] Generating session using auth_token: ${authToken}`);
      return {
        accessToken: `mock_angel_one_access_token_mockclient_${Date.now()}`,
        refreshToken: `mock_angel_one_refresh_token_mockclient`,
        expiresAt: new Date(Date.now() + 18 * 60 * 60 * 1000),
      };
    }

    try {
      // The auth_token from AngelOne publisher OAuth callback is the session token.
      // Its payload contains a nested `token` (trade_access_token) and an expiry.
      const payloadBase64 = authToken.split('.')[1];
      const payloadJson = Buffer.from(payloadBase64, 'base64').toString('utf8');
      const outerPayload = JSON.parse(payloadJson);

      // Determine expiry from the outer JWT's `exp` claim
      const expMs = outerPayload.exp ? outerPayload.exp * 1000 : Date.now() + 18 * 60 * 60 * 1000;
      const expiresAt = new Date(expMs);

      const refreshToken = callbackData.params.refresh_token || '';

      this.logger.log(
        `AngelOne OAuth callback processed. Username: ${outerPayload.username}, expires: ${expiresAt.toISOString()}`,
      );

      // Store the auth_token directly as accessToken — it's the publisher session token
      // Include the username as brokerUserId so the controller can set brokerClientId correctly
      return {
        accessToken: authToken,
        refreshToken,
        expiresAt,
        brokerUserId: outerPayload.username || '',
      };
    } catch (error: any) {
      this.logger.error(`Angel One token extraction error: ${error.message}`, error.stack);
      throw new BadRequestException(`Broker token extraction error: ${error.message}`);
    }
  }

  async validateSession(token: string): Promise<boolean> {
    if (this.isMock) {
      return token.startsWith('mock_angel_one_access_token_');
    }

    // Validate session by checking the JWT expiry locally.
    // AngelOne publisher OAuth tokens (auth_token) cannot be validated via /getProfile
    // (that endpoint only accepts tokens from the loginByPassword flow).
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return false;

      const payloadJson = Buffer.from(parts[1], 'base64').toString('utf8');
      const payload = JSON.parse(payloadJson);

      if (!payload.exp) return false;

      const expiryMs = payload.exp * 1000;
      const isValid = Date.now() < expiryMs;

      this.logger.debug(
        `AngelOne session validation: exp=${new Date(expiryMs).toISOString()}, valid=${isValid}`,
      );

      return isValid;
    } catch {
      return false;
    }
  }

  async getMargin(token: string, clientCode: string): Promise<number> {
    const funds = await this.getFunds(token, clientCode);
    return funds.availableMargin;
  }

  async getProfile(token: string): Promise<ProfileResponse> {
    if (this.isMock) {
      return {
        clientcode: 'M320967',
        name: 'HARSH MODI',
        email: 'harsh.modi@example.com',
        mobileno: '919876543210',
        exchanges: ['NSE', 'BSE', 'NFO', 'MCX'],
        products: ['CNC', 'MIS', 'NRML', 'CO', 'BO'],
        lastlogintime: '18-Jun-2026 10:15:32',
        brokerid: 'ANGEL',
        activeStatus: 'ACTIVE',
      };
    }

    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}${AngelOneEndpoints.PROFILE}`, {
          headers: this.getHeaders(token),
        }),
      );

      if (response.data && response.data.status === true) {
        const data = response.data.data;
        return {
          clientcode: data.clientcode || '',
          name: data.name || '',
          email: data.email || '',
          mobileno: data.mobileno || '',
          exchanges: data.exchanges || [],
          products: data.products || [],
          lastlogintime: data.lastlogintime || '',
          brokerid: data.brokerid || '',
          activeStatus: data.activeStatus || 'ACTIVE',
        };
      }
      throw new Error(response.data?.message || 'Failed to fetch profile from broker');
    } catch (error) {
      this.logger.error(`Get profile failed: ${error.message}`);
      throw error;
    }
  }

  async getOrders(token: string, clientCode: string): Promise<any[]> {
    if (this.isMock) {
      return [
        {
          brokerOrderId: 'mock_angel_order_123',
          symbol: 'SBIN-EQ',
          quantity: 10,
          price: 750.0,
          side: 'BUY',
          status: 'COMPLETE',
          rejreason: '',
        },
      ];
    }

    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}${AngelOneEndpoints.ORDER_BOOK}`, {
          headers: this.getHeaders(token),
        }),
      );

      if (response.data && response.data.status === true && Array.isArray(response.data.data)) {
        return response.data.data.map((o: any) => ({
          brokerOrderId: o.orderid || '',
          symbol: o.tradingsymbol || '',
          quantity: parseInt(o.quantity || '0', 10),
          price: parseFloat(o.price || '0'),
          side: o.transactiontype || '',
          status: this.mapOrderStatus(o.status),
          rejreason: o.text || '',
        }));
      }
      return [];
    } catch (error: any) {
      this.logger.error(`Get orders failed: ${error.message}`);
      return [];
    }
  }

  async placeOrder(
    token: string,
    clientCode: string,
    order: OrderRequest,
    httpsAgent?: any,
  ): Promise<OrderResponse> {
    if (this.isMock) {
      const mockId = `mock_order_${Math.floor(100000 + Math.random() * 900000)}`;
      this.logger.log(
        `[SANDBOX MOCK] Placed order ${mockId} for ${clientCode}: ${order.side} ${order.quantity} x ${order.symbol} (${order.orderType})`,
      );
      return {
        brokerOrderId: mockId,
        status: 'EXECUTED',
        message: 'Mock execution successful',
      };
    }

    try {
      let variety = 'ROBO';
      let ordertype = order.orderType;

      const symbolToken = this.instrumentsService.findToken(order.symbol, order.exchange) || 'DUMMY_TOKEN';

      let proxyIp: string | undefined;
      if (httpsAgent && httpsAgent.options) {
        // Extract IP address from HttpsProxyAgent instance configuration parameters
        const proxyUrl = httpsAgent.options.href || httpsAgent.options.host || httpsAgent.options.hostname;
        if (proxyUrl) {
          try {
            const parsed = new URL(httpsAgent.options.href || `http://${proxyUrl}`);
            proxyIp = parsed.hostname;
          } catch (_) {}
        }
      }

      const response = await firstValueFrom(
        this.httpService.post(
          `${this.baseUrl}${AngelOneEndpoints.PLACE_ORDER}`,
          {
            variety,
            tradingsymbol: order.symbol,
            symboltoken: symbolToken,
            transactiontype: order.side,
            exchange: order.exchange,
            ordertype,
            producttype: 'BO',
            duration: 'DAY',
            price: order.price?.toString() || '0',
            triggerprice: order.triggerPrice?.toString() || '0',
            quantity: order.quantity.toString(),
            squareoff: order.squareoff?.toString(),
            stoploss: order.stoploss?.toString(),
            trailingStopLoss: order.trailingStopLoss?.toString(),
            scripconsent: 'yes',
          },
          {
            headers: this.getHeaders(token, proxyIp),
            ...(httpsAgent ? { httpsAgent } : {}),
          },
        ),
      );

      if (response.data && response.data.status === true) {
        return {
          brokerOrderId:
            response.data.data.scriptid || response.data.data.orderid,
          status: 'PENDING',
        };
      }

      return {
        brokerOrderId: '',
        status: 'REJECTED',
        message: response.data.message || 'Order rejected by broker',
      };
    } catch (error) {
      this.logger.error(`Order execution failed: ${error.message}`);
      return {
        brokerOrderId: '',
        status: 'REJECTED',
        message: error.message,
      };
    }
  }

  async getOrderStatus(
    token: string,
    clientCode: string,
    brokerOrderId: string,
  ): Promise<OrderResponse> {
    if (this.isMock) {
      return {
        brokerOrderId,
        status: 'EXECUTED',
        message: 'Mock execution successful',
      };
    }

    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}${AngelOneEndpoints.ORDER_BOOK}`, {
          headers: this.getHeaders(token),
        }),
      );

      if (response.data && response.data.status === true) {
        const orders = response.data.data || [];
        const order = orders.find((o: any) => o.orderid === brokerOrderId);
        if (order) {
          return {
            brokerOrderId: order.orderid,
            status: this.mapOrderStatus(order.status),
            message: order.text,
          };
        }
      }
      throw new NotFoundException(`Order ${brokerOrderId} not found on broker`);
    } catch (error) {
      this.logger.error(`Get order status failed: ${error.message}`);
      throw error;
    }
  }

  /**
   * Fetch the Last Traded Price (LTP) for a symbol.
   * @param exchange - e.g. 'NSE', 'BSE', 'NFO', 'MCX'
   * @param symbol   - trading symbol e.g. 'SBIN-EQ'
   * @param token    - optional user auth token; falls back to unauthenticated headers
   * @param symbolToken - optional pre-resolved instrument token
   */
  async getLtp(
    exchange: string,
    symbol: string,
    token?: string,
    symbolToken?: string,
  ): Promise<{ ltp: number; close: number; open: number; high: number; low: number } | null> {
    const resolvedToken = symbolToken || this.instrumentsService.findToken(symbol, exchange) || '';

    if (this.isMock) {
      // Return plausible mock prices
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
      const response = await firstValueFrom(
        this.httpService.post(
          `${this.baseUrl}${AngelOneEndpoints.LTP_DATA}`,
          {
            exchange: exchange.toUpperCase(),
            tradingsymbol: symbol,
            symboltoken: resolvedToken,
          },
          { headers: this.getHeaders(token) },
        ),
      );

      if (response.data?.status === true && response.data?.data) {
        const d = response.data.data;
        return {
          ltp: parseFloat(d.ltp || '0'),
          close: parseFloat(d.close || '0'),
          open: parseFloat(d.open || '0'),
          high: parseFloat(d.high || '0'),
          low: parseFloat(d.low || '0'),
        };
      }

      this.logger.warn(`getLtp returned non-ok: ${JSON.stringify(response.data)}`);
      return null;
    } catch (error: any) {
      this.logger.error(`getLtp failed for ${symbol}@${exchange}: ${error.message}`);
      return null;
    }
  }

  async getPositions(
    token: string,
    clientCode: string,
  ): Promise<PositionResponse[]> {
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

    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}${AngelOneEndpoints.POSITION}`, {
          headers: this.getHeaders(token),
        }),
      );

      if (response.data && response.data.status === true) {
        const positions = response.data.data || [];
        return positions.map((p: any) => ({
          symbol: p.tradingsymbol,
          quantity: parseInt(p.netqty || '0'),
          avgPrice: parseFloat(p.buyprice || '0'),
          currentPrice: parseFloat(p.ltp || '0'),
          unrealizedPnl: parseFloat(p.urmtom || '0'),
          realizedPnl: parseFloat(p.realised || '0'),
        }));
      }
      return [];
    } catch (error) {
      this.logger.error(`Get positions failed: ${error.message}`);
      return [];
    }
  }

  async getHoldings(
    token: string,
    clientCode: string,
  ): Promise<HoldingResponse[]> {
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

    try {
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}${AngelOneEndpoints.HOLDINGS}`, {
          headers: this.getHeaders(token),
        }),
      );

      if (response.data && response.data.status === true) {
        const holdings = response.data.data || [];
        return holdings.map((h: any) => ({
          symbol: h.tradingsymbol,
          quantity: parseInt(h.quantity || '0'),
          avgPrice: parseFloat(h.averageprice || '0'),
          currentPrice: parseFloat(h.ltp || '0'),
          unrealizedPnl: parseFloat(h.profitandloss || '0'),
        }));
      }
      return [];
    } catch (error) {
      this.logger.error(`Get holdings failed: ${error.message}`);
      return [];
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
      const response = await firstValueFrom(
        this.httpService.get(`${this.baseUrl}${AngelOneEndpoints.FUNDS}`, {
          headers: this.getHeaders(token),
        }),
      );

      if (response.data && response.data.status === true) {
        const data = response.data.data;
        const net = parseFloat(data.net || '0');
        const utilized = parseFloat(data.utilized || '0');
        return {
          availableMargin: net,
          usedMargin: utilized,
          totalMargin: net + utilized,
        };
      }
      return { availableMargin: 0, usedMargin: 0, totalMargin: 0 };
    } catch (error) {
      this.logger.error(`Get funds failed: ${error.message}`);
      return { availableMargin: 0, usedMargin: 0, totalMargin: 0 };
    }
  }

  async refreshSession(
    token: string,
    refreshToken: string,
  ): Promise<SessionResponse> {
    if (this.isMock) {
      return {
        accessToken: `mock_angel_one_access_token_refreshed_${Date.now()}`,
        refreshToken: `mock_angel_one_refresh_token_refreshed`,
        tokenExpiry: new Date(Date.now() + 12 * 60 * 60 * 1000),
      };
    }

    try {
      const response = await firstValueFrom(
        this.httpService.post(
          `${this.baseUrl}${AngelOneEndpoints.REFRESH_TOKEN}`,
          {
            refreshToken,
          },
          {
            headers: this.getHeaders(token),
          },
        ),
      );

      if (response.data && response.data.status === true) {
        return {
          accessToken: response.data.data.jwtToken,
          refreshToken: response.data.data.refreshToken,
          tokenExpiry: new Date(Date.now() + 18 * 60 * 60 * 1000),
        };
      }
      throw new BadRequestException(
        response.data.message || 'Angel One token renewal failed',
      );
    } catch (error) {
      this.logger.error(`Session refresh failed: ${error.message}`);
      throw new BadRequestException(`Session refresh failed: ${error.message}`);
    }
  }

  async modifyOrder(
    token: string,
    clientCode: string,
    orderId: string,
    variety: string,
    order: { quantity: number; price?: number; ordertype?: string; producttype?: string; duration?: string }
  ): Promise<OrderResponse> {
    if (this.isMock) {
      this.logger.log(`[SANDBOX MOCK] Modifying order ${orderId}: ${JSON.stringify(order)}`);
      return {
        brokerOrderId: orderId,
        status: 'PENDING',
        message: 'Mock modification successful',
      };
    }

    return this.circuitBreaker.execute('angelone-modify-order', async () => {
      await this.rateLimiter.throttle('angelone', 'trading');
      const start = Date.now();
      try {
        const response = await firstValueFrom(
          this.httpService.post(
            `${this.baseUrl}${AngelOneEndpoints.MODIFY_ORDER}`,
            {
              variety,
              orderid: orderId,
              ordertype: order.ordertype || 'LIMIT',
              producttype: order.producttype || 'INTRADAY',
              duration: order.duration || 'DAY',
              price: order.price !== undefined ? order.price.toString() : '0',
              quantity: order.quantity.toString(),
            },
            {
              headers: this.getHeaders(token),
            },
          ),
        );

        this.metrics.incrementBrokerCalls('angelone', 'modifyOrder', 'success');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);

        if (response.data && response.data.status === true) {
          return {
            brokerOrderId: response.data.data.orderid,
            status: 'PENDING',
          };
        }

        return {
          brokerOrderId: '',
          status: 'REJECTED',
          message: response.data.message || 'Modify order rejected by broker',
        };
      } catch (error) {
        this.metrics.incrementBrokerCalls('angelone', 'modifyOrder', 'failure');
        this.metrics.incrementBrokerFailures('angelone', 'modifyOrder');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);
        return {
          brokerOrderId: '',
          status: 'REJECTED',
          message: error.message,
        };
      }
    });
  }

  async cancelOrder(
    token: string,
    clientCode: string,
    orderId: string,
    variety: string
  ): Promise<OrderResponse> {
    if (this.isMock) {
      this.logger.log(`[SANDBOX MOCK] Cancelling order ${orderId}`);
      return {
        brokerOrderId: orderId,
        status: 'CANCELLED',
        message: 'Mock cancellation successful',
      };
    }

    return this.circuitBreaker.execute('angelone-cancel-order', async () => {
      await this.rateLimiter.throttle('angelone', 'trading');
      const start = Date.now();
      try {
        const response = await firstValueFrom(
          this.httpService.post(
            `${this.baseUrl}${AngelOneEndpoints.CANCEL_ORDER}`,
            {
              variety,
              orderid: orderId,
            },
            {
              headers: this.getHeaders(token),
            },
          ),
        );

        this.metrics.incrementBrokerCalls('angelone', 'cancelOrder', 'success');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);

        if (response.data && response.data.status === true) {
          return {
            brokerOrderId: response.data.data.orderid,
            status: 'CANCELLED',
          };
        }

        return {
          brokerOrderId: '',
          status: 'REJECTED',
          message: response.data.message || 'Cancel order rejected by broker',
        };
      } catch (error) {
        this.metrics.incrementBrokerCalls('angelone', 'cancelOrder', 'failure');
        this.metrics.incrementBrokerFailures('angelone', 'cancelOrder');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);
        return {
          brokerOrderId: '',
          status: 'REJECTED',
          message: error.message,
        };
      }
    });
  }

  async getTradeBook(
    token: string,
    clientCode: string
  ): Promise<BrokerTrade[]> {
    if (this.isMock) {
      return [
        {
          tradeId: 'mock_trade_1',
          orderId: 'mock_order_1',
          symbol: 'SBIN-EQ',
          quantity: 10,
          price: 750.0,
          side: 'BUY',
          executedAt: new Date(),
        },
      ];
    }

    return this.circuitBreaker.execute('angelone-trade-book', async () => {
      await this.rateLimiter.throttle('angelone', 'market');
      const start = Date.now();
      try {
        const response = await firstValueFrom(
          this.httpService.get(`${this.baseUrl}${AngelOneEndpoints.TRADE_BOOK}`, {
            headers: this.getHeaders(token),
          }),
        );

        this.metrics.incrementBrokerCalls('angelone', 'getTradeBook', 'success');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);

        if (response.data && response.data.status === true) {
          const trades = response.data.data || [];
          return trades.map((t: any) => ({
            tradeId: t.tradeid,
            orderId: t.orderid,
            symbol: t.tradingsymbol,
            quantity: parseInt(t.fillquantity || t.quantity || '0'),
            price: parseFloat(t.fillprice || t.price || '0'),
            side: t.transactiontype === 'BUY' ? 'BUY' : 'SELL',
            executedAt: t.filltime ? new Date(t.filltime) : new Date(),
          }));
        }
        return [];
      } catch (error) {
        this.metrics.incrementBrokerCalls('angelone', 'getTradeBook', 'failure');
        this.metrics.incrementBrokerFailures('angelone', 'getTradeBook');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);
        throw error;
      }
    });
  }

  async getLtpData(
    token: string,
    exchange: string,
    symbol: string,
    symbolToken: string
  ): Promise<BrokerLtp> {
    if (this.isMock) {
      return {
        exchange,
        symbol,
        token: symbolToken,
        ltp: 752.4,
        timestamp: new Date(),
      };
    }

    const cacheKey = `broker:ltp:${exchange}:${symbolToken}`;
    if (this.redisService.isHealthy()) {
      try {
        const cached = await this.redisService.getClient().get(cacheKey);
        if (cached) {
          return JSON.parse(cached);
        }
      } catch (err) {
        this.logger.error(`Error reading LTP cache: ${err.message}`);
      }
    }

    const ltpVal = await this.circuitBreaker.execute('angelone-ltp', async () => {
      await this.rateLimiter.throttle('angelone', 'market');
      const start = Date.now();
      try {
        const response = await firstValueFrom(
          this.httpService.post(
            `${this.baseUrl}${AngelOneEndpoints.LTP_DATA}`,
            {
              exchange,
              tradingsymbol: symbol,
              symboltoken: symbolToken,
            },
            {
              headers: this.getHeaders(token),
            },
          ),
        );

        this.metrics.incrementBrokerCalls('angelone', 'getLtpData', 'success');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);

        if (response.data && response.data.status === true) {
          const data = response.data.data;
          const ltpResponse: BrokerLtp = {
            exchange: data.exchange,
            symbol: data.tradingsymbol,
            token: data.symboltoken,
            ltp: parseFloat(data.ltp || '0'),
            timestamp: new Date(),
          };
          return ltpResponse;
        }

        throw new Error(response.data.message || 'Failed to fetch LTP from broker');
      } catch (error) {
        this.metrics.incrementBrokerCalls('angelone', 'getLtpData', 'failure');
        this.metrics.incrementBrokerFailures('angelone', 'getLtpData');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);
        throw error;
      }
    });

    if (this.redisService.isHealthy()) {
      try {
        await this.redisService.getClient().set(cacheKey, JSON.stringify(ltpVal), 'EX', 1);
      } catch (err) {
        this.logger.error(`Error saving LTP cache: ${err.message}`);
      }
    }

    return ltpVal;
  }

  async getOrderDetails(
    token: string,
    clientCode: string,
    orderId: string
  ): Promise<OrderResponse> {
    if (this.isMock) {
      return {
        brokerOrderId: orderId,
        status: 'EXECUTED',
        message: 'Mock details successful',
      };
    }

    return this.circuitBreaker.execute('angelone-order-details', async () => {
      await this.rateLimiter.throttle('angelone', 'market');
      const start = Date.now();
      try {
        const response = await firstValueFrom(
          this.httpService.get(`${this.baseUrl}${AngelOneEndpoints.ORDER_DETAILS}${orderId}`, {
            headers: this.getHeaders(token),
          }),
        );

        this.metrics.incrementBrokerCalls('angelone', 'getOrderDetails', 'success');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);

        if (response.data && response.data.status === true && response.data.data) {
          return {
            brokerOrderId: response.data.data.orderid,
            status: this.mapOrderStatus(response.data.data.status),
            message: response.data.data.text || response.data.data.status,
          };
        }
        throw new Error(response.data.message || 'Failed to fetch order details');
      } catch (error) {
        this.metrics.incrementBrokerCalls('angelone', 'getOrderDetails', 'failure');
        this.metrics.incrementBrokerFailures('angelone', 'getOrderDetails');
        this.metrics.observeBrokerLatency('angelone', Date.now() - start);
        throw error;
      }
    });
  }

  private mapOrderStatus(
    brokerStatus: string,
  ): 'PENDING' | 'EXECUTED' | 'REJECTED' | 'CANCELLED' {
    const status = brokerStatus.toUpperCase();
    if (status === 'COMPLETE' || status === 'EXECUTED') return 'EXECUTED';
    if (status === 'REJECTED') return 'REJECTED';
    if (status === 'CANCELLED') return 'CANCELLED';
    return 'PENDING';
  }
}
