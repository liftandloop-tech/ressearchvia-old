import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { HealthCheckService, PrismaHealthIndicator } from '@nestjs/terminus';
import { PrismaService } from '../prisma.service';
import { RedisHealthIndicator } from './redis.health';
import { BrokerHealthIndicator } from './broker.health';
import { ConfigService } from '@nestjs/config';
import { BrokerFactory } from '../brokers/factory/broker.factory';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { TradingGateway } from '../websocket/gateway/trading.gateway';

const mockRedisPing = jest.fn().mockResolvedValue('PONG');

jest.mock('ioredis', () => {
  return jest.fn().mockImplementation(() => {
    return {
      connect: jest.fn().mockResolvedValue(undefined),
      ping: mockRedisPing,
      quit: jest.fn().mockResolvedValue(undefined),
    };
  });
});

describe('Health Indicators & Controller', () => {
  let controller: HealthController;
  let brokerIndicator: BrokerHealthIndicator;
  let redisIndicator: RedisHealthIndicator;
  let healthCheckServiceMock: any;
  let prismaHealthIndicatorMock: any;
  let prismaServiceMock: any;
  let configServiceMock: any;
  let redisMock: any;
  let mockAngelOneAdapter: any;
  let mockBrokerFactory: any;
  let redisServiceMock: any;
  let queueServiceMock: any;

  beforeEach(async () => {
    mockRedisPing.mockReset();
    mockRedisPing.mockResolvedValue('PONG');

    healthCheckServiceMock = {
      check: jest.fn().mockImplementation((indicators) => {
        return Promise.all(indicators.map((ind: any) => ind()));
      }),
    };

    prismaHealthIndicatorMock = {
      pingCheck: jest.fn().mockResolvedValue({ database: { status: 'up' } }),
    };

    prismaServiceMock = {
      baseClient: {},
    };

    configServiceMock = {
      get: jest.fn().mockImplementation((key, defaultValue) => {
        if (key === 'MOCK_BROKERS') return true;
        if (key === 'ANGEL_ONE_API_KEY') return 'test-api-key';
        if (key === 'REDIS_HOST') return 'localhost';
        if (key === 'REDIS_PORT') return 6379;
        return defaultValue;
      }),
    };

    redisMock = {
      ping: jest.fn().mockResolvedValue('PONG'),
    };

    mockAngelOneAdapter = {
      healthCheck: jest.fn(),
    };

    mockBrokerFactory = {
      getAdapter: jest.fn().mockReturnValue(mockAngelOneAdapter),
    };

    redisServiceMock = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: jest.fn().mockReturnValue({
        ping: mockRedisPing,
      }),
    };

    queueServiceMock = {
      getAggregatedMetrics: jest.fn().mockResolvedValue({
        waiting: 0,
        active: 0,
        failed: 0,
        dlq: 0,
      }),
      getQueue: jest.fn().mockReturnValue({
        getWaitingCount: jest.fn().mockResolvedValue(0),
      }),
    };

    const mockTradingGateway = {
      server: {
        engine: {
          clientsCount: 5,
        },
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        BrokerHealthIndicator,
        RedisHealthIndicator,
        { provide: HealthCheckService, useValue: healthCheckServiceMock },
        { provide: PrismaHealthIndicator, useValue: prismaHealthIndicatorMock },
        { provide: PrismaService, useValue: prismaServiceMock },
        { provide: ConfigService, useValue: configServiceMock },
        { provide: 'REDIS_CLIENT', useValue: redisMock },
        { provide: BrokerFactory, useValue: mockBrokerFactory },
        { provide: RedisService, useValue: redisServiceMock },
        { provide: QueueService, useValue: queueServiceMock },
        { provide: TradingGateway, useValue: mockTradingGateway },
      ],
    }).compile();

    controller = module.get<HealthController>(HealthController);
    brokerIndicator = module.get<BrokerHealthIndicator>(BrokerHealthIndicator);
    redisIndicator = module.get<RedisHealthIndicator>(RedisHealthIndicator);
  });

  describe('RedisHealthIndicator', () => {
    it('should return up status if ping is successful', async () => {
      const result = await redisIndicator.isHealthy('redis');
      expect(result).toEqual({ redis: { status: 'up' } });
    });

    it('should throw error if ping fails', async () => {
      mockRedisPing.mockRejectedValue(new Error('Redis Down'));
      await expect(redisIndicator.isHealthy('redis')).rejects.toThrow();
    });
  });

  describe('BrokerHealthIndicator', () => {
    it('should return up status when MOCK_BROKERS is true', async () => {
      configServiceMock.get.mockReturnValue(true);
      const result = await brokerIndicator.isHealthy('broker');
      expect(result.broker.status).toBe('up');
      expect(result.broker.message).toContain('Mock broker mode');
    });

    it('should check live API if MOCK_BROKERS is false', async () => {
      configServiceMock.get.mockImplementation((key, defaultValue) => {
        if (key === 'MOCK_BROKERS') return false;
        if (key === 'ANGEL_ONE_API_KEY') return 'test-key';
        return defaultValue;
      });
      mockAngelOneAdapter.healthCheck.mockResolvedValue({
        reachable: true,
        responseTimeMs: 50,
      });

      const result = await brokerIndicator.isHealthy('broker');
      expect(result.broker.status).toBe('up');
      expect(result.broker.reachable).toBe(true);
      expect(result.broker.responseTimeMs).toBe(50);
    });

    it('should report status down if api key is missing', async () => {
      configServiceMock.get.mockImplementation((key, defaultValue) => {
        if (key === 'MOCK_BROKERS') return false;
        if (key === 'ANGEL_ONE_API_KEY') return undefined;
        return defaultValue;
      });
      mockAngelOneAdapter.healthCheck.mockResolvedValue({
        reachable: true,
        responseTimeMs: 50,
      });

      await expect(brokerIndicator.isHealthy('broker')).rejects.toThrow();
    });

    it('should throw if healthCheck throws or fails', async () => {
      configServiceMock.get.mockReturnValue(false);
      mockAngelOneAdapter.healthCheck.mockRejectedValue(
        new Error('Unreachable'),
      );

      await expect(brokerIndicator.isHealthy('broker')).rejects.toThrow();
    });
  });

  describe('HealthController', () => {
    it('should check all health endpoints', async () => {
      const result = await controller.checkAll();
      expect(result).toBeDefined();
    });

    it('should check only db health', async () => {
      const result = await controller.checkDb();
      expect(result).toBeDefined();
    });

    it('should check only redis health', async () => {
      const result = await controller.checkRedis();
      expect(result).toBeDefined();
    });

    it('should check only broker health', async () => {
      const result = await controller.checkBroker();
      expect(result).toBeDefined();
    });

    it('should check queues metrics', async () => {
      const result = await controller.checkQueues();
      expect(result).toBeDefined();
      expect(queueServiceMock.getAggregatedMetrics).toHaveBeenCalled();
    });

    it('should check websocket health', async () => {
      const result = await controller.checkWebsocket();
      expect(result).toEqual({
        status: 'up',
        gateway: 'initialized',
        activeConnections: 5,
      });
    });

    it('should check outbox health', async () => {
      prismaServiceMock.outboxEvent = {
        count: jest.fn().mockResolvedValue(10),
      };
      queueServiceMock.getQueue = jest.fn().mockReturnValue({
        getWaitingCount: jest.fn().mockResolvedValue(2),
      });
      const result = await controller.checkOutbox();
      expect(result).toEqual({
        status: 'up',
        pendingEvents: 10,
        stuckEvents: 10,
        queueDepth: 2,
      });
    });

    it('should check reports health', async () => {
      queueServiceMock.getQueue = jest.fn().mockReturnValue({
        getWaitingCount: jest.fn().mockResolvedValue(5),
      });
      const result = await controller.checkReports();
      expect(result).toEqual({
        status: 'up',
        queueDepth: 5,
      });
    });

    it('should check queues health and report degraded when limits are exceeded', async () => {
      queueServiceMock.getQueue = jest.fn().mockReturnValue({
        getWaitingCount: jest.fn().mockResolvedValue(6000), // > 5000
      });
      queueServiceMock.getAggregatedMetrics = jest.fn().mockResolvedValue({
        waiting: 6000,
        active: 0,
        failed: 0,
        dlq: 0,
      });

      const result = await controller.checkQueues();
      expect(result).toEqual({
        status: 'degraded',
        signalProcessingDepth: 6000,
        orderPlacementDepth: 6000,
        reportDepth: 6000,
        waiting: 6000,
        active: 0,
        failed: 0,
        dlq: 0,
      });
    });

    it('should check analytics health', async () => {
      prismaServiceMock.analyticsJobRun = {
        findFirst: jest.fn().mockResolvedValue({
          id: 'run-1',
          startedAt: new Date(),
          completedAt: new Date(),
          status: 'SUCCESS',
          usersProcessed: 10,
          failures: 0,
          durationMs: 1200,
        }),
      };
      prismaServiceMock.user = {
        findMany: jest.fn().mockResolvedValue([
          { id: 'user-1' },
        ]),
      };
      prismaServiceMock.dailyPortfolioSnapshot = {
        findFirst: jest.fn().mockResolvedValue({
          date: new Date(),
        }),
      };

      const result = await controller.checkAnalytics();
      expect(result).toBeDefined();
      expect(result.status).toBe('healthy');
      expect(result.staleSnapshotsCount).toBe(0);
    });
  });
});
