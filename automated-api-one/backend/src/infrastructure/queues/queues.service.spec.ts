import { Test, TestingModule } from '@nestjs/testing';
import { ServiceUnavailableException } from '@nestjs/common';
import { QueueService } from './queues.service';
import { RedisService } from '../redis/redis.service';
import { PrismaService } from '../../prisma.service';
import { getQueueToken } from '@nestjs/bullmq';
import { Queues } from './queue.constants';
import { QueueJobStatus } from '@prisma/client';

describe('QueueService', () => {
  let service: QueueService;
  let prismaService: PrismaService;
  let mockQueue: any;

  beforeEach(async () => {
    mockQueue = {
      add: jest.fn().mockResolvedValue({ id: 'job_123' }),
      getJob: jest.fn(),
      getWaitingCount: jest.fn().mockResolvedValue(2),
      getActiveCount: jest.fn().mockResolvedValue(1),
      getFailedCount: jest.fn().mockResolvedValue(0),
      getJobCountByTypes: jest.fn().mockResolvedValue(0),
    };

    const mockPrisma = {
      queueJob: {
        upsert: jest.fn().mockResolvedValue({} as any),
        update: jest.fn().mockResolvedValue({} as any),
      },
    };

    const mockRedis = {
      getClient: jest.fn().mockReturnValue({}),
      assertHealthy: jest.fn(),
      isHealthy: jest.fn().mockReturnValue(true),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        QueueService,
        { provide: RedisService, useValue: mockRedis },
        { provide: PrismaService, useValue: mockPrisma },
        { provide: getQueueToken(Queues.SIGNAL_PROCESSING), useValue: mockQueue },
        { provide: getQueueToken(Queues.ORDER_PLACEMENT), useValue: mockQueue },
        { provide: getQueueToken(Queues.ORDER_MONITORING), useValue: mockQueue },
        { provide: getQueueToken(Queues.NOTIFICATION), useValue: mockQueue },
        { provide: getQueueToken(Queues.SIGNAL_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.ORDER_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.ORDER_MONITORING_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.NOTIFICATION_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.OUTBOX_DISPATCHER), useValue: mockQueue },
        { provide: getQueueToken(Queues.OUTBOX_DISPATCHER_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.WEBSOCKET), useValue: mockQueue },
        { provide: getQueueToken(Queues.WEBSOCKET_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.REPORT_GENERATION), useValue: mockQueue },
        { provide: getQueueToken(Queues.REPORT_GENERATION_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.REPORT_EXPORT), useValue: mockQueue },
        { provide: getQueueToken(Queues.REPORT_EXPORT_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.ANALYTICS_SNAPSHOT), useValue: mockQueue },
        { provide: getQueueToken(Queues.ANALYTICS_SNAPSHOT_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.POSITION_REBUILD), useValue: mockQueue },
        { provide: getQueueToken(Queues.POSITION_REBUILD_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.RECONCILIATION), useValue: mockQueue },
        { provide: getQueueToken(Queues.RECONCILIATION_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.RISK_RECALCULATE), useValue: mockQueue },
        { provide: getQueueToken(Queues.RISK_RECALCULATE_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.ANALYTICS_RECALCULATE), useValue: mockQueue },
        { provide: getQueueToken(Queues.ANALYTICS_RECALCULATE_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.EMAIL), useValue: mockQueue },
        { provide: getQueueToken(Queues.EMAIL_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.SMS), useValue: mockQueue },
        { provide: getQueueToken(Queues.SMS_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.WHATSAPP), useValue: mockQueue },
        { provide: getQueueToken(Queues.WHATSAPP_DLQ), useValue: mockQueue },
        { provide: getQueueToken(Queues.PUSH), useValue: mockQueue },
        { provide: getQueueToken(Queues.PUSH_DLQ), useValue: mockQueue },
        ...Array.from({ length: 10 }, (_, i) => ({
          provide: getQueueToken(`analytics-snapshot-${i}`),
          useValue: mockQueue,
        })),
        ...Array.from({ length: 10 }, (_, i) => ({
          provide: getQueueToken(`analytics-snapshot-dlq-${i}`),
          useValue: mockQueue,
        })),
      ],
    }).compile();

    service = module.get<QueueService>(QueueService);
    prismaService = module.get<PrismaService>(PrismaService);

    // Pre-populate dynamic sharded map with mock queue so real Queue creation is bypassed in tests
    for (let i = 0; i < 10; i++) {
      service['shardedSnapshotQueues'].set(`analytics-snapshot-${i}`, mockQueue);
      service['shardedSnapshotQueues'].set(`analytics-snapshot-dlq-${i}`, mockQueue);
    }
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('addJob', () => {
    it('should upsert job in DB and publish to queue', async () => {
      await service.addJob(Queues.SIGNAL_PROCESSING, 'job_123', { data: 'test' }, 1);
      
      expect(prismaService.queueJob.upsert).toHaveBeenCalledWith({
        where: {
          queueName_jobId: {
            queueName: Queues.SIGNAL_PROCESSING,
            jobId: 'job_123',
          },
        },
        update: {
          payload: { data: 'test' },
          status: QueueJobStatus.ACTIVE,
          attempts: 0,
          updatedAt: expect.any(Date),
        },
        create: {
          queueName: Queues.SIGNAL_PROCESSING,
          jobId: 'job_123',
          payload: { data: 'test' },
          status: QueueJobStatus.ACTIVE,
          attempts: 0,
        },
      });

      expect(mockQueue.add).toHaveBeenCalledWith(
        'job_123',
        { data: 'test' },
        {
          jobId: 'job_123',
          priority: 1,
          attempts: 3,
          backoff: {
            type: 'exponential',
            delay: 1000,
          },
        },
      );
    });

    it('should throw ServiceUnavailableException if queue backpressure limit is exceeded', async () => {
      mockQueue.getWaitingCount.mockResolvedValue(50000); // limit for ORDER_PLACEMENT is 50000

      await expect(
        service.addJob(Queues.ORDER_PLACEMENT, 'job_123', { data: 'test' }),
      ).rejects.toThrow(ServiceUnavailableException);

      expect(prismaService.queueJob.upsert).not.toHaveBeenCalled();
      expect(mockQueue.add).not.toHaveBeenCalled();
    });
  });

  describe('updateJobStatus', () => {
    it('should update job status in database', async () => {
      await service.updateJobStatus(Queues.SIGNAL_PROCESSING, 'job_123', QueueJobStatus.COMPLETED);
      
      expect(prismaService.queueJob.update).toHaveBeenCalledWith({
        where: {
          queueName_jobId: {
            queueName: Queues.SIGNAL_PROCESSING,
            jobId: 'job_123',
          },
        },
        data: {
          status: QueueJobStatus.COMPLETED,
          updatedAt: expect.any(Date),
        },
      });
    });
  });

  describe('getAggregatedMetrics', () => {
    it('should aggregate metrics correctly', async () => {
      const metrics = await service.getAggregatedMetrics();
      expect(metrics).toEqual({
        waiting: 52, // 26 queues * 2 waiting
        active: 26,  // 26 queues * 1 active
        failed: 0,
        dlq: 0,
      });
    });
  });
});
