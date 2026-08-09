import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { RiskService } from './risk.service';
import { PrismaService } from '../prisma.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import {
  UserSegmentStatus,
  Prisma,
  BrokerStatus,
  TradeStatus,
} from '@prisma/client';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { ConsentsService } from '../consents/consents.service';
import { BrokerSessionService } from '../brokers/services/broker-session.service';
import { BrokerFactory } from '../brokers/factory/broker.factory';
import { AuditService } from '../audit/audit.service';
import { RiskCode } from './enums/risk-code.enum';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { OutboxService } from '../infrastructure/outbox/outbox.service';

describe('RiskService', () => {
  let service: RiskService;
  let prismaMock: any;
  let subscriptionsMock: any;
  let consentsMock: any;
  let brokerSessionMock: any;
  let brokerFactoryMock: any;
  let auditMock: any;
  let mockAdapter: any;
  let redisMock: any;
  let queueMock: any;
  let metricsMock: any;
  let outboxMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    subscriptionsMock = {
      validateSubscription: jest.fn().mockResolvedValue({
        active: true,
        plan: 'SPARK',
        expiresAt: new Date(),
      }),
    };
    consentsMock = {
      hasTodayConsent: jest.fn().mockResolvedValue(true),
    };
    brokerSessionMock = {
      validateSession: jest.fn().mockResolvedValue(true),
      refreshSession: jest.fn().mockResolvedValue({ accessToken: 'new-token' }),
    };
    mockAdapter = {
      getFunds: jest.fn().mockResolvedValue({
        availableMargin: 10000,
        usedMargin: 0,
        totalMargin: 10000,
      }),
    };
    brokerFactoryMock = {
      getAdapter: jest.fn().mockReturnValue(mockAdapter),
    };
    auditMock = {
      logEvent: jest.fn().mockResolvedValue({}),
    };
    redisMock = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue(null),
        set: jest.fn().mockResolvedValue('OK'),
        del: jest.fn().mockResolvedValue(1),
      }),
    };
    queueMock = {
      addJob: jest.fn().mockResolvedValue({}),
    };
    metricsMock = {
      incrementRiskViolations: jest.fn(),
      incrementRiskUsersBlocked: jest.fn(),
      setRiskDailyPnl: jest.fn(),
      setRiskState: jest.fn(),
    };
    outboxMock = {
      createEvent: jest.fn().mockResolvedValue({ id: 'evt-1' }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RiskService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: SubscriptionsService, useValue: subscriptionsMock },
        { provide: ConsentsService, useValue: consentsMock },
        { provide: BrokerSessionService, useValue: brokerSessionMock },
        { provide: BrokerFactory, useValue: brokerFactoryMock },
        { provide: AuditService, useValue: auditMock },
        { provide: RedisService, useValue: redisMock },
        { provide: QueueService, useValue: queueMock },
        { provide: MetricsService, useValue: metricsMock },
        { provide: OutboxService, useValue: outboxMock },
      ],
    }).compile();

    service = module.get<RiskService>(RiskService);
  });

  describe('validateExecution Pipeline', () => {
    const testUserId = 'user-123';
    const testSegmentId = 'strat-123';

    beforeEach(() => {
      // Mock basic setup success cases
      prismaMock.userBroker.findFirst.mockResolvedValue({
        id: 'ub-1',
        accessToken: 'token-123',
        brokerClientId: 'CLIENT001',
        broker: { code: 'ANGEL_ONE' },
      });

      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-123',
        userId: testUserId,
        segmentId: testSegmentId,
        capital: new Prisma.Decimal(10000),
        backupCapital: new Prisma.Decimal(2000),
        baseLot: 1,
        maxMultiplier: 4,
        dailyLossLimit: new Prisma.Decimal(5000),
        status: UserSegmentStatus.ACTIVE,
      });

      prismaMock.trade.findMany.mockResolvedValue([]);
      prismaMock.segmentMultiplier.findFirst.mockResolvedValue(null);
      prismaMock.riskEvent.create.mockResolvedValue({ id: 're-1' });
    });

    it('should approve execution if all validators pass', async () => {
      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(true);
      expect(auditMock.logEvent).toHaveBeenCalledWith(
        testUserId,
        'RISK_APPROVED',
        'SegmentMaster',
        testSegmentId,
        expect.any(Object),
      );
    });

    it('should reject when subscription is inactive', async () => {
      subscriptionsMock.validateSubscription.mockResolvedValue({
        active: false,
      });

      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(false);
      expect(result.code).toBe(RiskCode.NO_SUBSCRIPTION);
      expect(prismaMock.riskEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ eventType: 'NO_SUBSCRIPTION' }),
        }),
      );
    });

    it('should reject when daily consent is not granted', async () => {
      consentsMock.hasTodayConsent.mockResolvedValue(false);

      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(false);
      expect(result.code).toBe(RiskCode.NO_CONSENT);
    });

    it('should reject and try refresh when broker session is invalid', async () => {
      brokerSessionMock.validateSession
        .mockResolvedValueOnce(false)
        .mockResolvedValueOnce(true);

      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(true); // Should pass after refresh
      expect(brokerSessionMock.refreshSession).toHaveBeenCalled();
    });

    it('should reject when broker session refresh throws error', async () => {
      brokerSessionMock.validateSession.mockResolvedValue(false);
      brokerSessionMock.refreshSession.mockRejectedValue(
        new Error('Refresh Error'),
      );

      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(false);
      expect(result.code).toBe(RiskCode.SESSION_EXPIRED);
    });

    it('should reject when allocated capital is less than estimatedCost', async () => {
      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-123',
        userId: testUserId,
        segmentId: testSegmentId,
        capital: new Prisma.Decimal(2000), // less than 3000
        maxMultiplier: 4,
        dailyLossLimit: new Prisma.Decimal(5000),
        status: UserSegmentStatus.ACTIVE,
      });

      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(false);
      expect(result.code).toBe(RiskCode.INSUFFICIENT_CAPITAL);
    });

    it('should reject when broker margin available is less than estimatedCost', async () => {
      mockAdapter.getFunds.mockResolvedValue({
        availableMargin: 2000,
        usedMargin: 0,
        totalMargin: 10000,
      });

      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(false);
      expect(result.code).toBe(RiskCode.INSUFFICIENT_MARGIN);
    });

    it('should reject, pause segment and trigger risk lock when daily loss limit is hit', async () => {
      prismaMock.trade.findMany.mockResolvedValue([
        {
          id: 't-1',
          pnl: new Prisma.Decimal(-6000),
          status: TradeStatus.CLOSED,
        }, // Exceeds 5000 limit
      ]);

      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(false);
      expect(result.code).toBe(RiskCode.DAILY_LOSS_LIMIT);

      expect(prismaMock.userSegment.update).toHaveBeenCalledWith({
        where: { id: 'us-123' },
        data: expect.objectContaining({ status: UserSegmentStatus.PAUSED }),
      });

      expect(auditMock.logEvent).toHaveBeenCalledWith(
        testUserId,
        'SEGMENT_RISK_LOCKED',
        'UserSegment',
        'us-123',
        expect.any(Object),
      );
    });

    it('should reject when current lot multiplier exceeds max multiplier', async () => {
      prismaMock.segmentMultiplier.findFirst.mockResolvedValue({
        id: 'sm-1',
        currentMultiplier: 8, // Exceeds maxMultiplier = 4
      });

      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(false);
      expect(result.code).toBe(RiskCode.MULTIPLIER_LIMIT);
    });

    it('should reject when segment status is PAUSED', async () => {
      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-123',
        userId: testUserId,
        segmentId: testSegmentId,
        status: UserSegmentStatus.PAUSED,
      });

      const result = await service.validateExecution(
        testUserId,
        testSegmentId,
        3000,
      );
      expect(result.approved).toBe(false);
      expect(result.code).toBe(RiskCode.SEGMENT_PAUSED);
    });
  });

  describe('getRiskEventsForSegment', () => {
    it('should call paginate with segment query filters', async () => {
      prismaMock.riskEvent.paginate.mockResolvedValue({ data: [], total: 0 });

      await service.getRiskEventsForSegment('user-123', 'strat-123', 2, 15);
      expect(prismaMock.riskEvent.paginate).toHaveBeenCalledWith({
        page: 2,
        limit: 15,
        where: { userId: 'user-123', segmentId: 'strat-123' },
        orderBy: { createdAt: 'desc' },
      });
    });
  });

  describe('getRiskStatusForSegment', () => {
    it('should return locking and loss status details', async () => {
      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-123',
        status: UserSegmentStatus.ACTIVE,
        dailyLossLimit: new Prisma.Decimal(5000),
      });

      prismaMock.trade.findMany.mockResolvedValue([
        {
          id: 't-1',
          pnl: new Prisma.Decimal(-2000),
          status: TradeStatus.CLOSED,
        },
      ]);

      const result = await service.getRiskStatusForSegment(
        'user-123',
        'strat-123',
      );
      expect(result).toEqual({
        locked: false,
        dailyLoss: 2000,
        dailyLossLimit: 5000,
      });
    });

    it('should return locked true if status is PAUSED', async () => {
      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-123',
        status: UserSegmentStatus.PAUSED,
        dailyLossLimit: new Prisma.Decimal(5000),
      });
      prismaMock.trade.findMany.mockResolvedValue([]);

      const result = await service.getRiskStatusForSegment(
        'user-123',
        'strat-123',
      );
      expect(result.locked).toBe(true);
    });
  });

  describe('unlockSegment', () => {
    const testUserId = 'user-123';
    const testSegmentId = 'strat-123';

    beforeEach(() => {
      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-123',
        userId: testUserId,
        segmentId: testSegmentId,
      });

      const txMock = {
        userSegment: {
          update: jest.fn().mockResolvedValue({
            id: 'us-123',
            status: UserSegmentStatus.ACTIVE,
          }),
        },
        segmentMultiplier: {
          findFirst: jest.fn().mockResolvedValue({ id: 'sm-1' }),
          update: jest.fn(),
        },
        riskEvent: {
          create: jest.fn(),
        },
      };

      prismaMock.$transaction.mockImplementation(async (callback) => {
        return callback(txMock);
      });
    });

    it('should allow owner to unlock and emit SEGMENT_RISK_UNLOCKED audit log', async () => {
      const result = await service.unlockSegment(testUserId, testSegmentId);
      expect(result.status).toBe(UserSegmentStatus.ACTIVE);
      expect(auditMock.logEvent).toHaveBeenCalledWith(
        testUserId,
        'SEGMENT_RISK_UNLOCKED',
        'UserSegment',
        'us-123',
        expect.any(Object),
      );
    });

    it('should throw ForbiddenException if client user attempts to unlock another users segment', async () => {
      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-123',
        userId: 'other-user',
        segmentId: testSegmentId,
      });

      await expect(
        service.unlockSegment(testUserId, testSegmentId),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow admin to unlock for other user', async () => {
      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-123',
        userId: 'other-user',
        segmentId: testSegmentId,
      });

      const result = await service.unlockSegment(
        'admin-user',
        testSegmentId,
        'other-user',
        true,
      );
      expect(result.status).toBe(UserSegmentStatus.ACTIVE);
    });
  });

  describe('evaluateRisk', () => {
    const userId = 'user-1';
    const symbol = 'INFY';
    const quantity = 100;
    const price = 1500;
    const brokerId = 'broker-1';
    const segmentId = 'seg-1';

    beforeEach(() => {
      process.env.RISK_DEFAULT_MODE = 'BLOCK';
      jest.clearAllMocks();
    });

    it('should block order if global emergency lock is active in Redis', async () => {
      redisMock.getClient().get.mockImplementation(async (key: string) => {
        if (key === 'risk:global:blocked') return 'true';
        return null;
      });

      const result = await service.evaluateRisk(userId, symbol, quantity, price, brokerId, segmentId);
      expect(result.approved).toBe(false);
      expect(result.reason).toContain('Global emergency risk lock');
    });

    it('should block order if user-level risk lock is active in Redis', async () => {
      redisMock.getClient().get.mockImplementation(async (key: string) => {
        if (key === `user:risk:blocked:${userId}`) return 'true';
        return null;
      });

      const result = await service.evaluateRisk(userId, symbol, quantity, price, brokerId, segmentId);
      expect(result.approved).toBe(false);
      expect(result.reason).toContain('User risk circuit breaker');
    });

    it('should block order and trigger background recalculation if snapshot is stale', async () => {
      prismaMock.riskSnapshot.findUnique.mockResolvedValue({
        userId,
        updatedAt: new Date(Date.now() - 360000), // 6 minutes ago (stale)
      });

      const result = await service.evaluateRisk(userId, symbol, quantity, price, brokerId, segmentId);
      expect(result.approved).toBe(false);
      expect(result.reason).toContain('stale');
      expect(queueMock.addJob).toHaveBeenCalledWith(
        'risk-recalculate',
        `risk:recalc:${userId}`,
        { userId }
      );
    });

    it('should fail closed when no profiles exist and RISK_DEFAULT_MODE=BLOCK', async () => {
      prismaMock.riskProfile.findMany.mockResolvedValue([]);

      const result = await service.evaluateRisk(userId, symbol, quantity, price, brokerId, segmentId);
      expect(result.approved).toBe(false);
      expect(result.reason).toContain('No active risk profile found');
    });

    it('should allow order when no profiles exist and RISK_DEFAULT_MODE=ALLOW', async () => {
      process.env.RISK_DEFAULT_MODE = 'ALLOW';
      prismaMock.riskProfile.findMany.mockResolvedValue([]);

      const result = await service.evaluateRisk(userId, symbol, quantity, price, brokerId, segmentId);
      expect(result.approved).toBe(true);
    });

    it('should block order if Max Capital Per User limit is exceeded', async () => {
      prismaMock.riskSnapshot.findUnique.mockResolvedValue({
        userId,
        currentCapitalUsed: 50000,
        updatedAt: new Date(),
      });
      prismaMock.riskProfile.findMany.mockResolvedValue([
        {
          version: 1,
          maxCapitalPerUser: 100000, // 50000 used + 150000 order = 200000 (> 100000 limit)
          priority: 1,
        }
      ]);

      const result = await service.evaluateRisk(userId, symbol, 100, 1500, brokerId, segmentId); // 150,000 order value
      expect(result.approved).toBe(false);
      expect(result.reason).toContain('Exceeded Max Capital Limit');
    });

    it('should block order if Max Daily Loss limit is exceeded', async () => {
      prismaMock.riskSnapshot.findUnique.mockResolvedValue({
        userId,
        dailyLoss: 6000,
        updatedAt: new Date(),
      });
      prismaMock.riskProfile.findMany.mockResolvedValue([
        {
          version: 1,
          maxDailyLoss: 5000, // limit is 5000, currently 6000 lost
          priority: 1,
        }
      ]);

      const result = await service.evaluateRisk(userId, symbol, quantity, price, brokerId, segmentId);
      expect(result.approved).toBe(false);
      expect(result.reason).toContain('Exceeded Max Daily Loss Limit');
    });
  });
});
