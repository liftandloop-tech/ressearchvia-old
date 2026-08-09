import { Test, TestingModule } from '@nestjs/testing';
import { ReconciliationService } from './reconciliation.service';
import { ReconciliationProcessor } from './reconciliation.processor';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { BrokerRegistry } from '../brokers/registry/broker.registry';
import { OutboxService } from '../infrastructure/outbox/outbox.service';
import { ReconciliationStatus, OrderStatus, Severity, ReconciliationIssueType } from '@prisma/client';

describe('Reconciliation Engine Tests', () => {
  let reconciliationService: ReconciliationService;
  let reconciliationProcessor: ReconciliationProcessor;

  // Mock structures
  const mockUserBroker = {
    id: 'ub-123',
    userId: 'user-123',
    brokerId: 'broker-123',
    brokerClientId: 'client-123',
    accessToken: 'valid_token',
    broker: {
      id: 'broker-123',
      code: 'ANGEL_ONE',
    },
  };

  const mockPrismaService = {
    userBroker: {
      findMany: jest.fn().mockResolvedValue([mockUserBroker]),
      findFirst: jest.fn().mockResolvedValue(mockUserBroker),
    },
    reconciliationRun: {
      create: jest.fn().mockResolvedValue({ id: 'run-123' }),
      update: jest.fn().mockResolvedValue({}),
      findUnique: jest.fn().mockResolvedValue({
        id: 'run-123',
        shards: [
          { status: ReconciliationStatus.COMPLETED, issuesFound: 0 },
        ],
      }),
    },
    reconciliationShard: {
      create: jest.fn().mockResolvedValue({}),
      update: jest.fn().mockResolvedValue({}),
    },
    reconciliationIssue: {
      count: jest.fn().mockResolvedValue(0),
      findUnique: jest.fn().mockResolvedValue(null),
      create: jest.fn().mockResolvedValue({}),
      update: jest.fn().mockResolvedValue({}),
    },
    reconciliationSnapshot: {
      upsert: jest.fn().mockResolvedValue({}),
    },
    trade: {
      findMany: jest.fn().mockResolvedValue([]),
      update: jest.fn().mockResolvedValue({}),
    },
    order: {
      findMany: jest.fn().mockResolvedValue([]),
      update: jest.fn().mockResolvedValue({}),
    },
    position: {
      findMany: jest.fn().mockResolvedValue([]),
    },
    operationsAudit: {
      create: jest.fn().mockResolvedValue({}),
    },
    outboxEvent: {
      create: jest.fn().mockResolvedValue({}),
    },
  };

  const mockRedisService = {
    isHealthy: jest.fn().mockReturnValue(true),
    getClient: jest.fn().mockReturnValue({
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockResolvedValue('OK'),
      del: jest.fn().mockResolvedValue(1),
    }),
  };

  const mockQueueService = {
    addJob: jest.fn().mockResolvedValue({}),
  };

  const mockMetricsService = {
    incrementReconciliationRuns: jest.fn(),
    incrementReconciliationIssuesTotal: jest.fn(),
    setReconciliationIssuesOpen: jest.fn(),
    incrementReconciliationAutoResolved: jest.fn(),
    incrementReconciliationFailed: jest.fn(),
    observeReconciliationDuration: jest.fn(),
  };

  const mockBrokerAdapter = {
    getTradeBook: jest.fn().mockResolvedValue([]),
    getOrderDetails: jest.fn().mockResolvedValue({ status: 'complete', orderid: 'ord-123' }),
    getPositions: jest.fn().mockResolvedValue([]),
  };

  const mockBrokerRegistry = {
    get: jest.fn().mockReturnValue(mockBrokerAdapter),
  };

  const mockOutboxService = {
    createEvent: jest.fn().mockResolvedValue({}),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ReconciliationService,
        ReconciliationProcessor,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: RedisService, useValue: mockRedisService },
        { provide: QueueService, useValue: mockQueueService },
        { provide: MetricsService, useValue: mockMetricsService },
        { provide: BrokerRegistry, useValue: mockBrokerRegistry },
        { provide: OutboxService, useValue: mockOutboxService },
      ],
    }).compile();

    reconciliationService = module.get<ReconciliationService>(ReconciliationService);
    reconciliationProcessor = module.get<ReconciliationProcessor>(ReconciliationProcessor);
  });

  describe('ReconciliationService', () => {
    it('should successfully trigger reconciliation and enqueue shards', async () => {
      const runId = await reconciliationService.triggerReconciliation('operator-1');
      expect(runId).toBeDefined();
      expect(mockPrismaService.reconciliationRun.create).toHaveBeenCalled();
      expect(mockPrismaService.reconciliationShard.create).toHaveBeenCalled();
      expect(mockQueueService.addJob).toHaveBeenCalled();
    });

    it('should reconcile user broker and register issues on mismatches', async () => {
      // Setup some trade mismatches
      mockBrokerAdapter.getTradeBook.mockResolvedValueOnce([
        { tradeId: 't-123', orderId: 'ord-123', symbol: 'SBIN-EQ', quantity: 10, price: 750, side: 'BUY' },
      ]);
      mockPrismaService.trade.findMany.mockResolvedValueOnce([]); // DB empty -> mismatch expected

      await reconciliationService.reconcileUserBroker('user-123', 'run-123');

      expect(mockBrokerAdapter.getTradeBook).toHaveBeenCalled();
      expect(mockOutboxService.createEvent).toHaveBeenCalledWith(
        'RECONCILIATION_ISSUE',
        expect.objectContaining({
          issueType: ReconciliationIssueType.TRADE_MISSING_IN_DB,
          severity: Severity.CRITICAL,
        }),
      );
    });

    it('should perform safe auto-resolution on order status mismatched details', async () => {
      // Pending order in DB, complete in Broker
      mockPrismaService.order.findMany.mockResolvedValueOnce([
        { id: 'o-pending', brokerOrderId: 'ord-123', status: OrderStatus.PENDING, tradeId: 'tr-123' },
      ]);
      mockBrokerAdapter.getOrderDetails.mockResolvedValueOnce({ status: 'complete', orderid: 'ord-123' });

      await reconciliationService.reconcileUserBroker('user-123', 'run-123');

      expect(mockPrismaService.order.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'o-pending' },
          data: { status: OrderStatus.FILLED },
        }),
      );
      expect(mockPrismaService.operationsAudit.create).toHaveBeenCalled();
    });
  });

  describe('ReconciliationProcessor', () => {
    it('should invoke reconcileUserBroker on processor execution', async () => {
      const job: any = { id: 'job-1', data: { userId: 'user-123', runId: 'run-123' } };
      const reconcileSpy = jest.spyOn(reconciliationService, 'reconcileUserBroker').mockResolvedValue(undefined);

      await reconciliationProcessor.process(job);

      expect(reconcileSpy).toHaveBeenCalledWith('user-123', 'run-123');
    });
  });
});
