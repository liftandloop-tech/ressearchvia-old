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
var ReportsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReportsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const redis_service_1 = require("../infrastructure/redis/redis.service");
const queues_service_1 = require("../infrastructure/queues/queues.service");
const metrics_service_1 = require("../infrastructure/metrics/metrics.service");
const outbox_service_1 = require("../infrastructure/outbox/outbox.service");
const queue_constants_1 = require("../infrastructure/queues/queue.constants");
const report_storage_provider_1 = require("./providers/report-storage.provider");
const client_1 = require("@prisma/client");
let ReportsService = ReportsService_1 = class ReportsService {
    prisma;
    redisService;
    queueService;
    metrics;
    outboxService;
    storageProvider;
    logger = new common_1.Logger(ReportsService_1.name);
    constructor(prisma, redisService, queueService, metrics, outboxService, storageProvider) {
        this.prisma = prisma;
        this.redisService = redisService;
        this.queueService = queueService;
        this.metrics = metrics;
        this.outboxService = outboxService;
        this.storageProvider = storageProvider;
    }
    parsePeriod(type, period) {
        if (type === 'DAILY' || (period && period.length === 10)) {
            const date = new Date(period);
            if (isNaN(date.getTime())) {
                throw new Error(`Invalid date format for daily period: ${period}`);
            }
            const startDate = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0, 0));
            const endDate = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 23, 59, 59, 999));
            return { startDate, endDate };
        }
        else {
            const parts = period.split('-');
            const year = parseInt(parts[0], 10);
            const month = parseInt(parts[1], 10) - 1;
            if (isNaN(year) || isNaN(month) || month < 0 || month > 11) {
                throw new Error(`Invalid monthly period format: ${period}`);
            }
            const startDate = new Date(Date.UTC(year, month, 1, 0, 0, 0, 0));
            const endDate = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59, 999));
            return { startDate, endDate };
        }
    }
    async getReportFromCache(userId, type, period, segmentId) {
        const cacheKey = segmentId
            ? `report:v1:segment:${userId}:${segmentId}:${period}`
            : type === 'DAILY'
                ? `report:v1:daily:${userId}:${period}`
                : `report:v1:monthly:${userId}:${period}`;
        try {
            const cached = await this.redisService.getClient().get(cacheKey);
            if (cached) {
                this.metrics.incrementReportCacheHits();
                return JSON.parse(cached);
            }
        }
        catch (err) {
            this.logger.warn(`Failed to read from cache key ${cacheKey}: ${err.message}`);
        }
        this.metrics.incrementReportCacheMisses();
        return null;
    }
    async cacheReport(userId, type, period, segmentId, data) {
        const cacheKey = segmentId
            ? `report:v1:segment:${userId}:${segmentId}:${period}`
            : type === 'DAILY'
                ? `report:v1:daily:${userId}:${period}`
                : `report:v1:monthly:${userId}:${period}`;
        try {
            await this.redisService.getClient().set(cacheKey, JSON.stringify(data), 'EX', 300);
        }
        catch (err) {
            this.logger.warn(`Failed to cache key ${cacheKey}: ${err.message}`);
        }
    }
    async getReportOrEnqueue(userId, type, period, segmentId) {
        if (this.redisService.isHealthy()) {
            const isGlobalMaint = await this.redisService.getClient().get('system:maintenance:global');
            const isReportsMaint = await this.redisService.getClient().get('system:maintenance:reports');
            if (isGlobalMaint === 'true' || isReportsMaint === 'true') {
                throw new common_1.ServiceUnavailableException('Report generation is currently disabled due to system maintenance');
            }
        }
        const cachedData = await this.getReportFromCache(userId, type, period, segmentId);
        if (cachedData) {
            return { status: 'COMPLETED', data: cachedData };
        }
        try {
            const q = this.queueService.getQueue(queue_constants_1.Queues.REPORT_GENERATION);
            const queueDepth = await q.getWaitingCount();
            if (queueDepth > 10000) {
                this.logger.warn(`Report queue depth exceeded limit (waiting=${queueDepth}). Rejecting request.`);
                return { status: 'QUEUED', estimatedWait: 'later' };
            }
        }
        catch (err) {
            this.logger.error(`Failed to verify report queue depth: ${err.message}`);
        }
        const idempotencyKey = `report:idempotency:${userId}:${type}:${period}${segmentId ? `:${segmentId}` : ''}`;
        try {
            const acquired = await this.redisService.getClient().set(idempotencyKey, 'PROCESSING', 'EX', 600, 'NX');
            if (acquired !== 'OK') {
                const existing = await this.prisma.report.findFirst({
                    where: {
                        userId,
                        reportType: type,
                        status: { in: [client_1.ReportState.REQUESTED, client_1.ReportState.PROCESSING] },
                    },
                    orderBy: { generatedAt: 'desc' },
                });
                if (existing) {
                    return { status: existing.status, reportId: existing.id };
                }
                return { status: 'PROCESSING' };
            }
        }
        catch (err) {
            this.logger.error(`Idempotency check failed: ${err.message}`);
        }
        const report = await this.prisma.report.create({
            data: {
                userId,
                reportType: type,
                status: client_1.ReportState.REQUESTED,
            },
        });
        await this.queueService.addJob(queue_constants_1.Queues.REPORT_GENERATION, report.id, {
            reportId: report.id,
            userId,
            type,
            period,
            segmentId,
        }, 5);
        return { status: 'REQUESTED', reportId: report.id };
    }
    async requestCsvExport(userId, type, period, segmentId) {
        const exportRecord = await this.prisma.reportExport.create({
            data: {
                userId,
                exportType: type,
                status: client_1.ExportState.REQUESTED,
            },
        });
        await this.queueService.addJob(queue_constants_1.Queues.REPORT_EXPORT, exportRecord.id, {
            exportId: exportRecord.id,
            userId,
            type,
            period,
            segmentId,
        }, 5);
        return { status: 'REQUESTED', exportId: exportRecord.id };
    }
    async rebuildSnapshots(payload) {
        const jobId = `rebuild-${Date.now()}`;
        if (payload.userId) {
            const shardQueue = (0, queue_constants_1.getSnapshotQueueName)(payload.userId);
            await this.queueService.addJob(shardQueue, jobId, {
                startDate: payload.startDate.toISOString(),
                endDate: payload.endDate.toISOString(),
                userId: payload.userId,
                segmentId: payload.segmentId,
            }, 5);
        }
        else {
            for (let i = 0; i < 10; i++) {
                await this.queueService.addJob(`analytics-snapshot-${i}`, `${jobId}-${i}`, {
                    startDate: payload.startDate.toISOString(),
                    endDate: payload.endDate.toISOString(),
                }, 5);
            }
        }
    }
    async calculateAndUpsertSnapshot(userId, segmentId, date) {
        const startOfDay = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0, 0));
        const endOfDay = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 23, 59, 59, 999));
        const dateStr = startOfDay.toISOString().split('T')[0];
        const lockKey = `analytics:snapshot:lock:${userId}:${segmentId}:${dateStr}`;
        const acquired = await this.redisService.getClient().set(lockKey, '1', 'EX', 60, 'NX');
        if (acquired !== 'OK') {
            this.logger.warn(`Snapshot lock active for user ${userId} segment ${segmentId} on ${dateStr}. Skipping generation.`);
            const existing = await this.prisma.analyticsSnapshot.findFirst({
                where: {
                    userId,
                    segmentId,
                    date: startOfDay,
                },
            });
            if (existing) {
                return existing;
            }
            throw new Error(`Snapshot calculation currently locked for ${userId}:${segmentId} on ${dateStr}`);
        }
        try {
            const trades = await this.prisma.trade.findMany({
                where: {
                    userId,
                    segmentId,
                    createdAt: {
                        gte: startOfDay,
                        lte: endOfDay,
                    },
                    status: {
                        in: ['OPEN', 'CLOSED', 'TARGET_HIT', 'STOPLOSS_HIT'],
                    },
                },
                include: {
                    position: true,
                },
            });
            let realizedPnl = 0;
            let unrealizedPnl = 0;
            const totalTrades = trades.length;
            let winningTrades = 0;
            let losingTrades = 0;
            for (const trade of trades) {
                if (trade.pnl) {
                    const pnlNum = Number(trade.pnl);
                    realizedPnl += pnlNum;
                    if (pnlNum > 0) {
                        winningTrades++;
                    }
                    else if (pnlNum < 0) {
                        losingTrades++;
                    }
                }
                if (trade.position) {
                    unrealizedPnl += Number(trade.position.unrealizedPnl || 0);
                    realizedPnl += Number(trade.position.realizedPnl || 0);
                }
            }
            const winRate = totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0;
            const userSegment = await this.prisma.userSegment.findUnique({
                where: {
                    userId_segmentId: { userId, segmentId },
                },
            });
            const capital = userSegment ? Number(userSegment.capital) : 100000;
            const roi = capital > 0 ? (realizedPnl / capital) * 100 : 0;
            const drawdown = 0;
            const snapshot = await this.prisma.analyticsSnapshot.upsert({
                where: {
                    userId_segmentId_date: {
                        userId,
                        segmentId,
                        date: startOfDay,
                    },
                },
                update: {
                    realizedPnl,
                    unrealizedPnl,
                    winRate,
                    totalTrades,
                    winningTrades,
                    losingTrades,
                    roi,
                    drawdown,
                    snapshotVersion: 1,
                },
                create: {
                    userId,
                    segmentId,
                    date: startOfDay,
                    realizedPnl,
                    unrealizedPnl,
                    winRate,
                    totalTrades,
                    winningTrades,
                    losingTrades,
                    roi,
                    drawdown,
                    snapshotVersion: 1,
                },
            });
            this.metrics.incrementAnalyticsSnapshotsCreated();
            return snapshot;
        }
        finally {
            await this.redisService.getClient().del(lockKey).catch(() => { });
        }
    }
};
exports.ReportsService = ReportsService;
exports.ReportsService = ReportsService = ReportsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(5, (0, common_1.Inject)(report_storage_provider_1.REPORT_STORAGE_PROVIDER)),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        redis_service_1.RedisService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService,
        outbox_service_1.OutboxService, Object])
], ReportsService);
//# sourceMappingURL=reports.service.js.map