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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var OrderPlacementService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderPlacementService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma.service");
const broker_factory_1 = require("../../brokers/factory/broker.factory");
const circuit_breaker_service_1 = require("../../infrastructure/circuit-breaker/circuit-breaker.service");
const broker_rate_limiter_service_1 = require("../../infrastructure/redis/broker-rate-limiter.service");
const outbox_service_1 = require("../../infrastructure/outbox/outbox.service");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const redis_keys_1 = require("../../infrastructure/redis/redis-keys");
const audit_service_1 = require("../../audit/audit.service");
const audit_event_enum_1 = require("../../audit/enums/audit-event.enum");
const position_cache_service_1 = require("./position-cache.service");
const config_1 = require("@nestjs/config");
const client_1 = require("@prisma/client");
const risk_service_1 = require("../../risk/risk.service");
const egress_service_1 = require("../../egress/egress.service");
const common_2 = require("@nestjs/common");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
let OrderPlacementService = OrderPlacementService_1 = class OrderPlacementService {
    prisma;
    brokerFactory;
    circuitBreaker;
    rateLimiter;
    outbox;
    redisService;
    auditService;
    positionCache;
    configService;
    metrics;
    riskService;
    egressService;
    logger = new common_1.Logger(OrderPlacementService_1.name);
    brokerTimeoutMs;
    constructor(prisma, brokerFactory, circuitBreaker, rateLimiter, outbox, redisService, auditService, positionCache, configService, metrics, riskService, egressService) {
        this.prisma = prisma;
        this.brokerFactory = brokerFactory;
        this.circuitBreaker = circuitBreaker;
        this.rateLimiter = rateLimiter;
        this.outbox = outbox;
        this.redisService = redisService;
        this.auditService = auditService;
        this.positionCache = positionCache;
        this.configService = configService;
        this.metrics = metrics;
        this.riskService = riskService;
        this.egressService = egressService;
        this.brokerTimeoutMs = this.configService.get('BROKER_TIMEOUT_MS', 5000);
    }
    async placeEntryOrder(ctx) {
        const { snapshot, correlationId, signalId, symbol, exchange, side, entryPrice, stopLoss, targetPrice } = ctx;
        const { userId, brokerId, brokerCode, brokerClientId, effectiveLot } = snapshot;
        this.logger.log(`[${correlationId}] Placing entry order: user=${userId} symbol=${symbol} lot=${effectiveLot}`);
        const riskDecision = await this.riskService.evaluateRisk(userId, symbol, effectiveLot, entryPrice, brokerId, snapshot.segmentId);
        if (!riskDecision.approved) {
            this.logger.warn(`[${correlationId}] Blocked by Risk Engine: ${riskDecision.reason}`);
            return { success: false, reason: `Risk Engine block: ${riskDecision.reason}` };
        }
        await this.rateLimiter.throttle(brokerCode);
        const tokenInfo = await this.resolveBrokerToken(userId, brokerId, brokerClientId);
        if (!tokenInfo || !tokenInfo.accessToken) {
            this.logger.warn(`[${correlationId}] No active broker session for user ${userId}`);
            return { success: false, reason: 'No active broker session' };
        }
        const adapter = this.brokerFactory.getAdapter(brokerCode);
        let brokerOrderId;
        const startPlacement = Date.now();
        try {
            this.metrics.incrementOrdersPlaced();
            this.metrics.incrementBrokerCalls(brokerCode);
            this.metrics.incrementOrderPlacementAttempts();
            const orderResult = await this.circuitBreaker.execute(brokerCode, () => Promise.race([
                adapter.placeOrder(tokenInfo.accessToken, brokerClientId, {
                    symbol,
                    exchange,
                    side,
                    quantity: effectiveLot,
                    orderType: ctx.orderType,
                    price: entryPrice,
                    triggerPrice: stopLoss,
                    squareoff: targetPrice ? Math.abs(entryPrice - targetPrice) : undefined,
                    stoploss: stopLoss ? Math.abs(entryPrice - stopLoss) : undefined,
                }, tokenInfo.proxyAgent),
                new Promise((_, reject) => setTimeout(() => reject(new Error(`Broker API timeout after ${this.brokerTimeoutMs}ms`)), this.brokerTimeoutMs)),
            ]));
            if (orderResult.status === 'REJECTED' || !orderResult.brokerOrderId) {
                throw new Error(orderResult.message || 'Order rejected by broker');
            }
            brokerOrderId = orderResult.brokerOrderId;
            const duration = Date.now() - startPlacement;
            this.metrics.observeBrokerLatency(brokerCode, duration);
            this.metrics.observeOrderPlacementDuration(duration);
            this.metrics.incrementExecutionSuccess();
        }
        catch (err) {
            this.metrics.incrementExecutionFailed();
            this.metrics.incrementBrokerFailures(brokerCode);
            if (err.message && err.message.toLowerCase().includes('timeout')) {
                this.metrics.incrementBrokerTimeouts(brokerCode);
            }
            this.metrics.incrementOrdersRejected();
            this.logger.error(`[${correlationId}] Broker order placement failed for user ${userId}: ${err.message}`);
            return { success: false, reason: err.message };
        }
        let tradeId;
        let orderId;
        try {
            const result = await this.prisma.$transaction(async (tx) => {
                const trade = await tx.trade.create({
                    data: {
                        correlationId,
                        userId,
                        signalId,
                        segmentId: snapshot.segmentId,
                        brokerId,
                        quantity: effectiveLot,
                        multiplier: snapshot.multiplierValue,
                        entryPrice,
                        status: client_1.TradeStatus.OPEN,
                    },
                });
                const order = await tx.order.create({
                    data: {
                        correlationId,
                        tradeId: trade.id,
                        brokerOrderId,
                        orderType: ctx.orderType,
                        quantity: effectiveLot,
                        price: entryPrice,
                        status: client_1.OrderStatus.PLACED,
                    },
                });
                const outboxEvent = await this.outbox.createEvent('TRADE_OPENED', {
                    version: 1,
                    correlationId,
                    tradeId: trade.id,
                    orderId: order.id,
                    userId,
                    segmentId: snapshot.segmentId,
                    symbol,
                    side,
                    quantity: effectiveLot,
                    entryPrice,
                    brokerOrderId,
                }, tx);
                return { trade, order, outboxEvent };
            });
            tradeId = result.trade.id;
            orderId = result.order.id;
            await this.outbox.enqueueEvent(result.outboxEvent.id);
        }
        catch (err) {
            this.logger.error(`[${correlationId}] DB transaction failed after successful broker call: ${err.message}. ` +
                `Broker order ${brokerOrderId} may need manual reconciliation.`);
            return { success: false, reason: `DB write failed: ${err.message}` };
        }
        await this.positionCache.set({
            userId,
            segmentId: snapshot.segmentId,
            tradeId,
            symbol,
            quantity: effectiveLot,
            entryPrice,
            stopLoss: ctx.stopLoss,
            targetPrice: ctx.targetPrice,
            side,
            cachedAt: new Date().toISOString(),
        });
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.TRADE_OPENED, 'Trade', tradeId, { correlationId, brokerOrderId, symbol, side, quantity: effectiveLot, entryPrice });
        this.logger.log(`[${correlationId}] Entry order placed: tradeId=${tradeId} orderId=${orderId} brokerOrderId=${brokerOrderId}`);
        return { success: true, tradeId, orderId, brokerOrderId };
    }
    async resolveBrokerToken(userId, brokerId, brokerClientId) {
        this.logger.log(`[resolveBrokerToken] Resolving token & proxy for user=${userId}, brokerId=${brokerId}, clientId=${brokerClientId}`);
        const { createProxyAgent } = require('../../infrastructure/proxy-agent.util');
        let proxyAgent = undefined;
        if (this.egressService) {
            try {
                proxyAgent = await this.egressService.getProxyAgentForUser(userId);
            }
            catch (err) {
                this.logger.warn(`[resolveBrokerToken] EgressService proxy resolution note for user ${userId}: ${err.message}`);
            }
        }
        if (this.redisService.isHealthy()) {
            try {
                const sessionKey = redis_keys_1.RedisKeys.brokerSession(userId, brokerId);
                const cachedRaw = await this.redisService.getClient().get(sessionKey);
                this.logger.log(`[resolveBrokerToken] Redis check for key=${sessionKey}: exists=${!!cachedRaw}`);
                if (cachedRaw) {
                    const session = JSON.parse(cachedRaw);
                    if (session?.accessToken) {
                        this.logger.debug(`Broker session for user ${userId} resolved from Redis cache`);
                        if (!proxyAgent) {
                            const { createProxyAgent } = require('../../infrastructure/proxy-agent.util');
                            proxyAgent = createProxyAgent({
                                proxyIp: session.proxyIp || null,
                                proxyPort: session.proxyPort || null,
                                proxyHostname: null,
                                proxyUsername: session.proxyUsername || null,
                                proxyPassword: session.proxyPassword || null,
                            });
                        }
                        return { accessToken: session.accessToken, proxyAgent };
                    }
                }
            }
            catch (err) {
                this.logger.warn(`Redis broker session read failed for user ${userId}: ${err.message}. Falling back to DB.`);
            }
        }
        else {
            this.logger.log(`[resolveBrokerToken] Redis is NOT healthy`);
        }
        const userBroker = await this.prisma.userBroker.findFirst({
            where: { userId, brokerId },
        });
        this.logger.log(`[resolveBrokerToken] DB fallback result: ${JSON.stringify(userBroker)}`);
        if (userBroker) {
            if (!proxyAgent) {
                const { createProxyAgent } = require('../../infrastructure/proxy-agent.util');
                proxyAgent = createProxyAgent({
                    proxyIp: userBroker.proxyIp,
                    proxyPort: userBroker.proxyPort,
                    proxyHostname: userBroker.proxyHostname,
                    proxyUsername: userBroker.proxyUsername,
                    proxyPassword: userBroker.proxyPassword,
                });
            }
            return { accessToken: userBroker.accessToken, proxyAgent };
        }
        return { accessToken: null };
    }
};
exports.OrderPlacementService = OrderPlacementService;
exports.OrderPlacementService = OrderPlacementService = OrderPlacementService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(11, (0, common_2.Optional)()),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        broker_factory_1.BrokerFactory,
        circuit_breaker_service_1.CircuitBreakerService,
        broker_rate_limiter_service_1.BrokerRateLimiterService,
        outbox_service_1.OutboxService,
        redis_service_1.RedisService,
        audit_service_1.AuditService,
        position_cache_service_1.PositionCacheService,
        config_1.ConfigService,
        metrics_service_1.MetricsService,
        risk_service_1.RiskService,
        egress_service_1.EgressService])
], OrderPlacementService);
//# sourceMappingURL=order-placement.service.js.map