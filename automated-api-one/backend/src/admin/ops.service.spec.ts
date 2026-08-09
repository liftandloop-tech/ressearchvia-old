import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { OpsService } from './ops.service';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { BrokerSessionService } from '../brokers/services/broker-session.service';
import { OperationsAction, OperationStatus, TradeStatus } from '@prisma/client';
import { ReconciliationService } from '../reconciliation/reconciliation.service';
import { AlertingService } from '../notifications/alerting.service';

describe('OpsService', () => {
  let service: OpsService;
  let prisma: PrismaService;
  let redisService: RedisService;
  let queueService: QueueService;
  let metrics: MetricsService;
  let brokerSessionService: BrokerSessionService;

  const mockRedisClient = {
    set: jest.fn(),
    del: jest.fn(),
    keys: jest.fn(),
    exists: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OpsService,
        {
          provide: PrismaService,
          useValue: {
            signal: { findUnique: jest.fn(), update: jest.fn() },
            segmentMaster: { findUnique: jest.fn() },
            segmentExecution: { findFirst: jest.fn() },
            operationsAudit: { create: jest.fn(), update: jest.fn(), findMany: jest.fn(), deleteMany: jest.fn() },
            outboxEvent: { findUnique: jest.fn(), create: jest.fn() },
            userBroker: { findUnique: jest.fn() },
            trade: { findFirst: jest.fn() },
            userSegment: { findMany: jest.fn() },
          },
        },
        {
          provide: RedisService,
          useValue: {
            isHealthy: jest.fn().mockReturnValue(true),
            getClient: jest.fn().mockReturnValue(mockRedisClient),
          },
        },
        {
          provide: QueueService,
          useValue: {
            addJob: jest.fn(),
            getQueue: jest.fn(),
            getDlqMetrics: jest.fn(),
          },
        },
        {
          provide: MetricsService,
          useValue: {
            incrementOperationsRequests: jest.fn(),
            incrementOperationsSuccess: jest.fn(),
            incrementOperationsFailed: jest.fn(),
            incrementOperationsRejected: jest.fn(),
            incrementQueuePausedTotal: jest.fn(),
            incrementDlqReplayed: jest.fn(),
            incrementDlqPurged: jest.fn(),
            incrementOperationsAuditRecords: jest.fn(),
            incrementOperationsAuditFailures: jest.fn(),
          },
        },
        {
          provide: BrokerSessionService,
          useValue: {
            refreshSession: jest.fn(),
          },
        },
        {
          provide: ReconciliationService,
          useValue: {
            triggerReconciliation: jest.fn().mockResolvedValue('mock-run-id'),
          },
        },
        {
          provide: AlertingService,
          useValue: {
            triggerAlert: jest.fn().mockResolvedValue({}),
            acknowledgeAlert: jest.fn().mockResolvedValue({}),
            resolveAlert: jest.fn().mockResolvedValue({}),
          },
        },
      ],
    }).compile();

    service = module.get<OpsService>(OpsService);
    prisma = module.get<PrismaService>(PrismaService);
    redisService = module.get<RedisService>(RedisService);
    queueService = module.get<QueueService>(QueueService);
    metrics = module.get<MetricsService>(MetricsService);
    brokerSessionService = module.get<BrokerSessionService>(BrokerSessionService);

    (prisma.operationsAudit.create as jest.Mock).mockResolvedValue({ id: 'audit-default-id' });
    jest.clearAllMocks();
  });

  describe('replaySignal', () => {
    it('should throw NotFoundException if signal does not exist', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      (prisma.signal.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(service.replaySignal('op-123', 'signal-999')).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException if segment does not exist', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      (prisma.signal.findUnique as jest.Mock).mockResolvedValue({ id: 'signal-1', segmentId: 'seg-1' });
      (prisma.segmentMaster.findUnique as jest.Mock).mockResolvedValue(null);

      await expect(service.replaySignal('op-123', 'signal-1')).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException if segment is locked in Redis', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      (prisma.signal.findUnique as jest.Mock).mockResolvedValue({ id: 'signal-1', segmentId: 'seg-1' });
      (prisma.segmentMaster.findUnique as jest.Mock).mockResolvedValue({ id: 'seg-1' });
      mockRedisClient.exists.mockResolvedValue(1);

      await expect(service.replaySignal('op-123', 'signal-1')).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException if signal is currently PROCESSING', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      (prisma.signal.findUnique as jest.Mock).mockResolvedValue({ id: 'signal-1', segmentId: 'seg-1' });
      (prisma.segmentMaster.findUnique as jest.Mock).mockResolvedValue({ id: 'seg-1' });
      mockRedisClient.exists.mockResolvedValue(0);
      (prisma.segmentExecution.findFirst as jest.Mock).mockResolvedValue({ id: 'exec-1', state: 'PROCESSING' });
      (prisma.operationsAudit.create as jest.Mock).mockResolvedValue({ id: 'audit-1' });

      await expect(service.replaySignal('op-123', 'signal-1')).rejects.toThrow(BadRequestException);
    });

    it('should re-enqueue signal and log operations audit successfully', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      (prisma.signal.findUnique as jest.Mock).mockResolvedValue({ id: 'signal-1', segmentId: 'seg-1' });
      (prisma.segmentMaster.findUnique as jest.Mock).mockResolvedValue({ id: 'seg-1' });
      mockRedisClient.exists.mockResolvedValue(0);
      (prisma.segmentExecution.findFirst as jest.Mock).mockResolvedValue(null);
      (prisma.operationsAudit.create as jest.Mock).mockResolvedValue({ id: 'audit-1' });

      const res = await service.replaySignal('op-123', 'signal-1');

      expect(res.operationId).toBeDefined();
      expect(queueService.addJob).toHaveBeenCalledWith(
        'trade-execution',
        expect.stringContaining('signal:signal-1:'),
        { signalId: 'signal-1' },
      );
      expect(prisma.operationsAudit.create).toHaveBeenCalled();
      expect(metrics.incrementOperationsSuccess).toHaveBeenCalledWith(OperationsAction.REPLAY_SIGNAL);
    });
  });

  describe('replayOutboxEvent', () => {
    it('should clone and enqueue outbox event', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      (prisma.outboxEvent.findUnique as jest.Mock).mockResolvedValue({
        id: 'outbox-1',
        eventType: 'ORDER_PLACED',
        eventKey: 'key-1',
        aggregateId: 'agg-1',
        version: 1,
        payload: { x: 1 },
      });
      (prisma.operationsAudit.create as jest.Mock).mockResolvedValue({ id: 'audit-1' });
      (prisma.outboxEvent.create as jest.Mock).mockResolvedValue({ id: 'outbox-2' });

      const res = await service.replayOutboxEvent('op-123', 'outbox-1');

      expect(res.operationId).toBeDefined();
      expect(prisma.outboxEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            eventType: 'ORDER_PLACED',
            status: 'PENDING',
          }),
        }),
      );
      expect(queueService.addJob).toHaveBeenCalledWith(
        'outbox-dispatcher',
        'outbox-2',
        { outboxEventId: 'outbox-2' },
      );
    });
  });

  describe('replayDlqJob', () => {
    it('should throw BadRequestException if replayCount is >= 3', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      const mockQueue = {
        getJob: jest.fn().mockResolvedValue({
          id: 'job-1',
          data: { replayCount: 3 },
          remove: jest.fn(),
        }),
      };
      (queueService.getQueue as jest.Mock).mockReturnValue(mockQueue);

      await expect(
        service.replayDlqJob('op-123', 'order-placement-dlq', 'job-1'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should increment replayCount and re-enqueue job if replayCount < 3', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      const mockJob = {
        id: 'job-1',
        data: { replayCount: 1, payload: 'data' },
        remove: jest.fn(),
      };
      const mockQueue = {
        getJob: jest.fn().mockResolvedValue(mockJob),
      };
      (queueService.getQueue as jest.Mock).mockReturnValue(mockQueue);

      const res = await service.replayDlqJob('op-123', 'order-placement-dlq', 'job-1');

      expect(res.operationId).toBeDefined();
      expect(queueService.addJob).toHaveBeenCalledWith(
        'order-placement',
        'job-1',
        { replayCount: 2, payload: 'data' },
      );
      expect(mockJob.remove).toHaveBeenCalled();
    });
  });

  describe('forceBrokerSessionRefresh', () => {
    it('should throw BadRequestException if session refresh requested within 60s rate limit', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      (prisma.userBroker.findUnique as jest.Mock).mockResolvedValue({ id: 'ub-1', userId: 'u-1', brokerId: 'b-1', broker: { code: 'ZERODHA' } });
      mockRedisClient.exists.mockResolvedValue(1); // rate limited

      await expect(
        service.forceBrokerSessionRefresh('op-123', 'ub-1'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should successfully refresh broker session if rate limit not active', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      (prisma.userBroker.findUnique as jest.Mock).mockResolvedValue({ id: 'ub-1', userId: 'u-1', brokerId: 'b-1', broker: { code: 'ZERODHA' } });
      mockRedisClient.exists.mockResolvedValue(0); // not rate limited

      const res = await service.forceBrokerSessionRefresh('op-123', 'ub-1');

      expect(res.operationId).toBeDefined();
      expect(brokerSessionService.refreshSession).toHaveBeenCalledWith('u-1', 'ZERODHA');
    });
  });

  describe('pauseQueue', () => {
    it('should throw BadRequestException if order queue is paused during market hours without force', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      jest.spyOn(service as any, 'isMarketHours').mockReturnValue(true);

      await expect(
        service.pauseQueue('op-123', 'order-placement', false),
      ).rejects.toThrow(BadRequestException);
    });

    it('should successfully pause order queue during market hours if force is true', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      jest.spyOn(service as any, 'isMarketHours').mockReturnValue(true);
      (prisma.operationsAudit.create as jest.Mock).mockResolvedValue({ id: 'audit-1' });
      const mockQueue = { pause: jest.fn() };
      (queueService.getQueue as jest.Mock).mockReturnValue(mockQueue);

      await service.pauseQueue('op-123', 'order-placement', true);

      expect(mockQueue.pause).toHaveBeenCalled();
      expect(metrics.incrementQueuePausedTotal).toHaveBeenCalledWith('order-placement');
    });
  });

  describe('replaySignal Limits', () => {
    it('should throw BadRequestException if replayCount >= 5', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      (prisma.signal.findUnique as jest.Mock).mockResolvedValue({
        id: 'signal-1',
        segmentId: 'seg-1',
        metadata: { replayCount: 5 },
      });

      await expect(service.replaySignal('op-123', 'signal-1')).rejects.toThrow(BadRequestException);
    });
  });

  describe('drainQueue', () => {
    it('should throw BadRequestException if reason is empty', async () => {
      await expect(service.drainQueue('op-123', 'order-placement', '')).rejects.toThrow(BadRequestException);
    });

    it('should drain queue and mark active jobs as CANCELLED', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      const mockQueue = { drain: jest.fn() };
      (queueService.getQueue as jest.Mock).mockReturnValue(mockQueue);
      
      const mockJobs = [{ id: 'job-1' }];
      const prismaMock = prisma as any;
      prismaMock.queueJob = {
        findMany: jest.fn().mockResolvedValue(mockJobs),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      };

      const res = await service.drainQueue('op-123', 'order-placement', 'Broker crash');
      expect(res.operationId).toBeDefined();
      expect(mockQueue.drain).toHaveBeenCalled();
      expect(prismaMock.queueJob.updateMany).toHaveBeenCalledWith({
        where: { queueName: 'order-placement', status: 'ACTIVE' },
        data: { status: 'CANCELLED', updatedAt: expect.any(Date) },
      });
    });
  });

  describe('Granular Maintenance Mode', () => {
    it('should setRedis key for enableMaintenance', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      const res = await service.enableMaintenance('op-123', 'signals');
      expect(res.operationId).toBeDefined();
      expect(mockRedisClient.set).toHaveBeenCalledWith('system:maintenance:signals', 'true');
    });

    it('should delete Redis key for disableMaintenance', async () => {
      mockRedisClient.del.mockResolvedValue(1);
      const res = await service.disableMaintenance('op-123', 'signals');
      expect(res.operationId).toBeDefined();
      expect(mockRedisClient.del).toHaveBeenCalledWith('system:maintenance:signals');
    });
  });

  describe('Trading Kill Switch with TTL', () => {
    it('should set global trading disabled with 15 min TTL on stopTrading', async () => {
      mockRedisClient.set.mockResolvedValue('OK');
      const res = await service.stopTrading('op-123', false, 'Emergency');
      expect(res.operationId).toBeDefined();
      expect(mockRedisClient.set).toHaveBeenCalledWith(
        'trading:global:disabled',
        expect.stringContaining('"enabled":true'),
        'EX',
        900,
      );
    });

    it('should del global trading disabled on startTrading', async () => {
      mockRedisClient.del.mockResolvedValue(1);
      const res = await service.startTrading('op-123');
      expect(res.operationId).toBeDefined();
      expect(mockRedisClient.del).toHaveBeenCalledWith('trading:global:disabled');
    });
  });
});

