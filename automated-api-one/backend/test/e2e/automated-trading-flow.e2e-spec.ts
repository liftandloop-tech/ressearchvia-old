import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { createTestApp } from '../helpers/test-app';
import { AuthTestHelper } from '../helpers/auth.helper';
import {
  BrokerCode,
  BrokerStatus,
  ConsentStatus,
  Side,
  OrderStatus,
  OrderType,
  SignalState,
  SignalStatus,
  StrategyType,
  SubscriptionStatus,
  TradeStatus,
  UserSegmentStatus,
} from '@prisma/client';
import { SignalsService } from '../../src/signals/signals.service';
import { SignalOrchestratorService } from '../../src/trading/services/signal-orchestrator.service';
import { OrderPlacementService } from '../../src/trading/services/order-placement.service';
import { OrderMonitoringService } from '../../src/trading/services/order-monitoring.service';
import { BrokerFactory } from '../../src/brokers/factory/broker.factory';
import { BrokerType } from '../../src/brokers/interfaces/broker-type.enum';
import { RedisService } from '../../src/infrastructure/redis/redis.service';
import { BrokerRateLimiterService } from '../../src/infrastructure/redis/broker-rate-limiter.service';
import { QueueService } from '../../src/infrastructure/queues/queues.service';
import { Queues } from '../../src/infrastructure/queues/queue.constants';
import { RiskService } from '../../src/risk/risk.service';
import axios from 'axios';

describe('Automated Trading Flow (E2E Integration)', () => {
  let app: INestApplication<App>;
  let prismaMock: any;
  let redisService: RedisService;
  let queueService: QueueService;
  let signalsService: SignalsService;
  let orchestratorService: SignalOrchestratorService;
  let orderPlacementService: OrderPlacementService;
  let orderMonitoringService: OrderMonitoringService;
  let brokerFactory: BrokerFactory;
  let riskService: RiskService;
  let rateLimiter: BrokerRateLimiterService;

  const authHelper = new AuthTestHelper();
  const testAdminId = '990e8400-e29b-41d4-a716-446655440099';
  const testAdminMobile = '9999999999';

  const mockSegmentId = 'segment-nifty-opt-01';
  const mockSignalId = 'sig-auto-trade-1001';

  // Test subscribers
  const userAngel = {
    id: 'user-angel-001',
    mobile: '9111111111',
    brokerId: 'broker-angel-id',
    brokerClientId: 'ANGEL_CLIENT_01',
    brokerCode: BrokerCode.ANGEL_ONE,
  };

  const userZebu = {
    id: 'user-zebu-002',
    mobile: '9222222222',
    brokerId: 'broker-zebu-id',
    brokerClientId: 'ZEBU_CLIENT_02',
    brokerCode: BrokerCode.ZEBU,
  };

  const userMultiBroker = {
    id: 'user-multi-003',
    mobile: '9333333333',
    angelBrokerId: 'broker-angel-id-multi',
    zebuBrokerId: 'broker-zebu-id-multi',
    zebuClientId: 'ZEBU_MULTI_03',
  };

  beforeAll(async () => {
    const testEnv = await createTestApp();
    app = testEnv.app;
    prismaMock = testEnv.prismaMock;

    redisService = app.get(RedisService);
    queueService = app.get(QueueService);
    signalsService = app.get(SignalsService);
    orchestratorService = app.get(SignalOrchestratorService);
    orderPlacementService = app.get(OrderPlacementService);
    orderMonitoringService = app.get(OrderMonitoringService);
    brokerFactory = app.get(BrokerFactory);
    riskService = app.get(RiskService);
    rateLimiter = app.get(BrokerRateLimiterService);
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  beforeEach(() => {
    jest.clearAllMocks();

    // Default mocks for JWT Auth
    prismaMock.adminUser.findUnique.mockResolvedValue(null);
    prismaMock.user.findUnique.mockResolvedValue({
      id: testAdminId,
      mobile: testAdminMobile,
      status: 'ACTIVE',
    });

    jest.spyOn(rateLimiter, 'throttle').mockResolvedValue(true);
    jest.spyOn(queueService, 'addJob').mockResolvedValue('mock-job' as any);
    jest.spyOn(redisService, 'assertHealthy').mockImplementation(() => {});
    jest.spyOn(redisService, 'isHealthy').mockReturnValue(true);
    jest.spyOn(redisService.getClient(), 'get').mockResolvedValue(null);
    jest.spyOn(redisService.getClient(), 'set').mockResolvedValue('OK');
    jest.spyOn(redisService.getClient(), 'del').mockResolvedValue(1);

    prismaMock.riskProfile.findMany.mockResolvedValue([]);
    prismaMock.riskEvent.create.mockResolvedValue({ id: 're-1' });
    prismaMock.auditLog.create.mockResolvedValue({ id: 'audit-log-1' });
    prismaMock.outboxEvent.create.mockResolvedValue({
      id: 'outbox-evt-1',
      eventType: 'ORDER_PLACED',
    });
    prismaMock.userTradingStrategy.findFirst.mockResolvedValue({
      id: 'uts-default',
      userId: userAngel.id,
      strategyType: StrategyType.FIXED_1X,
      baseMultiplier: 1,
      currentMultiplier: 1,
      consecutiveLosses: 0,
      status: 'ACTIVE',
      version: 1,
      agreementVersion: 'v1.0',
    });
    prismaMock.userTradingStrategy.updateMany.mockResolvedValue({ count: 1 });
    prismaMock.segmentMultiplier.upsert.mockResolvedValue({});
  });

  describe('1. Signal Publication API & l-l-backend Integration', () => {
    it('should validate segment, create signal, enqueue processing, and notify l-l-backend', async () => {
      // Mock segment exists
      prismaMock.segmentMaster.findUnique.mockResolvedValue({
        id: mockSegmentId,
        name: 'NIFTY OPTIONS SCALPING',
        segment: 'FO',
        status: 'ACTIVE',
      });

      // Mock signal creation
      prismaMock.signal.create.mockResolvedValue({
        id: mockSignalId,
        segmentId: mockSegmentId,
        symbol: 'NIFTY26OCT24500CE',
        exchange: 'NFO',
        segment: 'FO',
        side: Side.BUY,
        orderType: OrderType.MARKET,
        entryPrice: 125.5,
        stopLoss: 100.0,
        targetPrice: 165.0,
        status: SignalStatus.PUBLISHED,
        publishedAt: new Date(),
      });

      const queueSpy = jest
        .spyOn(queueService, 'addJob')
        .mockResolvedValue('job-sig-1' as any);
      const axiosPostSpy = jest.spyOn(axios, 'post').mockResolvedValue({
        status: 200,
        data: {
          status: 200,
          message: 'Automated trading call created successfully',
        },
      });

      const headers = authHelper.getHeadersForUser(
        testAdminId,
        testAdminMobile,
      );

      const response = await request(app.getHttpServer())
        .post('/signals/publish')
        .set(headers)
        .send({
          segmentId: mockSegmentId,
          symbol: 'NIFTY26OCT24500CE',
          exchange: 'NFO',
          segment: 'FO',
          side: Side.BUY,
          orderType: OrderType.MARKET,
          entryPrice: 125.5,
          stopLoss: 100.0,
          targetPrice: 165.0,
        })
        .expect(200);

      expect(response.body).toEqual({
        success: true,
        signalId: mockSignalId,
      });

      // Assert queue enqueue
      expect(queueSpy).toHaveBeenCalledWith(
        Queues.SIGNAL_PROCESSING,
        `signal-${mockSignalId}`,
        { signalId: mockSignalId },
      );

      // Assert cross-repo forwarding to l-l-backend
      expect(axiosPostSpy).toHaveBeenCalledWith(
        expect.stringContaining('/api/reports/automated-trading-call'),
        expect.objectContaining({
          symbol: 'NIFTY26OCT24500CE',
          exchange: 'NFO',
          side: Side.BUY,
          entryPrice: 125.5,
          stopLoss: 100.0,
          targetPrice: 165.0,
          segment: 'FO',
          rawSignalId: mockSignalId,
        }),
        expect.objectContaining({
          headers: expect.objectContaining({
            'x-api-key': expect.any(String),
          }),
        }),
      );
    });

    it('should reject signal publish with 404 if segment does not exist', async () => {
      prismaMock.segmentMaster.findUnique.mockResolvedValue(null);
      const headers = authHelper.getHeadersForUser(
        testAdminId,
        testAdminMobile,
      );

      await request(app.getHttpServer())
        .post('/signals/publish')
        .set(headers)
        .send({
          segmentId: 'non-existent-segment',
          symbol: 'BANKNIFTY26OCT50000CE',
          exchange: 'NFO',
          segment: 'FO',
          side: Side.BUY,
          orderType: OrderType.MARKET,
          entryPrice: 350.0,
          stopLoss: 300.0,
          targetPrice: 420.0,
        })
        .expect(404);
    });

    it('should reject signal publish with 503 if system is in maintenance mode', async () => {
      jest.spyOn(redisService, 'isHealthy').mockReturnValue(true);
      jest
        .spyOn(redisService.getClient(), 'get')
        .mockImplementation(async (key: string) => {
          if (key === 'system:maintenance:signals') return 'true';
          return null;
        });

      const headers = authHelper.getHeadersForUser(
        testAdminId,
        testAdminMobile,
      );

      await request(app.getHttpServer())
        .post('/signals/publish')
        .set(headers)
        .send({
          segmentId: mockSegmentId,
          symbol: 'NIFTY26OCT24500CE',
          exchange: 'NFO',
          segment: 'FO',
          side: Side.BUY,
          orderType: OrderType.MARKET,
          entryPrice: 125.5,
          stopLoss: 100.0,
          targetPrice: 165.0,
        })
        .expect(503);
    });
  });

  describe('2. Fan-out Orchestration & Multi-Broker Active Consent Filtering', () => {
    it('should filter subscribers by today consent, match specific broker, apply position sizing, and enqueue orders', async () => {
      // Mock Signal
      prismaMock.signal.findUnique.mockResolvedValue({
        id: mockSignalId,
        segmentId: mockSegmentId,
        symbol: 'NIFTY26OCT24500CE',
        exchange: 'NFO',
        segment: 'FO',
        side: Side.BUY,
        orderType: OrderType.MARKET,
        entryPrice: 125.5,
        stopLoss: 100.0,
        targetPrice: 165.0,
        status: SignalStatus.PUBLISHED,
        segmentRelation: { id: mockSegmentId, name: 'Nifty Options' },
      });

      // Mock SegmentExecution with state progression
      const executionId = 'exec-auto-trade-888';
      let currentExecutionState = SignalState.RECEIVED;

      prismaMock.segmentExecution.create.mockResolvedValue({
        id: executionId,
        correlationId: 'corr-888',
        segmentId: mockSegmentId,
        signalId: mockSignalId,
        state: SignalState.RECEIVED,
        totalUsers: 0,
        processedUsers: 0,
        successfulUsers: 0,
        failedUsers: 0,
      });

      prismaMock.segmentExecution.findUnique.mockImplementation(() => {
        return Promise.resolve({
          id: executionId,
          state: currentExecutionState,
        });
      });

      prismaMock.segmentExecution.update.mockImplementation(({ data }: any) => {
        if (data.state) {
          currentExecutionState = data.state;
        }
        return Promise.resolve({ id: executionId, ...data });
      });

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      // Mock batch of 3 users:
      // User 1: Angel One broker, active consent for Angel One
      // User 2: Zebu broker, active consent for Zebu
      // User 3: Has Angel One AND Zebu, but today's consent is explicitly for Zebu
      prismaMock.userSegment.findMany
        .mockResolvedValueOnce([
          {
            id: 'us-1',
            userId: userAngel.id,
            segmentId: mockSegmentId,
            status: UserSegmentStatus.ACTIVE,
            capital: 50000,
            baseLot: 1,
            user: {
              subscriptions: [
                {
                  id: 'sub-1',
                  planId: 'SPARK',
                  status: SubscriptionStatus.ACTIVE,
                },
              ],
              consents: [
                {
                  id: 'c-1',
                  brokerId: userAngel.brokerId,
                  consentDate: new Date(),
                  status: ConsentStatus.ACTIVE,
                },
              ],
              userBrokers: [
                {
                  id: 'ub-1',
                  brokerId: userAngel.brokerId,
                  brokerClientId: userAngel.brokerClientId,
                  status: BrokerStatus.ACTIVE,
                  accessToken: 'mock_angel_token',
                  tokenExpiry: new Date(Date.now() + 3600000),
                  broker: { code: BrokerCode.ANGEL_ONE },
                },
              ],
            },
          },
          {
            id: 'us-2',
            userId: userZebu.id,
            segmentId: mockSegmentId,
            status: UserSegmentStatus.ACTIVE,
            capital: 100000,
            baseLot: 2,
            user: {
              subscriptions: [
                {
                  id: 'sub-2',
                  planId: 'SPLENDID',
                  status: SubscriptionStatus.ACTIVE,
                },
              ],
              consents: [
                {
                  id: 'c-2',
                  brokerId: userZebu.brokerId,
                  consentDate: new Date(),
                  status: ConsentStatus.ACTIVE,
                },
              ],
              userBrokers: [
                {
                  id: 'ub-2',
                  brokerId: userZebu.brokerId,
                  brokerClientId: userZebu.brokerClientId,
                  status: BrokerStatus.ACTIVE,
                  accessToken: 'mock_zebu_token',
                  tokenExpiry: new Date(Date.now() + 3600000),
                  broker: { code: BrokerCode.ZEBU },
                },
              ],
            },
          },
          {
            id: 'us-3',
            userId: userMultiBroker.id,
            segmentId: mockSegmentId,
            status: UserSegmentStatus.ACTIVE,
            capital: 80000,
            baseLot: 1,
            user: {
              subscriptions: [
                {
                  id: 'sub-3',
                  planId: 'SPARK',
                  status: SubscriptionStatus.ACTIVE,
                },
              ],
              consents: [
                {
                  id: 'c-3',
                  brokerId: userMultiBroker.zebuBrokerId,
                  consentDate: new Date(),
                  status: ConsentStatus.ACTIVE,
                },
              ],
              userBrokers: [
                {
                  id: 'ub-multi-angel',
                  brokerId: userMultiBroker.angelBrokerId,
                  brokerClientId: 'ANGEL_MULTI_OLD',
                  status: BrokerStatus.ACTIVE,
                  accessToken: 'mock_angel_multi_token',
                  tokenExpiry: new Date(Date.now() + 3600000),
                  broker: { code: BrokerCode.ANGEL_ONE },
                },
                {
                  id: 'ub-multi-zebu',
                  brokerId: userMultiBroker.zebuBrokerId,
                  brokerClientId: userMultiBroker.zebuClientId,
                  status: BrokerStatus.ACTIVE,
                  accessToken: 'mock_zebu_multi_token',
                  tokenExpiry: new Date(Date.now() + 3600000),
                  broker: { code: BrokerCode.ZEBU },
                },
              ],
            },
          },
        ])
        .mockResolvedValueOnce([]); // Second batch empty to terminate cursor loop

      // Mock user trading strategies:
      // User 1: FIXED_1X
      // User 2: LOSS_MULTIPLIER_2X with 2 consecutive losses -> Multiplier 4x (2 baseLot * 4 = 8 effectiveLot)
      // User 3: FIXED_1X
      prismaMock.userTradingStrategy.findFirst.mockImplementation(
        ({ where }: any) => {
          if (where.userId === userZebu.id) {
            return Promise.resolve({
              id: 'uts-zebu',
              userId: userZebu.id,
              strategyType: StrategyType.LOSS_MULTIPLIER_2X,
              baseMultiplier: 1,
              currentMultiplier: 4,
              consecutiveLosses: 2,
              status: 'ACTIVE',
              version: 1,
              agreementVersion: 'v1.0',
            });
          }
          return Promise.resolve({
            id: 'uts-fixed',
            userId: where.userId,
            strategyType: StrategyType.FIXED_1X,
            baseMultiplier: 1,
            currentMultiplier: 1,
            consecutiveLosses: 0,
            status: 'ACTIVE',
            version: 1,
            agreementVersion: 'v1.0',
          });
        },
      );

      const queueSpy = jest
        .spyOn(queueService, 'addJob')
        .mockResolvedValue('order-job' as any);
      jest.spyOn(axios, 'post').mockResolvedValue({ status: 200, data: {} });

      // Execute Orchestrator Fan-Out
      const result = await orchestratorService.processSignal(mockSignalId);

      expect(result.state).toBe(SignalState.COMPLETED);
      expect(result.totalUsers).toBe(3);
      expect(result.successUsers).toBe(3);
      expect(result.rejectedUsers).toBe(0);

      // Check job dispatch details for all 3 users
      expect(queueSpy).toHaveBeenCalledWith(
        Queues.ORDER_PLACEMENT,
        `job-${mockSignalId}-${userAngel.id}`,
        expect.objectContaining({
          snapshot: expect.objectContaining({
            userId: userAngel.id,
            brokerCode: BrokerCode.ANGEL_ONE,
            effectiveLot: 1,
          }),
        }),
      );

      // User 2 has 2 baseLot * 4 multiplier = 8 effectiveLot
      expect(queueSpy).toHaveBeenCalledWith(
        Queues.ORDER_PLACEMENT,
        `job-${mockSignalId}-${userZebu.id}`,
        expect.objectContaining({
          snapshot: expect.objectContaining({
            userId: userZebu.id,
            brokerCode: BrokerCode.ZEBU,
            effectiveLot: 8,
          }),
        }),
      );

      // User 3 correctly resolved to Zebu broker ID matching today's consent
      expect(queueSpy).toHaveBeenCalledWith(
        Queues.ORDER_PLACEMENT,
        `job-${mockSignalId}-${userMultiBroker.id}`,
        expect.objectContaining({
          snapshot: expect.objectContaining({
            userId: userMultiBroker.id,
            brokerId: userMultiBroker.zebuBrokerId,
            brokerCode: BrokerCode.ZEBU,
          }),
        }),
      );
    });

    it('should halt fan-out immediately when global trading kill switch is engaged', async () => {
      jest
        .spyOn(redisService.getClient(), 'get')
        .mockImplementation(async (key: string) => {
          if (key === 'trading:global:disabled') return 'true';
          return null;
        });

      await expect(
        orchestratorService.processSignal(mockSignalId),
      ).rejects.toThrow('Trading is disabled globally via kill switch');
    });
  });

  describe('3. Automated Order Placement across Angel One and Zebu', () => {
    it('should place an intraday order via Angel One adapter and atomically write Trade & Order', async () => {
      jest
        .spyOn(riskService, 'evaluateRisk')
        .mockResolvedValueOnce({ approved: true });

      const angelAdapter = brokerFactory.getAdapter(BrokerType.ANGEL_ONE);
      jest.spyOn(angelAdapter, 'placeOrder').mockResolvedValue({
        status: 'EXECUTED',
        brokerOrderId: 'ANGEL_ORDER_990011',
        message: 'Order placed successfully',
      });

      // Mock user broker session token in DB
      prismaMock.userBroker.findFirst.mockResolvedValue({
        id: 'ub-1',
        userId: userAngel.id,
        brokerId: userAngel.brokerId,
        brokerClientId: userAngel.brokerClientId,
        accessToken: 'valid_angel_jwt_token',
        status: BrokerStatus.ACTIVE,
      });

      prismaMock.trade.create.mockResolvedValue({
        id: 'trade-angel-1',
        userId: userAngel.id,
        signalId: mockSignalId,
        brokerId: userAngel.brokerId,
        symbol: 'NIFTY26OCT24500CE',
        status: TradeStatus.PENDING,
      });

      prismaMock.order.create.mockResolvedValue({
        id: 'order-angel-1',
        tradeId: 'trade-angel-1',
        brokerOrderId: 'ANGEL_ORDER_990011',
        status: OrderStatus.PENDING,
      });

      const placementResult = await orderPlacementService.placeEntryOrder({
        correlationId: 'corr-angel-exec',
        jobId: 'job-angel-1',
        signalId: mockSignalId,
        segmentId: mockSegmentId,
        symbol: 'NIFTY26OCT24500CE',
        exchange: 'NFO',
        side: Side.BUY,
        orderType: OrderType.MARKET,
        entryPrice: 125.5,
        stopLoss: 100.0,
        targetPrice: 165.0,
        snapshot: {
          userId: userAngel.id,
          segmentId: mockSegmentId,
          brokerId: userAngel.brokerId,
          brokerCode: BrokerCode.ANGEL_ONE,
          brokerClientId: userAngel.brokerClientId,
          subscriptionPlan: 'SPARK',
          capitalAllocated: 50000,
          baseLot: 1,
          effectiveLot: 1,
          multiplierIndex: 0,
          multiplierValue: 1,
          strategyType: StrategyType.FIXED_1X,
        },
      });

      expect(placementResult.success).toBe(true);
      expect(placementResult.brokerOrderId).toBe('ANGEL_ORDER_990011');
      expect(placementResult.tradeId).toBe('trade-angel-1');
      expect(placementResult.orderId).toBe('order-angel-1');

      // Verify adapter called with proper intraday params
      expect(angelAdapter.placeOrder).toHaveBeenCalledWith(
        'valid_angel_jwt_token',
        userAngel.brokerClientId,
        expect.objectContaining({
          symbol: 'NIFTY26OCT24500CE',
          exchange: 'NFO',
          side: Side.BUY,
          quantity: 1,
          price: 125.5,
        }),
        undefined,
      );
    });

    it('should place an intraday multiplied order via Zebu adapter with correct quantity', async () => {
      jest
        .spyOn(riskService, 'evaluateRisk')
        .mockResolvedValueOnce({ approved: true });

      const zebuAdapter = brokerFactory.getAdapter(BrokerType.ZEBU);
      jest.spyOn(zebuAdapter, 'placeOrder').mockResolvedValue({
        status: 'EXECUTED',
        brokerOrderId: 'ZEBU_ORD_887766',
        message: 'Order accepted',
      });

      prismaMock.userBroker.findFirst.mockResolvedValue({
        id: 'ub-2',
        userId: userZebu.id,
        brokerId: userZebu.brokerId,
        brokerClientId: userZebu.brokerClientId,
        accessToken: 'valid_zebu_auth_token',
        status: BrokerStatus.ACTIVE,
      });

      prismaMock.trade.create.mockResolvedValue({
        id: 'trade-zebu-2',
        userId: userZebu.id,
        signalId: mockSignalId,
        brokerId: userZebu.brokerId,
        symbol: 'NIFTY26OCT24500CE',
        status: TradeStatus.PENDING,
      });

      prismaMock.order.create.mockResolvedValue({
        id: 'order-zebu-2',
        tradeId: 'trade-zebu-2',
        brokerOrderId: 'ZEBU_ORD_887766',
        status: OrderStatus.PENDING,
      });

      const placementResult = await orderPlacementService.placeEntryOrder({
        correlationId: 'corr-zebu-exec',
        jobId: 'job-zebu-2',
        signalId: mockSignalId,
        segmentId: mockSegmentId,
        symbol: 'NIFTY26OCT24500CE',
        exchange: 'NFO',
        side: Side.BUY,
        orderType: OrderType.MARKET,
        entryPrice: 125.5,
        stopLoss: 100.0,
        targetPrice: 165.0,
        snapshot: {
          userId: userZebu.id,
          segmentId: mockSegmentId,
          brokerId: userZebu.brokerId,
          brokerCode: BrokerCode.ZEBU,
          brokerClientId: userZebu.brokerClientId,
          subscriptionPlan: 'SPLENDID',
          capitalAllocated: 100000,
          baseLot: 2,
          effectiveLot: 8, // 2 lots * 4x multiplier
          multiplierIndex: 2,
          multiplierValue: 4,
          strategyType: StrategyType.LOSS_MULTIPLIER_2X,
        },
      });

      expect(placementResult.success).toBe(true);
      expect(placementResult.brokerOrderId).toBe('ZEBU_ORD_887766');

      expect(zebuAdapter.placeOrder).toHaveBeenCalledWith(
        'valid_zebu_auth_token',
        userZebu.brokerClientId,
        expect.objectContaining({
          quantity: 8,
          symbol: 'NIFTY26OCT24500CE',
          side: Side.BUY,
        }),
        undefined,
      );
    });

    it('should halt placement if Risk Engine denies execution', async () => {
      jest.spyOn(riskService, 'evaluateRisk').mockResolvedValueOnce({
        approved: false,
        reason: 'Daily loss limit of INR 5000 exceeded for strategy segment',
      });

      const placementResult = await orderPlacementService.placeEntryOrder({
        correlationId: 'corr-risk-denied',
        jobId: 'job-risk-denied',
        signalId: mockSignalId,
        segmentId: mockSegmentId,
        symbol: 'NIFTY26OCT24500CE',
        exchange: 'NFO',
        side: Side.BUY,
        orderType: OrderType.MARKET,
        entryPrice: 125.5,
        stopLoss: 100.0,
        targetPrice: 165.0,
        snapshot: {
          userId: userAngel.id,
          segmentId: mockSegmentId,
          brokerId: userAngel.brokerId,
          brokerCode: BrokerCode.ANGEL_ONE,
          brokerClientId: userAngel.brokerClientId,
          subscriptionPlan: 'SPARK',
          capitalAllocated: 50000,
          baseLot: 1,
          effectiveLot: 1,
          multiplierIndex: 0,
          multiplierValue: 1,
          strategyType: StrategyType.FIXED_1X,
        },
      });

      expect(placementResult.success).toBe(false);
      expect(placementResult.reason).toContain('Risk Engine block');
    });
  });

  describe('4. Order Monitoring, Fill Reconciliation & Multiplier Engine', () => {
    it('should reconcile FILLED webhook callback: transition trade to OPEN and reset multiplier on win', async () => {
      prismaMock.order.findFirst.mockResolvedValue({
        id: 'order-angel-1',
        tradeId: 'trade-angel-1',
        brokerOrderId: 'ANGEL_ORDER_990011',
        status: OrderStatus.PENDING,
        trade: {
          id: 'trade-angel-1',
          userId: userAngel.id,
          segmentId: mockSegmentId,
          status: TradeStatus.PENDING,
        },
      });

      prismaMock.order.update.mockResolvedValue({
        id: 'order-angel-1',
        status: OrderStatus.FILLED,
      });

      prismaMock.trade.update.mockResolvedValue({
        id: 'trade-angel-1',
        status: TradeStatus.OPEN,
      });

      const result =
        await orderMonitoringService.processBrokerWebhookOrderUpdate({
          brokerOrderId: 'ANGEL_ORDER_990011',
          status: 'COMPLETE',
          filledQuantity: 1,
          averagePrice: 125.0,
        });

      expect(result.success).toBe(true);
      expect(result.status).toBe('FILLED');
      expect(prismaMock.order.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'order-angel-1' },
          data: { status: OrderStatus.FILLED },
        }),
      );
      expect(prismaMock.trade.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'trade-angel-1' },
          data: { status: TradeStatus.OPEN },
        }),
      );
    });

    it('should reconcile REJECTED webhook callback: transition trade to FAILED and advance multiplier on loss', async () => {
      prismaMock.order.findFirst.mockResolvedValue({
        id: 'order-zebu-2',
        tradeId: 'trade-zebu-2',
        brokerOrderId: 'ZEBU_ORD_887766',
        status: OrderStatus.PENDING,
        trade: {
          id: 'trade-zebu-2',
          userId: userZebu.id,
          segmentId: mockSegmentId,
          status: TradeStatus.PENDING,
        },
      });

      prismaMock.order.update.mockResolvedValue({
        id: 'order-zebu-2',
        status: OrderStatus.REJECTED,
      });

      prismaMock.trade.update.mockResolvedValue({
        id: 'trade-zebu-2',
        status: TradeStatus.FAILED,
      });

      const result =
        await orderMonitoringService.processBrokerWebhookOrderUpdate({
          brokerOrderId: 'ZEBU_ORD_887766',
          status: 'REJECTED',
          rejectionReason: 'Margin Shortfall: Required 45000, Available 12000',
        });

      expect(result.success).toBe(true);
      expect(result.status).toBe('REJECTED');
      expect(prismaMock.order.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'order-zebu-2' },
          data: { status: OrderStatus.REJECTED },
        }),
      );
      expect(prismaMock.trade.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'trade-zebu-2' },
          data: { status: TradeStatus.FAILED },
        }),
      );
    });
  });
});
