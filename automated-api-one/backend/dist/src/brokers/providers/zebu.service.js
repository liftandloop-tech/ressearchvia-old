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
const prisma_service_1 = require("../../prisma.service");
const https_proxy_agent_1 = require("https-proxy-agent");
let ZebuService = ZebuService_1 = class ZebuService extends broker_adapter_interface_1.BrokerAdapter {
    httpService;
    configService;
    redisService;
    metrics;
    circuitBreaker;
    rateLimiter;
    prisma;
    logger = new common_1.Logger(ZebuService_1.name);
    isMock;
    baseUrl;
    constructor(httpService, configService, redisService, metrics, circuitBreaker, rateLimiter, prisma) {
        super();
        this.httpService = httpService;
        this.configService = configService;
        this.redisService = redisService;
        this.metrics = metrics;
        this.circuitBreaker = circuitBreaker;
        this.rateLimiter = rateLimiter;
        this.prisma = prisma;
        const mockVal = this.configService.get('MOCK_BROKERS', true);
        this.isMock = mockVal === true || mockVal === 'true';
        this.baseUrl =
            this.configService.get('ZEBU_BASE_URL') ||
                'https://go.mynt.in/NorenWClientAPI';
    }
    async executeBrokerPost(token, clientCode, endpoint, body, timeoutMs = 8000, providedHttpsAgent) {
        const requestId = `req_${Date.now().toString(36)}_${Math.random().toString(36).substring(2, 7)}`;
        let httpsAgent = providedHttpsAgent;
        let proxyIp = 'DIRECT';
        let networkMode = 'DIRECT';
        if (!httpsAgent) {
            let userBroker = null;
            if (token) {
                userBroker = await this.prisma.userBroker.findFirst({
                    where: { accessToken: token },
                    include: { proxyCredential: true },
                });
            }
            else if (clientCode) {
                userBroker = await this.prisma.userBroker.findFirst({
                    where: { brokerClientId: clientCode },
                    include: { proxyCredential: true },
                });
            }
            if (userBroker) {
                const userId = userBroker.userId;
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
                    httpsAgent = new https_proxy_agent_1.HttpsProxyAgent(`http://${proxy.ip}:${proxy.port}`, {
                        headers: {
                            'Proxy-Authorization': `Basic ${auth}`,
                        },
                    });
                    this.logger.log(`[Proxy Routing] requestId=${requestId} Routing outbound broker call via Dedicated Proxy ${proxy.ip}:${proxy.port} (user: ${proxy.ip_userid}) for user ${userId} [endpoint: ${endpoint}]`);
                }
            }
        }
        else {
            networkMode = 'FORWARDED_PROXY';
            proxyIp = 'FORWARDED';
        }
        this.logger.log(`[Broker Outbound] requestId=${requestId} networkMode=${networkMode} proxyIp=${proxyIp} endpoint=${endpoint}`);
        const start = Date.now();
        const headers = {
            'Content-Type': 'text/plain',
        };
        if (token && endpoint !== zebu_endpoints_1.ZebuEndpoints.GEN_ACCESS_TOKEN && endpoint !== zebu_endpoints_1.ZebuEndpoints.REFRESH_TOKEN) {
            headers['Authorization'] = `Bearer ${token}`;
        }
        try {
            const response = await (0, rxjs_1.firstValueFrom)(this.httpService.post(`${this.baseUrl}${endpoint}`, body, {
                headers,
                ...(httpsAgent ? { httpsAgent } : {}),
                timeout: timeoutMs,
            }));
            const durationMs = Date.now() - start;
            let data = response.data;
            if (typeof data === 'string') {
                try {
                    data = JSON.parse(data);
                }
                catch {
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
            if (response.status === 404 && endpoint === zebu_endpoints_1.ZebuEndpoints.REFRESH_TOKEN) {
                return { stat: 'Not_Ok', emsg: 'RefreshToken endpoint not supported by Zebu server (tokens are 90-day long lived)' };
            }
            if (response.status >= 400 && (!data || !data.stat)) {
                const errMsg = data?.emsg || data?.message || (typeof data === 'string' ? data : `HTTP ${response.status}`);
                throw new Error(`Zebu Error (${response.status}): ${errMsg}`);
            }
            return data;
        }
        catch (err) {
            const durationMs = Date.now() - start;
            this.logger.error(`[Broker Outbound Failed] requestId=${requestId} endpoint=${endpoint} proxyIp=${proxyIp} duration=${durationMs}ms error=${err.message}`);
            throw err;
        }
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
        throw new common_1.BadRequestException('Zebu OAuth system enabled. Please use the redirection OAuth flow instead.');
    }
    async getAuthorizationUrl(state) {
        if (this.isMock) {
            return `http://localhost:3000/brokers/zebu/callback?code=mock_code&state=${state}&client_id=mock_client_id`;
        }
        const authState = await this.prisma.brokerAuthState.findFirst({
            where: { state },
        });
        if (!authState) {
            throw new common_1.BadRequestException('Invalid authorization state');
        }
        const userBroker = await this.prisma.userBroker.findFirst({
            where: { userId: authState.userId, broker: { code: 'ZEBU' } },
        });
        if (!userBroker) {
            throw new common_1.BadRequestException('Please link your Zebu broker details first');
        }
        let clientId = userBroker.apiKey || userBroker.brokerClientId || '';
        if (clientId && !clientId.includes('_')) {
            clientId = `${clientId}_U`;
        }
        return `https://go.mynt.in/OAuthlogin/authorize/oauth?client_id=${clientId}&state=${state}`;
    }
    async completeAuthorization(callbackData) {
        this.logger.log(`Completing Zebu OAuth authorization`);
        const authCode = callbackData.params.code;
        const queryClientId = callbackData.params.client_id;
        if (!authCode) {
            throw new common_1.BadRequestException('Authorization code (code) is missing in callback data');
        }
        if (this.isMock) {
            this.logger.log(`[SANDBOX MOCK] Generating session using authCode: ${authCode}`);
            return {
                accessToken: `mock_zebu_token_${Date.now()}`,
                refreshToken: `mock_zebu_refresh_${Date.now()}`,
                expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
                brokerUserId: queryClientId || 'mock_zebu_client',
            };
        }
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
            throw new common_1.BadRequestException(`Linked Zebu broker config not found for client_id: ${queryClientId}`);
        }
        let oauthAppId = userBroker.apiKey || userBroker.brokerClientId || '';
        if (oauthAppId && !oauthAppId.includes('_')) {
            oauthAppId = `${oauthAppId}_U`;
        }
        const apiSecret = userBroker.apiSecret || '';
        const hashString = `${oauthAppId}${apiSecret}${authCode}`;
        const checkSum = (0, crypto_1.createHash)('sha256').update(hashString).digest('hex');
        const payload = {
            code: authCode,
            checksum: checkSum,
        };
        const body = `jData=${JSON.stringify(payload)}`;
        try {
            const responseData = await this.executeBrokerPost(null, userBroker.brokerClientId, zebu_endpoints_1.ZebuEndpoints.GEN_ACCESS_TOKEN, body, 10000);
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
                expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
                brokerUserId,
            };
        }
        catch (err) {
            this.logger.error(`Zebu OAuth token exchange failed: ${err.message}`);
            throw new common_1.BadRequestException(`Zebu OAuth token exchange failed: ${err.message}`);
        }
    }
    async validateSession(token) {
        if (this.isMock) {
            return token.startsWith('mock_zebu_token_');
        }
        if (!token || token.length === 0)
            return false;
        const userBroker = await this.prisma.userBroker.findFirst({
            where: { accessToken: token },
        });
        if (!userBroker || !userBroker.tokenExpiry)
            return false;
        return new Date() < userBroker.tokenExpiry;
    }
    async refreshSession(token, refreshToken) {
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
            const body = `jData=${JSON.stringify({ refresh_token: refreshToken || userBroker.refreshToken })}`;
            const responseData = await this.executeBrokerPost(token, userBroker.brokerClientId, zebu_endpoints_1.ZebuEndpoints.REFRESH_TOKEN, body, 8000);
            const newAccessToken = responseData?.access_token || responseData?.susertoken;
            if (responseData?.stat !== 'Ok' || !newAccessToken) {
                throw new Error(responseData?.emsg || 'Failed to refresh token');
            }
            return {
                accessToken: newAccessToken,
                refreshToken: responseData?.refresh_token || refreshToken,
                tokenExpiry: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
            };
        }
        catch (error) {
            this.logger.error(`[Zebu] refreshSession failed: ${error.message}`);
            return {
                accessToken: token,
                refreshToken,
                tokenExpiry: new Date(Date.now() + 24 * 60 * 60 * 1000),
            };
        }
    }
    async getProfile(token, clientCode) {
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
            const data = await this.executeBrokerPost(token, uid, zebu_endpoints_1.ZebuEndpoints.CLIENT_DETAILS, body);
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
            const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode })}&jKey=${token}`;
            const data = await this.executeBrokerPost(token, clientCode, zebu_endpoints_1.ZebuEndpoints.LIMITS, body);
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
                const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode })}&jKey=${token}`;
                const data = await this.executeBrokerPost(token, clientCode, zebu_endpoints_1.ZebuEndpoints.POSITION_BOOK, body);
                this.metrics.incrementBrokerCalls('zebu', 'getPositions', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
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
                const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode, prd: 'C' })}&jKey=${token}`;
                const data = await this.executeBrokerPost(token, clientCode, zebu_endpoints_1.ZebuEndpoints.HOLDINGS, body);
                this.metrics.incrementBrokerCalls('zebu', 'getHoldings', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
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
                this.logger.log(`[Zebu Mynt API] Sending PlaceOrder request to ${zebu_endpoints_1.ZebuEndpoints.PLACE_ORDER}:\n` +
                    `jData Payload: ${JSON.stringify(jData, null, 2)}`);
                const body = `jData=${JSON.stringify(jData)}&jKey=${token}`;
                const data = await this.executeBrokerPost(token, clientCode, zebu_endpoints_1.ZebuEndpoints.PLACE_ORDER, body, 8000, httpsAgent);
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
                const body = `jData=${JSON.stringify(jData)}&jKey=${token}`;
                const data = await this.executeBrokerPost(token, clientCode, zebu_endpoints_1.ZebuEndpoints.MODIFY_ORDER, body);
                this.metrics.incrementBrokerCalls('zebu', 'modifyOrder', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
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
                const body = `jData=${JSON.stringify(jData)}&jKey=${token}`;
                const data = await this.executeBrokerPost(token, clientCode, zebu_endpoints_1.ZebuEndpoints.CANCEL_ORDER, body);
                this.metrics.incrementBrokerCalls('zebu', 'cancelOrder', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
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
            const body = `jData=${JSON.stringify({ uid: clientCode })}&jKey=${token}`;
            const data = await this.executeBrokerPost(token, clientCode, zebu_endpoints_1.ZebuEndpoints.ORDER_BOOK, body);
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
                const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode })}&jKey=${token}`;
                const data = await this.executeBrokerPost(token, clientCode, zebu_endpoints_1.ZebuEndpoints.ORDER_BOOK, body);
                this.metrics.incrementBrokerCalls('zebu', 'getOrders', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
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
                const body = `jData=${JSON.stringify({ uid: clientCode, actid: clientCode })}&jKey=${token}`;
                const data = await this.executeBrokerPost(token, clientCode, zebu_endpoints_1.ZebuEndpoints.TRADE_BOOK, body);
                this.metrics.incrementBrokerCalls('zebu', 'getTradeBook', 'success');
                this.metrics.observeBrokerLatency('zebu', Date.now() - start);
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
            const body = `jData=${JSON.stringify({ uid: '', exch: exchange.toUpperCase(), token: _symbolToken || symbol })}&jKey=${token || ''}`;
            const data = await this.executeBrokerPost(token || null, null, zebu_endpoints_1.ZebuEndpoints.GET_QUOTES, body);
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
                const body = `jData=${JSON.stringify({ uid: '', exch: exchange.toUpperCase(), token: symbolToken })}&jKey=${token}`;
                const data = await this.executeBrokerPost(token, null, zebu_endpoints_1.ZebuEndpoints.GET_QUOTES, body);
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
        broker_rate_limiter_service_1.BrokerRateLimiterService,
        prisma_service_1.PrismaService])
], ZebuService);
//# sourceMappingURL=zebu.service.js.map