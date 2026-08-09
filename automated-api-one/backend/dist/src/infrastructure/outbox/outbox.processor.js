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
var OutboxProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OutboxProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const schedule_1 = require("@nestjs/schedule");
const config_1 = require("@nestjs/config");
const prisma_service_1 = require("../../prisma.service");
const redis_service_1 = require("../redis/redis.service");
const queues_service_1 = require("../queues/queues.service");
const queue_constants_1 = require("../queues/queue.constants");
const client_1 = require("@prisma/client");
const metrics_service_1 = require("../metrics/metrics.service");
const EVENT_ROUTING = {
    ORDER_PLACED: queue_constants_1.Queues.NOTIFICATION,
    ORDER_FILLED: queue_constants_1.Queues.NOTIFICATION,
    ORDER_REJECTED: queue_constants_1.Queues.NOTIFICATION,
    ORDER_CANCELLED: queue_constants_1.Queues.NOTIFICATION,
    ORDER_FAILED: queue_constants_1.Queues.NOTIFICATION,
    POSITION_UPDATED: queue_constants_1.Queues.WEBSOCKET,
    TARGET_HIT: queue_constants_1.Queues.NOTIFICATION,
    STOPLOSS_HIT: queue_constants_1.Queues.NOTIFICATION,
    CONSENT_GRANTED: queue_constants_1.Queues.NOTIFICATION,
    CONSENT_REVOKED: queue_constants_1.Queues.NOTIFICATION,
    SUBSCRIPTION_ACTIVATED: queue_constants_1.Queues.NOTIFICATION,
    SUBSCRIPTION_RENEWED: queue_constants_1.Queues.NOTIFICATION,
    SUBSCRIPTION_CANCELLED: queue_constants_1.Queues.NOTIFICATION,
    BROKER_DISCONNECTED: [
        queue_constants_1.Queues.NOTIFICATION,
        queue_constants_1.Queues.WEBSOCKET,
    ],
    TRADE_OPENED: [
        queue_constants_1.Queues.NOTIFICATION,
        queue_constants_1.Queues.ORDER_MONITORING,
    ],
    TRADE_CLOSED: queue_constants_1.Queues.NOTIFICATION,
    TRADE_EXECUTED: queue_constants_1.Queues.NOTIFICATION,
    ORDER_PLACEMENT: queue_constants_1.Queues.ORDER_PLACEMENT,
    ORDER_MONITORING: queue_constants_1.Queues.ORDER_MONITORING,
    SIGNAL_PUBLISHED: queue_constants_1.Queues.SIGNAL_PROCESSING,
    RISK_VIOLATION: queue_constants_1.Queues.NOTIFICATION,
    RECONCILIATION_ISSUE: [
        queue_constants_1.Queues.NOTIFICATION,
        queue_constants_1.Queues.WEBSOCKET,
    ],
};
let OutboxProcessor = OutboxProcessor_1 = class OutboxProcessor extends bullmq_1.WorkerHost {
    prisma;
    redisService;
    queueService;
    configService;
    metrics;
    logger = new common_1.Logger(OutboxProcessor_1.name);
    isCronProcessing = false;
    constructor(prisma, redisService, queueService, configService, metrics) {
        super();
        this.prisma = prisma;
        this.redisService = redisService;
        this.queueService = queueService;
        this.configService = configService;
        this.metrics = metrics;
    }
    async process(job) {
        const { outboxEventId } = job.data;
        this.redisService.assertHealthy();
        const event = await this.prisma.outboxEvent.findUnique({
            where: { id: outboxEventId },
        });
        if (!event) {
            this.logger.warn(`Outbox event ${outboxEventId} not found in database. Skipping.`);
            return;
        }
        if (event.status === client_1.OutboxStatus.PROCESSED) {
            this.logger.debug(`Outbox event ${outboxEventId} already processed. Skipping.`);
            return;
        }
        await this.prisma.outboxEvent.update({
            where: { id: outboxEventId },
            data: { status: client_1.OutboxStatus.PROCESSING },
        });
        if (event.eventKey) {
            const redisKey = `outbox:idempotency:${event.eventKey}`;
            try {
                const isNew = await this.redisService
                    .getClient()
                    .set(redisKey, '1', 'PX', 604800000, 'NX');
                if (!isNew) {
                    this.logger.warn(`Outbox event ${outboxEventId} with key ${event.eventKey} is duplicate. Deduplicating.`);
                    await this.prisma.outboxEvent.update({
                        where: { id: outboxEventId },
                        data: {
                            status: client_1.OutboxStatus.PROCESSED,
                            processedAt: new Date(),
                        },
                    });
                    return;
                }
            }
            catch (err) {
                this.logger.error(`Redis idempotency check failed for key ${event.eventKey}: ${err.message}. Failing job to retry.`);
                await this.prisma.outboxEvent.update({
                    where: { id: outboxEventId },
                    data: { status: client_1.OutboxStatus.PENDING },
                });
                throw err;
            }
        }
        try {
            const targetQueues = this.determineQueues(event.eventType);
            for (const queueName of targetQueues) {
                await this.queueService.addJob(queueName, event.id, event.payload);
            }
            const riskRecalculateEvents = [
                'ORDER_PLACED',
                'ORDER_FILLED',
                'ORDER_REJECTED',
                'ORDER_CANCELLED',
                'ORDER_FAILED',
                'TRADE_OPENED',
                'TRADE_CLOSED',
                'TRADE_EXECUTED',
            ];
            if (riskRecalculateEvents.includes(event.eventType)) {
                const payload = event.payload;
                const userId = payload?.userId;
                if (userId) {
                    const jobId = `risk-recalc-${userId}`;
                    try {
                        await this.queueService.addJob(queue_constants_1.Queues.RISK_RECALCULATE, jobId, { userId });
                    }
                    catch (err) {
                        this.logger.error(`Failed to enqueue risk recalculation job for user ${userId}: ${err.message}`);
                    }
                }
            }
            await this.prisma.outboxEvent.update({
                where: { id: outboxEventId },
                data: {
                    status: client_1.OutboxStatus.PROCESSED,
                    processedAt: new Date(),
                    attempts: job.attemptsMade + 1,
                },
            });
            this.metrics.incrementOutboxEventsProcessed();
            this.logger.log(`Successfully dispatched outbox event ${outboxEventId} of type ${event.eventType} to [${targetQueues.join(', ')}]`);
        }
        catch (err) {
            const attempts = job.attemptsMade + 1;
            const maxAttempts = job.opts.attempts || 5;
            const status = attempts >= maxAttempts ? client_1.OutboxStatus.FAILED : client_1.OutboxStatus.PENDING;
            this.logger.error(`Failed to dispatch outbox event ${outboxEventId} (Attempt ${attempts}/${maxAttempts}): ${err.message}`);
            await this.prisma.outboxEvent.update({
                where: { id: outboxEventId },
                data: {
                    attempts,
                    status,
                },
            });
            if (status === client_1.OutboxStatus.FAILED) {
                this.metrics.incrementOutboxEventsDlq();
            }
            else {
                this.metrics.incrementOutboxEventsFailed();
            }
            throw err;
        }
    }
    async fallbackPoll() {
        if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
            return;
        }
        if (this.isCronProcessing)
            return;
        if (!this.redisService.isHealthy())
            return;
        this.isCronProcessing = true;
        try {
            const fiveMinutesAgo = new Date(Date.now() - 300000);
            const stuckProcessing = await this.prisma.outboxEvent.findMany({
                where: {
                    status: client_1.OutboxStatus.PROCESSING,
                    createdAt: { lte: fiveMinutesAgo },
                },
                take: 50,
            });
            for (const event of stuckProcessing) {
                this.logger.warn(`Outbox event ${event.id} stuck in PROCESSING. Resetting to PENDING.`);
                await this.prisma.outboxEvent.update({
                    where: { id: event.id },
                    data: { status: client_1.OutboxStatus.PENDING },
                });
            }
            const tenSecondsAgo = new Date(Date.now() - 10000);
            const stuckEvents = await this.prisma.outboxEvent.findMany({
                where: {
                    status: client_1.OutboxStatus.PENDING,
                    createdAt: { lte: tenSecondsAgo },
                },
                orderBy: { createdAt: 'asc' },
                take: 50,
            });
            if (stuckEvents.length > 0) {
                this.logger.log(`Fallback poller found ${stuckEvents.length} stuck PENDING outbox events. Re-enqueuing...`);
                for (const event of stuckEvents) {
                    try {
                        await this.queueService.addJob(queue_constants_1.Queues.OUTBOX_DISPATCHER, event.id, {
                            outboxEventId: event.id,
                            eventType: event.eventType,
                            eventKey: event.eventKey || null,
                        });
                    }
                    catch (err) {
                        this.logger.error(`Fallback poller failed to re-enqueue event ${event.id}: ${err.message}`);
                    }
                }
            }
        }
        catch (err) {
            this.logger.error(`Fallback outbox poller error: ${err.message}`);
        }
        finally {
            this.isCronProcessing = false;
        }
    }
    determineQueues(eventType) {
        const routes = EVENT_ROUTING[eventType];
        if (!routes) {
            this.logger.warn(`Unknown outbox event type: ${eventType}. Fallback to trade-execution.`);
            return [queue_constants_1.Queues.SIGNAL_PROCESSING];
        }
        return Array.isArray(routes) ? routes : [routes];
    }
};
exports.OutboxProcessor = OutboxProcessor;
__decorate([
    (0, schedule_1.Cron)('*/30 * * * * *'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], OutboxProcessor.prototype, "fallbackPoll", null);
exports.OutboxProcessor = OutboxProcessor = OutboxProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.OUTBOX_DISPATCHER, {
        concurrency: 10,
    }),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        redis_service_1.RedisService,
        queues_service_1.QueueService,
        config_1.ConfigService,
        metrics_service_1.MetricsService])
], OutboxProcessor);
//# sourceMappingURL=outbox.processor.js.map