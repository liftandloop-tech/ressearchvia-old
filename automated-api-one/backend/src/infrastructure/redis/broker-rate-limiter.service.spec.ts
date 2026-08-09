import { Test, TestingModule } from '@nestjs/testing';
import { BrokerRateLimiterService, BrokerRateLimitException } from './broker-rate-limiter.service';
import { RedisService } from './redis.service';
import { ConfigService } from '@nestjs/config';

describe('BrokerRateLimiterService', () => {
  let service: BrokerRateLimiterService;
  let redisService: RedisService;
  let clientMock: any;
  let multiMock: any;
  let execMock: any;

  beforeEach(async () => {
    execMock = jest.fn();
    multiMock = {
      zremrangebyscore: jest.fn().mockReturnThis(),
      zadd: jest.fn().mockReturnThis(),
      zcard: jest.fn().mockReturnThis(),
      expire: jest.fn().mockReturnThis(),
      exec: execMock,
    };

    clientMock = {
      multi: jest.fn().mockReturnValue(multiMock),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BrokerRateLimiterService,
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
      ],
    }).compile();

    service = module.get<BrokerRateLimiterService>(BrokerRateLimiterService);
    redisService = module.get<RedisService>(RedisService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should allow requests under rate limit threshold', async () => {
    execMock.mockResolvedValue([
      [null, 1], // ZREMRANGEBYSCORE count
      [null, 1], // ZADD status
      [null, 50], // ZCARD count (under 100 limit)
      [null, 1], // EXPIRE status
    ]);

    const res = await service.throttle('ANGEL_ONE');
    expect(res).toBe(true);
    expect(multiMock.zcard).toHaveBeenCalled();
  });

  it('should throw BrokerRateLimitException if rate limit is exceeded', async () => {
    execMock.mockResolvedValue([
      [null, 1],
      [null, 1],
      [null, 150], // ZCARD count (exceeds 100 limit)
      [null, 1],
    ]);

    await expect(service.throttle('ANGEL_ONE')).rejects.toThrow(BrokerRateLimitException);
  });

  it('should fail open (return true) if Redis is unhealthy', async () => {
    jest.spyOn(redisService, 'isHealthy').mockReturnValue(false);
    const res = await service.throttle('ANGEL_ONE');
    expect(res).toBe(true);
    expect(clientMock.multi).not.toHaveBeenCalled();
  });
});
