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
var QueueService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.QueueService = void 0;
const common_1 = require("@nestjs/common");
const bullmq_1 = require("@nestjs/bullmq");
const bullmq_2 = require("bullmq");
const prisma_service_1 = require("../../prisma.service");
const redis_service_1 = require("../redis/redis.service");
const queue_constants_1 = require("./queue.constants");
const client_1 = require("@prisma/client");
const QUEUE_LIMITS = {
    [queue_constants_1.Queues.ORDER_PLACEMENT]: 50000,
    [queue_constants_1.Queues.ORDER_MONITORING]: 100000,
    [queue_constants_1.Queues.NOTIFICATION]: 250000,
};
let QueueService = QueueService_1 = class QueueService {
    prisma;
    redisService;
    signalQueue;
    orderPlacementQueue;
    orderMonitoringQueue;
    notificationQueue;
    signalDlq;
    orderDlq;
    orderMonitoringDlq;
    notificationDlq;
    outboxDispatcherQueue;
    outboxDispatcherDlq;
    websocketQueue;
    websocketDlq;
    reportGenerationQueue;
    reportGenerationDlq;
    reportExportQueue;
    reportExportDlq;
    analyticsSnapshotQueue;
    analyticsSnapshotDlq;
    positionRebuildQueue;
    positionRebuildDlq;
    reconciliationQueue;
    reconciliationDlq;
    riskRecalculateQueue;
    riskRecalculateDlq;
    analyticsRecalculateQueue;
    analyticsRecalculateDlq;
    emailQueue;
    emailDlq;
    smsQueue;
    smsDlq;
    whatsappQueue;
    whatsappDlq;
    pushQueue;
    pushDlq;
    logger = new common_1.Logger(QueueService_1.name);
    flowProducer;
    shardedSnapshotQueues = new Map();
    constructor(prisma, redisService, signalQueue, orderPlacementQueue, orderMonitoringQueue, notificationQueue, signalDlq, orderDlq, orderMonitoringDlq, notificationDlq, outboxDispatcherQueue, outboxDispatcherDlq, websocketQueue, websocketDlq, reportGenerationQueue, reportGenerationDlq, reportExportQueue, reportExportDlq, analyticsSnapshotQueue, analyticsSnapshotDlq, positionRebuildQueue, positionRebuildDlq, reconciliationQueue, reconciliationDlq, riskRecalculateQueue, riskRecalculateDlq, analyticsRecalculateQueue, analyticsRecalculateDlq, emailQueue, emailDlq, smsQueue, smsDlq, whatsappQueue, whatsappDlq, pushQueue, pushDlq) {
        this.prisma = prisma;
        this.redisService = redisService;
        this.signalQueue = signalQueue;
        this.orderPlacementQueue = orderPlacementQueue;
        this.orderMonitoringQueue = orderMonitoringQueue;
        this.notificationQueue = notificationQueue;
        this.signalDlq = signalDlq;
        this.orderDlq = orderDlq;
        this.orderMonitoringDlq = orderMonitoringDlq;
        this.notificationDlq = notificationDlq;
        this.outboxDispatcherQueue = outboxDispatcherQueue;
        this.outboxDispatcherDlq = outboxDispatcherDlq;
        this.websocketQueue = websocketQueue;
        this.websocketDlq = websocketDlq;
        this.reportGenerationQueue = reportGenerationQueue;
        this.reportGenerationDlq = reportGenerationDlq;
        this.reportExportQueue = reportExportQueue;
        this.reportExportDlq = reportExportDlq;
        this.analyticsSnapshotQueue = analyticsSnapshotQueue;
        this.analyticsSnapshotDlq = analyticsSnapshotDlq;
        this.positionRebuildQueue = positionRebuildQueue;
        this.positionRebuildDlq = positionRebuildDlq;
        this.reconciliationQueue = reconciliationQueue;
        this.reconciliationDlq = reconciliationDlq;
        this.riskRecalculateQueue = riskRecalculateQueue;
        this.riskRecalculateDlq = riskRecalculateDlq;
        this.analyticsRecalculateQueue = analyticsRecalculateQueue;
        this.analyticsRecalculateDlq = analyticsRecalculateDlq;
        this.emailQueue = emailQueue;
        this.emailDlq = emailDlq;
        this.smsQueue = smsQueue;
        this.smsDlq = smsDlq;
        this.whatsappQueue = whatsappQueue;
        this.whatsappDlq = whatsappDlq;
        this.pushQueue = pushQueue;
        this.pushDlq = pushDlq;
        this.flowProducer = new bullmq_2.FlowProducer({
            connection: this.redisService.getClient(),
        });
    }
    getFlowProducer() {
        return this.flowProducer;
    }
    getQueue(queueName) {
        switch (queueName) {
            case queue_constants_1.Queues.SIGNAL_PROCESSING:
                return this.signalQueue;
            case queue_constants_1.Queues.ORDER_PLACEMENT:
                return this.orderPlacementQueue;
            case queue_constants_1.Queues.ORDER_MONITORING:
                return this.orderMonitoringQueue;
            case queue_constants_1.Queues.NOTIFICATION:
                return this.notificationQueue;
            case queue_constants_1.Queues.SIGNAL_DLQ:
                return this.signalDlq;
            case queue_constants_1.Queues.ORDER_DLQ:
                return this.orderDlq;
            case queue_constants_1.Queues.ORDER_MONITORING_DLQ:
                return this.orderMonitoringDlq;
            case queue_constants_1.Queues.NOTIFICATION_DLQ:
                return this.notificationDlq;
            case queue_constants_1.Queues.OUTBOX_DISPATCHER:
                return this.outboxDispatcherQueue;
            case queue_constants_1.Queues.OUTBOX_DISPATCHER_DLQ:
                return this.outboxDispatcherDlq;
            case queue_constants_1.Queues.WEBSOCKET:
                return this.websocketQueue;
            case queue_constants_1.Queues.WEBSOCKET_DLQ:
                return this.websocketDlq;
            case queue_constants_1.Queues.REPORT_GENERATION:
                return this.reportGenerationQueue;
            case queue_constants_1.Queues.REPORT_GENERATION_DLQ:
                return this.reportGenerationDlq;
            case queue_constants_1.Queues.REPORT_EXPORT:
                return this.reportExportQueue;
            case queue_constants_1.Queues.REPORT_EXPORT_DLQ:
                return this.reportExportDlq;
            case queue_constants_1.Queues.ANALYTICS_SNAPSHOT:
                return this.analyticsSnapshotQueue;
            case queue_constants_1.Queues.ANALYTICS_SNAPSHOT_DLQ:
                return this.analyticsSnapshotDlq;
            case queue_constants_1.Queues.POSITION_REBUILD:
                return this.positionRebuildQueue;
            case queue_constants_1.Queues.POSITION_REBUILD_DLQ:
                return this.positionRebuildDlq;
            case queue_constants_1.Queues.RECONCILIATION:
                return this.reconciliationQueue;
            case queue_constants_1.Queues.RECONCILIATION_DLQ:
                return this.reconciliationDlq;
            case queue_constants_1.Queues.RISK_RECALCULATE:
                return this.riskRecalculateQueue;
            case queue_constants_1.Queues.RISK_RECALCULATE_DLQ:
                return this.riskRecalculateDlq;
            case queue_constants_1.Queues.ANALYTICS_RECALCULATE:
                return this.analyticsRecalculateQueue;
            case queue_constants_1.Queues.ANALYTICS_RECALCULATE_DLQ:
                return this.analyticsRecalculateDlq;
            case queue_constants_1.Queues.EMAIL:
                return this.emailQueue;
            case queue_constants_1.Queues.EMAIL_DLQ:
                return this.emailDlq;
            case queue_constants_1.Queues.SMS:
                return this.smsQueue;
            case queue_constants_1.Queues.SMS_DLQ:
                return this.smsDlq;
            case queue_constants_1.Queues.WHATSAPP:
                return this.whatsappQueue;
            case queue_constants_1.Queues.WHATSAPP_DLQ:
                return this.whatsappDlq;
            case queue_constants_1.Queues.PUSH:
                return this.pushQueue;
            case queue_constants_1.Queues.PUSH_DLQ:
                return this.pushDlq;
            default:
                if (queueName.startsWith('analytics-snapshot-dlq-')) {
                    let q = this.shardedSnapshotQueues.get(queueName);
                    if (!q) {
                        q = new bullmq_2.Queue(queueName, { connection: this.redisService.getClient() });
                        this.shardedSnapshotQueues.set(queueName, q);
                    }
                    return q;
                }
                if (queueName.startsWith('analytics-snapshot-')) {
                    let q = this.shardedSnapshotQueues.get(queueName);
                    if (!q) {
                        q = new bullmq_2.Queue(queueName, { connection: this.redisService.getClient() });
                        this.shardedSnapshotQueues.set(queueName, q);
                    }
                    return q;
                }
                throw new Error(`Queue '${queueName}' not found`);
        }
    }
    async addJob(queueName, jobId, payload, priority, delay) {
        this.redisService.assertHealthy();
        const queue = this.getQueue(queueName);
        const limit = QUEUE_LIMITS[queueName];
        if (limit !== undefined) {
            const waiting = await queue.getWaitingCount();
            if (waiting >= limit) {
                this.logger.warn(`Queue '${queueName}' backpressure limit exceeded: waiting=${waiting}, limit=${limit}`);
                throw new common_1.ServiceUnavailableException(`Queue '${queueName}' is overloaded`);
            }
        }
        try {
            await this.prisma.queueJob.upsert({
                where: {
                    queueName_jobId: { queueName, jobId },
                },
                update: {
                    payload: payload || {},
                    status: client_1.QueueJobStatus.ACTIVE,
                    attempts: 0,
                    updatedAt: new Date(),
                },
                create: {
                    queueName,
                    jobId,
                    payload: payload || {},
                    status: client_1.QueueJobStatus.ACTIVE,
                    attempts: 0,
                },
            });
            await queue.add(jobId, payload, {
                jobId,
                priority,
                delay,
                attempts: 3,
                backoff: {
                    type: 'exponential',
                    delay: 1000,
                },
            });
            this.logger.log(`Enqueued job ${jobId} to queue ${queueName} (Priority: ${priority || 'none'}, Delay: ${delay || 'none'})`);
        }
        catch (err) {
            this.logger.error(`Failed to add job ${jobId} to queue ${queueName}: ${err.message}`);
            throw err;
        }
    }
    async updateJobStatus(queueName, jobId, status, attempts) {
        try {
            await this.prisma.queueJob.update({
                where: {
                    queueName_jobId: { queueName, jobId },
                },
                data: {
                    status,
                    ...(attempts !== undefined ? { attempts } : {}),
                    updatedAt: new Date(),
                },
            });
        }
        catch (err) {
            this.logger.error(`Failed to update DB status for job ${jobId} in queue ${queueName}: ${err.message}`);
        }
    }
    async getAggregatedMetrics() {
        let waiting = 0;
        let active = 0;
        let failed = 0;
        let dlq = 0;
        const mainQueues = [
            queue_constants_1.Queues.SIGNAL_PROCESSING,
            queue_constants_1.Queues.ORDER_PLACEMENT,
            queue_constants_1.Queues.ORDER_MONITORING,
            queue_constants_1.Queues.NOTIFICATION,
            queue_constants_1.Queues.OUTBOX_DISPATCHER,
            queue_constants_1.Queues.WEBSOCKET,
            queue_constants_1.Queues.REPORT_GENERATION,
            queue_constants_1.Queues.REPORT_EXPORT,
            queue_constants_1.Queues.POSITION_REBUILD,
            queue_constants_1.Queues.RECONCILIATION,
            queue_constants_1.Queues.RISK_RECALCULATE,
            queue_constants_1.Queues.ANALYTICS_RECALCULATE,
            queue_constants_1.Queues.EMAIL,
            queue_constants_1.Queues.SMS,
            queue_constants_1.Queues.WHATSAPP,
            queue_constants_1.Queues.PUSH,
            ...Array.from({ length: 10 }, (_, i) => `analytics-snapshot-${i}`),
        ];
        for (const name of mainQueues) {
            try {
                const q = this.getQueue(name);
                waiting += await q.getWaitingCount();
                active += await q.getActiveCount();
                failed += await q.getFailedCount();
            }
            catch (err) {
                this.logger.warn(`Failed to count metrics for queue ${name}: ${err.message}`);
            }
        }
        const dlqQueues = [
            queue_constants_1.Queues.SIGNAL_DLQ,
            queue_constants_1.Queues.ORDER_DLQ,
            queue_constants_1.Queues.ORDER_MONITORING_DLQ,
            queue_constants_1.Queues.NOTIFICATION_DLQ,
            queue_constants_1.Queues.OUTBOX_DISPATCHER_DLQ,
            queue_constants_1.Queues.WEBSOCKET_DLQ,
            queue_constants_1.Queues.REPORT_GENERATION_DLQ,
            queue_constants_1.Queues.REPORT_EXPORT_DLQ,
            queue_constants_1.Queues.POSITION_REBUILD_DLQ,
            queue_constants_1.Queues.RECONCILIATION_DLQ,
            queue_constants_1.Queues.RISK_RECALCULATE_DLQ,
            queue_constants_1.Queues.ANALYTICS_RECALCULATE_DLQ,
            queue_constants_1.Queues.EMAIL_DLQ,
            queue_constants_1.Queues.SMS_DLQ,
            queue_constants_1.Queues.WHATSAPP_DLQ,
            queue_constants_1.Queues.PUSH_DLQ,
            ...Array.from({ length: 10 }, (_, i) => `analytics-snapshot-dlq-${i}`),
        ];
        for (const name of dlqQueues) {
            try {
                const q = this.getQueue(name);
                dlq += await q.getJobCountByTypes('waiting', 'active', 'failed', 'completed');
            }
            catch (err) {
                this.logger.warn(`Failed to count metrics for DLQ ${name}: ${err.message}`);
            }
        }
        return { waiting, active, failed, dlq };
    }
    async getDlqMetrics() {
        const getCount = async (queue) => {
            try {
                return await queue.getJobCountByTypes('waiting', 'active', 'failed', 'completed');
            }
            catch {
                return 0;
            }
        };
        let shardedSnapshotDlqSum = 0;
        for (let i = 0; i < 10; i++) {
            try {
                const q = this.getQueue(`analytics-snapshot-dlq-${i}`);
                shardedSnapshotDlqSum += await getCount(q);
            }
            catch { }
        }
        const [signalDlq, orderPlacementDlq, orderMonitoringDlq, notificationDlq, outboxDispatcherDlq, websocketDlq, reportGenerationDlq, reportExportDlq, positionRebuildDlq, reconciliationDlq, riskRecalculateDlq, analyticsRecalculateDlq, emailDlq, smsDlq, whatsappDlq, pushDlq,] = await Promise.all([
            getCount(this.signalDlq),
            getCount(this.orderDlq),
            getCount(this.orderMonitoringDlq),
            getCount(this.notificationDlq),
            getCount(this.outboxDispatcherDlq),
            getCount(this.websocketDlq),
            getCount(this.reportGenerationDlq),
            getCount(this.reportExportDlq),
            getCount(this.positionRebuildDlq),
            getCount(this.reconciliationDlq),
            getCount(this.riskRecalculateDlq),
            getCount(this.analyticsRecalculateDlq),
            getCount(this.emailDlq),
            getCount(this.smsDlq),
            getCount(this.whatsappDlq),
            getCount(this.pushDlq),
        ]);
        return {
            signalDlq,
            orderPlacementDlq,
            orderMonitoringDlq,
            notificationDlq,
            outboxDispatcherDlq,
            websocketDlq,
            reportGenerationDlq,
            reportExportDlq,
            positionRebuildDlq,
            reconciliationDlq,
            riskRecalculateDlq,
            analyticsRecalculateDlq,
            emailDlq,
            smsDlq,
            whatsappDlq,
            pushDlq,
            analyticsSnapshotDlq: shardedSnapshotDlqSum,
        };
    }
};
exports.QueueService = QueueService;
exports.QueueService = QueueService = QueueService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(2, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.SIGNAL_PROCESSING)),
    __param(3, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.ORDER_PLACEMENT)),
    __param(4, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.ORDER_MONITORING)),
    __param(5, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.NOTIFICATION)),
    __param(6, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.SIGNAL_DLQ)),
    __param(7, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.ORDER_DLQ)),
    __param(8, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.ORDER_MONITORING_DLQ)),
    __param(9, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.NOTIFICATION_DLQ)),
    __param(10, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.OUTBOX_DISPATCHER)),
    __param(11, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.OUTBOX_DISPATCHER_DLQ)),
    __param(12, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.WEBSOCKET)),
    __param(13, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.WEBSOCKET_DLQ)),
    __param(14, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.REPORT_GENERATION)),
    __param(15, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.REPORT_GENERATION_DLQ)),
    __param(16, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.REPORT_EXPORT)),
    __param(17, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.REPORT_EXPORT_DLQ)),
    __param(18, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.ANALYTICS_SNAPSHOT)),
    __param(19, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.ANALYTICS_SNAPSHOT_DLQ)),
    __param(20, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.POSITION_REBUILD)),
    __param(21, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.POSITION_REBUILD_DLQ)),
    __param(22, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.RECONCILIATION)),
    __param(23, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.RECONCILIATION_DLQ)),
    __param(24, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.RISK_RECALCULATE)),
    __param(25, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.RISK_RECALCULATE_DLQ)),
    __param(26, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.ANALYTICS_RECALCULATE)),
    __param(27, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.ANALYTICS_RECALCULATE_DLQ)),
    __param(28, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.EMAIL)),
    __param(29, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.EMAIL_DLQ)),
    __param(30, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.SMS)),
    __param(31, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.SMS_DLQ)),
    __param(32, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.WHATSAPP)),
    __param(33, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.WHATSAPP_DLQ)),
    __param(34, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.PUSH)),
    __param(35, (0, bullmq_1.InjectQueue)(queue_constants_1.Queues.PUSH_DLQ)),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        redis_service_1.RedisService,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue,
        bullmq_2.Queue])
], QueueService);
//# sourceMappingURL=queues.service.js.map