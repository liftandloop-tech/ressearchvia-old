import { Injectable, Inject, Logger, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { OutboxService } from '../infrastructure/outbox/outbox.service';
import { Queues, getSnapshotQueueName } from '../infrastructure/queues/queue.constants';
import { REPORT_STORAGE_PROVIDER, ReportStorageProvider } from './providers/report-storage.provider';
import { Report, ReportExport, AnalyticsSnapshot, ReportState, ExportState } from '@prisma/client';

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
    private readonly outboxService: OutboxService,
    @Inject(REPORT_STORAGE_PROVIDER) private readonly storageProvider: any,
  ) {}

  /**
   * Parse a period string (e.g. YYYY-MM-DD or YYYY-MM) to UTC date bounds.
   */
  parsePeriod(type: string, period: string): { startDate: Date; endDate: Date } {
    if (type === 'DAILY' || (period && period.length === 10)) {
      const date = new Date(period);
      if (isNaN(date.getTime())) {
        throw new Error(`Invalid date format for daily period: ${period}`);
      }
      const startDate = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0, 0));
      const endDate = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 23, 59, 59, 999));
      return { startDate, endDate };
    } else {
      // MONTHLY format YYYY-MM
      const parts = period.split('-');
      const year = parseInt(parts[0], 10);
      const month = parseInt(parts[1], 10) - 1; // 0-indexed
      if (isNaN(year) || isNaN(month) || month < 0 || month > 11) {
        throw new Error(`Invalid monthly period format: ${period}`);
      }
      const startDate = new Date(Date.UTC(year, month, 1, 0, 0, 0, 0));
      const endDate = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59, 999));
      return { startDate, endDate };
    }
  }

  /**
   * Retrieves a report from Redis cache if exists.
   */
  async getReportFromCache(userId: string, type: string, period: string, segmentId?: string): Promise<any | null> {
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
    } catch (err) {
      this.logger.warn(`Failed to read from cache key ${cacheKey}: ${err.message}`);
    }
    this.metrics.incrementReportCacheMisses();
    return null;
  }

  /**
   * Caches a completed report.
   */
  async cacheReport(userId: string, type: string, period: string, segmentId: string | undefined, data: any): Promise<void> {
    const cacheKey = segmentId
      ? `report:v1:segment:${userId}:${segmentId}:${period}`
      : type === 'DAILY'
      ? `report:v1:daily:${userId}:${period}`
      : `report:v1:monthly:${userId}:${period}`;

    try {
      await this.redisService.getClient().set(
        cacheKey,
        JSON.stringify(data),
        'EX',
        300, // 5 min TTL
      );
    } catch (err) {
      this.logger.warn(`Failed to cache key ${cacheKey}: ${err.message}`);
    }
  }

  /**
   * Flow: Check cache first, if miss, try to enqueue async report generation.
   */
  async getReportOrEnqueue(
    userId: string,
    type: 'DAILY' | 'MONTHLY',
    period: string,
    segmentId?: string,
  ): Promise<{ status: string; reportId?: string; estimatedWait?: string; data?: any }> {
    if (this.redisService.isHealthy()) {
      const isGlobalMaint = await this.redisService.getClient().get('system:maintenance:global');
      const isReportsMaint = await this.redisService.getClient().get('system:maintenance:reports');
      if (isGlobalMaint === 'true' || isReportsMaint === 'true') {
        throw new ServiceUnavailableException('Report generation is currently disabled due to system maintenance');
      }
    }

    // 1. Check cache first
    const cachedData = await this.getReportFromCache(userId, type, period, segmentId);
    if (cachedData) {
      return { status: 'COMPLETED', data: cachedData };
    }

    // Rule 6: Report Queue Backpressure Protection (queueDepth > 10000 -> reject)
    try {
      const q = this.queueService.getQueue(Queues.REPORT_GENERATION);
      const queueDepth = await q.getWaitingCount();
      if (queueDepth > 10000) {
        this.logger.warn(`Report queue depth exceeded limit (waiting=${queueDepth}). Rejecting request.`);
        return { status: 'QUEUED', estimatedWait: 'later' };
      }
    } catch (err) {
      this.logger.error(`Failed to verify report queue depth: ${err.message}`);
    }

    // 2. Check/Acquire request idempotency lock (10 minutes TTL)
    const idempotencyKey = `report:idempotency:${userId}:${type}:${period}${segmentId ? `:${segmentId}` : ''}`;
    try {
      const acquired = await this.redisService.getClient().set(
        idempotencyKey,
        'PROCESSING',
        'EX',
        600, // 10 minutes
        'NX',
      );

      if (acquired !== 'OK') {
        // Idempotency lock exists: retrieve active or most recent generation request
        const existing = await this.prisma.report.findFirst({
          where: {
            userId,
            reportType: type,
            status: { in: [ReportState.REQUESTED, ReportState.PROCESSING] },
          },
          orderBy: { generatedAt: 'desc' },
        });

        if (existing) {
          return { status: existing.status, reportId: existing.id };
        }
        return { status: 'PROCESSING' };
      }
    } catch (err) {
      this.logger.error(`Idempotency check failed: ${err.message}`);
    }

    // 3. Create Report in DB and queue generation job
    const report = await this.prisma.report.create({
      data: {
        userId,
        reportType: type,
        status: ReportState.REQUESTED,
      },
    });

    await this.queueService.addJob(
      Queues.REPORT_GENERATION,
      report.id,
      {
        reportId: report.id,
        userId,
        type,
        period,
        segmentId,
      },
      5, // P5 priority (lowest)
    );

    return { status: 'REQUESTED', reportId: report.id };
  }

  /**
   * Request async CSV export.
   */
  async requestCsvExport(
    userId: string,
    type: string,
    period: string,
    segmentId?: string,
  ): Promise<{ status: string; exportId: string }> {
    const exportRecord = await this.prisma.reportExport.create({
      data: {
        userId,
        exportType: type,
        status: ExportState.REQUESTED,
      },
    });

    await this.queueService.addJob(
      Queues.REPORT_EXPORT,
      exportRecord.id,
      {
        exportId: exportRecord.id,
        userId,
        type,
        period,
        segmentId,
      },
      5, // P5 priority
    );

    return { status: 'REQUESTED', exportId: exportRecord.id };
  }

  /**
   * Enqueue nightly snapshot recovery/rebuild operations.
   * Rule 1: Analytics Snapshot Queue Must Be Sharded
   */
  async rebuildSnapshots(payload: {
    startDate: Date;
    endDate: Date;
    userId?: string;
    segmentId?: string;
  }): Promise<void> {
    const jobId = `rebuild-${Date.now()}`;
    if (payload.userId) {
      const shardQueue = getSnapshotQueueName(payload.userId);
      await this.queueService.addJob(
        shardQueue,
        jobId,
        {
          startDate: payload.startDate.toISOString(),
          endDate: payload.endDate.toISOString(),
          userId: payload.userId,
          segmentId: payload.segmentId,
        },
        5,
      );
    } else {
      for (let i = 0; i < 10; i++) {
        await this.queueService.addJob(
          `analytics-snapshot-${i}`,
          `${jobId}-${i}`,
          {
            startDate: payload.startDate.toISOString(),
            endDate: payload.endDate.toISOString(),
          },
          5,
        );
      }
    }
  }

  /**
   * Core Snapshot Aggregation Logic.
   * Calculations are based purely on completed Trade & Position records.
   * Rule 2: Report Generation Must Use Snapshot Lock (analytics:snapshot:lock:{userId}:{segmentId}:{date} TTL 60s)
   */
  async calculateAndUpsertSnapshot(userId: string, segmentId: string, date: Date): Promise<AnalyticsSnapshot> {
    const startOfDay = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0, 0));
    const endOfDay = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 23, 59, 59, 999));
    const dateStr = startOfDay.toISOString().split('T')[0];

    const lockKey = `analytics:snapshot:lock:${userId}:${segmentId}:${dateStr}`;
    const acquired = await this.redisService.getClient().set(
      lockKey,
      '1',
      'EX',
      60,
      'NX',
    );

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
      // Query trades for this user, segment and day
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
          } else if (pnlNum < 0) {
            losingTrades++;
          }
        }
        if (trade.position) {
          unrealizedPnl += Number(trade.position.unrealizedPnl || 0);
          realizedPnl += Number(trade.position.realizedPnl || 0);
        }
      }

      const winRate = totalTrades > 0 ? (winningTrades / totalTrades) * 100 : 0;

      // Fetch user segment capital for ROI
      const userSegment = await this.prisma.userSegment.findUnique({
        where: {
          userId_segmentId: { userId, segmentId },
        },
      });

      const capital = userSegment ? Number(userSegment.capital) : 100000;
      const roi = capital > 0 ? (realizedPnl / capital) * 100 : 0;
      const drawdown = 0; // placeholder or default

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
          snapshotVersion: 1, // Rule 5: Versioning snapshots
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
    } finally {
      await this.redisService.getClient().del(lockKey).catch(() => {});
    }
  }
}
