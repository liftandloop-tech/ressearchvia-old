import { Test, TestingModule } from '@nestjs/testing';
import { ZebuService } from './zebu.service';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { BrokerRateLimiterService } from '../../infrastructure/redis/broker-rate-limiter.service';
import { PrismaService } from '../../prisma.service';
import { mockPrismaService } from '../../../test/mocks/prisma.mock';
import { of } from 'rxjs';
import { createHash } from 'crypto';
import { BadRequestException } from '@nestjs/common';
import { OrderRequest } from '../interfaces/broker-client.interface';

describe('ZebuService', () => {
  let service: ZebuService;
  let httpMock: any;
  let configMock: any;
  let redisMock: any;
  let metricsMock: any;
  let circuitBreakerMock: any;
  let rateLimiterMock: any;
  let prismaMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    httpMock = {
      post: jest.fn(),
      get: jest.fn(),
    };
    configMock = {
      get: jest.fn((key: string, defaultValue?: any) => {
        if (key === 'MOCK_BROKERS') return false; // test real logic paths
        if (key === 'ZEBU_BASE_URL')
          return 'https://go.mynt.in/NorenWClientAPI';
        return defaultValue;
      }),
    };
    redisMock = {
      getClient: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue(null),
        set: jest.fn().mockResolvedValue('OK'),
      }),
    };
    metricsMock = {
      incrementBrokerCalls: jest.fn(),
      observeBrokerLatency: jest.fn(),
    };
    circuitBreakerMock = {
      execute: jest.fn().mockImplementation((name, fn) => fn()),
    };
    rateLimiterMock = {
      throttle: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ZebuService,
        { provide: HttpService, useValue: httpMock },
        { provide: ConfigService, useValue: configMock },
        { provide: RedisService, useValue: redisMock },
        { provide: MetricsService, useValue: metricsMock },
        { provide: CircuitBreakerService, useValue: circuitBreakerMock },
        { provide: BrokerRateLimiterService, useValue: rateLimiterMock },
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = module.get<ZebuService>(ZebuService);
  });

  describe('completeAuthorization (OAuth Callback)', () => {
    it('should throw BadRequestException if auth code is missing', async () => {
      await expect(
        service.completeAuthorization({ params: {} } as any),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException if linked user broker config not found', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue(null);

      await expect(
        service.completeAuthorization({
          params: { code: 'test_auth_code_123', client_id: 'UNKNOWN_USER' },
        } as any),
      ).rejects.toThrow(BadRequestException);
    });

    it('should compute valid SHA-256 checksum and exchange code for session token', async () => {
      const mockUserBroker = {
        id: 'ub-zebu-1',
        userId: 'user-123',
        brokerClientId: 'ZEBU_CLI_1',
        apiKey: 'APP_KEY_123',
        apiSecret: 'SECRET_XYZ',
      };
      prismaMock.userBroker.findFirst.mockResolvedValue(mockUserBroker);

      const authCode = 'AUTH_CODE_ABC';
      // Expected SHA256(apiKey + apiSecret + authCode)
      const expectedHash = createHash('sha256')
        .update(`APP_KEY_123SECRET_XYZ${authCode}`)
        .digest('hex');

      httpMock.post.mockReturnValue(
        of({
          status: 200,
          data: {
            stat: 'Ok',
            access_token: 'valid_zebu_access_token',
            refresh_token: 'valid_zebu_refresh_token',
            actid: 'ZEBU_CLI_1',
          },
        }),
      );

      const session = await service.completeAuthorization({
        params: {
          code: authCode,
          userId: 'user-123',
        },
      });

      expect(session.accessToken).toBe('valid_zebu_access_token');
      expect(session.brokerUserId).toBe('ZEBU_CLI_1');

      // Verify the POST body contains the correct SHA256 checksum
      expect(httpMock.post).toHaveBeenCalledWith(
        expect.stringContaining('GenAcsTok'),
        expect.stringContaining(expectedHash),
        expect.any(Object),
      );
    });

    it('should throw Error if Zebu returns Not_Ok status on token exchange', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        apiKey: 'APP_KEY',
        apiSecret: 'SECRET',
        brokerClientId: 'CLI_1',
      });

      httpMock.post.mockReturnValue(
        of({
          status: 200,
          data: {
            stat: 'Not_Ok',
            emsg: 'Invalid checksum or expired code',
          },
        }),
      );

      await expect(
        service.completeAuthorization({
          params: { code: 'bad_code', client_id: 'CLI_1' },
        } as any),
      ).rejects.toThrow('Invalid checksum or expired code');
    });
  });

  describe('placeOrder', () => {
    it('should strictly place Intraday MIS (prd=I) orders with mapped order type and symbol suffix', async () => {
      httpMock.post.mockReturnValue(
        of({
          status: 200,
          data: {
            stat: 'Ok',
            norenordno: 'ZEBU_ORDER_9999',
          },
        }),
      );

      const orderRequest: OrderRequest = {
        symbol: 'RELIANCE',
        exchange: 'NSE',
        side: 'BUY',
        orderType: 'MARKET',
        quantity: 10,
        price: 0,
      };

      const result = await service.placeOrder(
        'mock_token_123',
        'CLIENT_ZB1',
        orderRequest,
      );

      expect(result.brokerOrderId).toBe('ZEBU_ORDER_9999');
      expect(result.status).toBe('PENDING');

      // Check the payload sent to Zebu
      const postCallArgs = httpMock.post.mock.calls[0];
      const sentBody = postCallArgs[1];

      // Must be MIS ('I') for intraday copy-trading
      expect(sentBody).toContain('"prd":"I"');
      // Symbol formatted with -EQ suffix for NSE equity
      expect(sentBody).toContain('"tsym":"RELIANCE-EQ"');
      // Transaction type B for BUY
      expect(sentBody).toContain('"trantype":"B"');
      // Product type MKT for MARKET order
      expect(sentBody).toContain('"prctyp":"MKT"');
      // Remarks AutoTrade
      expect(sentBody).toContain('"remarks":"AutoTrade"');
    });

    it('should handle order placement rejection from Zebu gracefully', async () => {
      httpMock.post.mockReturnValue(
        of({
          status: 200,
          data: {
            stat: 'Not_Ok',
            emsg: 'Insufficient funds for MIS order',
          },
        }),
      );

      const orderRequest: OrderRequest = {
        symbol: 'TCS',
        exchange: 'NSE',
        side: 'BUY',
        orderType: 'LIMIT',
        quantity: 50,
        price: 3500,
      };

      const result = await service.placeOrder(
        'mock_token_123',
        'CLIENT_ZB1',
        orderRequest,
      );

      expect(result.status).toBe('REJECTED');
      expect(result.message).toBe('Insufficient funds for MIS order');
    });
  });

  describe('getMargin / getFunds', () => {
    it('should return available margin from Zebu limits response', async () => {
      httpMock.post.mockReturnValue(
        of({
          status: 200,
          data: {
            stat: 'Ok',
            cash: '250000.50',
            marginused: '50000.00',
          },
        }),
      );

      const margin = await service.getMargin('mock_token_123', 'CLIENT_ZB1');
      expect(margin).toBe(250000.5);
    });

    it('should return 0 margin on broker error', async () => {
      httpMock.post.mockReturnValue(
        of({
          status: 200,
          data: {
            stat: 'Not_Ok',
            emsg: 'Session invalid',
          },
        }),
      );

      const margin = await service.getMargin('mock_token_123', 'CLIENT_ZB1');
      expect(margin).toBe(0);
    });
  });
});
