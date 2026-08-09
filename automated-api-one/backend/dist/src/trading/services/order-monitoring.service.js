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
var OrderMonitoringService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderMonitoringService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma.service");
const broker_factory_1 = require("../../brokers/factory/broker.factory");
const circuit_breaker_service_1 = require("../../infrastructure/circuit-breaker/circuit-breaker.service");
const outbox_service_1 = require("../../infrastructure/outbox/outbox.service");
const audit_service_1 = require("../../audit/audit.service");
const audit_event_enum_1 = require("../../audit/enums/audit-event.enum");
const position_cache_service_1 = require("./position-cache.service");
const multiplier_service_1 = require("./multiplier.service");
const config_1 = require("@nestjs/config");
const client_1 = require("@prisma/client");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
let OrderMonitoringService = OrderMonitoringService_1 = class OrderMonitoringService {
    prisma;
    brokerFactory;
    circuitBreaker;
    outbox;
    auditService;
    positionCache;
    multiplierService;
    configService;
    metrics;
    logger = new common_1.Logger(OrderMonitoringService_1.name);
    brokerTimeoutMs;
    constructor(prisma, brokerFactory, circuitBreaker, outbox, auditService, positionCache, multiplierService, configService, metrics) {
        this.prisma = prisma;
        this.brokerFactory = brokerFactory;
        this.circuitBreaker = circuitBreaker;
        this.outbox = outbox;
        this.auditService = auditService;
        this.positionCache = positionCache;
        this.multiplierService = multiplierService;
        this.configService = configService;
        this.metrics = metrics;
        this.brokerTimeoutMs = this.configService.get('BROKER_TIMEOUT_MS', 5000);
    }
    async pollOrderStatus(orderId, correlationId) {
        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
            include: { trade: true },
        });
        if (!order) {
            this.logger.warn(`[${correlationId}] Order ${orderId} not found for monitoring`);
            return { finalStatus: 'PENDING', brokerOrderId: '', reason: 'Order not found' };
        }
        if (!order.brokerOrderId) {
            return { finalStatus: 'PENDING', brokerOrderId: '', reason: 'No broker order ID' };
        }
        const trade = order.trade;
        const userBroker = await this.prisma.userBroker.findFirst({
            where: { userId: trade.userId, brokerId: trade.brokerId },
            include: { broker: true },
        });
        if (!userBroker?.accessToken) {
            return { finalStatus: 'PENDING', brokerOrderId: order.brokerOrderId, reason: 'No broker session' };
        }
        const brokerCode = userBroker.broker.code;
        const adapter = this.brokerFactory.getAdapter(brokerCode);
        let brokerStatus;
        try {
            const statusResult = await this.circuitBreaker.execute(userBroker.broker.code, () => Promise.race([
                adapter.getOrderStatus(userBroker.accessToken, userBroker.brokerClientId, order.brokerOrderId),
                new Promise((_, reject) => setTimeout(() => reject(new Error(`Status poll timeout after ${this.brokerTimeoutMs}ms`)), this.brokerTimeoutMs)),
            ]));
            brokerStatus = statusResult.status;
        }
        catch (err) {
            this.logger.warn(`[${correlationId}] Failed to poll order ${orderId}: ${err.message}`);
            return {
                finalStatus: 'PENDING',
                brokerOrderId: order.brokerOrderId,
                reason: err.message,
            };
        }
        if (brokerStatus === 'FILLED' || brokerStatus === 'COMPLETE' || brokerStatus === 'EXECUTED') {
            await this.reconcileFilled(order.id, trade.id, trade.userId, trade.segmentId, correlationId);
            return { finalStatus: 'FILLED', brokerOrderId: order.brokerOrderId };
        }
        if (['CANCELLED', 'REJECTED', 'EXPIRED'].includes(brokerStatus)) {
            const mapped = brokerStatus;
            await this.reconcileFailed(order.id, trade.id, trade.userId, trade.segmentId, mapped, correlationId);
            return { finalStatus: mapped, brokerOrderId: order.brokerOrderId };
        }
        return { finalStatus: 'PENDING', brokerOrderId: order.brokerOrderId };
    }
    async reconcileFilled(orderId, tradeId, userId, segmentId, correlationId) {
        const event = await this.prisma.$transaction(async (tx) => {
            await tx.order.update({
                where: { id: orderId },
                data: { status: client_1.OrderStatus.FILLED },
            });
            await tx.trade.update({
                where: { id: tradeId },
                data: { status: client_1.TradeStatus.OPEN },
            });
            const evt = await this.outbox.createEvent('ORDER_FILLED', { version: 1, correlationId, orderId, tradeId, userId, segmentId }, tx);
            return evt;
        });
        await this.outbox.enqueueEvent(event.id);
        this.metrics.incrementOrdersFilled();
        await this.multiplierService.resetOnWin(userId, segmentId);
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.ORDER_FILLED, 'Order', orderId, { correlationId, tradeId });
    }
    async reconcileFailed(orderId, tradeId, userId, segmentId, failStatus, correlationId) {
        const orderStatusMap = {
            CANCELLED: client_1.OrderStatus.CANCELLED,
            REJECTED: client_1.OrderStatus.REJECTED,
            EXPIRED: client_1.OrderStatus.EXPIRED,
        };
        const event = await this.prisma.$transaction(async (tx) => {
            await tx.order.update({
                where: { id: orderId },
                data: { status: orderStatusMap[failStatus] },
            });
            await tx.trade.update({
                where: { id: tradeId },
                data: { status: client_1.TradeStatus.FAILED },
            });
            const evt = await this.outbox.createEvent('ORDER_FAILED', { version: 1, correlationId, orderId, tradeId, userId, segmentId, failStatus }, tx);
            return evt;
        });
        await this.outbox.enqueueEvent(event.id);
        this.metrics.incrementOrdersRejected();
        await this.multiplierService.advanceOnLoss(userId, segmentId);
        await this.positionCache.del(userId, segmentId);
        this.logger.warn(`[${correlationId}] Order ${orderId} terminal status: ${failStatus}. Multiplier advanced.`);
    }
};
exports.OrderMonitoringService = OrderMonitoringService;
exports.OrderMonitoringService = OrderMonitoringService = OrderMonitoringService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        broker_factory_1.BrokerFactory,
        circuit_breaker_service_1.CircuitBreakerService,
        outbox_service_1.OutboxService,
        audit_service_1.AuditService,
        position_cache_service_1.PositionCacheService,
        multiplier_service_1.MultiplierService,
        config_1.ConfigService,
        metrics_service_1.MetricsService])
], OrderMonitoringService);
//# sourceMappingURL=order-monitoring.service.js.map