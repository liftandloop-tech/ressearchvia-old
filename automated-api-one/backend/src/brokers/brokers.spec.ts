import { Test, TestingModule } from '@nestjs/testing';
import { BrokerRegistry } from './registry/broker.registry';
import { BrokerFactory } from './factory/broker.factory';
import { BrokerType } from './interfaces/broker-type.enum';
import { BrokerAdapter } from './interfaces/broker-adapter.interface';
import { AngelOneService } from './providers/angel-one.service';
import { BrokerSessionService } from './services/broker-session.service';
import { AuditService } from '../audit/audit.service';
import { AuditEventType } from '../audit/enums/audit-event.enum';
import { PrismaService } from '../prisma.service';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { NotImplementedException } from '@nestjs/common';
import { BrokerCode } from '@prisma/client';
import { RedisService } from '../infrastructure/redis/redis.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { CircuitBreakerService } from '../infrastructure/circuit-breaker/circuit-breaker.service';
import { BrokerRateLimiterService } from '../infrastructure/redis/broker-rate-limiter.service';
import { InstrumentsService } from '../instruments/instruments.service';

describe('Brokers Module Tests', () => {
  let registry: BrokerRegistry;
  let factory: BrokerFactory;
  let sessionService: BrokerSessionService;
  let auditService: AuditService;
  let angelOneService: AngelOneService;
  let prismaService: PrismaService;

  // Mock services
  const mockAuditService = {
    logEvent: jest.fn().mockResolvedValue({}),
  };

  const mockRedisService = {
    isHealthy: jest.fn().mockReturnValue(true),
    getClient: jest.fn().mockReturnValue({
      get: jest.fn(),
      set: jest.fn(),
    }),
  };

  const mockMetricsService = {
    incrementBrokerCalls: jest.fn(),
    incrementBrokerFailures: jest.fn(),
    observeBrokerLatency: jest.fn(),
  };

  const mockCircuitBreakerService = {
    execute: jest.fn().mockImplementation((key, operation) => operation()),
  };

  const mockRateLimiter = {
    throttle: jest.fn().mockResolvedValue(true),
  };

  const mockUserBroker = {
    id: 'ub-123',
    userId: 'user-123',
    brokerId: 'broker-123',
    brokerClientId: 'client-123',
    accessToken: 'mock_angel_one_access_token_client-123_12345',
    refreshToken: 'mock_angel_one_refresh_token_client-123',
    tokenExpiry: new Date(Date.now() + 3600000),
  };

  const mockBroker = {
    id: 'broker-123',
    code: BrokerCode.ANGEL_ONE,
    name: 'ANGEL ONE',
  };

  const mockPrismaService = {
    broker: {
      findFirst: jest.fn().mockResolvedValue(mockBroker),
    },
    userBroker: {
      findFirst: jest.fn().mockResolvedValue(mockUserBroker),
      update: jest.fn().mockImplementation((args) => {
        return Promise.resolve({
          ...mockUserBroker,
          ...args.data,
        });
      }),
    },
    auditLog: {
      create: jest.fn().mockResolvedValue({}),
    },
  };

  const mockConfigService = {
    get: jest.fn().mockImplementation((key, defaultValue) => {
      if (key === 'MOCK_BROKERS') return true;
      return defaultValue;
    }),
  };

  const mockHttpService = {
    get: jest.fn(),
    post: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BrokerRegistry,
        BrokerFactory,
        BrokerSessionService,
        AngelOneService,
        { provide: AuditService, useValue: mockAuditService },
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: HttpService, useValue: mockHttpService },
        { provide: RedisService, useValue: mockRedisService },
        { provide: MetricsService, useValue: mockMetricsService },
        { provide: CircuitBreakerService, useValue: mockCircuitBreakerService },
        { provide: BrokerRateLimiterService, useValue: mockRateLimiter },
        { provide: InstrumentsService, useValue: {} },
      ],
    }).compile();

    registry = module.get<BrokerRegistry>(BrokerRegistry);
    factory = module.get<BrokerFactory>(BrokerFactory);
    sessionService = module.get<BrokerSessionService>(BrokerSessionService);
    auditService = module.get<AuditService>(AuditService);
    angelOneService = module.get<AngelOneService>(AngelOneService);
    prismaService = module.get<PrismaService>(PrismaService);

    // Initialize registry
    registry.onModuleInit();
  });

  describe('BrokerRegistry & BrokerFactory', () => {
    it('should register AngelOne adapter on module init', () => {
      expect(registry.get(BrokerType.ANGEL_ONE)).toBe(angelOneService);
      expect(registry.has(BrokerType.ANGEL_ONE)).toBe(true);
    });

    it('should return false for unregistered broker in has()', () => {
      expect(registry.has('ZERODHA' as BrokerType)).toBe(false);
    });

    it('should throw NotImplementedException for ZERODHA factory request', () => {
      expect(() => factory.getAdapter('ZERODHA' as BrokerType)).toThrow(
        new NotImplementedException('ZERODHA adapter not implemented'),
      );
    });

    it('should return adapter from factory if registered', () => {
      const adapter = factory.getAdapter(BrokerType.ANGEL_ONE);
      expect(adapter).toBe(angelOneService);
    });
  });

  describe('AngelOneService Mock Mode', () => {
    it('should report correct capabilities', () => {
      const caps = angelOneService.capabilities();
      expect(caps).toEqual({
        positions: true,
        holdings: true,
        funds: true,
        gtt: false,
        margin: true,
      });
    });

    it('should return mock health check', async () => {
      const health = await angelOneService.healthCheck();
      expect(health.reachable).toBe(true);
      expect(health.responseTimeMs).toBeDefined();
    });

    it('should generate session with mock tokens', async () => {
      const session = await angelOneService.generateSession({
        clientCode: 'TEST01',
        password: '1234',
        totpKey: 'SECRET',
      });
      expect(session.accessToken).toContain(
        'mock_angel_one_access_token_TEST01_',
      );
      expect(session.refreshToken).toBe('mock_angel_one_refresh_token_TEST01');
      expect(session.tokenExpiry).toBeInstanceOf(Date);
    });

    it('should validate mock tokens', async () => {
      const valid = await angelOneService.validateSession(
        'mock_angel_one_access_token_123',
      );
      expect(valid).toBe(true);
      const invalid = await angelOneService.validateSession('invalid_token');
      expect(invalid).toBe(false);
    });

    it('should get mock margins and funds', async () => {
      const margin = await angelOneService.getMargin('token', 'TEST01');
      expect(margin).toBe(150000.0);

      const funds = await angelOneService.getFunds('token', 'TEST01');
      expect(funds).toEqual({
        availableMargin: 150000.0,
        usedMargin: 0.0,
        totalMargin: 150000.0,
      });
    });

    it('should place order successfully in mock mode', async () => {
      const order = await angelOneService.placeOrder('token', 'TEST01', {
        symbol: 'SBIN-EQ',
        exchange: 'NSE',
        quantity: 10,
        orderType: 'MARKET',
        side: 'BUY',
      });
      expect(order.brokerOrderId).toContain('mock_order_');
      expect(order.status).toBe('EXECUTED');
    });

    it('should get mock order status', async () => {
      const status = await angelOneService.getOrderStatus(
        'token',
        'TEST01',
        'mock_order_123',
      );
      expect(status.status).toBe('EXECUTED');
      expect(status.brokerOrderId).toBe('mock_order_123');
    });

    it('should get mock positions and holdings', async () => {
      const positions = await angelOneService.getPositions('token', 'TEST01');
      expect(positions.length).toBe(1);
      expect(positions[0].symbol).toBe('SBIN-EQ');

      const holdings = await angelOneService.getHoldings('token', 'TEST01');
      expect(holdings.length).toBe(1);
      expect(holdings[0].symbol).toBe('TATASTEEL-EQ');
    });

    it('should refresh session with mock tokens', async () => {
      const session = await angelOneService.refreshSession(
        'token',
        'refresh_token',
      );
      expect(session.accessToken).toContain(
        'mock_angel_one_access_token_refreshed_',
      );
    });
  });

  describe('BrokerSessionService', () => {
    it('should store session and emit BROKER_CONNECTED', async () => {
      const session = {
        accessToken: 'new_token',
        refreshToken: 'new_refresh',
        tokenExpiry: new Date(),
      };
      await sessionService.storeSession(
        'user-123',
        BrokerCode.ANGEL_ONE,
        session,
        'ub-123',
      );
      expect(prismaService.userBroker.update).toHaveBeenCalled();
      expect(mockAuditService.logEvent).toHaveBeenCalledWith(
        'user-123',
        AuditEventType.BROKER_CONNECTED,
        'UserBroker',
        'ub-123',
        expect.any(Object),
      );
    });

    it('should refresh session and emit BROKER_SESSION_REFRESHED', async () => {
      const newSession = await sessionService.refreshSession(
        'user-123',
        BrokerCode.ANGEL_ONE,
      );
      expect(newSession.accessToken).toContain(
        'mock_angel_one_access_token_refreshed_',
      );
      expect(mockAuditService.logEvent).toHaveBeenCalledWith(
        'user-123',
        AuditEventType.BROKER_SESSION_REFRESHED,
        'UserBroker',
        'ub-123',
        expect.any(Object),
      );
    });

    it('should log failed event on refresh error', async () => {
      jest
        .spyOn(angelOneService, 'refreshSession')
        .mockRejectedValue(new Error('Refresh failed'));
      await expect(
        sessionService.refreshSession('user-123', BrokerCode.ANGEL_ONE),
      ).rejects.toThrow('Refresh failed');
      expect(mockAuditService.logEvent).toHaveBeenCalledWith(
        'user-123',
        AuditEventType.BROKER_SESSION_FAILED,
        'UserBroker',
        'ub-123',
        expect.any(Object),
      );
    });

    it('should invalidate session and emit BROKER_DISCONNECTED', async () => {
      await sessionService.invalidateSession('user-123', BrokerCode.ANGEL_ONE);
      expect(prismaService.userBroker.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { accessToken: null, refreshToken: null, tokenExpiry: null },
        }),
      );
      expect(mockAuditService.logEvent).toHaveBeenCalledWith(
        'user-123',
        AuditEventType.BROKER_DISCONNECTED,
        'UserBroker',
        'ub-123',
        expect.any(Object),
      );
    });

    it('should detect token expiry correctly', () => {
      expect(sessionService.isSessionExpired(null)).toBe(true);
      expect(
        sessionService.isSessionExpired(new Date(Date.now() - 10000)),
      ).toBe(true);
      expect(
        sessionService.isSessionExpired(new Date(Date.now() + 10000)),
      ).toBe(false);
    });

    it('should validate session using adapter', async () => {
      const valid = await sessionService.validateSession(
        'user-123',
        BrokerCode.ANGEL_ONE,
      );
      expect(valid).toBe(true);
    });
  });

  describe('Broker End-to-End Flow (Mock)', () => {
    it('should successfully complete the entire mock authorization and lifecycle flow', async () => {
      // 1. Generate Session
      const session = await angelOneService.generateSession({
        clientCode: 'client-123',
        password: '1234',
        totpKey: 'SECRET',
      });
      expect(session.accessToken).toBeDefined();

      // 2. Store Session
      await sessionService.storeSession(
        'user-123',
        BrokerCode.ANGEL_ONE,
        session,
        'ub-123',
      );
      expect(mockAuditService.logEvent).toHaveBeenLastCalledWith(
        'user-123',
        AuditEventType.BROKER_CONNECTED,
        'UserBroker',
        'ub-123',
        expect.any(Object),
      );

      // 3. Validate Session
      const isValid = await sessionService.validateSession(
        'user-123',
        BrokerCode.ANGEL_ONE,
      );
      expect(isValid).toBe(true);

      // 4. Refresh Session
      const refreshed = await sessionService.refreshSession(
        'user-123',
        BrokerCode.ANGEL_ONE,
      );
      expect(refreshed.accessToken).toContain(
        'mock_angel_one_access_token_refreshed_',
      );
      expect(mockAuditService.logEvent).toHaveBeenLastCalledWith(
        'user-123',
        AuditEventType.BROKER_SESSION_REFRESHED,
        'UserBroker',
        'ub-123',
        expect.any(Object),
      );

      // 5. Invalidate Session
      await sessionService.invalidateSession('user-123', BrokerCode.ANGEL_ONE);
      expect(mockAuditService.logEvent).toHaveBeenLastCalledWith(
        'user-123',
        AuditEventType.BROKER_DISCONNECTED,
        'UserBroker',
        'ub-123',
        expect.any(Object),
      );
    });
  });

  describe('AngelOneService Redirect Authentication Flow', () => {
    it('should generate a valid authorization URL containing apiKey, redirectUrl and state', async () => {
      mockConfigService.get.mockImplementation((key, defaultValue) => {
        if (key === 'MOCK_BROKERS') return true;
        if (key === 'ANGEL_ONE_API_KEY') return 'test_api_key';
        if (key === 'ANGEL_ONE_REDIRECT_URL') return 'https://example.com/callback';
        return defaultValue;
      });

      const authUrl = await angelOneService.getAuthorizationUrl('my-random-state-123');
      expect(authUrl).toContain('smartapi.angelone.in/publisher-login');
      expect(authUrl).toContain('api_key=test_api_key');
      expect(authUrl).toContain('state=my-random-state-123');
      expect(authUrl).toContain(encodeURIComponent('https://example.com/callback'));
    });

    it('should complete authorization and return mock session', async () => {
      const session = await angelOneService.completeAuthorization({
        params: {
          auth_token: 'test_auth_token_456',
          state: 'my-random-state-123',
        },
      });
      expect(session.accessToken).toContain('mock_angel_one_access_token_');
      expect(session.refreshToken).toContain('mock_angel_one_refresh_token_');
      expect(session.expiresAt).toBeDefined();
    });
  });
});
