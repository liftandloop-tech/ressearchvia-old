import { Test, TestingModule } from '@nestjs/testing';
import { SignalOrchestratorService } from './signal-orchestrator.service';
import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { IdempotencyService } from '../../infrastructure/idempotency/idempotency.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MultiplierService } from './multiplier.service';
import { PositionSizingService } from './position-sizing.service';
import { AuditService } from '../../audit/audit.service';
import { mockPrismaService } from '../../../test/mocks/prisma.mock';
import { ServiceUnavailableException } from '@nestjs/common';
import {
  SignalState,
  SubscriptionStatus,
  ConsentStatus,
  BrokerStatus,
  Side,
  SignalStatus,
} from '@prisma/client';
import { Queues } from '../../infrastructure/queues/queue.constants';

describe('SignalOrchestratorService', () => {
  let service: SignalOrchestratorService;
  let prismaMock: any;
  let queueMock: any;
  let idempotencyMock: any;
  let redisMock: any;
  let multiplierMock: any;
  let positionSizingMock: any;
  let auditMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    queueMock = {
      addJob: jest.fn().mockResolvedValue(undefined),
      getQueue: jest
        .fn()
        .mockReturnValue({ add: jest.fn().mockResolvedValue({}) }),
    };
    idempotencyMock = {
      tryAcquire: jest.fn().mockResolvedValue(true),
      markSuccess: jest.fn().mockResolvedValue(undefined),
      markFailed: jest.fn().mockResolvedValue(undefined),
    };
    redisMock = {
      assertHealthy: jest.fn(),
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue(null),
        set: jest.fn().mockResolvedValue('OK'),
      }),
    };
    multiplierMock = {
      getMultiplier: jest.fn().mockResolvedValue({
        multiplier: 1,
        source: 'DEFAULT',
      }),
    };
    positionSizingMock = {
      getUserStrategy: jest.fn().mockResolvedValue({
        strategyType: 'FIXED_1X',
        baseMultiplier: 1,
        currentCycleStep: 0,
      }),
      calculatePositionSize: jest.fn().mockResolvedValue({
        multiplier: 1,
        baseQuantity: 1,
        actualQuantity: 1,
        strategyType: 'FIXED_1X',
        strategyVersion: 'v1.0',
        consecutiveLosses: 0,
        previousTradeResult: null,
        agreementVersion: 'v1.0',
      }),
    };
    auditMock = {
      logEvent: jest.fn().mockResolvedValue({}),
    };

    let currentExecState = SignalState.RECEIVED;
    prismaMock.segmentExecution.create.mockImplementation(() => {
      currentExecState = SignalState.RECEIVED;
      return {
        id: 'exec-1',
        signalId: 'sig-123',
        state: currentExecState,
        startedAt: new Date(),
      };
    });
    prismaMock.segmentExecution.findUnique.mockImplementation(() => ({
      id: 'exec-1',
      state: currentExecState,
      startedAt: new Date(),
    }));
    prismaMock.segmentExecution.update.mockImplementation(({ data }: any) => {
      if (data.state) currentExecState = data.state;
      return {
        id: 'exec-1',
        signalId: 'sig-123',
        state: currentExecState,
        startedAt: new Date(),
        ...data,
      };
    });

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SignalOrchestratorService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: QueueService, useValue: queueMock },
        { provide: IdempotencyService, useValue: idempotencyMock },
        { provide: RedisService, useValue: redisMock },
        { provide: MultiplierService, useValue: multiplierMock },
        { provide: PositionSizingService, useValue: positionSizingMock },
        { provide: AuditService, useValue: auditMock },
      ],
    }).compile();

    service = module.get<SignalOrchestratorService>(SignalOrchestratorService);
  });

  describe('processSignal', () => {
    it('should throw ServiceUnavailableException if global trading kill switch is ON', async () => {
      redisMock.getClient().get.mockImplementation(async (key: string) => {
        if (key === 'trading:global:disabled') return 'true';
        return null;
      });

      await expect(service.processSignal('sig-1')).rejects.toThrow(
        ServiceUnavailableException,
      );
    });

    it('should throw ServiceUnavailableException if global emergency risk lock is ON', async () => {
      redisMock.getClient().get.mockImplementation(async (key: string) => {
        if (key === 'risk:global:blocked') return 'true';
        return null;
      });

      await expect(service.processSignal('sig-1')).rejects.toThrow(
        ServiceUnavailableException,
      );
    });

    it('should skip duplicate signals idempotently without throwing', async () => {
      idempotencyMock.tryAcquire.mockResolvedValue(false);

      const result = await service.processSignal('sig-duplicate');
      expect(result.state).toBe(SignalState.COMPLETED);
      expect(result.totalUsers).toBe(0);
      expect(prismaMock.signal.findUnique).not.toHaveBeenCalled();
    });

    it('should return FAILED state if signal does not exist', async () => {
      prismaMock.signal.findUnique.mockResolvedValue(null);

      const result = await service.processSignal('sig-nonexistent');
      expect(result.state).toBe(SignalState.FAILED);
      expect(idempotencyMock.markFailed).toHaveBeenCalled();
    });

    it('should process signal and fan out to eligible subscribers', async () => {
      const mockSignal = {
        id: 'sig-123',
        segment: 'NIFTY_FUT',
        symbol: 'NIFTY',
        side: Side.BUY,
        status: SignalStatus.PUBLISHED,
        entryPrice: 22000,
        stopLoss: 21900,
        targetPrice: 22200,
        segmentRelation: {
          id: 'seg-1',
          code: 'NIFTY_FUT',
          name: 'Nifty Futures',
        },
      };
      prismaMock.signal.findUnique.mockResolvedValue(mockSignal);

      // Mock userSegment batch
      const today = new Date();
      const future = new Date(Date.now() + 86400000);
      prismaMock.userSegment.findMany
        .mockResolvedValueOnce([
          {
            id: 'us-1',
            userId: 'user-1',
            segmentId: 'seg-1',
            capital: 100000,
            baseLot: 1,
            user: {
              subscriptions: [
                {
                  id: 'sub-1',
                  planId: 'PLAN_SPLENDID',
                  status: SubscriptionStatus.ACTIVE,
                  startDate: today,
                  endDate: future,
                },
              ],
              consents: [
                {
                  id: 'con-1',
                  brokerId: 'broker-angel',
                  status: ConsentStatus.ACTIVE,
                  consentDate: today,
                },
              ],
              userBrokers: [
                {
                  id: 'ub-1',
                  brokerId: 'broker-angel',
                  brokerClientId: 'ANGEL123',
                  status: BrokerStatus.ACTIVE,
                  accessToken: 'token-123',
                  tokenExpiry: future,
                  broker: { code: 'ANGEL_ONE' },
                },
              ],
            },
          },
        ])
        .mockResolvedValueOnce([]); // end of cursor pagination

      const result = await service.processSignal('sig-123');

      expect(result.state).toBe(SignalState.COMPLETED);
      expect(result.totalUsers).toBe(1);
      expect(result.successUsers).toBe(1);
      expect(queueMock.addJob).toHaveBeenCalledWith(
        Queues.ORDER_PLACEMENT,
        'job-sig-123-user-1',
        expect.objectContaining({
          signalId: 'sig-123',
          snapshot: expect.objectContaining({
            userId: 'user-1',
            brokerCode: 'ANGEL_ONE',
          }),
        }),
      );
    });

    it('should filter out users who do not have today active consent', async () => {
      const mockSignal = {
        id: 'sig-123',
        segment: 'NIFTY_FUT',
        segmentRelation: { id: 'seg-1', code: 'NIFTY_FUT' },
      };
      // Return empty batch because prisma query filters consents.some(status: ACTIVE)
      prismaMock.userSegment.findMany.mockResolvedValue([]);

      const result = await service.processSignal('sig-123');
      expect(result.totalUsers).toBe(0);
      expect(queueMock.addJob).not.toHaveBeenCalled();
    });

    it('should pick linked broker matching user active consent when user has multiple linked brokers', async () => {
      const mockSignal = {
        id: 'sig-123',
        segment: 'NIFTY_FUT',
        segmentRelation: { id: 'seg-1', code: 'NIFTY_FUT' },
      };
      prismaMock.signal.findUnique.mockResolvedValue(mockSignal);

      const today = new Date();
      const future = new Date(Date.now() + 86400000);

      // User has both Angel One and Zebu linked, but granted consent to Zebu today!
      prismaMock.userSegment.findMany
        .mockResolvedValueOnce([
          {
            id: 'us-multi',
            userId: 'user-multi',
            segmentId: 'seg-1',
            capital: 200000,
            baseLot: 2,
            user: {
              subscriptions: [
                {
                  id: 'sub-1',
                  planId: 'PLAN_SPLENDID',
                  status: SubscriptionStatus.ACTIVE,
                  startDate: today,
                  endDate: future,
                },
              ],
              consents: [
                {
                  id: 'con-zebu',
                  brokerId: 'broker-zebu-id',
                  status: ConsentStatus.ACTIVE,
                  consentDate: today,
                },
              ],
              userBrokers: [
                {
                  id: 'ub-angel',
                  brokerId: 'broker-angel-id',
                  brokerClientId: 'ANGEL_USER',
                  status: BrokerStatus.ACTIVE,
                  accessToken: 'token-angel',
                  tokenExpiry: future,
                  broker: { code: 'ANGEL_ONE' },
                },
                {
                  id: 'ub-zebu',
                  brokerId: 'broker-zebu-id',
                  brokerClientId: 'ZEBU_USER',
                  status: BrokerStatus.ACTIVE,
                  accessToken: 'token-zebu',
                  tokenExpiry: future,
                  broker: { code: 'ZEBU' },
                },
              ],
            },
          },
        ])
        .mockResolvedValueOnce([]);

      const result = await service.processSignal('sig-123');
      expect(result.successUsers).toBe(1);
      // Verify job was enqueued for ZEBU, not Angel One!
      expect(queueMock.addJob).toHaveBeenCalledWith(
        Queues.ORDER_PLACEMENT,
        'job-sig-123-user-multi',
        expect.objectContaining({
          snapshot: expect.objectContaining({
            brokerCode: 'ZEBU',
            brokerClientId: 'ZEBU_USER',
          }),
        }),
      );
    });
  });
});
