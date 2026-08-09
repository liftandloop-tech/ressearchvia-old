import { Test, TestingModule } from '@nestjs/testing';
import { OutboxProcessor } from './outbox.processor';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../redis/redis.service';
import { QueueService } from '../queues/queues.service';
import { ConfigService } from '@nestjs/config';
import { OutboxStatus } from '@prisma/client';
import { Queues } from '../queues/queue.constants';
import { MetricsService } from '../metrics/metrics.service';

describe('OutboxProcessor', () => {
  let processor: OutboxProcessor;
  let prismaService: PrismaService;
  let redisService: RedisService;
  let redisClientMock: any;
  let queueService: QueueService;

  const mockMetrics = {
    incrementOutboxEventsProcessed: jest.fn(),
    incrementOutboxEventsFailed: jest.fn(),
    incrementOutboxEventsDlq: jest.fn(),
  };

  beforeEach(async () => {
    const mockPrisma = {
      outboxEvent: {
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
        create: jest.fn(),
      },
    };

    redisClientMock = {
      set: jest.fn(),
    };

    const mockRedis = {
      isHealthy: jest.fn().mockReturnValue(true),
      assertHealthy: jest.fn(),
      getClient: jest.fn().mockReturnValue(redisClientMock),
    };

    const mockQueue = {
      addJob: jest.fn(),
    };

    const mockConfig = {
      get: jest.fn((key, defaultValue) => defaultValue),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OutboxProcessor,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: mockRedis },
        { provide: QueueService, useValue: mockQueue },
        { provide: ConfigService, useValue: mockConfig },
        { provide: MetricsService, useValue: mockMetrics },
      ],
    }).compile();

    processor = module.get<OutboxProcessor>(OutboxProcessor);
    prismaService = module.get<PrismaService>(PrismaService);
    redisService = module.get<RedisService>(RedisService);
    queueService = module.get<QueueService>(QueueService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(processor).toBeDefined();
  });

  describe('process', () => {
    const mockJob = {
      id: 'job-1',
      data: { outboxEventId: 'event-123' },
      attemptsMade: 0,
      opts: { attempts: 5 },
    } as any;

    it('should process event and dispatch to target queues', async () => {
      const mockEvent = {
        id: 'event-123',
        eventType: 'ORDER_FILLED',
        payload: { orderId: 'ord-1' },
        status: OutboxStatus.PENDING,
        attempts: 0,
        eventKey: null,
      };

      jest.spyOn(prismaService.outboxEvent, 'findUnique').mockResolvedValue(mockEvent as any);
      const updateSpy = jest.spyOn(prismaService.outboxEvent, 'update').mockResolvedValue({} as any);

      await processor.process(mockJob);

      expect(prismaService.outboxEvent.findUnique).toHaveBeenCalledWith({ where: { id: 'event-123' } });
      expect(queueService.addJob).toHaveBeenCalledWith(Queues.NOTIFICATION, 'event-123', { orderId: 'ord-1' });
      expect(updateSpy).toHaveBeenCalledWith({
        where: { id: 'event-123' },
        data: { status: OutboxStatus.PROCESSING },
      });
      expect(updateSpy).toHaveBeenCalledWith({
        where: { id: 'event-123' },
        data: {
          status: OutboxStatus.PROCESSED,
          processedAt: expect.any(Date),
          attempts: 1,
        },
      });
    });

    it('should deduplicate and mark PROCESSED without queue dispatch if eventKey exists in Redis', async () => {
      const mockEvent = {
        id: 'event-123',
        eventType: 'ORDER_FILLED',
        payload: { orderId: 'ord-1' },
        status: OutboxStatus.PENDING,
        attempts: 0,
        eventKey: 'ORDER_FILLED:ord-1',
      };

      jest.spyOn(prismaService.outboxEvent, 'findUnique').mockResolvedValue(mockEvent as any);
      redisClientMock.set.mockResolvedValue(null); // Already exists
      const updateSpy = jest.spyOn(prismaService.outboxEvent, 'update').mockResolvedValue({} as any);

      await processor.process(mockJob);

      expect(redisClientMock.set).toHaveBeenCalledWith('outbox:idempotency:ORDER_FILLED:ord-1', '1', 'PX', 604800000, 'NX');
      expect(queueService.addJob).not.toHaveBeenCalled();
      expect(updateSpy).toHaveBeenCalledWith({
        where: { id: 'event-123' },
        data: {
          status: OutboxStatus.PROCESSED,
          processedAt: expect.any(Date),
        },
      });
    });

    it('should update status to PENDING on first dispatch failure', async () => {
      const mockEvent = {
        id: 'event-123',
        eventType: 'ORDER_FILLED',
        payload: { orderId: 'ord-1' },
        status: OutboxStatus.PENDING,
        attempts: 0,
        eventKey: null,
      };

      jest.spyOn(prismaService.outboxEvent, 'findUnique').mockResolvedValue(mockEvent as any);
      jest.spyOn(queueService, 'addJob').mockRejectedValue(new Error('BullMQ connection lost'));
      const updateSpy = jest.spyOn(prismaService.outboxEvent, 'update').mockResolvedValue({} as any);

      await expect(processor.process(mockJob)).rejects.toThrow('BullMQ connection lost');

      expect(updateSpy).toHaveBeenCalledWith({
        where: { id: 'event-123' },
        data: {
          attempts: 1,
          status: OutboxStatus.PENDING,
        },
      });
    });

    it('should mark status as FAILED on the final attempt exhaustion', async () => {
      const mockEvent = {
        id: 'event-123',
        eventType: 'ORDER_FILLED',
        payload: { orderId: 'ord-1' },
        status: OutboxStatus.PENDING,
        attempts: 4,
        eventKey: null,
      };

      const failingJob = {
        ...mockJob,
        attemptsMade: 4,
      };

      jest.spyOn(prismaService.outboxEvent, 'findUnique').mockResolvedValue(mockEvent as any);
      jest.spyOn(queueService, 'addJob').mockRejectedValue(new Error('BullMQ connection lost'));
      const updateSpy = jest.spyOn(prismaService.outboxEvent, 'update').mockResolvedValue({} as any);

      await expect(processor.process(failingJob)).rejects.toThrow('BullMQ connection lost');

      expect(updateSpy).toHaveBeenCalledWith({
        where: { id: 'event-123' },
        data: {
          attempts: 5,
          status: OutboxStatus.FAILED,
        },
      });
    });
  });

  describe('fallbackPoll', () => {
    it('should retrieve stuck pending events and re-enqueue them', async () => {
      const mockStuckEvents = [
        { id: 'stuck-1', eventType: 'ORDER_FILLED', status: OutboxStatus.PENDING, eventKey: null },
      ];

      jest.spyOn(prismaService.outboxEvent, 'findMany').mockResolvedValue(mockStuckEvents as any);

      await processor.fallbackPoll();

      expect(prismaService.outboxEvent.findMany).toHaveBeenCalled();
      expect(queueService.addJob).toHaveBeenCalledWith(
        Queues.OUTBOX_DISPATCHER,
        'stuck-1',
        { 
          outboxEventId: 'stuck-1',
          eventType: 'ORDER_FILLED',
          eventKey: null,
        },
      );
    });
  });
});
