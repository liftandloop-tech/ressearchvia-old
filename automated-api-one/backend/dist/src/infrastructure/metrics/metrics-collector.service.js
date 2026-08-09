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
var MetricsCollectorService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.MetricsCollectorService = void 0;
const common_1 = require("@nestjs/common");
const schedule_1 = require("@nestjs/schedule");
const metrics_service_1 = require("./metrics.service");
const queues_service_1 = require("../queues/queues.service");
const prisma_service_1 = require("../../prisma.service");
const redis_service_1 = require("../redis/redis.service");
const queue_constants_1 = require("../queues/queue.constants");
const client_1 = require("@prisma/client");
let MetricsCollectorService = MetricsCollectorService_1 = class MetricsCollectorService {
    metrics;
    queueService;
    prisma;
    redisService;
    logger = new common_1.Logger(MetricsCollectorService_1.name);
    constructor(metrics, queueService, prisma, redisService) {
        this.metrics = metrics;
        this.queueService = queueService;
        this.prisma = prisma;
        this.redisService = redisService;
    }
    async collectGauges() {
        try {
            const targetQueues = [
                queue_constants_1.Queues.SIGNAL_PROCESSING,
                queue_constants_1.Queues.ORDER_PLACEMENT,
                queue_constants_1.Queues.ORDER_MONITORING,
                queue_constants_1.Queues.NOTIFICATION,
                queue_constants_1.Queues.OUTBOX_DISPATCHER,
                queue_constants_1.Queues.WEBSOCKET,
                queue_constants_1.Queues.REPORT_GENERATION,
                queue_constants_1.Queues.REPORT_EXPORT,
            ];
            for (let i = 0; i < 10; i++) {
                targetQueues.push(`analytics-snapshot-${i}`);
            }
            for (const queueName of targetQueues) {
                try {
                    const queue = this.queueService.getQueue(queueName);
                    if (queue) {
                        const waiting = await queue.getWaitingCount();
                        const active = await queue.getActiveCount();
                        const failed = await queue.getFailedCount();
                        this.metrics.setQueueDepth(queueName, waiting);
                        this.metrics.setQueueProcessing(queueName, active);
                        this.metrics.setQueueFailed(queueName, failed);
                    }
                }
                catch (queueErr) {
                    this.logger.warn(`Failed to collect queue metrics for ${queueName}: ${queueErr.message}`);
                }
            }
        }
        catch (err) {
            this.logger.error(`Failed to collect queue metrics: ${err.message}`);
        }
        try {
            const targetDlqs = [
                queue_constants_1.Queues.SIGNAL_DLQ,
                queue_constants_1.Queues.ORDER_DLQ,
                queue_constants_1.Queues.ORDER_MONITORING_DLQ,
                queue_constants_1.Queues.NOTIFICATION_DLQ,
                queue_constants_1.Queues.OUTBOX_DISPATCHER_DLQ,
                queue_constants_1.Queues.WEBSOCKET_DLQ,
                queue_constants_1.Queues.REPORT_GENERATION_DLQ,
                queue_constants_1.Queues.REPORT_EXPORT_DLQ,
            ];
            for (let i = 0; i < 10; i++) {
                targetDlqs.push(`analytics-snapshot-dlq-${i}`);
            }
            for (const dlqName of targetDlqs) {
                try {
                    const queue = this.queueService.getQueue(dlqName);
                    if (queue) {
                        const waiting = await queue.getWaitingCount();
                        this.metrics.setQueueDlqDepth(dlqName, waiting);
                    }
                }
                catch (queueErr) {
                    this.logger.warn(`Failed to collect DLQ depth for ${dlqName}: ${queueErr.message}`);
                }
            }
        }
        catch (err) {
            this.logger.error(`Failed to collect DLQ metrics: ${err.message}`);
        }
        if (this.redisService.isHealthy()) {
            try {
                const client = this.redisService.getClient();
                const start = Date.now();
                await client.ping().catch(() => { });
                this.metrics.observeRedisLatency(Date.now() - start);
                const info = await client.info();
                const usedMemoryMatch = info.match(/used_memory:(\d+)/);
                if (usedMemoryMatch) {
                    this.metrics.setRedisMemoryUsage(parseInt(usedMemoryMatch[1], 10));
                }
                const connectedClientsMatch = info.match(/connected_clients:(\d+)/);
                if (connectedClientsMatch) {
                    this.metrics.setRedisConnectedClients(parseInt(connectedClientsMatch[1], 10));
                }
                const lockKeys = await client.keys('lock:*').catch(() => []);
                const reportLockKeys = await client.keys('report:lock:*').catch(() => []);
                const snapshotLockKeys = await client.keys('analytics:snapshot:lock:*').catch(() => []);
                const totalActiveLocks = lockKeys.length + reportLockKeys.length + snapshotLockKeys.length;
                this.metrics.setDistributedLocksActive(totalActiveLocks);
                const outboxIdempotencyKeys = await client.keys('outbox:idempotency:*').catch(() => []);
                const reportIdempotencyKeys = await client.keys('report:idempotency:*').catch(() => []);
                const totalIdempotencyKeys = outboxIdempotencyKeys.length + reportIdempotencyKeys.length;
                this.metrics.setRedisIdempotencyKeysActive(totalIdempotencyKeys);
            }
            catch (redisErr) {
                this.logger.warn(`Failed to collect Redis telemetry metrics: ${redisErr.message}`);
            }
        }
        try {
            const openPositionsCount = await this.prisma.trade.count({
                where: { status: client_1.TradeStatus.OPEN },
            });
            this.metrics.setOpenPositions(openPositionsCount);
        }
        catch (err) {
            this.logger.error(`Failed to collect open positions metric: ${err.message}`);
        }
        try {
            const activeSubscribers = await this.prisma.user.count({
                where: {
                    subscriptions: {
                        some: { status: 'ACTIVE' },
                    },
                },
            });
            this.metrics.setSubscribersActive(activeSubscribers);
            const sparkSubscribers = await this.prisma.subscription.count({
                where: {
                    planId: '11111111-e29b-41d4-a716-446655440001',
                    status: 'ACTIVE',
                },
            });
            this.metrics.setSparkSubscriptions(sparkSubscribers);
            const splendidSubscribers = await this.prisma.subscription.count({
                where: {
                    planId: '11111111-e29b-41d4-a716-446655440002',
                    status: 'ACTIVE',
                },
            });
            this.metrics.setSplendidSubscriptions(splendidSubscribers);
            const activeSegs = await this.prisma.userSegment.count({
                where: { status: 'ACTIVE' },
            });
            this.metrics.setSegmentsActive(activeSegs);
            this.metrics.setActiveSegments(activeSegs);
            const pausedSegs = await this.prisma.userSegment.count({
                where: { status: 'PAUSED' },
            });
            this.metrics.setSegmentsPaused(pausedSegs);
            const lockedSegs = await this.prisma.userSegment.count({
                where: {
                    status: 'PAUSED',
                    lastRiskLockAt: { not: null },
                },
            });
            this.metrics.setSegmentsRiskLocked(lockedSegs);
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const activeConsents = await this.prisma.consent.count({
                where: {
                    status: 'ACTIVE',
                    updatedAt: { gte: today },
                },
            });
            this.metrics.setConsentsActiveToday(activeConsents);
        }
        catch (dbErr) {
            this.logger.warn(`Failed to collect database KPI metrics: ${dbErr.message}`);
        }
        try {
            const pendingCount = await this.prisma.outboxEvent.count({
                where: { status: 'PENDING' },
            });
            this.metrics.setOutboxEventsPending(pendingCount);
            const processingCount = await this.prisma.outboxEvent.count({
                where: { status: 'PROCESSING' },
            });
            this.metrics.setOutboxEventsProcessing(processingCount);
            const failedCount = await this.prisma.outboxEvent.count({
                where: { status: 'FAILED' },
            });
            this.metrics.setOutboxEventsFailed(failedCount);
        }
        catch (outboxErr) {
            this.logger.warn(`Failed to collect outbox telemetry: ${outboxErr.message}`);
        }
    }
};
exports.MetricsCollectorService = MetricsCollectorService;
__decorate([
    (0, schedule_1.Cron)('*/15 * * * * *'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MetricsCollectorService.prototype, "collectGauges", null);
exports.MetricsCollectorService = MetricsCollectorService = MetricsCollectorService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [metrics_service_1.MetricsService,
        queues_service_1.QueueService,
        prisma_service_1.PrismaService,
        redis_service_1.RedisService])
], MetricsCollectorService);
//# sourceMappingURL=metrics-collector.service.js.map