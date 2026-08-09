import { Test, TestingModule } from '@nestjs/testing';
import { ReportGenerationProcessor, ReportExportProcessor } from './report-generation.processor';
import { AnalyticsSnapshotProcessor } from './analytics-snapshot.processor';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { ReportsService } from '../reports.service';
import { REPORT_STORAGE_PROVIDER } from '../providers/report-storage.provider';
import { Job } from 'bullmq';

describe('Report Processors', () => {
  let reportProcessor: ReportGenerationProcessor;
  let exportProcessor: ReportExportProcessor;
  let snapshotProcessor: AnalyticsSnapshotProcessor;
  let prisma: PrismaService;
  let redis: RedisService;
  let outbox: OutboxService;
  let reportsService: ReportsService;
  let mockRedisClient: any;

  const mockStorageProvider = {
    upload: jest.fn().mockResolvedValue('/uploads/reports/test.json'),
  };

  beforeEach(async () => {
    mockRedisClient = {
      set: jest.fn().mockResolvedValue('OK'),
      del: jest.fn().mockResolvedValue(1),
    };

    const mockPrisma = {
      report: {
        update: jest.fn().mockResolvedValue({ id: 'rep-123', userId: 'usr-1', reportType: 'DAILY', fileUrl: '/uploads/reports/test.json', generatedAt: new Date() }),
      },
      reportExport: {
        update: jest.fn().mockResolvedValue({ id: 'exp-123' }),
      },
      userSegment: {
        findMany: jest.fn().mockResolvedValue([{ segmentId: 'seg-1' }]),
      },
      analyticsSnapshot: {
        findFirst: jest.fn().mockResolvedValue({}),
        findMany: jest.fn().mockResolvedValue([
          {
            realizedPnl: 100,
            unrealizedPnl: 10,
            totalTrades: 2,
            winningTrades: 1,
            losingTrades: 1,
            roi: 1,
          },
        ]),
      },
    };

    const mockReportsService = {
      parsePeriod: jest.fn().mockReturnValue({
        startDate: new Date('2026-06-12T00:00:00Z'),
        endDate: new Date('2026-06-12T23:59:59Z'),
      }),
      calculateAndUpsertSnapshot: jest.fn(),
      cacheReport: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReportGenerationProcessor,
        ReportExportProcessor,
        AnalyticsSnapshotProcessor,
        { provide: PrismaService, useValue: mockPrisma },
        {
          provide: RedisService,
          useValue: {
            getClient: () => mockRedisClient,
          },
        },
        {
          provide: MetricsService,
          useValue: {
            incrementReportsGenerated: jest.fn(),
            incrementReportGenerationFailed: jest.fn(),
            observeReportGenerationDuration: jest.fn(),
          },
        },
        {
          provide: OutboxService,
          useValue: {
            createEvent: jest.fn(),
          },
        },
        {
          provide: ReportsService,
          useValue: mockReportsService,
        },
        {
          provide: REPORT_STORAGE_PROVIDER,
          useValue: mockStorageProvider,
        },
      ],
    }).compile();

    reportProcessor = module.get<ReportGenerationProcessor>(ReportGenerationProcessor);
    exportProcessor = module.get<ReportExportProcessor>(ReportExportProcessor);
    snapshotProcessor = module.get<AnalyticsSnapshotProcessor>(AnalyticsSnapshotProcessor);
    prisma = module.get<PrismaService>(PrismaService);
    redis = module.get<RedisService>(RedisService);
    outbox = module.get<OutboxService>(OutboxService);
    reportsService = module.get<ReportsService>(ReportsService);
  });

  describe('ReportGenerationProcessor', () => {
    it('should skip processing if stampede lock not acquired', async () => {
      mockRedisClient.set.mockResolvedValue('BUSY'); // Lock not acquired

      const mockJob = {
        id: 'job-1',
        data: { reportId: 'rep-123', userId: 'usr-1', type: 'DAILY', period: '2026-06-12' },
      } as Job;

      await reportProcessor.process(mockJob);

      expect(prisma.report.update).not.toHaveBeenCalled();
    });

    it('should process generation and publish outbox event if lock acquired', async () => {
      mockRedisClient.set.mockResolvedValue('OK'); // Lock acquired

      const mockJob = {
        id: 'job-1',
        data: { reportId: 'rep-123', userId: 'usr-1', type: 'DAILY', period: '2026-06-12' },
      } as Job;

      await reportProcessor.process(mockJob);

      expect(prisma.report.update).toHaveBeenCalledWith({
        where: { id: 'rep-123' },
        data: { status: 'PROCESSING' },
      });
      expect(outbox.createEvent).toHaveBeenCalledWith(
        'REPORT_READY',
        expect.objectContaining({ reportId: 'rep-123', userId: 'usr-1' }),
        undefined,
        expect.objectContaining({ aggregateId: 'rep-123' }),
      );
    });
  });
});
