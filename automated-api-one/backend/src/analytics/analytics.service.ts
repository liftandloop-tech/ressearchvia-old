import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CacheService } from '../infrastructure/cache/cache.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { Queues } from '../infrastructure/queues/queue.constants';
import {
  Prisma,
  EquityCurveSourceType,
  AnalyticsRunStatus,
  TradeStatus,
  PositionStatus,
} from '@prisma/client';
import { Cron } from '@nestjs/schedule';

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cacheService: CacheService,
    private readonly metrics: MetricsService,
    private readonly queueService: QueueService,
  ) {}

  /**
   * Recalculates EOD DailyPortfolioSnapshot for the user (today) and records equity curve point.
   */
  async recalculateAnalyticsSnapshot(userId: string): Promise<void> {
    this.logger.log(`Recalculating daily portfolio snapshot for user: ${userId}`);

    const segments = await this.prisma.userSegment.findMany({
      where: { userId, deletedAt: null },
    });
    let initialCapital = segments.reduce((sum, seg) => sum + Number(seg.capital), 0);
    if (initialCapital <= 0) {
      const firstSnap = await this.prisma.dailyPortfolioSnapshot.findFirst({
        where: { userId },
        orderBy: { date: 'asc' },
      });
      initialCapital = firstSnap ? Number(firstSnap.equity) : 100000;
    }

    const closedTrades = await this.prisma.trade.findMany({
      where: {
        userId,
        status: { in: [TradeStatus.CLOSED, TradeStatus.TARGET_HIT, TradeStatus.STOPLOSS_HIT] },
      },
    });

    const openPositions = await this.prisma.position.findMany({
      where: {
        trade: { userId },
        status: PositionStatus.OPEN,
      },
    });

    const totalRealizedPnl = closedTrades.reduce((sum, t) => sum + Number(t.pnl || 0), 0);
    const totalUnrealizedPnl = openPositions.reduce((sum, p) => sum + Number(p.unrealizedPnl || 0), 0);
    const currentEquity = initialCapital + totalRealizedPnl + totalUnrealizedPnl;

    const todayDate = new Date();
    todayDate.setHours(0, 0, 0, 0);

    // Get peak equity including today to calculate drawdown
    const pastSnapshots = await this.prisma.dailyPortfolioSnapshot.findMany({
      where: { userId, date: { lt: todayDate } },
    });
    const allEquities = [...pastSnapshots.map((s) => Number(s.equity)), currentEquity];
    const peakEquity = Math.max(initialCapital, ...allEquities);
    const drawdown = peakEquity - currentEquity;

    const openPositionsCount = openPositions.length;

    // Calculate volume traded today
    const startOfToday = new Date(todayDate);
    const endOfToday = new Date(todayDate);
    endOfToday.setHours(23, 59, 59, 999);
    const todayTrades = await this.prisma.trade.findMany({
      where: {
        userId,
        createdAt: { gte: startOfToday, lte: endOfToday },
      },
    });
    const volumeTraded = todayTrades.reduce(
      (sum, t) => sum + Number(t.quantity) * Number(t.entryPrice || 0),
      0,
    );

    // 1. Upsert daily portfolio snapshot
    await this.prisma.dailyPortfolioSnapshot.upsert({
      where: { userId_date: { userId, date: todayDate } },
      update: {
        equity: new Prisma.Decimal(currentEquity),
        realizedPnl: new Prisma.Decimal(totalRealizedPnl),
        unrealizedPnl: new Prisma.Decimal(totalUnrealizedPnl),
        drawdown: new Prisma.Decimal(drawdown),
        openPositionsCount,
        volumeTraded: new Prisma.Decimal(volumeTraded),
        version: 1,
      },
      create: {
        userId,
        date: todayDate,
        equity: new Prisma.Decimal(currentEquity),
        realizedPnl: new Prisma.Decimal(totalRealizedPnl),
        unrealizedPnl: new Prisma.Decimal(totalUnrealizedPnl),
        drawdown: new Prisma.Decimal(drawdown),
        openPositionsCount,
        volumeTraded: new Prisma.Decimal(volumeTraded),
        version: 1,
      },
    });

    // 2. Record daily equity curve point
    await this.prisma.equityCurvePoint.create({
      data: {
        userId,
        equityValue: new Prisma.Decimal(currentEquity),
        sourceType: EquityCurveSourceType.DAILY,
        timestamp: new Date(),
      },
    });

    this.metrics.incrementAnalyticsSnapshotsCreated();
    await this.invalidateUserCache(userId);
  }

  /**
   * Performs a complete historical rebuild of daily snapshots from trades.
   */
  async rebuildHistoricalSnapshots(userId: string): Promise<void> {
    this.logger.log(`Performing full historical rebuild of daily snapshots for user: ${userId}`);

    const segments = await this.prisma.userSegment.findMany({
      where: { userId, deletedAt: null },
    });
    let initialCapital = segments.reduce((sum, seg) => sum + Number(seg.capital), 0);
    if (initialCapital <= 0) {
      initialCapital = 100000;
    }

    const closedTrades = await this.prisma.trade.findMany({
      where: {
        userId,
        status: { in: [TradeStatus.CLOSED, TradeStatus.TARGET_HIT, TradeStatus.STOPLOSS_HIT] },
      },
      orderBy: { createdAt: 'asc' },
    });

    const openPositions = await this.prisma.position.findMany({
      where: {
        trade: { userId },
        status: PositionStatus.OPEN,
      },
    });

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let startDate = new Date(today);
    startDate.setDate(startDate.getDate() - 90);

    if (closedTrades.length > 0) {
      const firstTradeDate = new Date(closedTrades[0].createdAt);
      firstTradeDate.setHours(0, 0, 0, 0);
      if (firstTradeDate < startDate) {
        startDate = firstTradeDate;
      }
    }

    let peakEquity = initialCapital;
    const currentDate = new Date(startDate);

    while (currentDate <= today) {
      const endOfDay = new Date(currentDate);
      endOfDay.setHours(23, 59, 59, 999);

      const tradesUpToD = closedTrades.filter((t) => new Date(t.createdAt) <= endOfDay);
      const realizedPnl = tradesUpToD.reduce((sum, t) => sum + Number(t.pnl || 0), 0);

      const isToday = currentDate.getTime() === today.getTime();
      const unrealizedPnl = isToday
        ? openPositions.reduce((sum, p) => sum + Number(p.unrealizedPnl || 0), 0)
        : 0;

      const equity = initialCapital + realizedPnl + unrealizedPnl;
      if (equity > peakEquity) {
        peakEquity = equity;
      }
      const drawdown = peakEquity - equity;

      const openPositionsCount = isToday ? openPositions.length : 0;

      const startOfDay = new Date(currentDate);
      startOfDay.setHours(0, 0, 0, 0);
      const tradesOnD = closedTrades.filter((t) => {
        const d = new Date(t.createdAt);
        return d >= startOfDay && d <= endOfDay;
      });
      const volumeTraded = tradesOnD.reduce(
        (sum, t) => sum + Number(t.quantity) * Number(t.entryPrice || 0),
        0,
      );

      await this.prisma.dailyPortfolioSnapshot.upsert({
        where: { userId_date: { userId, date: startOfDay } },
        update: {
          equity: new Prisma.Decimal(equity),
          realizedPnl: new Prisma.Decimal(realizedPnl),
          unrealizedPnl: new Prisma.Decimal(unrealizedPnl),
          drawdown: new Prisma.Decimal(drawdown),
          openPositionsCount,
          volumeTraded: new Prisma.Decimal(volumeTraded),
          version: 1,
        },
        create: {
          userId,
          date: startOfDay,
          equity: new Prisma.Decimal(equity),
          realizedPnl: new Prisma.Decimal(realizedPnl),
          unrealizedPnl: new Prisma.Decimal(unrealizedPnl),
          drawdown: new Prisma.Decimal(drawdown),
          openPositionsCount,
          volumeTraded: new Prisma.Decimal(volumeTraded),
          version: 1,
        },
      });

      currentDate.setDate(currentDate.getDate() + 1);
    }

    this.logger.log(`Full historical rebuild of daily snapshots completed for user: ${userId}`);
    await this.invalidateUserCache(userId);
  }

  /**
   * Updates performance rollups (UserPerformance & SegmentPerformance).
   */
  async updatePerformanceRollups(userId: string): Promise<void> {
    this.logger.log(`Updating performance rollups for user: ${userId}`);

    const segments = await this.prisma.userSegment.findMany({
      where: { userId, deletedAt: null },
    });
    let initialCapital = segments.reduce((sum, seg) => sum + Number(seg.capital), 0);
    if (initialCapital <= 0) {
      initialCapital = 100000;
    }

    const closedTrades = await this.prisma.trade.findMany({
      where: {
        userId,
        status: { in: [TradeStatus.CLOSED, TradeStatus.TARGET_HIT, TradeStatus.STOPLOSS_HIT] },
      },
    });

    const snapshots = await this.prisma.dailyPortfolioSnapshot.findMany({
      where: { userId },
      orderBy: { date: 'asc' },
    });

    const totalTrades = closedTrades.length;
    const totalPnl = closedTrades.reduce((sum, t) => sum + Number(t.pnl || 0), 0);
    const grossProfit = closedTrades.reduce((sum, t) => sum + (Number(t.pnl || 0) > 0 ? Number(t.pnl || 0) : 0), 0);
    const grossLoss = closedTrades.reduce((sum, t) => sum + (Number(t.pnl || 0) < 0 ? Number(t.pnl || 0) : 0), 0);
    const winningTrades = closedTrades.filter((t) => Number(t.pnl || 0) > 0).length;
    const losingTrades = closedTrades.filter((t) => Number(t.pnl || 0) <= 0).length;
    const maxDrawdown = snapshots.reduce((max, s) => Math.max(max, Number(s.drawdown)), 0);

    const firstTradeAt = closedTrades.length > 0 ? closedTrades[0].createdAt : null;
    const lastTradeAt = closedTrades.length > 0 ? closedTrades[closedTrades.length - 1].createdAt : null;

    // 1. Update UserPerformance
    await this.prisma.userPerformance.upsert({
      where: { userId },
      update: {
        totalPnl: new Prisma.Decimal(totalPnl),
        grossProfit: new Prisma.Decimal(grossProfit),
        grossLoss: new Prisma.Decimal(grossLoss),
        totalTrades,
        winningTrades,
        losingTrades,
        maxDrawdown: new Prisma.Decimal(maxDrawdown),
        firstTradeAt,
        lastTradeAt,
        version: 1,
        calculatedAt: new Date(),
      },
      create: {
        userId,
        totalPnl: new Prisma.Decimal(totalPnl),
        grossProfit: new Prisma.Decimal(grossProfit),
        grossLoss: new Prisma.Decimal(grossLoss),
        totalTrades,
        winningTrades,
        losingTrades,
        maxDrawdown: new Prisma.Decimal(maxDrawdown),
        firstTradeAt,
        lastTradeAt,
        version: 1,
        calculatedAt: new Date(),
      },
    });

    // 2. Update SegmentPerformance for each segment
    const segmentIds = Array.from(new Set(closedTrades.map((t) => t.segmentId)));
    for (const segmentId of segmentIds) {
      const segTrades = closedTrades.filter((t) => t.segmentId === segmentId);
      const totalTradesForSegment = segTrades.length;
      const netPnL = segTrades.reduce((sum, t) => sum + Number(t.pnl || 0), 0);
      const winningTradesSegment = segTrades.filter((t) => Number(t.pnl || 0) > 0).length;
      const winRate = totalTradesForSegment > 0 ? (winningTradesSegment / totalTradesForSegment) * 100 : 0;

      const userSeg = segments.find((s) => s.segmentId === segmentId);
      const capitalUsed = userSeg ? Number(userSeg.capital) : 0;

      // Segment drawdown curve calculation
      let runningEquity = capitalUsed;
      let peak = capitalUsed;
      let maxDrawdownSegment = 0;
      const sortedSegTrades = [...segTrades].sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
      for (const t of sortedSegTrades) {
        runningEquity += Number(t.pnl || 0);
        if (runningEquity > peak) peak = runningEquity;
        const dd = peak - runningEquity;
        if (dd > maxDrawdownSegment) maxDrawdownSegment = dd;
      }

      const contributionPercent = totalPnl !== 0 ? (netPnL / Math.abs(totalPnl)) * 100 : 0;

      await this.prisma.segmentPerformance.upsert({
        where: { userId_segmentId: { userId, segmentId } },
        update: {
          totalTrades: totalTradesForSegment,
          winRate: new Prisma.Decimal(winRate),
          netPnL: new Prisma.Decimal(netPnL),
          maxDrawdown: new Prisma.Decimal(maxDrawdownSegment),
          capitalUsed: new Prisma.Decimal(capitalUsed),
          contributionPercent: new Prisma.Decimal(contributionPercent),
        },
        create: {
          userId,
          segmentId,
          totalTrades: totalTradesForSegment,
          winRate: new Prisma.Decimal(winRate),
          netPnL: new Prisma.Decimal(netPnL),
          maxDrawdown: new Prisma.Decimal(maxDrawdownSegment),
          capitalUsed: new Prisma.Decimal(capitalUsed),
          contributionPercent: new Prisma.Decimal(contributionPercent),
        },
      });
    }

    await this.invalidateUserCache(userId);
  }

  /**
   * Returns portfolio derived metrics, raw stats, and equity curve points. Uses Cache.
   */
  async getPortfolioPerformance(userId: string): Promise<any> {
    const cacheKey = `analytics:user:${userId}:portfolio`;
    const cached = await this.cacheService.get<any>(cacheKey);
    if (cached) return cached;

    const userPerf = await this.prisma.userPerformance.findUnique({
      where: { userId },
    });

    const snapshots = await this.prisma.dailyPortfolioSnapshot.findMany({
      where: { userId },
      orderBy: { date: 'asc' },
    });

    const segments = await this.prisma.userSegment.findMany({
      where: { userId, deletedAt: null },
    });
    let initialCapital = segments.reduce((sum, seg) => sum + Number(seg.capital), 0);
    if (initialCapital <= 0) {
      initialCapital = snapshots.length > 0 ? Number(snapshots[0].equity) : 100000;
    }

    if (!userPerf || snapshots.length === 0) {
      return {
        sharpeRatio: 0,
        sortinoRatio: 0,
        cagr: 0,
        winRate: 0,
        profitFactor: 0,
        alpha: {},
        rawStats: userPerf || null,
        equityCurvePoints: [],
      };
    }

    // 1. Calculate Daily Returns R_t
    const R: number[] = [];
    let prevEquity = initialCapital;
    for (const snap of snapshots) {
      const eq = Number(snap.equity);
      const ret = prevEquity > 0 ? (eq - prevEquity) / prevEquity : 0;
      R.push(ret);
      prevEquity = eq;
    }

    // 2. Sharpe & Sortino Calculations
    const annualRf = parseFloat(process.env.RISK_FREE_RATE_ANNUAL || '6.5');
    const dailyRf = annualRf / 100 / 252;
    const meanR = R.reduce((sum, r) => sum + r, 0) / R.length;

    const variance = R.reduce((sum, r) => sum + Math.pow(r - meanR, 2), 0) / R.length;
    const stdDevR = Math.sqrt(variance);
    const sharpeRatio = stdDevR > 0 ? ((meanR - dailyRf) / stdDevR) * Math.sqrt(252) : 0;

    const downsideDiffs = R.map((r) => Math.min(0, r - dailyRf));
    const downsideVariance = downsideDiffs.reduce((sum, d) => sum + Math.pow(d, 2), 0) / R.length;
    const downsideStdDev = Math.sqrt(downsideVariance);
    const sortinoRatio = downsideStdDev > 0 ? ((meanR - dailyRf) / downsideStdDev) * Math.sqrt(252) : 0;

    // 3. CAGR Calculation
    const firstDate = new Date(snapshots[0].date);
    const latestDate = new Date(snapshots[snapshots.length - 1].date);
    const diffMs = Math.max(1000 * 60 * 60 * 24, latestDate.getTime() - firstDate.getTime());
    const days = diffMs / (1000 * 60 * 60 * 24);
    const years = days / 365.25;

    const endingValue = Number(snapshots[snapshots.length - 1].equity);
    const beginningValue = initialCapital;
    let cagr = 0;
    if (endingValue > 0 && beginningValue > 0 && years > 0) {
      cagr = Math.pow(endingValue / beginningValue, 1 / years) - 1;
    }

    // 4. Alpha Calculation vs Benchmarks
    const portfolioReturn = beginningValue > 0 ? (endingValue - beginningValue) / beginningValue : 0;
    const alpha: Record<string, number> = {};

    const benchmarks = ['NIFTY50', 'BANKNIFTY', 'MIDCAP150'];
    for (const bName of benchmarks) {
      const startB = await this.prisma.benchmarkSnapshot.findFirst({
        where: { benchmarkName: bName, date: { lte: firstDate } },
        orderBy: { date: 'desc' },
      });
      const endB = await this.prisma.benchmarkSnapshot.findFirst({
        where: { benchmarkName: bName, date: { lte: latestDate } },
        orderBy: { date: 'desc' },
      });

      if (startB && endB) {
        const startVal = Number(startB.value);
        const endVal = Number(endB.value);
        const benchmarkReturn = startVal > 0 ? (endVal - startVal) / startVal : 0;
        alpha[bName] = portfolioReturn - benchmarkReturn;
      } else {
        alpha[bName] = 0;
      }
    }

    const winRate = Number(userPerf.totalTrades) > 0 ? Number(userPerf.winningTrades) / Number(userPerf.totalTrades) : 0;
    const profitFactor = Math.abs(Number(userPerf.grossLoss)) > 0
      ? Number(userPerf.grossProfit) / Math.abs(Number(userPerf.grossLoss))
      : Number(userPerf.grossProfit);

    const equityCurvePoints = await this.prisma.equityCurvePoint.findMany({
      where: { userId },
      orderBy: { timestamp: 'asc' },
    });

    const result = {
      sharpeRatio,
      sortinoRatio,
      cagr,
      winRate,
      profitFactor,
      alpha,
      rawStats: userPerf,
      equityCurvePoints,
    };

    await this.cacheService.set(cacheKey, result, 600);
    return result;
  }

  /**
   * Returns segment performances for the user. Uses Cache.
   */
  async getSegmentPerformance(userId: string): Promise<any> {
    const cacheKey = `analytics:user:${userId}:segments`;
    const cached = await this.cacheService.get<any>(cacheKey);
    if (cached) return cached;

    const performances = await this.prisma.segmentPerformance.findMany({
      where: { userId },
      include: { segment: true },
    });

    await this.cacheService.set(cacheKey, performances, 600);
    return performances;
  }

  /**
   * Returns broker performance metrics. Uses Cache.
   */
  async getBrokerPerformance(userId: string): Promise<any> {
    const cacheKey = `analytics:user:${userId}:broker-stats`;
    const cached = await this.cacheService.get<any>(cacheKey);
    if (cached) return cached;

    const trades = await this.prisma.trade.findMany({
      where: { userId },
      include: {
        signal: true,
        orders: true,
      },
    });

    const brokerGroup: Record<string, any> = {};

    for (const t of trades) {
      const brokerId = t.brokerId;
      if (!brokerGroup[brokerId]) {
        brokerGroup[brokerId] = {
          brokerId,
          totalOrders: 0,
          filledOrders: 0,
          rejectedOrders: 0,
          slippages: [] as number[],
        };
      }

      const group = brokerGroup[brokerId];
      for (const o of t.orders) {
        group.totalOrders++;
        if (o.status === 'FILLED') {
          group.filledOrders++;
        } else if (o.status === 'REJECTED') {
          group.rejectedOrders++;
        }
      }

      if (t.entryPrice && t.signal && t.signal.entryPrice) {
        const diff = Number(t.entryPrice) - Number(t.signal.entryPrice);
        // slippage is actual price - theoretical price
        group.slippages.push(diff);
      }
    }

    const result = Object.values(brokerGroup).map((g) => {
      const fillRate = g.totalOrders > 0 ? g.filledOrders / g.totalOrders : 0;
      const rejectionRate = g.totalOrders > 0 ? g.rejectedOrders / g.totalOrders : 0;
      const averageSlippage = g.slippages.length > 0
        ? g.slippages.reduce((sum: number, val: number) => sum + Math.abs(val), 0) / g.slippages.length
        : 0;

      return {
        brokerId: g.brokerId,
        totalOrders: g.totalOrders,
        filledOrders: g.filledOrders,
        rejectedOrders: g.rejectedOrders,
        fillRate,
        rejectionRate,
        averageSlippage,
      };
    });

    await this.cacheService.set(cacheKey, result, 600);
    return result;
  }

  /**
   * Invalidates Redis cache for user-level analytics endpoints.
   */
  async invalidateUserCache(userId: string): Promise<void> {
    const keys = [
      `analytics:user:${userId}:portfolio`,
      `analytics:user:${userId}:segments`,
      `analytics:user:${userId}:broker-stats`,
    ];
    for (const key of keys) {
      try {
        await this.cacheService.del(key);
      } catch (err) {
        this.logger.warn(`Failed to invalidate cache key: ${key}. Error: ${err.message}`);
      }
    }
  }

  /**
   * Daily scheduler running at 23:45 IST triggering sharded recalculations.
   */
  @Cron('45 23 * * *', { timeZone: 'Asia/Kolkata' })
  async handleNightlyAnalyticsRecalculation(): Promise<void> {
    this.logger.log('Nightly portfolio analytics cron triggered');
    this.metrics.incrementAnalyticsRuns();

    const activeUsers = await this.prisma.user.findMany({
      where: { status: 'ACTIVE' },
    });
    const totalUsers = activeUsers.length;

    const run = await this.prisma.analyticsJobRun.create({
      data: {
        startedAt: new Date(),
        status: AnalyticsRunStatus.RUNNING,
        usersProcessed: 0,
        failures: 0,
      },
    });

    this.logger.log(`Nightly analytics job run ${run.id} started. Enqueuing ${totalUsers} sharded recalculation tasks.`);

    for (const user of activeUsers) {
      try {
        await this.queueService.addJob(
          Queues.ANALYTICS_RECALCULATE,
          `recalculate-${run.id}-${user.id}`,
          { userId: user.id, runId: run.id, totalUsers },
        );
      } catch (err) {
        this.logger.error(`Failed to enqueue recalculate job for user ${user.id}: ${err.message}`);
        await this.handleJobCompletion(run.id, totalUsers, false);
      }
    }
  }

  /**
   * Processes the completion of a user recalculation job.
   */
  async handleJobCompletion(runId: string, totalUsers: number, success: boolean): Promise<void> {
    try {
      // Find and update run in a transaction / update statement
      const run = await this.prisma.analyticsJobRun.findUnique({ where: { id: runId } });
      if (!run) return;

      const usersProcessed = run.usersProcessed + (success ? 1 : 0);
      const failures = run.failures + (success ? 0 : 1);
      const isDone = usersProcessed + failures >= totalUsers;

      const completedAt = isDone ? new Date() : null;
      const status = isDone
        ? (failures === totalUsers ? AnalyticsRunStatus.FAILED : AnalyticsRunStatus.SUCCESS)
        : AnalyticsRunStatus.RUNNING;

      await this.prisma.analyticsJobRun.update({
        where: { id: runId },
        data: {
          usersProcessed,
          failures,
          status,
          completedAt,
          durationMs: completedAt ? completedAt.getTime() - run.startedAt.getTime() : null,
        },
      });

      this.metrics.incrementAnalyticsUsersProcessed();
      if (!success) {
        this.metrics.incrementAnalyticsFailures();
      }

      if (isDone && completedAt) {
        const duration = completedAt.getTime() - run.startedAt.getTime();
        this.metrics.observeAnalyticsDuration(duration);
        this.logger.log(`Nightly analytics job run ${runId} finished. Status: ${status}. Processed: ${usersProcessed}, Failures: ${failures}`);
      }
    } catch (err) {
      this.logger.error(`Failed to handle job completion update for run ${runId}: ${err.message}`);
    }
  }

  /**
   * Nightly cron job to clean up EquityCurvePoint records based on tiered retention policy:
   * - Intraday: 90 days
   * - Hourly: 365 days
   * - Daily: Keep forever
   */
  @Cron('0 2 * * *')
  async cleanupEquityCurvePoints(): Promise<void> {
    this.logger.log('Starting tiered equity curve points retention cleanup...');

    const now = new Date();

    const intradayCutoff = new Date(now);
    intradayCutoff.setDate(intradayCutoff.getDate() - 90);

    const hourlyCutoff = new Date(now);
    hourlyCutoff.setDate(hourlyCutoff.getDate() - 365);

    try {
      const deletedIntraday = await this.prisma.equityCurvePoint.deleteMany({
        where: {
          sourceType: EquityCurveSourceType.INTRADAY,
          timestamp: { lt: intradayCutoff },
        },
      });

      const deletedHourly = await this.prisma.equityCurvePoint.deleteMany({
        where: {
          sourceType: EquityCurveSourceType.HOURLY,
          timestamp: { lt: hourlyCutoff },
        },
      });

      this.logger.log(
        `Retention cleanup finished. Deleted ${deletedIntraday.count} intraday points, ${deletedHourly.count} hourly points.`,
      );

      this.metrics.incrementAnalyticsRetentionDeleted('INTRADAY', deletedIntraday.count);
      this.metrics.incrementAnalyticsRetentionDeleted('HOURLY', deletedHourly.count);
    } catch (err) {
      this.logger.error(`Failed to execute retention cleanup: ${err.message}`, err.stack);
    }
  }

  /**
   * Enqueues a manual recalculation job for a user.
   */
  async enqueueRecalculation(userId: string, rebuildHistory?: boolean): Promise<void> {
    await this.queueService.addJob(
      Queues.ANALYTICS_RECALCULATE,
      `recalculate-manual-${Date.now()}-${userId}`,
      { userId, rebuildHistory },
    );
  }
}
