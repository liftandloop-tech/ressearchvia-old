"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var AngelOneService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AngelOneService = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = require("@nestjs/axios");
const config_1 = require("@nestjs/config");
const broker_adapter_interface_1 = require("../interfaces/broker-adapter.interface");
const angel_one_endpoints_1 = require("./angel-one-endpoints");
const rxjs_1 = require("rxjs");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
const circuit_breaker_service_1 = require("../../infrastructure/circuit-breaker/circuit-breaker.service");
const broker_rate_limiter_service_1 = require("../../infrastructure/redis/broker-rate-limiter.service");
const instruments_service_1 = require("../../instruments/instruments.service");
let AngelOneService = AngelOneService_1 = class AngelOneService extends broker_adapter_interface_1.BrokerAdapter {
    httpService;
    configService;
    redisService;
    metrics;
    circuitBreaker;
    rateLimiter;
    instrumentsService;
    logger = new common_1.Logger(AngelOneService_1.name);
    isMock;
    baseUrl = 'https://apiconnect.angelone.in';
    constructor(httpService, configService, redisService, metrics, circuitBreaker, rateLimiter, instrumentsService) {
        super();
        this.httpService = httpService;
        this.configService = configService;
        this.redisService = redisService;
        this.metrics = metrics;
        this.circuitBreaker = circuitBreaker;
        this.rateLimiter = rateLimiter;
        this.instrumentsService = instrumentsService;
        const mockVal = this.configService.get('MOCK_BROKERS', true);
        this.isMock = mockVal === true || mockVal === 'true';
    }
    getHeaders(token, proxyIp) {
        const apiKey = this.configService.get('ANGEL_ONE_API_KEY') || '';
        const headers = {
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
    capabilities() {
        return {
            positions: true,
            holdings: true,
            funds: true,
            gtt: false,
            margin: true,
        };
    }
    async healthCheck() {
        const start = Date.now();
        if (this.isMock) {
            return { reachable: true, responseTimeMs: 10 };
        }
        try {
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.baseUrl}/health`, { timeout: 3000 }));
            return {
                reachable: response.status === 200,
                responseTimeMs: Date.now() - start,
            };
        }
        catch {
            try {
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.request({ method: 'OPTIONS', url: this.baseUrl, timeout: 3000 }));
                return {
                    reachable: response.status < 500,
                    responseTimeMs: Date.now() - start,
                };
            }
            catch {
                return {
                    reachable: false,
                    responseTimeMs: Date.now() - start,
                };
            }
        }
    }
    async generateSession(credentials) {
        this.logger.log(`Generating session for Client Code: ${credentials.clientCode}`);
        if (this.isMock) {
            this.logger.log(`[SANDBOX MOCK] Generating session for ${credentials.clientCode}`);
            return {
                accessToken: `mock_angel_one_access_token_${credentials.clientCode}_${Date.now()}`,
                refreshToken: `mock_angel_one_refresh_token_${credentials.clientCode}`,
                tokenExpiry: new Date(Date.now() + 12 * 60 * 60 * 1000),
            };
        }
        try {
            const apiKey = this.configService.get('ANGEL_ONE_API_KEY');
            if (!apiKey) {
                throw new common_1.BadRequestException('Angel One API Key is missing in environment variables');
            }
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.LOGIN}`, {
                clientcode: credentials.clientCode,
                password: credentials.password,
                totp: credentials.totpKey,
            }, {
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
            }));
            if (response.data && response.data.status === true) {
                const data = response.data.data;
                return {
                    accessToken: data.jwtToken,
                    refreshToken: data.refreshToken,
                    tokenExpiry: new Date(Date.now() + 18 * 60 * 60 * 1000),
                };
            }
            throw new common_1.BadRequestException(response.data.message || 'Angel One login failed');
        }
        catch (error) {
            const detail = error.response?.data;
            this.logger.error(`Angel One session generation error: ${error.message}`, error.stack);
            if (detail) {
                this.logger.error(`Angel One error details: ${JSON.stringify(detail)}`);
            }
            const errMessage = detail?.message || error.message;
            throw new common_1.BadRequestException(`Broker authentication error: ${errMessage}`);
        }
    }
    async getAuthorizationUrl(state) {
        const apiKey = this.configService.get('ANGEL_ONE_API_KEY') || '';
        const redirectUrl = this.configService.get('ANGEL_ONE_REDIRECT_URL') || '';
        if (!apiKey) {
            throw new common_1.BadRequestException('Angel One API Key is not configured');
        }
        return `https://smartapi.angelone.in/publisher-login?api_key=${apiKey}&redirect_url=${encodeURIComponent(redirectUrl)}&state=${state}`;
    }
    async completeAuthorization(callbackData) {
        this.logger.log(`Completing authorization flow for Angel One`);
        const authToken = callbackData.params.auth_token;
        if (!authToken) {
            throw new common_1.BadRequestException('Authorization token (auth_token) is missing in callback data');
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
            const payloadBase64 = authToken.split('.')[1];
            const payloadJson = Buffer.from(payloadBase64, 'base64').toString('utf8');
            const outerPayload = JSON.parse(payloadJson);
            const expMs = outerPayload.exp ? outerPayload.exp * 1000 : Date.now() + 18 * 60 * 60 * 1000;
            const expiresAt = new Date(expMs);
            const refreshToken = callbackData.params.refresh_token || '';
            this.logger.log(`AngelOne OAuth callback processed. Username: ${outerPayload.username}, expires: ${expiresAt.toISOString()}`);
            return {
                accessToken: authToken,
                refreshToken,
                expiresAt,
                brokerUserId: outerPayload.username || '',
            };
        }
        catch (error) {
            this.logger.error(`Angel One token extraction error: ${error.message}`, error.stack);
            throw new common_1.BadRequestException(`Broker token extraction error: ${error.message}`);
        }
    }
    async validateSession(token) {
        if (this.isMock) {
            return token.startsWith('mock_angel_one_access_token_');
        }
        try {
            const parts = token.split('.');
            if (parts.length !== 3)
                return false;
            const payloadJson = Buffer.from(parts[1], 'base64').toString('utf8');
            const payload = JSON.parse(payloadJson);
            if (!payload.exp)
                return false;
            const expiryMs = payload.exp * 1000;
            const isValid = Date.now() < expiryMs;
            this.logger.debug(`AngelOne session validation: exp=${new Date(expiryMs).toISOString()}, valid=${isValid}`);
            return isValid;
        }
        catch {
            return false;
        }
    }
    async getMargin(token, clientCode) {
        const funds = await this.getFunds(token, clientCode);
        return funds.availableMargin;
    }
    async getProfile(token) {
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
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.PROFILE}`, {
                headers: this.getHeaders(token),
            }));
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
        }
        catch (error) {
            this.logger.error(`Get profile failed: ${error.message}`);
            throw error;
        }
    }
    async getOrders(token, clientCode) {
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
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.ORDER_BOOK}`, {
                headers: this.getHeaders(token),
            }));
            if (response.data && response.data.status === true && Array.isArray(response.data.data)) {
                return response.data.data.map((o) => ({
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
        }
        catch (error) {
            this.logger.error(`Get orders failed: ${error.message}`);
            return [];
        }
    }
    async placeOrder(token, clientCode, order, httpsAgent) {
        if (this.isMock) {
            const mockId = `mock_order_${Math.floor(100000 + Math.random() * 900000)}`;
            this.logger.log(`[SANDBOX MOCK] Placed order ${mockId} for ${clientCode}: ${order.side} ${order.quantity} x ${order.symbol} (${order.orderType})`);
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
            let proxyIp;
            if (httpsAgent && httpsAgent.options) {
                const proxyUrl = httpsAgent.options.href || httpsAgent.options.host || httpsAgent.options.hostname;
                if (proxyUrl) {
                    try {
                        const parsed = new URL(httpsAgent.options.href || `http://${proxyUrl}`);
                        proxyIp = parsed.hostname;
                    }
                    catch (_) { }
                }
            }
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.PLACE_ORDER}`, {
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
            }, {
                headers: this.getHeaders(token, proxyIp),
                ...(httpsAgent ? { httpsAgent } : {}),
            }));
            if (response.data && response.data.status === true) {
                return {
                    brokerOrderId: response.data.data.scriptid || response.data.data.orderid,
                    status: 'PENDING',
                };
            }
            return {
                brokerOrderId: '',
                status: 'REJECTED',
                message: response.data.message || 'Order rejected by broker',
            };
        }
        catch (error) {
            this.logger.error(`Order execution failed: ${error.message}`);
            return {
                brokerOrderId: '',
                status: 'REJECTED',
                message: error.message,
            };
        }
    }
    async getOrderStatus(token, clientCode, brokerOrderId) {
        if (this.isMock) {
            return {
                brokerOrderId,
                status: 'EXECUTED',
                message: 'Mock execution successful',
            };
        }
        try {
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.ORDER_BOOK}`, {
                headers: this.getHeaders(token),
            }));
            if (response.data && response.data.status === true) {
                const orders = response.data.data || [];
                const order = orders.find((o) => o.orderid === brokerOrderId);
                if (order) {
                    return {
                        brokerOrderId: order.orderid,
                        status: this.mapOrderStatus(order.status),
                        message: order.text,
                    };
                }
            }
            throw new common_1.NotFoundException(`Order ${brokerOrderId} not found on broker`);
        }
        catch (error) {
            this.logger.error(`Get order status failed: ${error.message}`);
            throw error;
        }
    }
    async getLtp(exchange, symbol, token, symbolToken) {
        const resolvedToken = symbolToken || this.instrumentsService.findToken(symbol, exchange) || '';
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
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.LTP_DATA}`, {
                exchange: exchange.toUpperCase(),
                tradingsymbol: symbol,
                symboltoken: resolvedToken,
            }, { headers: this.getHeaders(token) }));
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
        }
        catch (error) {
            this.logger.error(`getLtp failed for ${symbol}@${exchange}: ${error.message}`);
            return null;
        }
    }
    async getPositions(token, clientCode) {
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
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.POSITION}`, {
                headers: this.getHeaders(token),
            }));
            if (response.data && response.data.status === true) {
                const positions = response.data.data || [];
                return positions.map((p) => ({
                    symbol: p.tradingsymbol,
                    quantity: parseInt(p.netqty || '0'),
                    avgPrice: parseFloat(p.buyprice || '0'),
                    currentPrice: parseFloat(p.ltp || '0'),
                    unrealizedPnl: parseFloat(p.urmtom || '0'),
                    realizedPnl: parseFloat(p.realised || '0'),
                }));
            }
            return [];
        }
        catch (error) {
            this.logger.error(`Get positions failed: ${error.message}`);
            return [];
        }
    }
    async getHoldings(token, clientCode) {
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
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.HOLDINGS}`, {
                headers: this.getHeaders(token),
            }));
            if (response.data && response.data.status === true) {
                const holdings = response.data.data || [];
                return holdings.map((h) => ({
                    symbol: h.tradingsymbol,
                    quantity: parseInt(h.quantity || '0'),
                    avgPrice: parseFloat(h.averageprice || '0'),
                    currentPrice: parseFloat(h.ltp || '0'),
                    unrealizedPnl: parseFloat(h.profitandloss || '0'),
                }));
            }
            return [];
        }
        catch (error) {
            this.logger.error(`Get holdings failed: ${error.message}`);
            return [];
        }
    }
    async getFunds(token, clientCode) {
        if (this.isMock) {
            return {
                availableMargin: 150000.0,
                usedMargin: 0.0,
                totalMargin: 150000.0,
            };
        }
        try {
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.FUNDS}`, {
                headers: this.getHeaders(token),
            }));
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
        }
        catch (error) {
            this.logger.error(`Get funds failed: ${error.message}`);
            return { availableMargin: 0, usedMargin: 0, totalMargin: 0 };
        }
    }
    async refreshSession(token, refreshToken) {
        if (this.isMock) {
            return {
                accessToken: `mock_angel_one_access_token_refreshed_${Date.now()}`,
                refreshToken: `mock_angel_one_refresh_token_refreshed`,
                tokenExpiry: new Date(Date.now() + 12 * 60 * 60 * 1000),
            };
        }
        try {
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.REFRESH_TOKEN}`, {
                refreshToken,
            }, {
                headers: this.getHeaders(token),
            }));
            if (response.data && response.data.status === true) {
                return {
                    accessToken: response.data.data.jwtToken,
                    refreshToken: response.data.data.refreshToken,
                    tokenExpiry: new Date(Date.now() + 18 * 60 * 60 * 1000),
                };
            }
            throw new common_1.BadRequestException(response.data.message || 'Angel One token renewal failed');
        }
        catch (error) {
            this.logger.error(`Session refresh failed: ${error.message}`);
            throw new common_1.BadRequestException(`Session refresh failed: ${error.message}`);
        }
    }
    async modifyOrder(token, clientCode, orderId, variety, order) {
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
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.MODIFY_ORDER}`, {
                    variety,
                    orderid: orderId,
                    ordertype: order.ordertype || 'LIMIT',
                    producttype: order.producttype || 'INTRADAY',
                    duration: order.duration || 'DAY',
                    price: order.price !== undefined ? order.price.toString() : '0',
                    quantity: order.quantity.toString(),
                }, {
                    headers: this.getHeaders(token),
                }));
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
            }
            catch (error) {
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
    async cancelOrder(token, clientCode, orderId, variety) {
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
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.CANCEL_ORDER}`, {
                    variety,
                    orderid: orderId,
                }, {
                    headers: this.getHeaders(token),
                }));
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
            }
            catch (error) {
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
    async getTradeBook(token, clientCode) {
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
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.TRADE_BOOK}`, {
                    headers: this.getHeaders(token),
                }));
                this.metrics.incrementBrokerCalls('angelone', 'getTradeBook', 'success');
                this.metrics.observeBrokerLatency('angelone', Date.now() - start);
                if (response.data && response.data.status === true) {
                    const trades = response.data.data || [];
                    return trades.map((t) => ({
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
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('angelone', 'getTradeBook', 'failure');
                this.metrics.incrementBrokerFailures('angelone', 'getTradeBook');
                this.metrics.observeBrokerLatency('angelone', Date.now() - start);
                throw error;
            }
        });
    }
    async getLtpData(token, exchange, symbol, symbolToken) {
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
            }
            catch (err) {
                this.logger.error(`Error reading LTP cache: ${err.message}`);
            }
        }
        const ltpVal = await this.circuitBreaker.execute('angelone-ltp', async () => {
            await this.rateLimiter.throttle('angelone', 'market');
            const start = Date.now();
            try {
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.LTP_DATA}`, {
                    exchange,
                    tradingsymbol: symbol,
                    symboltoken: symbolToken,
                }, {
                    headers: this.getHeaders(token),
                }));
                this.metrics.incrementBrokerCalls('angelone', 'getLtpData', 'success');
                this.metrics.observeBrokerLatency('angelone', Date.now() - start);
                if (response.data && response.data.status === true) {
                    const data = response.data.data;
                    const ltpResponse = {
                        exchange: data.exchange,
                        symbol: data.tradingsymbol,
                        token: data.symboltoken,
                        ltp: parseFloat(data.ltp || '0'),
                        timestamp: new Date(),
                    };
                    return ltpResponse;
                }
                throw new Error(response.data.message || 'Failed to fetch LTP from broker');
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('angelone', 'getLtpData', 'failure');
                this.metrics.incrementBrokerFailures('angelone', 'getLtpData');
                this.metrics.observeBrokerLatency('angelone', Date.now() - start);
                throw error;
            }
        });
        if (this.redisService.isHealthy()) {
            try {
                await this.redisService.getClient().set(cacheKey, JSON.stringify(ltpVal), 'EX', 1);
            }
            catch (err) {
                this.logger.error(`Error saving LTP cache: ${err.message}`);
            }
        }
        return ltpVal;
    }
    async getOrderDetails(token, clientCode, orderId) {
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
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.get(`${this.baseUrl}${angel_one_endpoints_1.AngelOneEndpoints.ORDER_DETAILS}${orderId}`, {
                    headers: this.getHeaders(token),
                }));
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
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('angelone', 'getOrderDetails', 'failure');
                this.metrics.incrementBrokerFailures('angelone', 'getOrderDetails');
                this.metrics.observeBrokerLatency('angelone', Date.now() - start);
                throw error;
            }
        });
    }
    mapOrderStatus(brokerStatus) {
        const status = brokerStatus.toUpperCase();
        if (status === 'COMPLETE' || status === 'EXECUTED')
            return 'EXECUTED';
        if (status === 'REJECTED')
            return 'REJECTED';
        if (status === 'CANCELLED')
            return 'CANCELLED';
        return 'PENDING';
    }
};
exports.AngelOneService = AngelOneService;
exports.AngelOneService = AngelOneService = AngelOneService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [axios_1.HttpService,
        config_1.ConfigService,
        redis_service_1.RedisService,
        metrics_service_1.MetricsService,
        circuit_breaker_service_1.CircuitBreakerService,
        broker_rate_limiter_service_1.BrokerRateLimiterService,
        instruments_service_1.InstrumentsService])
], AngelOneService);
//# sourceMappingURL=angel-one.service.js.map