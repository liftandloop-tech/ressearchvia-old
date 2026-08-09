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
var ReportGenerationProcessor_1, ReportExportProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReportExportProcessor = exports.ReportGenerationProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma.service");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
const outbox_service_1 = require("../../infrastructure/outbox/outbox.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const reports_service_1 = require("../reports.service");
const report_storage_provider_1 = require("../providers/report-storage.provider");
const client_1 = require("@prisma/client");
let ReportGenerationProcessor = ReportGenerationProcessor_1 = class ReportGenerationProcessor extends bullmq_1.WorkerHost {
    prisma;
    redisService;
    metrics;
    outboxService;
    reportsService;
    storageProvider;
    logger = new common_1.Logger(ReportGenerationProcessor_1.name);
    constructor(prisma, redisService, metrics, outboxService, reportsService, storageProvider) {
        super();
        this.prisma = prisma;
        this.redisService = redisService;
        this.metrics = metrics;
        this.outboxService = outboxService;
        this.reportsService = reportsService;
        this.storageProvider = storageProvider;
    }
    async process(job) {
        const startTime = Date.now();
        const { reportId, userId, type, period, segmentId } = job.data;
        const lockKey = `report:lock:${reportId}`;
        const idempotencyKey = `report:idempotency:${userId}:${type}:${period}${segmentId ? `:${segmentId}` : ''}`;
        this.logger.log(`Processing report generation job ${job.id} for report ${reportId}`);
        try {
            const lockAcquired = await this.redisService.getClient().set(lockKey, '1', 'EX', 60, 'NX');
            if (lockAcquired !== 'OK') {
                this.logger.warn(`Stampede lock active for report ${reportId}. Worker exiting.`);
                return;
            }
        }
        catch (err) {
            this.logger.error(`Failed to acquire stampede lock for report ${reportId}: ${err.message}`);
            throw err;
        }
        try {
            await this.prisma.report.update({
                where: { id: reportId },
                data: { status: client_1.ReportState.PROCESSING },
            });
            const { startDate, endDate } = this.reportsService.parsePeriod(type, period);
            const userSegments = segmentId
                ? [{ segmentId }]
                : await this.prisma.userSegment.findMany({
                    where: { userId },
                    select: { segmentId: true },
                });
            const currentDate = new Date(startDate.getTime());
            while (currentDate <= endDate) {
                for (const seg of userSegments) {
                    const snapshotExists = await this.prisma.analyticsSnapshot.findFirst({
                        where: {
                            userId,
                            segmentId: seg.segmentId,
                            date: {
                                gte: new Date(Date.UTC(currentDate.getUTCFullYear(), currentDate.getUTCMonth(), currentDate.getUTCDate(), 0, 0, 0, 0)),
                                lte: new Date(Date.UTC(currentDate.getUTCFullYear(), currentDate.getUTCMonth(), currentDate.getUTCDate(), 23, 59, 59, 999)),
                            },
                        },
                    });
                    if (!snapshotExists) {
                        await this.reportsService.calculateAndUpsertSnapshot(userId, seg.segmentId, currentDate);
                    }
                }
                currentDate.setUTCDate(currentDate.getUTCDate() + 1);
            }
            const snapshots = await this.prisma.analyticsSnapshot.findMany({
                where: {
                    userId,
                    ...(segmentId ? { segmentId } : {}),
                    date: {
                        gte: startDate,
                        lte: endDate,
                    },
                },
            });
            let realizedPnl = 0;
            let unrealizedPnl = 0;
            let totalTrades = 0;
            let winningTrades = 0;
            let losingTrades = 0;
            let sumRoi = 0;
            for (const snap of snapshots) {
                realizedPnl += Number(snap.realizedPnl);
                unrealizedPnl += Number(snap.unrealizedPnl);
                totalTrades += snap.totalTrades;
                winningTrades += snap.winningTrades;
                losingTrades += snap.losingTrades;
                sumRoi += Number(snap.roi);
            }
            const winRate = totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0;
            const roi = snapshots.length > 0 ? sumRoi / snapshots.length : 0;
            const reportData = {
                userId,
                reportId,
                reportType: type,
                period,
                segmentId,
                realizedPnl,
                unrealizedPnl,
                totalTrades,
                winningTrades,
                losingTrades,
                winRate,
                roi,
                drawdown: 0,
                generatedAt: new Date().toISOString(),
            };
            const fileName = `report-${reportId}.json`;
            const fileUrl = await this.storageProvider.upload(fileName, Buffer.from(JSON.stringify(reportData, null, 2)), 'application/json');
            const updatedReport = await this.prisma.report.update({
                where: { id: reportId },
                data: {
                    status: client_1.ReportState.COMPLETED,
                    fileUrl,
                    generatedAt: new Date(),
                },
            });
            await this.reportsService.cacheReport(userId, type, period, segmentId, reportData);
            await this.outboxService.createEvent('REPORT_READY', {
                version: 1,
                reportId: updatedReport.id,
                userId: updatedReport.userId,
                reportType: updatedReport.reportType,
                downloadUrl: updatedReport.fileUrl,
                generatedAt: updatedReport.generatedAt.toISOString(),
            }, undefined, {
                eventKey: `REPORT_READY:${updatedReport.id}`,
                aggregateId: updatedReport.id,
            });
            this.metrics.incrementReportsGenerated();
            this.metrics.observeReportGenerationDuration(Date.now() - startTime);
            this.logger.log(`Successfully completed report generation for report ${reportId}`);
        }
        catch (err) {
            this.logger.error(`Failed to generate report ${reportId}: ${err.message}`, err.stack);
            this.metrics.incrementReportGenerationFailed();
            await this.prisma.report.update({
                where: { id: reportId },
                data: {
                    status: client_1.ReportState.FAILED,
                    error: err.message,
                },
            }).catch(dbErr => this.logger.error(`Failed to save report error state to DB: ${dbErr.message}`));
            throw err;
        }
        finally {
            await this.redisService.getClient().del(lockKey).catch(() => { });
            await this.redisService.getClient().del(idempotencyKey).catch(() => { });
        }
    }
};
exports.ReportGenerationProcessor = ReportGenerationProcessor;
exports.ReportGenerationProcessor = ReportGenerationProcessor = ReportGenerationProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.REPORT_GENERATION),
    __param(5, (0, common_1.Inject)(report_storage_provider_1.REPORT_STORAGE_PROVIDER)),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        redis_service_1.RedisService,
        metrics_service_1.MetricsService,
        outbox_service_1.OutboxService,
        reports_service_1.ReportsService, Object])
], ReportGenerationProcessor);
let ReportExportProcessor = ReportExportProcessor_1 = class ReportExportProcessor extends bullmq_1.WorkerHost {
    prisma;
    reportsService;
    outboxService;
    storageProvider;
    logger = new common_1.Logger(ReportExportProcessor_1.name);
    constructor(prisma, reportsService, outboxService, storageProvider) {
        super();
        this.prisma = prisma;
        this.reportsService = reportsService;
        this.outboxService = outboxService;
        this.storageProvider = storageProvider;
    }
    async process(job) {
        const { exportId, userId, type, period, segmentId } = job.data;
        this.logger.log(`Processing report export job ${job.id} for export ${exportId}`);
        try {
            await this.prisma.reportExport.update({
                where: { id: exportId },
                data: { status: client_1.ExportState.PROCESSING },
            });
            if (type === 'AUDIT') {
                const audits = await this.prisma.operationsAudit.findMany({
                    orderBy: { createdAt: 'desc' },
                });
                let csvContent = 'operationId,createdAt,operatorId,action,status,resourceType,resourceId,errorMessage,metadata\n';
                for (const audit of audits) {
                    const opId = audit.operationId;
                    const created = audit.createdAt.toISOString();
                    const operator = audit.operatorId;
                    const act = audit.action;
                    const stat = audit.status;
                    const resType = audit.resourceType;
                    const resId = audit.resourceId;
                    const errMsg = audit.errorMessage ? audit.errorMessage.replace(/"/g, '""') : '';
                    const metaStr = audit.metadata ? JSON.stringify(audit.metadata).replace(/"/g, '""') : '';
                    csvContent += `"${opId}","${created}","${operator}","${act}","${stat}","${resType}","${resId}","${errMsg}","${metaStr}"\n`;
                }
                const fileName = `export-${exportId}.csv`;
                const fileUrl = await this.storageProvider.upload(fileName, Buffer.from(csvContent), 'text/csv');
                await this.prisma.reportExport.update({
                    where: { id: exportId },
                    data: {
                        status: client_1.ExportState.COMPLETED,
                        fileUrl,
                    },
                });
                await this.outboxService.createEvent('REPORT_READY', {
                    version: 1,
                    reportId: exportId,
                    userId: null,
                    reportType: 'AUDIT',
                    downloadUrl: fileUrl,
                    generatedAt: new Date().toISOString(),
                }, undefined, {
                    eventKey: `REPORT_READY:${exportId}`,
                    aggregateId: exportId,
                });
                this.logger.log(`Successfully completed SRE audit logs export ${exportId}`);
                return;
            }
            const { startDate, endDate } = this.reportsService.parsePeriod(type, period);
            const snapshots = await this.prisma.analyticsSnapshot.findMany({
                where: {
                    userId: userId,
                    ...(segmentId ? { segmentId } : {}),
                    date: {
                        gte: startDate,
                        lte: endDate,
                    },
                },
                orderBy: { date: 'asc' },
            });
            let csvContent = 'Date,Realized PnL,Unrealized PnL,Win Rate,Total Trades,Winning Trades,Losing Trades,ROI%\n';
            for (const snap of snapshots) {
                const dateStr = snap.date.toISOString().split('T')[0];
                csvContent += `${dateStr},${snap.realizedPnl},${snap.unrealizedPnl},${snap.winRate},${snap.totalTrades},${snap.winningTrades},${snap.losingTrades},${snap.roi}\n`;
            }
            const fileName = `export-${exportId}.csv`;
            const fileUrl = await this.storageProvider.upload(fileName, Buffer.from(csvContent), 'text/csv');
            await this.prisma.reportExport.update({
                where: { id: exportId },
                data: {
                    status: client_1.ExportState.COMPLETED,
                    fileUrl,
                },
            });
            this.logger.log(`Successfully completed export ${exportId}`);
        }
        catch (err) {
            this.logger.error(`Failed to export CSV ${exportId}: ${err.message}`);
            await this.prisma.reportExport.update({
                where: { id: exportId },
                data: {
                    status: client_1.ExportState.FAILED,
                    error: err.message,
                },
            }).catch(() => { });
            throw err;
        }
    }
};
exports.ReportExportProcessor = ReportExportProcessor;
exports.ReportExportProcessor = ReportExportProcessor = ReportExportProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.REPORT_EXPORT),
    __param(3, (0, common_1.Inject)(report_storage_provider_1.REPORT_STORAGE_PROVIDER)),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        reports_service_1.ReportsService,
        outbox_service_1.OutboxService, Object])
], ReportExportProcessor);
//# sourceMappingURL=report-generation.processor.js.map