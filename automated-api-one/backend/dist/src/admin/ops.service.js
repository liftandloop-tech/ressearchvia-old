"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var OpsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OpsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const redis_service_1 = require("../infrastructure/redis/redis.service");
const queues_service_1 = require("../infrastructure/queues/queues.service");
const metrics_service_1 = require("../infrastructure/metrics/metrics.service");
const broker_session_service_1 = require("../brokers/services/broker-session.service");
const broker_factory_1 = require("../brokers/factory/broker.factory");
const client_1 = require("@prisma/client");
const queue_constants_1 = require("../infrastructure/queues/queue.constants");
const schedule_1 = require("@nestjs/schedule");
const reconciliation_service_1 = require("../reconciliation/reconciliation.service");
const crypto = __importStar(require("crypto"));
const alerting_service_1 = require("../notifications/alerting.service");
let OpsService = OpsService_1 = class OpsService {
    prisma;
    redisService;
    queueService;
    metrics;
    brokerSessionService;
    reconciliationService;
    alertingService;
    brokerFactory;
    logger = new common_1.Logger(OpsService_1.name);
    constructor(prisma, redisService, queueService, metrics, brokerSessionService, reconciliationService, alertingService, brokerFactory) {
        this.prisma = prisma;
        this.redisService = redisService;
        this.queueService = queueService;
        this.metrics = metrics;
        this.brokerSessionService = brokerSessionService;
        this.reconciliationService = reconciliationService;
        this.alertingService = alertingService;
        this.brokerFactory = brokerFactory;
    }
    async runOperation(operatorId, action, resourceType, resourceId, metadata, handler) {
        const operationId = crypto.randomUUID();
        this.metrics.incrementOperationsRequests(action);
        const idempotencyKey = `ops:idempotency:${action}:${resourceId}`;
        if (this.redisService.isHealthy()) {
            const acquired = await this.redisService.getClient().set(idempotencyKey, '1', 'EX', 60, 'NX');
            if (acquired !== 'OK') {
                this.metrics.incrementOperationsRejected(action);
                throw new common_1.BadRequestException(`Operation ${action} on resource ${resourceId} is already being processed. Try again in 60 seconds.`);
            }
        }
        let audit = null;
        try {
            audit = await this.prisma.operationsAudit.create({
                data: {
                    operationId,
                    operatorId,
                    action,
                    status: client_1.OperationStatus.SUCCESS,
                    resourceType,
                    resourceId,
                    metadata: metadata || {},
                },
            });
            this.metrics.incrementOperationsAuditRecords();
        }
        catch (auditErr) {
            this.logger.error(`Failed to create operations audit record: ${auditErr.message || auditErr}`);
            this.metrics.incrementOperationsAuditFailures();
        }
        try {
            await handler(operationId);
            this.metrics.incrementOperationsSuccess(action);
            return { operationId };
        }
        catch (err) {
            if (this.redisService.isHealthy()) {
                try {
                    await this.redisService.getClient().del(idempotencyKey);
                }
                catch (redisErr) {
                    this.logger.warn(`Failed to clear idempotency key ${idempotencyKey} from Redis: ${redisErr.message || redisErr}`);
                }
            }
            const isRejected = err instanceof common_1.BadRequestException;
            const status = isRejected ? client_1.OperationStatus.REJECTED : client_1.OperationStatus.FAILED;
            if (audit) {
                try {
                    await this.prisma.operationsAudit.update({
                        where: { id: audit.id },
                        data: {
                            status,
                            errorMessage: err.message || String(err),
                        },
                    });
                    this.metrics.incrementOperationsAuditRecords();
                }
                catch (auditErr) {
                    this.logger.error(`Failed to update operations audit record: ${auditErr.message || auditErr}`);
                    this.metrics.incrementOperationsAuditFailures();
                }
            }
            else {
                this.metrics.incrementOperationsAuditFailures();
            }
            if (isRejected) {
                this.metrics.incrementOperationsRejected(action);
            }
            else {
                this.metrics.incrementOperationsFailed(action);
            }
            throw err;
        }
    }
    async cleanupOperationsAudit() {
        if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
            return;
        }
        this.logger.log('Running OperationsAudit cleanup task...');
        const retentionDate = new Date();
        retentionDate.setDate(retentionDate.getDate() - 180);
        try {
            const { count } = await this.prisma.operationsAudit.deleteMany({
                where: {
                    createdAt: {
                        lt: retentionDate,
                    },
                },
            });
            this.logger.log(`OperationsAudit cleanup complete. Removed ${count} records older than 180 days.`);
        }
        catch (err) {
            this.logger.error(`Failed to clean up OperationsAudit records: ${err.message || err}`);
        }
    }
    async replaySignal(operatorId, signalId) {
        return this.runOperation(operatorId, client_1.OperationsAction.REPLAY_SIGNAL, 'Signal', signalId, {}, async (operationId) => {
            const signal = await this.prisma.signal.findUnique({
                where: { id: signalId },
            });
            if (!signal) {
                throw new common_1.NotFoundException(`Signal ${signalId} not found`);
            }
            const metadata = signal.metadata || {};
            const replayCount = metadata.replayCount || 0;
            if (replayCount >= 5) {
                throw new common_1.BadRequestException(`Signal ${signalId} has exceeded the maximum replay limit of 5`);
            }
            metadata.replayCount = replayCount + 1;
            await this.prisma.signal.update({
                where: { id: signalId },
                data: { metadata },
            });
            const segment = await this.prisma.segmentMaster.findUnique({
                where: { id: signal.segmentId },
            });
            if (!segment) {
                throw new common_1.BadRequestException(`Segment ${signal.segmentId} not found`);
            }
            if (this.redisService.isHealthy()) {
                const lockKey = `lock:segment:${signal.segmentId}`;
                const isLocked = await this.redisService.getClient().exists(lockKey);
                if (isLocked === 1) {
                    throw new common_1.BadRequestException(`Segment ${signal.segmentId} is currently locked`);
                }
            }
            const activeExec = await this.prisma.segmentExecution.findFirst({
                where: {
                    signalId,
                    state: 'PROCESSING',
                },
            });
            if (activeExec) {
                throw new common_1.BadRequestException('Signal is currently processing');
            }
            const jobId = `signal-${signalId}-${operationId}`;
            await this.queueService.addJob(queue_constants_1.Queues.SIGNAL_PROCESSING, jobId, { signalId });
        });
    }
    async replayOutboxEvent(operatorId, eventId) {
        return this.runOperation(operatorId, client_1.OperationsAction.REPLAY_OUTBOX, 'OutboxEvent', eventId, {}, async (operationId) => {
            const original = await this.prisma.outboxEvent.findUnique({
                where: { id: eventId },
            });
            if (!original) {
                throw new common_1.NotFoundException(`OutboxEvent ${eventId} not found`);
            }
            const newEvent = await this.prisma.outboxEvent.create({
                data: {
                    eventType: original.eventType,
                    eventKey: original.eventKey ? `${original.eventKey}:replay:${operationId}` : null,
                    aggregateId: original.aggregateId,
                    version: original.version,
                    correlationId: original.correlationId,
                    payload: original.payload || {},
                    status: 'PENDING',
                    attempts: 0,
                },
            });
            await this.queueService.addJob(queue_constants_1.Queues.OUTBOX_DISPATCHER, newEvent.id, { outboxEventId: newEvent.id });
        });
    }
    async getDlqMetrics(operatorId) {
        return this.queueService.getDlqMetrics();
    }
    async getDlqJobs(operatorId, queueName) {
        const q = this.queueService.getQueue(queueName);
        if (!q) {
            throw new common_1.BadRequestException(`Queue ${queueName} not found`);
        }
        const jobs = await q.getJobs(['waiting', 'active', 'failed', 'completed']);
        return jobs.map((j) => ({
            id: j.id,
            name: j.name,
            data: j.data,
            attemptsMade: j.attemptsMade,
            failedReason: j.failedReason,
        }));
    }
    async replayDlqJob(operatorId, queueName, jobId) {
        return this.runOperation(operatorId, client_1.OperationsAction.DLQ_REPLAY, 'DLQJob', `${queueName}:${jobId}`, { queueName, jobId }, async () => {
            const dlqQueue = this.queueService.getQueue(queueName);
            if (!dlqQueue) {
                throw new common_1.BadRequestException(`Queue ${queueName} not found`);
            }
            const job = await dlqQueue.getJob(jobId);
            if (!job) {
                throw new common_1.NotFoundException(`Job ${jobId} not found in DLQ ${queueName}`);
            }
            const jobData = job.data || {};
            const replayCount = jobData.replayCount || 0;
            if (replayCount >= 3) {
                throw new common_1.BadRequestException(`Job ${jobId} in queue ${queueName} has exceeded the maximum replay attempts limit of 3.`);
            }
            const updatedData = {
                ...jobData,
                replayCount: replayCount + 1,
            };
            const parentQueue = queueName.replace('-dlq', '');
            await this.queueService.addJob(parentQueue, job.id, updatedData);
            await job.remove();
            this.metrics.incrementDlqReplayed(parentQueue);
        });
    }
    async deleteDlqJob(operatorId, queueName, jobId) {
        return this.runOperation(operatorId, client_1.OperationsAction.DLQ_DELETE, 'DLQJob', `${queueName}:${jobId}`, { queueName, jobId }, async () => {
            const dlqQueue = this.queueService.getQueue(queueName);
            if (!dlqQueue) {
                throw new common_1.BadRequestException(`Queue ${queueName} not found`);
            }
            const job = await dlqQueue.getJob(jobId);
            if (!job) {
                throw new common_1.NotFoundException(`Job ${jobId} not found in DLQ ${queueName}`);
            }
            await job.remove();
            const parentQueue = queueName.replace('-dlq', '');
            this.metrics.incrementDlqPurged(parentQueue);
        });
    }
    isMarketHours() {
        const now = new Date();
        const utc = now.getTime() + now.getTimezoneOffset() * 60000;
        const ist = new Date(utc + 3600000 * 5.5);
        const day = ist.getDay();
        if (day === 0 || day === 6)
            return false;
        const hours = ist.getHours();
        const minutes = ist.getMinutes();
        const timeNum = hours * 100 + minutes;
        return timeNum >= 915 && timeNum <= 1530;
    }
    async pauseQueue(operatorId, queueName, force, reason) {
        const defaultReason = reason || 'Manual SRE operation';
        return this.runOperation(operatorId, client_1.OperationsAction.QUEUE_PAUSE, 'Queue', queueName, {
            queue: queueName,
            reason: defaultReason,
            operatorId,
            timestamp: new Date().toISOString(),
        }, async () => {
            const isOrderQueue = queueName === queue_constants_1.Queues.ORDER_PLACEMENT || queueName === queue_constants_1.Queues.ORDER_MONITORING;
            if (isOrderQueue && this.isMarketHours() && !force) {
                throw new common_1.BadRequestException(`Cannot pause ${queueName} queue during market hours without force=true`);
            }
            const q = this.queueService.getQueue(queueName);
            if (!q) {
                throw new common_1.BadRequestException(`Queue ${queueName} not found`);
            }
            await q.pause();
            this.metrics.incrementQueuePausedTotal(queueName);
        });
    }
    async resumeQueue(operatorId, queueName, reason) {
        const defaultReason = reason || 'Manual SRE operation';
        return this.runOperation(operatorId, client_1.OperationsAction.QUEUE_RESUME, 'Queue', queueName, {
            queue: queueName,
            reason: defaultReason,
            operatorId,
            timestamp: new Date().toISOString(),
        }, async () => {
            const q = this.queueService.getQueue(queueName);
            if (!q) {
                throw new common_1.BadRequestException(`Queue ${queueName} not found`);
            }
            await q.resume();
        });
    }
    async drainQueue(operatorId, queueName, reason) {
        if (!reason) {
            throw new common_1.BadRequestException('A reason is mandatory for draining a queue');
        }
        let drainedJobsCount = 0;
        return this.runOperation(operatorId, client_1.OperationsAction.QUEUE_DRAIN, 'Queue', queueName, {
            reason,
            queue: queueName,
            drainedJobs: 0,
        }, async (operationId) => {
            const q = this.queueService.getQueue(queueName);
            if (!q) {
                throw new common_1.BadRequestException(`Queue ${queueName} not found`);
            }
            const jobs = await this.prisma.queueJob.findMany({
                where: { queueName, status: client_1.QueueJobStatus.ACTIVE },
            });
            drainedJobsCount = jobs.length;
            await q.drain();
            await this.prisma.queueJob.updateMany({
                where: { queueName, status: client_1.QueueJobStatus.ACTIVE },
                data: { status: client_1.QueueJobStatus.CANCELLED, updatedAt: new Date() },
            });
            await this.prisma.operationsAudit.update({
                where: { operationId },
                data: {
                    metadata: {
                        reason,
                        queue: queueName,
                        drainedJobs: drainedJobsCount,
                    },
                },
            });
        });
    }
    async unlockSegment(operatorId, segmentId) {
        return this.runOperation(operatorId, client_1.OperationsAction.SEGMENT_UNLOCK, 'Segment', segmentId, {}, async () => {
            const activeExec = await this.prisma.segmentExecution.findFirst({
                where: {
                    segmentId,
                    state: 'PROCESSING',
                },
            });
            if (activeExec) {
                throw new common_1.BadRequestException('Cannot unlock segment with an active processing execution');
            }
            if (this.redisService.isHealthy()) {
                const lockKey = `lock:segment:${segmentId}`;
                await this.redisService.getClient().del(lockKey);
            }
        });
    }
    async forceBrokerSessionRefresh(operatorId, userBrokerId) {
        return this.runOperation(operatorId, client_1.OperationsAction.BROKER_REFRESH, 'UserBroker', userBrokerId, {}, async () => {
            const userBroker = await this.prisma.userBroker.findUnique({
                where: { id: userBrokerId },
                include: { broker: true },
            });
            if (!userBroker) {
                throw new common_1.NotFoundException(`UserBroker ${userBrokerId} not found`);
            }
            if (this.redisService.isHealthy()) {
                const rateLimitKey = `ops:broker-refresh:${userBrokerId}`;
                const isRateLimited = await this.redisService.getClient().exists(rateLimitKey);
                if (isRateLimited === 1) {
                    throw new common_1.BadRequestException(`Rate limit exceeded: session refresh for broker connection ${userBrokerId} is restricted to once per 60 seconds.`);
                }
                await this.redisService.getClient().set(rateLimitKey, '1', 'EX', 60);
            }
            if (this.redisService.isHealthy()) {
                const sessionKey = `broker:session:${userBroker.userId}:${userBroker.brokerId}`;
                await this.redisService.getClient().del(sessionKey);
            }
            await this.brokerSessionService.refreshSession(userBroker.userId, userBroker.broker.code);
        });
    }
    async rebuildPositions(operatorId, userId) {
        return this.runOperation(operatorId, client_1.OperationsAction.POSITION_REBUILD, 'PositionCache', userId || 'ALL', { userId }, async (operationId) => {
            await this.queueService.addJob(queue_constants_1.Queues.POSITION_REBUILD, `rebuild:${userId || 'all'}:${operationId}`, { userId });
        });
    }
    async enableMaintenance(operatorId, type) {
        const validTypes = ['global', 'signals', 'subscriptions', 'reports'];
        if (!validTypes.includes(type)) {
            throw new common_1.BadRequestException(`Invalid maintenance type: ${type}`);
        }
        return this.runOperation(operatorId, client_1.OperationsAction.MAINTENANCE_ENABLE, 'System', type.toUpperCase(), { type }, async () => {
            if (this.redisService.isHealthy()) {
                const redisKey = `system:maintenance:${type}`;
                await this.redisService.getClient().set(redisKey, 'true');
            }
            else {
                throw new common_1.BadRequestException('Redis is not available');
            }
        });
    }
    async disableMaintenance(operatorId, type) {
        const validTypes = ['global', 'signals', 'subscriptions', 'reports'];
        if (!validTypes.includes(type)) {
            throw new common_1.BadRequestException(`Invalid maintenance type: ${type}`);
        }
        return this.runOperation(operatorId, client_1.OperationsAction.MAINTENANCE_DISABLE, 'System', type.toUpperCase(), { type }, async () => {
            if (this.redisService.isHealthy()) {
                const redisKey = `system:maintenance:${type}`;
                await this.redisService.getClient().del(redisKey);
            }
            else {
                throw new common_1.BadRequestException('Redis is not available');
            }
        });
    }
    async stopTrading(operatorId, permanent, reason) {
        const defaultReason = reason || 'Emergency emergency market event';
        const expiresAt = permanent ? 'never' : new Date(Date.now() + 900 * 1000).toISOString();
        const payload = JSON.stringify({
            enabled: true,
            reason: defaultReason,
            operatorId,
            expiresAt,
        });
        return this.runOperation(operatorId, client_1.OperationsAction.TRADING_STOP, 'TradingEngine', 'GLOBAL', { permanent, reason: defaultReason, expiresAt }, async () => {
            if (this.redisService.isHealthy()) {
                if (permanent) {
                    await this.redisService.getClient().set('trading:global:disabled', payload);
                }
                else {
                    await this.redisService.getClient().set('trading:global:disabled', payload, 'EX', 900);
                }
            }
            else {
                throw new common_1.BadRequestException('Redis is not available');
            }
        });
    }
    async startTrading(operatorId) {
        return this.runOperation(operatorId, client_1.OperationsAction.TRADING_START, 'TradingEngine', 'GLOBAL', {}, async () => {
            if (this.redisService.isHealthy()) {
                await this.redisService.getClient().del('trading:global:disabled');
            }
            else {
                throw new common_1.BadRequestException('Redis is not available');
            }
        });
    }
    async exportAuditLogs(operatorId) {
        const exportRecord = await this.prisma.reportExport.create({
            data: {
                userId: null,
                exportType: 'AUDIT',
                status: client_1.ExportState.REQUESTED,
            },
        });
        await this.queueService.addJob(queue_constants_1.Queues.REPORT_EXPORT, exportRecord.id, {
            exportId: exportRecord.id,
            userId: null,
            type: 'AUDIT',
            period: '',
        }, 5);
        return { exportId: exportRecord.id };
    }
    async getAudits(operatorId, query) {
        const page = query.page || 1;
        const limit = Math.min(query.limit || 50, 100);
        const where = {
            ...(query.action ? { action: query.action } : {}),
            ...(query.operatorId ? { operatorId: query.operatorId } : {}),
            ...(query.status ? { status: query.status } : {}),
            ...(query.from && !isNaN(Date.parse(query.from)) ? { createdAt: { gte: new Date(query.from) } } : {}),
        };
        return this.prisma.operationsAudit.paginate({
            page,
            limit,
            where,
            orderBy: { createdAt: 'desc' },
        });
    }
    async getReconciliationRuns() {
        return this.prisma.reconciliationRun.findMany({
            orderBy: { startedAt: 'desc' },
            include: { shards: true },
        });
    }
    async getReconciliationIssues(resolved) {
        return this.prisma.reconciliationIssue.findMany({
            where: resolved !== undefined
                ? { status: resolved ? client_1.ReconciliationIssueStatus.RESOLVED : { not: client_1.ReconciliationIssueStatus.RESOLVED } }
                : undefined,
            orderBy: { createdAt: 'desc' },
            include: { user: true, broker: true },
        });
    }
    async getReconciliationIssuesSummary() {
        const openCount = await this.prisma.reconciliationIssue.count({
            where: { status: client_1.ReconciliationIssueStatus.OPEN },
        });
        const criticalCount = await this.prisma.reconciliationIssue.count({
            where: { severity: client_1.Severity.CRITICAL, status: { not: client_1.ReconciliationIssueStatus.RESOLVED } },
        });
        const warningCount = await this.prisma.reconciliationIssue.count({
            where: { severity: client_1.Severity.WARNING, status: { not: client_1.ReconciliationIssueStatus.RESOLVED } },
        });
        const escalatedCount = await this.prisma.reconciliationIssue.count({
            where: { status: client_1.ReconciliationIssueStatus.ESCALATED },
        });
        const startOfToday = new Date();
        startOfToday.setHours(0, 0, 0, 0);
        const resolvedTodayCount = await this.prisma.reconciliationIssue.count({
            where: {
                status: client_1.ReconciliationIssueStatus.RESOLVED,
                createdAt: { gte: startOfToday },
            },
        });
        return {
            open: openCount,
            critical: criticalCount,
            warning: warningCount,
            escalated: escalatedCount,
            resolvedToday: resolvedTodayCount,
        };
    }
    async resolveReconciliationIssue(operatorId, issueId) {
        return this.runOperation(operatorId, client_1.OperationsAction.RECONCILIATION_RESOLVE, 'ReconciliationIssue', issueId, { manualResolution: true }, async () => {
            const issue = await this.prisma.reconciliationIssue.findUnique({
                where: { id: issueId },
            });
            if (!issue) {
                throw new common_1.NotFoundException(`Reconciliation issue ${issueId} not found`);
            }
            const updatedIssue = await this.prisma.reconciliationIssue.update({
                where: { id: issueId },
                data: { status: client_1.ReconciliationIssueStatus.RESOLVED },
            });
            const openIssues = await this.prisma.reconciliationIssue.count({
                where: {
                    userId: issue.userId,
                    brokerId: issue.brokerId,
                    status: { in: [client_1.ReconciliationIssueStatus.OPEN, client_1.ReconciliationIssueStatus.INVESTIGATING, client_1.ReconciliationIssueStatus.ESCALATED] },
                },
            });
            await this.prisma.reconciliationSnapshot.upsert({
                where: { userId_brokerId: { userId: issue.userId, brokerId: issue.brokerId } },
                update: { openIssues },
                create: { userId: issue.userId, brokerId: issue.brokerId, openIssues, lastReconciledAt: new Date() },
            });
            if (this.redisService.isHealthy()) {
                const keys = [
                    `analytics:user:${issue.userId}:portfolio`,
                    `analytics:user:${issue.userId}:segments`,
                    `analytics:user:${issue.userId}:broker-stats`,
                ];
                for (const key of keys) {
                    await this.redisService.getClient().del(key);
                }
            }
            return updatedIssue;
        });
    }
    async escalateReconciliationIssue(operatorId, issueId) {
        return this.runOperation(operatorId, client_1.OperationsAction.RECONCILIATION_RESOLVE, 'ReconciliationIssue', issueId, { manualEscalation: true }, async () => {
            const issue = await this.prisma.reconciliationIssue.findUnique({
                where: { id: issueId },
            });
            if (!issue) {
                throw new common_1.NotFoundException(`Reconciliation issue ${issueId} not found`);
            }
            const updatedIssue = await this.prisma.reconciliationIssue.update({
                where: { id: issueId },
                data: { status: client_1.ReconciliationIssueStatus.ESCALATED },
            });
            await this.prisma.outboxEvent.create({
                data: {
                    eventType: 'RECONCILIATION_ISSUE',
                    payload: {
                        issueId,
                        userId: issue.userId,
                        brokerId: issue.brokerId,
                        issueType: issue.issueType,
                        severity: issue.severity,
                        resourceId: issue.resourceId,
                        status: client_1.ReconciliationIssueStatus.ESCALATED,
                    },
                },
            });
            return updatedIssue;
        });
    }
    async triggerReconciliationRun(operatorId) {
        return this.runOperation(operatorId, client_1.OperationsAction.RECONCILIATION_RUN, 'System', 'global', {}, async () => {
            const runId = await this.reconciliationService.triggerReconciliation(operatorId);
            return { runId };
        });
    }
    async recalculateRiskSnapshot(operatorId, userId) {
        return this.runOperation(operatorId, client_1.OperationsAction.RISK_RECALCULATE, 'RiskSnapshot', userId, { userId }, async (operationId) => {
            const jobId = `risk-recalc-${userId}-manual-${operationId}`;
            await this.queueService.addJob(queue_constants_1.Queues.RISK_RECALCULATE, jobId, { userId });
        });
    }
    async unblockUserRisk(operatorId, userId) {
        return this.runOperation(operatorId, client_1.OperationsAction.RISK_UNBLOCK, 'UserRiskLock', userId, { userId }, async () => {
            if (this.redisService.isHealthy()) {
                await this.redisService.getClient().del(`user:risk:blocked:${userId}`);
            }
            await this.prisma.riskSnapshot.updateMany({
                where: { userId },
                data: {
                    state: 'HEALTHY',
                    lastRecalculationStatus: 'MANUALLY_UNBLOCKED',
                    lastRecalculatedAt: new Date(),
                },
            });
            await this.prisma.riskEvent.create({
                data: {
                    userId,
                    segmentId: '',
                    eventType: 'RISK_UNBLOCKED_MANUAL',
                    message: `User risk manually unblocked by operator ${operatorId}`,
                },
            });
        });
    }
    async toggleGlobalEmergencyLock(operatorId, blocked, reason) {
        return this.runOperation(operatorId, client_1.OperationsAction.RISK_GLOBAL_LOCK, 'GlobalRiskLock', 'GLOBAL', { blocked, reason }, async () => {
            if (!this.redisService.isHealthy()) {
                throw new common_1.BadRequestException('Redis is not available');
            }
            if (blocked) {
                await this.redisService.getClient().set('risk:global:blocked', 'true');
                this.logger.warn(`Global emergency risk lock activated by operator ${operatorId}. Reason: ${reason}`);
            }
            else {
                await this.redisService.getClient().del('risk:global:blocked');
                this.logger.warn(`Global emergency risk lock deactivated by operator ${operatorId}`);
            }
        });
    }
    async acknowledgeAlert(operatorId, alertId) {
        return this.alertingService.acknowledgeAlert(alertId);
    }
    async resolveAlert(operatorId, alertId) {
        return this.alertingService.resolveAlert(alertId);
    }
    async getUserLiveBrokerData(userIdOrCode) {
        const userBroker = await this.prisma.userBroker.findFirst({
            where: {
                OR: [
                    { userId: userIdOrCode },
                    { brokerClientId: userIdOrCode },
                    { user: { email: userIdOrCode } },
                ],
            },
            include: { broker: true, user: true },
        });
        if (!userBroker) {
            throw new common_1.NotFoundException(`No linked broker connection found for '${userIdOrCode}'`);
        }
        const isSessionActive = await this.brokerSessionService.validateSession(userBroker.userId, userBroker.broker.code);
        if (!isSessionActive || !userBroker.accessToken) {
            return {
                user: {
                    id: userBroker.user.id,
                    name: userBroker.user.name,
                    email: userBroker.user.email,
                },
                brokerCode: userBroker.broker.code,
                brokerClientId: userBroker.brokerClientId,
                isSessionActive: false,
                positions: [],
                holdings: [],
                orders: [],
                trades: [],
            };
        }
        const brokerType = userBroker.broker.code;
        const adapter = this.brokerFactory.getAdapter(brokerType);
        const [positions, holdings, orders, trades] = await Promise.all([
            adapter.getPositions(userBroker.accessToken, userBroker.brokerClientId).catch(() => []),
            adapter.getHoldings(userBroker.accessToken, userBroker.brokerClientId).catch(() => []),
            adapter.getOrders(userBroker.accessToken, userBroker.brokerClientId).catch(() => []),
            adapter.getTradeBook(userBroker.accessToken, userBroker.brokerClientId).catch(() => []),
        ]);
        return {
            user: {
                id: userBroker.user.id,
                name: userBroker.user.name,
                email: userBroker.user.email,
            },
            brokerCode: userBroker.broker.code,
            brokerClientId: userBroker.brokerClientId,
            isSessionActive: true,
            positions,
            holdings,
            orders,
            trades,
        };
    }
};
exports.OpsService = OpsService;
__decorate([
    (0, schedule_1.Cron)('0 0 3 * * *', { name: 'ops-audit-cleanup', timeZone: 'Asia/Kolkata' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], OpsService.prototype, "cleanupOperationsAudit", null);
exports.OpsService = OpsService = OpsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        redis_service_1.RedisService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService,
        broker_session_service_1.BrokerSessionService,
        reconciliation_service_1.ReconciliationService,
        alerting_service_1.AlertingService,
        broker_factory_1.BrokerFactory])
], OpsService);
//# sourceMappingURL=ops.service.js.map