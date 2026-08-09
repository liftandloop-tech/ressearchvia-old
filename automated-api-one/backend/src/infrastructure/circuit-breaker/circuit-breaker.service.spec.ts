import { Test, TestingModule } from '@nestjs/testing';
import { CircuitBreakerService, CircuitState, BrokerUnavailableException } from './circuit-breaker.service';
import { RedisService } from '../redis/redis.service';
import { ConfigService } from '@nestjs/config';
import { MetricsService } from '../metrics/metrics.service';

describe('CircuitBreakerService', () => {
  let service: CircuitBreakerService;
  let redisService: RedisService;
  let clientMock: any;

  beforeEach(async () => {
    clientMock = {
      get: jest.fn(),
      set: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CircuitBreakerService,
        {
          provide: RedisService,
          useValue: {
            isHealthy: jest.fn().mockReturnValue(true),
            getClient: jest.fn().mockReturnValue(clientMock),
          },
        },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key, defaultValue) => defaultValue),
          },
        },
        {
          provide: MetricsService,
          useValue: {
            setBrokerCircuitState: jest.fn(),
            observeBrokerCircuitOpenDuration: jest.fn(),
            incrementBrokerCircuitOpen: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<CircuitBreakerService>(CircuitBreakerService);
    redisService = module.get<RedisService>(RedisService);
    jest.useFakeTimers();
  });

  afterEach(() => {
    jest.useRealTimers();
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('execute', () => {
    it('should run operation successfully in CLOSED state', async () => {
      clientMock.get.mockResolvedValue(null); // No previous state -> defaults to CLOSED
      const op = jest.fn().mockResolvedValue('success');

      const res = await service.execute('ANGEL_ONE', op);

      expect(res).toBe('success');
      expect(op).toHaveBeenCalled();
      expect(clientMock.set).toHaveBeenCalledWith(
        'circuit:ANGEL_ONE',
        expect.stringContaining('"state":"CLOSED"'),
        'EX',
        86400,
      );
    });

    it('should transition to OPEN after 3 failures', async () => {
      clientMock.get.mockResolvedValue(null);
      const op = jest.fn().mockRejectedValue(new Error('Broker timeout'));

      // 1st failure
      await expect(service.execute('ANGEL_ONE', op)).rejects.toThrow('Broker timeout');
      // 2nd failure
      clientMock.get.mockResolvedValue(JSON.stringify({ state: CircuitState.CLOSED, failures: 1, lastChange: Date.now() }));
      await expect(service.execute('ANGEL_ONE', op)).rejects.toThrow('Broker timeout');
      // 3rd failure (trips)
      clientMock.get.mockResolvedValue(JSON.stringify({ state: CircuitState.CLOSED, failures: 2, lastChange: Date.now() }));
      await expect(service.execute('ANGEL_ONE', op)).rejects.toThrow('Broker timeout');

      expect(clientMock.set).toHaveBeenLastCalledWith(
        'circuit:ANGEL_ONE',
        expect.stringContaining('"state":"OPEN"'),
        'EX',
        86400,
      );
    });

    it('should block requests in OPEN state', async () => {
      // Set circuit as OPEN
      clientMock.get.mockResolvedValue(JSON.stringify({
        state: CircuitState.OPEN,
        failures: 3,
        lastChange: Date.now(),
      }));

      const op = jest.fn();
      await expect(service.execute('ANGEL_ONE', op)).rejects.toThrow(BrokerUnavailableException);
      expect(op).not.toHaveBeenCalled();
    });

    it('should transition to HALF_OPEN after cooldown expires', async () => {
      const startTime = Date.now();
      clientMock.get.mockResolvedValue(JSON.stringify({
        state: CircuitState.OPEN,
        failures: 3,
        lastChange: startTime,
      }));

      // Fast forward time by 60 seconds (60000ms)
      jest.advanceTimersByTime(60000);

      const op = jest.fn().mockResolvedValue('pilot-success');
      const res = await service.execute('ANGEL_ONE', op);

      expect(res).toBe('pilot-success');
      expect(op).toHaveBeenCalled();
      expect(clientMock.set).toHaveBeenCalledWith(
        'circuit:ANGEL_ONE',
        expect.stringContaining('"state":"HALF_OPEN"'),
        'EX',
        86400,
      );
      expect(clientMock.set).toHaveBeenLastCalledWith(
        'circuit:ANGEL_ONE',
        expect.stringContaining('"state":"CLOSED"'),
        'EX',
        86400,
      );
    });
  });
});
