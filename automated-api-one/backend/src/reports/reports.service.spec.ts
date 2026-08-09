import { Test, TestingModule } from '@nestjs/testing';
import { ReportsService } from './reports.service';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { OutboxService } from '../infrastructure/outbox/outbox.service';
import { REPORT_STORAGE_PROVIDER } from './providers/report-storage.provider';
import { Queues } from '../infrastructure/queues/queue.constants';

describe('ReportsService', () => {
  let service: ReportsService;
  let prisma: PrismaService;
  let redis: RedisService;
  let queue: QueueService;
  let metrics: MetricsService;
  let outbox: OutboxService;
  let mockRedisClient: any;

  const mockStorageProvider = {
    upload: jest.fn().mockResolvedValue('/uploads/reports/test.json'),
  };

  beforeEach(async () => {
    mockRedisClient = {
      get: jest.fn(),
      set: jest.fn().mockResolvedValue('OK'),
      del: jest.fn().mockResolvedValue(1),
    };

    const mockModulePrisma = {
      report: {
        create: jest.fn().mockResolvedValue({ id: 'rep-123', userId: 'usr-1', reportType: 'DAILY', status: 'REQUESTED' }),
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      reportExport: {
        create: jest.fn().mockResolvedValue({ id: 'exp-123', userId: 'usr-1', status: 'REQUESTED' }),
      },
      userSegment: {
        findUnique: jest.fn().mockResolvedValue({ capital: 100000 }),
        findMany: jest.fn().mockResolvedValue([]),
      },
      trade: {
        findMany: jest.fn().mockResolvedValue([]),
      },
      analyticsSnapshot: {
        findFirst: jest.fn(),
        upsert: jest.fn().mockResolvedValue({ id: 'snap-123' }),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReportsService,
        {
          provide: PrismaService,
          useValue: mockModulePrisma,
        },
        {
          provide: RedisService,
          useValue: {
            isHealthy: jest.fn().mockReturnValue(true),
            getClient: () => mockRedisClient,
          },
        },
        {
          provide: QueueService,
          useValue: {
            addJob: jest.fn(),
            getQueue: jest.fn().mockReturnValue({
              getWaitingCount: jest.fn().mockResolvedValue(0),
            }),
          },
        },
        {
          provide: MetricsService,
          useValue: {
            incrementReportCacheHits: jest.fn(),
            incrementReportCacheMisses: jest.fn(),
            incrementAnalyticsSnapshotsCreated: jest.fn(),
          },
        },
        {
          provide: OutboxService,
          useValue: {
            createEvent: jest.fn(),
          },
        },
        {
          provide: REPORT_STORAGE_PROVIDER,
          useValue: mockStorageProvider,
        },
      ],
    }).compile();

    service = module.get<ReportsService>(ReportsService);
    prisma = module.get<PrismaService>(PrismaService);
    redis = module.get<RedisService>(RedisService);
    queue = module.get<QueueService>(QueueService);
    metrics = module.get<MetricsService>(MetricsService);
    outbox = module.get<OutboxService>(OutboxService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('parsePeriod', () => {
    it('should parse DAILY format', () => {
      const bounds = service.parsePeriod('DAILY', '2026-06-12');
      expect(bounds.startDate.getUTCFullYear()).toBe(2026);
      expect(bounds.startDate.getUTCMonth()).toBe(5); // June is index 5
      expect(bounds.startDate.getUTCDate()).toBe(12);
      expect(bounds.startDate.getUTCHours()).toBe(0);
      expect(bounds.endDate.getUTCHours()).toBe(23);
    });

    it('should parse MONTHLY format', () => {
      const bounds = service.parsePeriod('MONTHLY', '2026-06');
      expect(bounds.startDate.getUTCFullYear()).toBe(2026);
      expect(bounds.startDate.getUTCMonth()).toBe(5);
      expect(bounds.startDate.getUTCDate()).toBe(1);
      expect(bounds.endDate.getUTCDate()).toBe(30);
    });
  });

  describe('getReportOrEnqueue', () => {
    it('should return COMPLETED status if cache hit', async () => {
      mockRedisClient.get.mockResolvedValue(JSON.stringify({ some: 'data' }));

      const res = await service.getReportOrEnqueue('usr-1', 'DAILY', '2026-06-12');
      expect(res.status).toBe('COMPLETED');
      expect(res.data).toEqual({ some: 'data' });
      expect(metrics.incrementReportCacheHits).toHaveBeenCalled();
    });

    it('should enqueue job and return REQUESTED status if cache miss and lock acquired', async () => {
      mockRedisClient.get.mockResolvedValue(null);
      mockRedisClient.set.mockResolvedValue('OK');

      const res = await service.getReportOrEnqueue('usr-1', 'DAILY', '2026-06-12');
      expect(res.status).toBe('REQUESTED');
      expect(res.reportId).toBe('rep-123');
      expect(prisma.report.create).toHaveBeenCalled();
      expect(queue.addJob).toHaveBeenCalledWith(
        Queues.REPORT_GENERATION,
        'rep-123',
        expect.objectContaining({ reportId: 'rep-123', userId: 'usr-1' }),
        5,
      );
    });

    it('should reject requests and return status QUEUED when queue depth is too large', async () => {
      mockRedisClient.get.mockResolvedValue(null);
      jest.spyOn(queue, 'getQueue').mockReturnValue({
        getWaitingCount: jest.fn().mockResolvedValue(12000), // depth > 10000
      } as any);

      const res = await service.getReportOrEnqueue('usr-1', 'DAILY', '2026-06-12');
      expect(res.status).toBe('QUEUED');
      expect(res.estimatedWait).toBe('later');
      expect(prisma.report.create).not.toHaveBeenCalled();
    });
  });
});
