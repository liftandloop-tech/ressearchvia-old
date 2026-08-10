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
var ZebuService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ZebuService = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = require("@nestjs/axios");
const config_1 = require("@nestjs/config");
const broker_adapter_interface_1 = require("../interfaces/broker-adapter.interface");
const zebu_endpoints_1 = require("./zebu-endpoints");
const rxjs_1 = require("rxjs");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
const circuit_breaker_service_1 = require("../../infrastructure/circuit-breaker/circuit-breaker.service");
const broker_rate_limiter_service_1 = require("../../infrastructure/redis/broker-rate-limiter.service");
const crypto_1 = require("crypto");
let ZebuService = ZebuService_1 = class ZebuService extends broker_adapter_interface_1.BrokerAdapter {
    httpService;
    configService;
    redisService;
    metrics;
    circuitBreaker;
    rateLimiter;
    logger = new common_1.Logger(ZebuService_1.name);
    isMock;
    authUrl;
    baseUrl;
    tokenToUidMap = new Map();
    constructor(httpService, configService, redisService, metrics, circuitBreaker, rateLimiter) {
        super();
        this.httpService = httpService;
        this.configService = configService;
        this.redisService = redisService;
        this.metrics = metrics;
        this.circuitBreaker = circuitBreaker;
        this.rateLimiter = rateLimiter;
        const mockVal = this.configService.get('MOCK_BROKERS', true);
        this.isMock = mockVal === true || mockVal === 'true';
        this.authUrl =
            this.configService.get('ZEBU_AUTH_URL') ||
                'https://go.mynt.in/NorenWClientTP';
        this.baseUrl =
            this.configService.get('ZEBU_BASE_URL') ||
                'https://go.mynt.in/NorenWClientTP';
    }
    buildBody(data, susertoken) {
        return `jData=${JSON.stringify(data)}&jKey=${susertoken}`;
    }
    getHeaders() {
        return {
            'Content-Type': 'application/x-www-form-urlencoded',
        };
    }
    hashPassword(pwd) {
        return (0, crypto_1.createHash)('sha256').update(pwd).digest('hex');
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
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.request({
                method: 'OPTIONS',
                url: this.baseUrl,
                timeout: 3000,
            }));
            return {
                reachable: response.status < 500,
                responseTimeMs: Date.now() - start,
            };
        }
        catch {
            return { reachable: false, responseTimeMs: Date.now() - start };
        }
    }
    async generateSession(credentials) {
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
            const apiKey = credentials.apiKey;
            const vendorCode = credentials.vendorCode;
            if (!apiKey || !vendorCode) {
                throw new common_1.BadRequestException('Zebu API key and vendor code are required. Please re-link your Zebu account and provide your appkey and vendor code.');
            }
            const hashedPwd = this.hashPassword(credentials.password);
            const otpCode = credentials.totpKey;
            const hashedAppkey = this.hashPassword(`${credentials.clientCode}|${apiKey}`);
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
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.authUrl}${zebu_endpoints_1.ZebuEndpoints.QUICK_AUTH}`, body, {
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            }));
            const data = response.data;
            if (data && (data.stat === 'Ok' || data.susertoken)) {
                this.logger.log(`[Zebu] Session generated successfully for ${credentials.clientCode}`);
                this.tokenToUidMap.set(data.susertoken, credentials.clientCode);
                return {
                    accessToken: data.susertoken,
                    refreshToken: '',
                    tokenExpiry: this.midnightIst(),
                };
            }
            throw new common_1.BadRequestException(data?.emsg || 'Zebu login failed');
        }
        catch (error) {
            const detail = error.response?.data;
            this.logger.error(`[Zebu] Session generation error: ${error.message}`, error.stack);
            if (detail) {
                this.logger.error(`[Zebu] Error details: ${JSON.stringify(detail)}`);
            }
            const errMessage = detail?.emsg || error.message;
            throw new common_1.BadRequestException(`Zebu broker authentication error: ${errMessage}`);
        }
    }
    async getAuthorizationUrl(_state) {
        throw new common_1.BadRequestException('Zebu Base API does not use OAuth — use generateSession() instead');
    }
    async completeAuthorization(_callbackData) {
        throw new common_1.BadRequestException('Zebu Base API does not use OAuth callbacks');
    }
    async validateSession(token) {
        if (this.isMock) {
            return token.startsWith('mock_zebu_token_');
        }
        if (!token || token.length === 0)
            return false;
        return Date.now() < this.midnightIst().getTime();
    }
    async refreshSession(token, _refreshToken) {
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
    async getProfile(token, clientCode) {
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
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.CLIENT_DETAILS}`, body, {
                headers: this.getHeaders(),
            }));
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
        }
        catch (error) {
            this.logger.error(`[Zebu] getProfile failed: ${error.message}`);
            throw error;
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
            const body = this.buildBody({ uid: clientCode, actid: clientCode }, token);
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.LIMITS}`, body, {
                headers: this.getHeaders(),
            }));
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
        }
        catch (error) {
            this.logger.error(`[Zebu] getFunds failed: ${error.message}`);
            return { availableMargin: 0, usedMargin: 0, totalMargin: 0 };
        }
    }
    async getMargin(token, clientCode) {
        const funds = await this.getFunds(token, clientCode);
        return funds.availableMargin;
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
        return this.circuitBreaker.execute('zebu-positions', async () => {
            await this.rateLimiter.throttle('zebu', 'market');
            const start = Date.now();
            try {
                const body = this.buildBody({ uid: clientCode, actid: clientCode }, token);
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.POSITION_BOOK}`, body, {
                    headers: this.getHeaders(),
                }));
                this.metrics.incrementBrokerCalls('zebu', 'getPositions', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                const data = response.data;
                const positions = Array.isArray(data) ? data : data?.stat === 'Ok' ? data.data || [] : [];
                return positions.map((p) => ({
                    symbol: p.tsym || p.tradingsymbol || '',
                    quantity: parseInt(p.netqty || '0', 10),
                    avgPrice: parseFloat(p.netupldprc || p.avgprc || '0'),
                    currentPrice: parseFloat(p.lp || p.ltp || '0'),
                    unrealizedPnl: parseFloat(p.urmtom || '0'),
                    realizedPnl: parseFloat(p.rpnl || '0'),
                }));
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('zebu', 'getPositions', 'failure');
                this.logger.error(`[Zebu] getPositions failed: ${error.message}`);
                return [];
            }
        });
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
        return this.circuitBreaker.execute('zebu-holdings', async () => {
            await this.rateLimiter.throttle('zebu', 'market');
            const start = Date.now();
            try {
                const body = this.buildBody({ uid: clientCode, actid: clientCode, prd: 'C' }, token);
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.HOLDINGS}`, body, {
                    headers: this.getHeaders(),
                }));
                this.metrics.incrementBrokerCalls('zebu', 'getHoldings', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                const data = response.data;
                const holdings = Array.isArray(data) ? data : data?.stat === 'Ok' ? data.data || [] : [];
                return holdings.map((h) => ({
                    symbol: h.tsym || h.tradingsymbol || '',
                    quantity: parseInt(h.holdqty || h.quantity || '0', 10),
                    avgPrice: parseFloat(h.avgprc || h.averageprice || '0'),
                    currentPrice: parseFloat(h.lp || h.ltp || '0'),
                    unrealizedPnl: parseFloat(h.upldpnl || h.pnl || '0'),
                }));
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('zebu', 'getHoldings', 'failure');
                this.logger.error(`[Zebu] getHoldings failed: ${error.message}`);
                return [];
            }
        });
    }
    async placeOrder(token, clientCode, order, httpsAgent) {
        if (this.isMock) {
            const mockId = `mock_zebu_order_${Math.floor(100000 + Math.random() * 900000)}`;
            this.logger.log(`[SANDBOX MOCK] Placed Zebu order ${mockId} for ${clientCode}: ${order.side} ${order.quantity} x ${order.symbol}`);
            return { brokerOrderId: mockId, status: 'EXECUTED', message: 'Mock execution successful' };
        }
        return this.circuitBreaker.execute('zebu-place-order', async () => {
            await this.rateLimiter.throttle('zebu', 'trading');
            const start = Date.now();
            try {
                const exch = order.exchange || 'NSE';
                let prd = 'I';
                if (exch === 'NFO' ||
                    exch === 'MCX' ||
                    exch === 'CDS' ||
                    exch === 'BFO' ||
                    exch === 'BCD') {
                    prd = 'M';
                }
                let tsym = order.symbol;
                if ((exch === 'NSE' || exch === 'BSE') && !tsym.endsWith('-EQ')) {
                    tsym = `${tsym}-EQ`;
                }
                const jData = {
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
                this.logger.log(`[Zebu Mynt API] Sending PlaceOrder request to ${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.PLACE_ORDER}:\n` +
                    `jData Payload: ${JSON.stringify(jData, null, 2)}`);
                const body = this.buildBody(jData, token);
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.PLACE_ORDER}`, body, {
                    headers: this.getHeaders(),
                    ...(httpsAgent ? { httpsAgent } : {}),
                }));
                const data = response.data;
                this.logger.log(`[Zebu Mynt API] PlaceOrder response received from ${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.PLACE_ORDER}:\n` +
                    `Response: ${JSON.stringify(data, null, 2)}`);
                this.metrics.incrementBrokerCalls('zebu', 'placeOrder', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                if (data && data.stat === 'Ok' && data.norenordno) {
                    return { brokerOrderId: data.norenordno, status: 'PENDING' };
                }
                return { brokerOrderId: '', status: 'REJECTED', message: data?.emsg || 'Order rejected by Zebu' };
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('zebu', 'placeOrder', 'failure');
                this.metrics.incrementBrokerFailures('zebu', 'placeOrder');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                this.logger.error(`[Zebu] placeOrder failed: ${error.message}`);
                return { brokerOrderId: '', status: 'REJECTED', message: error.message };
            }
        });
    }
    async modifyOrder(token, clientCode, orderId, _variety, order) {
        if (this.isMock) {
            this.logger.log(`[SANDBOX MOCK] Modifying Zebu order ${orderId}`);
            return { brokerOrderId: orderId, status: 'PENDING', message: 'Mock modification successful' };
        }
        return this.circuitBreaker.execute('zebu-modify-order', async () => {
            await this.rateLimiter.throttle('zebu', 'trading');
            const start = Date.now();
            try {
                const jData = {
                    uid: clientCode,
                    norenordno: orderId,
                    qty: order.quantity.toString(),
                    prc: (order.price ?? 0).toString(),
                    prctyp: order.ordertype ? this.mapOrderType(order.ordertype) : 'LMT',
                    ret: order.duration || 'DAY',
                };
                const body = this.buildBody(jData, token);
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.MODIFY_ORDER}`, body, {
                    headers: this.getHeaders(),
                }));
                this.metrics.incrementBrokerCalls('zebu', 'modifyOrder', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                const data = response.data;
                if (data && data.stat === 'Ok' && data.result) {
                    return { brokerOrderId: data.result, status: 'PENDING' };
                }
                return { brokerOrderId: '', status: 'REJECTED', message: data?.emsg || 'Modify rejected by Zebu' };
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('zebu', 'modifyOrder', 'failure');
                this.metrics.incrementBrokerFailures('zebu', 'modifyOrder');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                return { brokerOrderId: '', status: 'REJECTED', message: error.message };
            }
        });
    }
    async cancelOrder(token, clientCode, orderId, _variety) {
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
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.CANCEL_ORDER}`, body, {
                    headers: this.getHeaders(),
                }));
                this.metrics.incrementBrokerCalls('zebu', 'cancelOrder', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                const data = response.data;
                if (data && data.stat === 'Ok' && data.result) {
                    return { brokerOrderId: data.result, status: 'CANCELLED' };
                }
                return { brokerOrderId: '', status: 'REJECTED', message: data?.emsg || 'Cancel rejected by Zebu' };
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('zebu', 'cancelOrder', 'failure');
                this.metrics.incrementBrokerFailures('zebu', 'cancelOrder');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                return { brokerOrderId: '', status: 'REJECTED', message: error.message };
            }
        });
    }
    async getOrderStatus(token, clientCode, brokerOrderId) {
        if (this.isMock) {
            return { brokerOrderId, status: 'EXECUTED', message: 'Mock execution successful' };
        }
        try {
            const jData = { uid: clientCode };
            const body = this.buildBody(jData, token);
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.ORDER_BOOK}`, body, {
                headers: this.getHeaders(),
            }));
            const data = response.data;
            const orders = Array.isArray(data) ? data : [];
            const found = orders.find((o) => o.norenordno === brokerOrderId);
            if (found) {
                return {
                    brokerOrderId: found.norenordno,
                    status: this.mapOrderStatus(found.status),
                    message: found.rejreason || found.status,
                };
            }
            throw new common_1.NotFoundException(`Order ${brokerOrderId} not found in Zebu order book`);
        }
        catch (error) {
            this.logger.error(`[Zebu] getOrderStatus failed: ${error.message}`);
            throw error;
        }
    }
    async getOrders(token, clientCode) {
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
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.ORDER_BOOK}`, body, {
                    headers: this.getHeaders(),
                }));
                this.metrics.incrementBrokerCalls('zebu', 'getOrders', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                const data = response.data;
                const orders = Array.isArray(data) ? data : [];
                return orders.map((o) => ({
                    brokerOrderId: o.norenordno || '',
                    symbol: o.tsym || o.tradingsymbol || '',
                    quantity: parseInt(o.qty || '0', 10),
                    price: parseFloat(o.prc || '0'),
                    side: o.trantype || '',
                    status: this.mapOrderStatus(o.status),
                    rejreason: o.rejreason || '',
                }));
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('zebu', 'getOrders', 'failure');
                this.logger.error(`[Zebu] getOrders failed: ${error.message}`);
                return [];
            }
        });
    }
    async getTradeBook(token, clientCode) {
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
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.TRADE_BOOK}`, body, {
                    headers: this.getHeaders(),
                }));
                this.metrics.incrementBrokerCalls('zebu', 'getTradeBook', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                const data = response.data;
                const trades = Array.isArray(data) ? data : [];
                return trades.map((t) => ({
                    tradeId: t.flfilledtm || t.tradeid || '',
                    orderId: t.norenordno || '',
                    symbol: t.tsym || '',
                    quantity: parseInt(t.flqty || '0', 10),
                    price: parseFloat(t.flprc || '0'),
                    side: t.trantype === 'B' ? 'BUY' : 'SELL',
                    executedAt: t.flfilledtm ? new Date(t.flfilledtm) : new Date(),
                }));
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('zebu', 'getTradeBook', 'failure');
                this.metrics.incrementBrokerFailures('zebu', 'getTradeBook');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                throw error;
            }
        });
    }
    async getLtp(exchange, symbol, token, _symbolToken) {
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
            const jData = {
                uid,
                exch: exchange.toUpperCase(),
                token: _symbolToken || symbol,
            };
            const body = this.buildBody(jData, token || '');
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.GET_QUOTES}`, body, {
                headers: this.getHeaders(),
            }));
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
        }
        catch (error) {
            this.logger.error(`[Zebu] getLtp failed for ${symbol}@${exchange}: ${error.message}`);
            return null;
        }
    }
    async getLtpData(token, exchange, symbol, symbolToken) {
        if (this.isMock) {
            return { exchange, symbol, token: symbolToken, ltp: 752.4, timestamp: new Date() };
        }
        const cacheKey = `broker:ltp:zebu:${exchange}:${symbolToken}`;
        if (this.redisService.isHealthy()) {
            try {
                const cached = await this.redisService.getClient().get(cacheKey);
                if (cached)
                    return JSON.parse(cached);
            }
            catch (err) {
                this.logger.error(`[Zebu] Error reading LTP cache: ${err.message}`);
            }
        }
        const ltpVal = await this.circuitBreaker.execute('zebu-ltp', async () => {
            await this.rateLimiter.throttle('zebu', 'market');
            const start = Date.now();
            try {
                const jData = { uid: '', exch: exchange.toUpperCase(), token: symbolToken };
                const body = this.buildBody(jData, token);
                const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${zebu_endpoints_1.ZebuEndpoints.GET_QUOTES}`, body, {
                    headers: this.getHeaders(),
                }));
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
            }
            catch (error) {
                this.metrics.incrementBrokerCalls('zebu', 'getLtpData', 'failure');
                this.metrics.incrementBrokerFailures('zebu', 'getLtpData');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
                throw error;
            }
        });
        if (this.redisService.isHealthy()) {
            try {
                await this.redisService.getClient().set(cacheKey, JSON.stringify(ltpVal), 'EX', 1);
            }
            catch (err) {
                this.logger.error(`[Zebu] Error saving LTP cache: ${err.message}`);
            }
        }
        return ltpVal;
    }
    async getOrderDetails(token, clientCode, orderId) {
        if (this.isMock) {
            return { brokerOrderId: orderId, status: 'EXECUTED', message: 'Mock details successful' };
        }
        return this.getOrderStatus(token, clientCode, orderId);
    }
    midnightIst() {
        const now = new Date();
        const istOffsetMs = 5.5 * 60 * 60 * 1000;
        const istNow = new Date(now.getTime() + istOffsetMs);
        const midnightIst = new Date(Date.UTC(istNow.getUTCFullYear(), istNow.getUTCMonth(), istNow.getUTCDate() + 1));
        return new Date(midnightIst.getTime() - istOffsetMs);
    }
    mapOrderType(orderType) {
        switch ((orderType || '').toUpperCase()) {
            case 'MARKET': return 'MKT';
            case 'LIMIT': return 'LMT';
            case 'SL': return 'SL-LMT';
            case 'SL-M': return 'SL-MKT';
            default: return 'LMT';
        }
    }
    mapOrderStatus(brokerStatus) {
        const s = (brokerStatus || '').toUpperCase();
        if (s === 'COMPLETE' || s === 'FILLED' || s === 'EXECUTED')
            return 'EXECUTED';
        if (s === 'REJECTED')
            return 'REJECTED';
        if (s === 'CANCELLED' || s === 'CANCELED')
            return 'CANCELLED';
        return 'PENDING';
    }
};
exports.ZebuService = ZebuService;
exports.ZebuService = ZebuService = ZebuService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [axios_1.HttpService,
        config_1.ConfigService,
        redis_service_1.RedisService,
        metrics_service_1.MetricsService,
        circuit_breaker_service_1.CircuitBreakerService,
        broker_rate_limiter_service_1.BrokerRateLimiterService])
], ZebuService);
//# sourceMappingURL=zebu.service.js.map