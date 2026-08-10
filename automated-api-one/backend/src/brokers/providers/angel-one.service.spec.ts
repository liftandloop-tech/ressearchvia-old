import { Test, TestingModule } from '@nestjs/testing';
import { AngelOneService } from './angel-one.service';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { BrokerRateLimiterService } from '../../infrastructure/redis/broker-rate-limiter.service';
import { InstrumentsService } from '../../instruments/instruments.service';
import { of } from 'rxjs';

// We test with MOCK_BROKERS=false to exercise the real order path
const configGet = (key: string, def?: any) => {
  if (key === 'MOCK_BROKERS') return false;
  if (key === 'ANGEL_ONE_API_KEY') return 'TEST_API_KEY';
  return def;
};

const makeMockHttpService = () => ({
  post: jest.fn(),
  get: jest.fn(),
});

const makeMockMetrics = () => ({
  incrementBrokerCalls: jest.fn(),
  observeBrokerLatency: jest.fn(),
  incrementBrokerFailures: jest.fn(),
});

const makeMockCircuitBreaker = () => ({
  execute: jest.fn((name: string, fn: () => any) => fn()),
});

const makeMockRateLimiter = () => ({
  throttle: jest.fn().mockResolvedValue(undefined),
});

const makeMockInstruments = () => ({
  findToken: jest.fn().mockReturnValue('12345'),
});

describe('AngelOneService.placeOrder', () => {
  let service: AngelOneService;
  let httpService: ReturnType<typeof makeMockHttpService>;

  beforeEach(async () => {
    httpService = makeMockHttpService();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AngelOneService,
        { provide: HttpService, useValue: httpService },
        { provide: ConfigService, useValue: { get: jest.fn(configGet) } },
        { provide: RedisService, useValue: { isHealthy: () => false } },
        { provide: MetricsService, useValue: makeMockMetrics() },
        { provide: CircuitBreakerService, useValue: makeMockCircuitBreaker() },
        { provide: BrokerRateLimiterService, useValue: makeMockRateLimiter() },
        { provide: InstrumentsService, useValue: makeMockInstruments() },
      ],
    }).compile();

    service = module.get<AngelOneService>(AngelOneService);
  });

  describe('proxy injection into X-ClientPublicIP header', () => {
    const order = {
      symbol: 'NIFTY24DECFUT',
      exchange: 'NFO',
      side: 'BUY' as const,
      quantity: 1,
      price: 22500,
      orderType: 'LIMIT' as const,
    };

    it('should use the proxy IP in X-ClientPublicIP when a proxy agent is provided', async () => {
      // Simulate an httpsAgent whose .proxy.hostname resolves to our IP
      const fakeProxy = new URL('http://user:pass@10.20.30.40:3128');
      const fakeAgent = {
        options: {
          href: 'http://user:pass@10.20.30.40:3128',
        },
        proxy: fakeProxy,
      };

      httpService.post.mockReturnValue(
        of({
          data: {
            status: true,
            data: { orderid: 'AOB123456' },
          },
        }),
      );

      await service.placeOrder('TOKEN_ABC', 'CLIENT01', order, fakeAgent);

      // Capture the config object passed to httpService.post
      const callArgs = httpService.post.mock.calls[0];
      const axiosConfig = callArgs[2] as any;
      expect(axiosConfig.headers['X-ClientPublicIP']).toBe('10.20.30.40');
    });

    it('should fall back to default IP in X-ClientPublicIP when no proxy agent is provided', async () => {
      httpService.post.mockReturnValue(
        of({
          data: {
            status: true,
            data: { orderid: 'AOB999999' },
          },
        }),
      );

      await service.placeOrder('TOKEN_ABC', 'CLIENT01', order, undefined);

      const callArgs = httpService.post.mock.calls[0];
      const axiosConfig = callArgs[2] as any;
      // Default fallback IP defined in getHeaders
      expect(axiosConfig.headers['X-ClientPublicIP']).toBe('106.193.147.98');
    });

    it('should attach httpsAgent to the axios config when a proxy agent is provided', async () => {
      const fakeAgent = {
        options: { href: 'http://1.2.3.4:3128' },
        proxy: new URL('http://1.2.3.4:3128'),
      };

      httpService.post.mockReturnValue(
        of({ data: { status: true, data: { orderid: 'AOB111' } } }),
      );

      await service.placeOrder('TOKEN_ABC', 'CLIENT01', order, fakeAgent);

      const callArgs = httpService.post.mock.calls[0];
      const axiosConfig = callArgs[2] as any;
      expect(axiosConfig.httpsAgent).toBe(fakeAgent);
    });

    it('should NOT attach httpsAgent to axios config when no proxy is provided', async () => {
      httpService.post.mockReturnValue(
        of({ data: { status: true, data: { orderid: 'AOB222' } } }),
      );

      await service.placeOrder('TOKEN_ABC', 'CLIENT01', order, undefined);

      const callArgs = httpService.post.mock.calls[0];
      const axiosConfig = callArgs[2] as any;
      expect(axiosConfig.httpsAgent).toBeUndefined();
    });

    it('should return success result when broker responds with status=true', async () => {
      httpService.post.mockReturnValue(
        of({ data: { status: true, data: { orderid: 'AOB_SUCCESS' } } }),
      );

      const result = await service.placeOrder('TOKEN_ABC', 'CLIENT01', order);
      expect(result.brokerOrderId).toBe('AOB_SUCCESS');
      expect(result.status).toBe('PENDING');
    });

    it('should return REJECTED when broker responds with status=false', async () => {
      httpService.post.mockReturnValue(
        of({ data: { status: false, message: 'Insufficient funds' } }),
      );

      const result = await service.placeOrder('TOKEN_ABC', 'CLIENT01', order);
      expect(result.status).toBe('REJECTED');
      expect(result.message).toBe('Insufficient funds');
    });
  });
});
