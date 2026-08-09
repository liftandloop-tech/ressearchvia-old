import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Inject, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { ReportsService } from '../reports.service';
import { REPORT_STORAGE_PROVIDER, ReportStorageProvider } from '../providers/report-storage.provider';
import { ReportState, ExportState } from '@prisma/client';

@Processor(Queues.REPORT_GENERATION)
export class ReportGenerationProcessor extends WorkerHost {
  private readonly logger = new Logger(ReportGenerationProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    private readonly metrics: MetricsService,
    private readonly outboxService: OutboxService,
    private readonly reportsService: ReportsService,
    @Inject(REPORT_STORAGE_PROVIDER) private readonly storageProvider: any,
  ) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    const startTime = Date.now();
    const { reportId, userId, type, period, segmentId } = job.data;
    const lockKey = `report:lock:${reportId}`;
    const idempotencyKey = `report:idempotency:${userId}:${type}:${period}${segmentId ? `:${segmentId}` : ''}`;

    this.logger.log(`Processing report generation job ${job.id} for report ${reportId}`);

    // Rule 5: Cache Stampede Protection (SETNX report:lock:{reportId} TTL 60s)
    try {
      const lockAcquired = await this.redisService.getClient().set(
        lockKey,
        '1',
        'EX',
        60,
        'NX',
      );

      if (lockAcquired !== 'OK') {
        this.logger.warn(`Stampede lock active for report ${reportId}. Worker exiting.`);
        return;
      }
    } catch (err) {
      this.logger.error(`Failed to acquire stampede lock for report ${reportId}: ${err.message}`);
      throw err;
    }

    try {
      // Update report status in DB to PROCESSING
      await this.prisma.report.update({
        where: { id: reportId },
        data: { status: ReportState.PROCESSING },
      });

      // Parse date bounds
      const { startDate, endDate } = this.reportsService.parsePeriod(type, period);

      // Fetch user's segments
      const userSegments = segmentId
        ? [{ segmentId }]
        : await this.prisma.userSegment.findMany({
            where: { userId },
            select: { segmentId: true },
          });

      // Ensure snapshots exist for all dates in the range for active segments
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
            // Missing -> aggregate and create snapshot
            await this.reportsService.calculateAndUpsertSnapshot(userId, seg.segmentId, currentDate);
          }
        }
        // Advance current date by 1 day
        currentDate.setUTCDate(currentDate.getUTCDate() + 1);
      }

      // Fetch all snapshots in range for aggregation
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

      // Aggregate snapshot metrics
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

      // Upload to Storage Provider
      const fileName = `report-${reportId}.json`;
      const fileUrl = await this.storageProvider.upload(
        fileName,
        Buffer.from(JSON.stringify(reportData, null, 2)),
        'application/json',
      );

      // Update Report in DB
      const updatedReport = await this.prisma.report.update({
        where: { id: reportId },
        data: {
          status: ReportState.COMPLETED,
          fileUrl,
          generatedAt: new Date(),
        },
      });

      // Cache the report
      await this.reportsService.cacheReport(userId, type, period, segmentId, reportData);

      // Rule 3: REPORT_READY Must Include Download Metadata
      await this.outboxService.createEvent(
        'REPORT_READY',
        {
          version: 1,
          reportId: updatedReport.id,
          userId: updatedReport.userId,
          reportType: updatedReport.reportType,
          downloadUrl: updatedReport.fileUrl,
          generatedAt: updatedReport.generatedAt.toISOString(),
        },
        undefined,
        {
          eventKey: `REPORT_READY:${updatedReport.id}`,
          aggregateId: updatedReport.id,
        },
      );

      this.metrics.incrementReportsGenerated();
      this.metrics.observeReportGenerationDuration(Date.now() - startTime);
      this.logger.log(`Successfully completed report generation for report ${reportId}`);
    } catch (err) {
      this.logger.error(`Failed to generate report ${reportId}: ${err.message}`, err.stack);
      this.metrics.incrementReportGenerationFailed();

      await this.prisma.report.update({
        where: { id: reportId },
        data: {
          status: ReportState.FAILED,
          error: err.message,
        },
      }).catch(dbErr => this.logger.error(`Failed to save report error state to DB: ${dbErr.message}`));

      throw err;
    } finally {
      // Cleanup locks
      await this.redisService.getClient().del(lockKey).catch(() => {});
      await this.redisService.getClient().del(idempotencyKey).catch(() => {});
    }
  }
}

@Processor(Queues.REPORT_EXPORT)
export class ReportExportProcessor extends WorkerHost {
  private readonly logger = new Logger(ReportExportProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsService: ReportsService,
    private readonly outboxService: OutboxService,
    @Inject(REPORT_STORAGE_PROVIDER) private readonly storageProvider: any,
  ) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    const { exportId, userId, type, period, segmentId } = job.data;
    this.logger.log(`Processing report export job ${job.id} for export ${exportId}`);

    try {
      await this.prisma.reportExport.update({
        where: { id: exportId },
        data: { status: ExportState.PROCESSING },
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
        const fileUrl = await this.storageProvider.upload(
          fileName,
          Buffer.from(csvContent),
          'text/csv',
        );

        await this.prisma.reportExport.update({
          where: { id: exportId },
          data: {
            status: ExportState.COMPLETED,
            fileUrl,
          },
        });

        await this.outboxService.createEvent(
          'REPORT_READY',
          {
            version: 1,
            reportId: exportId,
            userId: null,
            reportType: 'AUDIT',
            downloadUrl: fileUrl,
            generatedAt: new Date().toISOString(),
          },
          undefined,
          {
            eventKey: `REPORT_READY:${exportId}`,
            aggregateId: exportId,
          },
        );

        this.logger.log(`Successfully completed SRE audit logs export ${exportId}`);
        return;
      }

      const { startDate, endDate } = this.reportsService.parsePeriod(type, period);

      // Fetch all snapshots in range
      const snapshots = await this.prisma.analyticsSnapshot.findMany({
        where: {
          userId: userId!,
          ...(segmentId ? { segmentId } : {}),
          date: {
            gte: startDate,
            lte: endDate,
          },
        },
        orderBy: { date: 'asc' },
      });

      // Construct CSV
      let csvContent = 'Date,Realized PnL,Unrealized PnL,Win Rate,Total Trades,Winning Trades,Losing Trades,ROI%\n';
      for (const snap of snapshots) {
        const dateStr = snap.date.toISOString().split('T')[0];
        csvContent += `${dateStr},${snap.realizedPnl},${snap.unrealizedPnl},${snap.winRate},${snap.totalTrades},${snap.winningTrades},${snap.losingTrades},${snap.roi}\n`;
      }

      const fileName = `export-${exportId}.csv`;
      const fileUrl = await this.storageProvider.upload(
        fileName,
        Buffer.from(csvContent),
        'text/csv',
      );

      await this.prisma.reportExport.update({
        where: { id: exportId },
        data: {
          status: ExportState.COMPLETED,
          fileUrl,
        },
      });

      this.logger.log(`Successfully completed export ${exportId}`);
    } catch (err) {
      this.logger.error(`Failed to export CSV ${exportId}: ${err.message}`);
      await this.prisma.reportExport.update({
        where: { id: exportId },
        data: {
          status: ExportState.FAILED,
          error: err.message,
        },
      }).catch(() => {});
      throw err;
    }
  }
}

