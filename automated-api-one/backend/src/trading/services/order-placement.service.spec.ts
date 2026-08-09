import { Test, TestingModule } from '@nestjs/testing';
import { OrderPlacementService } from './order-placement.service';
import { PrismaService } from '../../prisma.service';
import { BrokerFactory } from '../../brokers/factory/broker.factory';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { BrokerRateLimiterService } from '../../infrastructure/redis/broker-rate-limiter.service';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { AuditService } from '../../audit/audit.service';
import { PositionCacheService } from './position-cache.service';
import { ConfigService } from '@nestjs/config';
import { ExecutionContext } from '../interfaces/execution-context.interface';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { RiskService } from '../../risk/risk.service';

const mockAdapter = { placeOrder: jest.fn() };
const mockBrokerFactory = { getAdapter: jest.fn().mockReturnValue(mockAdapter) };
const mockCircuitBreaker = { execute: jest.fn().mockImplementation((_broker, fn) => fn()) };
const mockRateLimiter = { throttle: jest.fn().mockResolvedValue(true) };
const mockOutbox = {
  createEvent: jest.fn().mockResolvedValue({}),
  enqueueEvent: jest.fn().mockResolvedValue(undefined),
};
const mockAuditService = { logEvent: jest.fn().mockResolvedValue(undefined) };
const mockPositionCache = { set: jest.fn().mockResolvedValue(undefined) };
const mockConfigService = { get: jest.fn().mockReturnValue(5000) };
const mockRiskService = { evaluateRisk: jest.fn().mockResolvedValue({ approved: true }) };
const mockMetrics = {
  incrementSignalsReceived: jest.fn(),
  incrementSignalsProcessed: jest.fn(),
  incrementSignalsFailed: jest.fn(),
  incrementOrdersPlaced: jest.fn(),
  incrementOrdersFilled: jest.fn(),
  incrementOrdersRejected: jest.fn(),
  incrementRiskRejected: jest.fn(),
  incrementBrokerTimeout: jest.fn(),
  incrementCircuitBreakerOpen: jest.fn(),
  incrementRedisLockContention: jest.fn(),
  setQueueDepth: jest.fn(),
  setActiveWorkers: jest.fn(),
  setOpenPositions: jest.fn(),
  incrementBrokerCalls: jest.fn(),
  incrementBrokerFailures: jest.fn(),
  incrementBrokerTimeouts: jest.fn(),
  incrementOrderPlacementAttempts: jest.fn(),
  incrementExecutionSuccess: jest.fn(),
  incrementExecutionFailed: jest.fn(),
  observeBrokerLatency: jest.fn(),
  observeOrderPlacementDuration: jest.fn(),
};

const mockRedisClient = { get: jest.fn() };
const mockRedisService = {
  isHealthy: jest.fn(),
  getClient: jest.fn().mockReturnValue(mockRedisClient),
};

const mockTrade = { id: 'trade-abc', userId: 'user-1', segmentId: 'seg-1' };
const mockOrder = { id: 'order-abc' };

const mockPrisma = {
  userBroker: { findFirst: jest.fn() },
  $transaction: jest.fn(),
};

describe('OrderPlacementService', () => {
  let service: OrderPlacementService;

  const ctx: ExecutionContext = {
    correlationId: 'corr-001',
    jobId: 'job:signal-1:user-1',
    signalId: 'signal-1',
    segmentId: 'seg-1',
    symbol: 'NIFTY50',
    exchange: 'NSE',
    side: 'BUY',
    entryPrice: 22000,
    stopLoss: 21800,
    targetPrice: 22300,
    snapshot: {
      userId: 'user-1',
      brokerId: 'broker-1',
      brokerCode: 'ANGEL_ONE',
      brokerClientId: 'CLIENT001',
      segmentId: 'seg-1',
      subscriptionPlan: 'SPARK',
      multiplierIndex: 0,
      multiplierValue: 1,
      capitalAllocated: 100000,
      baseLot: 10,
      effectiveLot: 10,
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrderPlacementService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: BrokerFactory, useValue: mockBrokerFactory },
        { provide: CircuitBreakerService, useValue: mockCircuitBreaker },
        { provide: BrokerRateLimiterService, useValue: mockRateLimiter },
        { provide: OutboxService, useValue: mockOutbox },
        { provide: RedisService, useValue: mockRedisService },
        { provide: AuditService, useValue: mockAuditService },
        { provide: PositionCacheService, useValue: mockPositionCache },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: MetricsService, useValue: mockMetrics },
        { provide: RiskService, useValue: mockRiskService },
      ],
    }).compile();

    service = module.get<OrderPlacementService>(OrderPlacementService);
    jest.clearAllMocks();
  });

  describe('broker session resolution', () => {
    it('should return failure if no broker session in Redis or DB', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.get.mockResolvedValue(null); // Redis miss
      mockPrisma.userBroker.findFirst.mockResolvedValue(null); // DB miss

      const result = await service.placeEntryOrder(ctx);

      expect(result.success).toBe(false);
      expect(result.reason).toContain('No active broker session');
    });

    it('should use Redis-cached token and skip DB when Redis is healthy', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.get.mockResolvedValue(JSON.stringify({ accessToken: 'redis-token-999' }));
      mockCircuitBreaker.execute.mockRejectedValue(new Error('Circuit open'));

      await service.placeEntryOrder(ctx);

      // DB should NOT be called — token came from Redis
      expect(mockPrisma.userBroker.findFirst).not.toHaveBeenCalled();
    });

    it('should fall back to DB when Redis returns null', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.get.mockResolvedValue(null);
      mockPrisma.userBroker.findFirst.mockResolvedValue({ accessToken: 'db-token-456' });
      mockCircuitBreaker.execute.mockRejectedValue(new Error('Broker error'));

      await service.placeEntryOrder(ctx);

      expect(mockPrisma.userBroker.findFirst).toHaveBeenCalled();
    });

    it('should fall back to DB when Redis read throws', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.get.mockRejectedValue(new Error('Redis timeout'));
      mockPrisma.userBroker.findFirst.mockResolvedValue({ accessToken: 'db-token-789' });
      mockCircuitBreaker.execute.mockRejectedValue(new Error('Broker error'));

      await service.placeEntryOrder(ctx);

      // Should not throw — fell back to DB
      expect(mockPrisma.userBroker.findFirst).toHaveBeenCalled();
    });

    it('should use DB directly when Redis is unhealthy', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);
      mockPrisma.userBroker.findFirst.mockResolvedValue({ accessToken: 'db-token-direct' });
      mockCircuitBreaker.execute.mockRejectedValue(new Error('Broker error'));

      await service.placeEntryOrder(ctx);

      expect(mockRedisClient.get).not.toHaveBeenCalled();
      expect(mockPrisma.userBroker.findFirst).toHaveBeenCalled();
    });
  });

  describe('order placement flow', () => {
    it('should return failure if broker API throws', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);
      mockPrisma.userBroker.findFirst.mockResolvedValue({ accessToken: 'token-123' });
      mockCircuitBreaker.execute.mockRejectedValue(new Error('Network error'));

      const result = await service.placeEntryOrder(ctx);

      expect(result.success).toBe(false);
      expect(result.reason).toContain('Network error');
    });

    it('should call rateLimiter.throttle before broker call', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);
      mockPrisma.userBroker.findFirst.mockResolvedValue({ accessToken: 'token-123' });
      mockCircuitBreaker.execute.mockRejectedValue(new Error('Broker error'));

      await service.placeEntryOrder(ctx);

      expect(mockRateLimiter.throttle).toHaveBeenCalledWith('ANGEL_ONE');
    });

    it('should write Trade + Order + Outbox atomically in $transaction', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);
      mockPrisma.userBroker.findFirst.mockResolvedValue({ accessToken: 'token-123' });
      // Adapter must return a brokerOrderId to proceed to $transaction
      mockAdapter.placeOrder.mockResolvedValue({ brokerOrderId: 'BROKER-ORDER-001' });
      mockCircuitBreaker.execute.mockImplementation((_b, fn) => fn());
      mockPrisma.$transaction.mockResolvedValue({ trade: mockTrade, order: mockOrder, outboxEvent: { id: 'outbox-abc', eventType: 'TRADE_OPENED', eventKey: null } });

      await service.placeEntryOrder(ctx);

      expect(mockRateLimiter.throttle).toHaveBeenCalledWith('ANGEL_ONE');
      expect(mockPrisma.$transaction).toHaveBeenCalled();
    });
  });
});
