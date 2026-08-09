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
Object.defineProperty(exports, "__esModule", { value: true });
exports.HealthController = void 0;
const common_1 = require("@nestjs/common");
const terminus_1 = require("@nestjs/terminus");
const prisma_service_1 = require("../prisma.service");
const redis_health_1 = require("./redis.health");
const broker_health_1 = require("./broker.health");
const swagger_1 = require("@nestjs/swagger");
const queues_service_1 = require("../infrastructure/queues/queues.service");
const trading_gateway_1 = require("../websocket/gateway/trading.gateway");
let HealthController = class HealthController {
    health;
    prismaHealth;
    prisma;
    redisHealth;
    brokerHealth;
    queueService;
    tradingGateway;
    constructor(health, prismaHealth, prisma, redisHealth, brokerHealth, queueService, tradingGateway) {
        this.health = health;
        this.prismaHealth = prismaHealth;
        this.prisma = prisma;
        this.redisHealth = redisHealth;
        this.brokerHealth = brokerHealth;
        this.queueService = queueService;
        this.tradingGateway = tradingGateway;
    }
    async checkAll() {
        return this.health.check([
            () => this.prismaHealth.pingCheck('database', this.prisma.baseClient),
            () => this.redisHealth.isHealthy('redis'),
            () => this.brokerHealth.isHealthy('broker'),
        ]);
    }
    async checkDb() {
        return this.health.check([
            () => this.prismaHealth.pingCheck('database', this.prisma.baseClient),
        ]);
    }
    async checkRedis() {
        return this.health.check([() => this.redisHealth.isHealthy('redis')]);
    }
    async checkBroker() {
        return this.brokerHealth.getCustomHealth();
    }
    async checkQueues() {
        const metrics = await this.queueService.getAggregatedMetrics();
        const signalQueue = this.queueService.getQueue('trade-execution');
        const orderQueue = this.queueService.getQueue('order-placement');
        const reportQueue = this.queueService.getQueue('report-generation');
        const signalProcessingDepth = signalQueue ? await signalQueue.getWaitingCount() : 0;
        const orderPlacementDepth = orderQueue ? await orderQueue.getWaitingCount() : 0;
        const reportDepth = reportQueue ? await reportQueue.getWaitingCount() : 0;
        let status = 'up';
        if (signalProcessingDepth > 5000 || orderPlacementDepth > 5000 || reportDepth > 10000) {
            status = 'degraded';
        }
        return {
            status,
            signalProcessingDepth,
            orderPlacementDepth,
            reportDepth,
            ...metrics,
        };
    }
    async checkWebsocket() {
        const isInitialized = !!this.tradingGateway.server;
        const activeConnections = this.tradingGateway.server?.engine?.clientsCount || 0;
        return {
            status: isInitialized ? 'up' : 'down',
            gateway: isInitialized ? 'initialized' : 'uninitialized',
            activeConnections,
        };
    }
    async checkOutbox() {
        try {
            const pendingCount = await this.prisma.outboxEvent.count({
                where: { status: 'PENDING' },
            });
            const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
            const stuckCount = await this.prisma.outboxEvent.count({
                where: {
                    status: 'PROCESSING',
                    createdAt: { lt: fiveMinutesAgo },
                },
            });
            const q = this.queueService.getQueue('outbox-dispatcher');
            const queueDepth = q ? await q.getWaitingCount() : 0;
            const isDegraded = stuckCount > 10;
            return {
                status: isDegraded ? 'degraded' : 'up',
                pendingEvents: pendingCount,
                stuckEvents: stuckCount,
                queueDepth,
            };
        }
        catch (err) {
            return {
                status: 'down',
                error: err.message,
            };
        }
    }
    async checkReports() {
        try {
            const q = this.queueService.getQueue('report-generation');
            const queueDepth = q ? await q.getWaitingCount() : 0;
            return {
                status: 'up',
                queueDepth,
            };
        }
        catch (err) {
            return {
                status: 'down',
                error: err.message,
            };
        }
    }
    async checkReconciliation() {
        try {
            const snapshots = await this.prisma.reconciliationSnapshot.findMany();
            const openIssues = snapshots.reduce((acc, s) => acc + s.openIssues, 0);
            const criticalCount = await this.prisma.reconciliationIssue.count({
                where: {
                    severity: 'CRITICAL',
                    status: { not: 'RESOLVED' },
                },
            });
            const lastRun = await this.prisma.reconciliationRun.findFirst({
                orderBy: { startedAt: 'desc' },
            });
            let status = 'healthy';
            if (criticalCount > 0) {
                status = 'critical';
            }
            else if (openIssues > 0) {
                status = 'degraded';
            }
            return {
                status,
                lastRun: lastRun?.completedAt || lastRun?.startedAt || null,
                openIssues,
                criticalIssues: criticalCount,
            };
        }
        catch (err) {
            return {
                status: 'down',
                error: err.message,
            };
        }
    }
    async checkAnalytics() {
        try {
            const lastRun = await this.prisma.analyticsJobRun.findFirst({
                orderBy: { startedAt: 'desc' },
            });
            const activeUsers = await this.prisma.user.findMany({
                where: { status: 'ACTIVE' },
                select: { id: true },
            });
            let staleSnapshotsCount = 0;
            const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
            for (const u of activeUsers) {
                const lastSnap = await this.prisma.dailyPortfolioSnapshot.findFirst({
                    where: { userId: u.id },
                    orderBy: { date: 'desc' },
                });
                if (!lastSnap || lastSnap.date < twentyFourHoursAgo) {
                    staleSnapshotsCount++;
                }
            }
            let status = 'healthy';
            if (lastRun?.status === 'FAILED') {
                status = 'degraded';
            }
            if (staleSnapshotsCount > 0) {
                status = 'degraded';
            }
            return {
                status,
                lastRun: {
                    id: lastRun?.id || null,
                    startedAt: lastRun?.startedAt || null,
                    completedAt: lastRun?.completedAt || null,
                    status: lastRun?.status || null,
                    usersProcessed: lastRun?.usersProcessed || 0,
                    failures: lastRun?.failures || 0,
                    durationMs: lastRun?.durationMs || null,
                },
                staleSnapshotsCount,
            };
        }
        catch (err) {
            return {
                status: 'down',
                error: err.message,
            };
        }
    }
};
exports.HealthController = HealthController;
__decorate([
    (0, common_1.Get)(),
    (0, terminus_1.HealthCheck)(),
    (0, swagger_1.ApiOperation)({ summary: 'Run all health checks' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkAll", null);
__decorate([
    (0, common_1.Get)('db'),
    (0, terminus_1.HealthCheck)(),
    (0, swagger_1.ApiOperation)({ summary: 'Check database connectivity' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkDb", null);
__decorate([
    (0, common_1.Get)('redis'),
    (0, terminus_1.HealthCheck)(),
    (0, swagger_1.ApiOperation)({ summary: 'Check Redis connectivity' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkRedis", null);
__decorate([
    (0, common_1.Get)('broker'),
    (0, swagger_1.ApiOperation)({ summary: 'Check Broker connectivity' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkBroker", null);
__decorate([
    (0, common_1.Get)('queues'),
    (0, swagger_1.ApiOperation)({ summary: 'Get aggregated queue and DLQ metrics' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkQueues", null);
__decorate([
    (0, common_1.Get)('websocket'),
    (0, swagger_1.ApiOperation)({ summary: 'Check WebSocket Gateway health' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkWebsocket", null);
__decorate([
    (0, common_1.Get)('outbox'),
    (0, swagger_1.ApiOperation)({ summary: 'Check Outbox service health' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkOutbox", null);
__decorate([
    (0, common_1.Get)('reports'),
    (0, swagger_1.ApiOperation)({ summary: 'Check Reports service health' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkReports", null);
__decorate([
    (0, common_1.Get)('reconciliation'),
    (0, swagger_1.ApiOperation)({ summary: 'Check Reconciliation health' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkReconciliation", null);
__decorate([
    (0, common_1.Get)('analytics'),
    (0, swagger_1.ApiOperation)({ summary: 'Check Analytics health' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], HealthController.prototype, "checkAnalytics", null);
exports.HealthController = HealthController = __decorate([
    (0, swagger_1.ApiTags)('Health'),
    (0, common_1.Controller)('health'),
    __metadata("design:paramtypes", [terminus_1.HealthCheckService,
        terminus_1.PrismaHealthIndicator,
        prisma_service_1.PrismaService,
        redis_health_1.RedisHealthIndicator,
        broker_health_1.BrokerHealthIndicator,
        queues_service_1.QueueService,
        trading_gateway_1.TradingGateway])
], HealthController);
//# sourceMappingURL=health.controller.js.map