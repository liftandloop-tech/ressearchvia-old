import { Test, TestingModule } from '@nestjs/testing';
import { AnalyticsService } from './analytics.service';
import { PrismaService } from '../prisma.service';
import { CacheService } from '../infrastructure/cache/cache.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import { EquityCurveSourceType, TradeStatus, PositionStatus, AnalyticsRunStatus } from '@prisma/client';
import { Prisma } from '@prisma/client';

describe('AnalyticsService', () => {
  let service: AnalyticsService;
  let prismaMock: any;
  let cacheMock: any;
  let metricsMock: any;
  let queueMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    cacheMock = {
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockResolvedValue(undefined),
      del: jest.fn().mockResolvedValue(undefined),
    };
    metricsMock = {
      incrementAnalyticsSnapshotsCreated: jest.fn(),
      incrementAnalyticsRuns: jest.fn(),
      incrementAnalyticsUsersProcessed: jest.fn(),
      incrementAnalyticsFailures: jest.fn(),
      observeAnalyticsDuration: jest.fn(),
      incrementAnalyticsRetentionDeleted: jest.fn(),
    };
    queueMock = {
      addJob: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AnalyticsService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: CacheService, useValue: cacheMock },
        { provide: MetricsService, useValue: metricsMock },
        { provide: QueueService, useValue: queueMock },
      ],
    }).compile();

    service = module.get<AnalyticsService>(AnalyticsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('recalculateAnalyticsSnapshot', () => {
    it('should recalculate snapshots and create daily portfolio snapshot', async () => {
      const userId = 'user-uuid';
      prismaMock.userSegment.findMany.mockResolvedValue([
        { segmentId: 'seg-1', capital: new Prisma.Decimal(50000) },
        { segmentId: 'seg-2', capital: new Prisma.Decimal(50000) },
      ]);
      prismaMock.trade.findMany.mockResolvedValue([
        { id: 't-1', pnl: new Prisma.Decimal(1500), status: TradeStatus.CLOSED },
        { id: 't-2', pnl: new Prisma.Decimal(-500), status: TradeStatus.CLOSED },
      ]);
      prismaMock.position.findMany.mockResolvedValue([
        { id: 'pos-1', unrealizedPnl: new Prisma.Decimal(200) },
      ]);
      prismaMock.dailyPortfolioSnapshot.findMany.mockResolvedValue([]);
      prismaMock.dailyPortfolioSnapshot.upsert.mockResolvedValue({});
      prismaMock.equityCurvePoint.create.mockResolvedValue({});

      await service.recalculateAnalyticsSnapshot(userId);

      expect(prismaMock.userSegment.findMany).toHaveBeenCalledWith({
        where: { userId, deletedAt: null },
      });
      expect(prismaMock.dailyPortfolioSnapshot.upsert).toHaveBeenCalledWith({
        where: expect.any(Object),
        update: expect.objectContaining({
          equity: new Prisma.Decimal(101200), // 100k capital + 1000 realized + 200 unrealized
          realizedPnl: new Prisma.Decimal(1000),
          unrealizedPnl: new Prisma.Decimal(200),
        }),
        create: expect.any(Object),
      });
      expect(prismaMock.equityCurvePoint.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId,
          equityValue: new Prisma.Decimal(101200),
          sourceType: EquityCurveSourceType.DAILY,
        }),
      });
      expect(cacheMock.del).toHaveBeenCalled();
    });
  });

  describe('rebuildHistoricalSnapshots', () => {
    it('should rebuild daily snapshots historically', async () => {
      const userId = 'user-uuid';
      prismaMock.userSegment.findMany.mockResolvedValue([
        { segmentId: 'seg-1', capital: new Prisma.Decimal(100000) },
      ]);

      const testDate = new Date();
      testDate.setDate(testDate.getDate() - 2);

      prismaMock.trade.findMany.mockResolvedValue([
        { id: 't-1', pnl: new Prisma.Decimal(5000), status: TradeStatus.CLOSED, createdAt: testDate },
      ]);
      prismaMock.position.findMany.mockResolvedValue([]);
      prismaMock.dailyPortfolioSnapshot.upsert.mockResolvedValue({});

      await service.rebuildHistoricalSnapshots(userId);

      expect(prismaMock.dailyPortfolioSnapshot.upsert).toHaveBeenCalled();
      expect(cacheMock.del).toHaveBeenCalled();
    });
  });

  describe('updatePerformanceRollups', () => {
    it('should update performance rollups for user and segment', async () => {
      const userId = 'user-uuid';
      prismaMock.userSegment.findMany.mockResolvedValue([
        { segmentId: 'seg-1', capital: new Prisma.Decimal(100000) },
      ]);
      prismaMock.trade.findMany.mockResolvedValue([
        { segmentId: 'seg-1', pnl: new Prisma.Decimal(3000), status: TradeStatus.CLOSED, createdAt: new Date() },
        { segmentId: 'seg-1', pnl: new Prisma.Decimal(-1000), status: TradeStatus.CLOSED, createdAt: new Date() },
      ]);
      prismaMock.dailyPortfolioSnapshot.findMany.mockResolvedValue([
        { drawdown: new Prisma.Decimal(500) },
      ]);
      prismaMock.userPerformance.upsert.mockResolvedValue({});
      prismaMock.segmentPerformance.upsert.mockResolvedValue({});

      await service.updatePerformanceRollups(userId);

      expect(prismaMock.userPerformance.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          update: expect.objectContaining({
            totalPnl: new Prisma.Decimal(2000),
            grossProfit: new Prisma.Decimal(3000),
            grossLoss: new Prisma.Decimal(-1000),
            totalTrades: 2,
            winningTrades: 1,
            losingTrades: 1,
          }),
        }),
      );
      expect(prismaMock.segmentPerformance.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          update: expect.objectContaining({
            totalTrades: 2,
            netPnL: new Prisma.Decimal(2000),
            winRate: new Prisma.Decimal(50),
          }),
        }),
      );
    });
  });

  describe('getPortfolioPerformance Math formulas', () => {
    it('should correctly calculate Sharpe, Sortino, CAGR, Win Rate, and Profit Factor', async () => {
      const userId = 'user-uuid';
      const mockUserPerf = {
        userId,
        totalPnl: new Prisma.Decimal(2000),
        grossProfit: new Prisma.Decimal(3000),
        grossLoss: new Prisma.Decimal(-1000),
        totalTrades: 2,
        winningTrades: 1,
        losingTrades: 1,
      };

      prismaMock.userPerformance.findUnique.mockResolvedValue(mockUserPerf);

      // Create a sequence of increasing daily snapshots
      const date1 = new Date();
      date1.setDate(date1.getDate() - 5);
      const date2 = new Date();
      date2.setDate(date2.getDate() - 4);
      const date3 = new Date();
      date3.setDate(date3.getDate() - 3);

      prismaMock.dailyPortfolioSnapshot.findMany.mockResolvedValue([
        { date: date1, equity: new Prisma.Decimal(101000), drawdown: new Prisma.Decimal(0) },
        { date: date2, equity: new Prisma.Decimal(100500), drawdown: new Prisma.Decimal(500) },
        { date: date3, equity: new Prisma.Decimal(103000), drawdown: new Prisma.Decimal(0) },
      ]);

      prismaMock.userSegment.findMany.mockResolvedValue([
        { segmentId: 'seg-1', capital: new Prisma.Decimal(100000) },
      ]);

      prismaMock.equityCurvePoint.findMany.mockResolvedValue([]);
      prismaMock.benchmarkSnapshot.findFirst.mockResolvedValue(null);

      const result = await service.getPortfolioPerformance(userId);

      expect(result.sharpeRatio).toBeGreaterThan(0);
      expect(result.sortinoRatio).toBeGreaterThan(0);
      expect(result.cagr).toBeGreaterThan(0);
      expect(result.winRate).toBe(0.5);
      expect(result.profitFactor).toBe(3);
    });
  });

  describe('cleanupEquityCurvePoints', () => {
    it('should run retention deletion of old intraday/hourly equity curve points', async () => {
      prismaMock.equityCurvePoint.deleteMany.mockResolvedValue({ count: 15 });

      await service.cleanupEquityCurvePoints();

      expect(prismaMock.equityCurvePoint.deleteMany).toHaveBeenCalledTimes(2);
      expect(metricsMock.incrementAnalyticsRetentionDeleted).toHaveBeenCalledWith('INTRADAY', 15);
      expect(metricsMock.incrementAnalyticsRetentionDeleted).toHaveBeenCalledWith('HOURLY', 15);
    });
  });

  describe('handleNightlyAnalyticsRecalculation', () => {
    it('should create job run audit tracking and enqueue sharded tasks', async () => {
      prismaMock.user.findMany.mockResolvedValue([
        { id: 'user-1', status: 'ACTIVE' },
        { id: 'user-2', status: 'ACTIVE' },
      ]);
      prismaMock.analyticsJobRun.create.mockResolvedValue({
        id: 'run-id-123',
        startedAt: new Date(),
        status: AnalyticsRunStatus.RUNNING,
      });

      await service.handleNightlyAnalyticsRecalculation();

      expect(prismaMock.analyticsJobRun.create).toHaveBeenCalled();
      expect(queueMock.addJob).toHaveBeenCalledTimes(2);
    });
  });
});
