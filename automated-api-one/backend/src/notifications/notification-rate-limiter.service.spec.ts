import { Test, TestingModule } from '@nestjs/testing';
import { NotificationRateLimiterService } from './notification-rate-limiter.service';
import { RedisService } from '../infrastructure/redis/redis.service';

describe('NotificationRateLimiterService', () => {
  let service: NotificationRateLimiterService;
  let redisServiceMock: any;
  let redisClientMock: any;
  let multiMock: any;

  beforeEach(async () => {
    multiMock = {
      zremrangebyscore: jest.fn().mockReturnThis(),
      zadd: jest.fn().mockReturnThis(),
      zcard: jest.fn().mockReturnThis(),
      expire: jest.fn().mockReturnThis(),
      exec: jest.fn(),
    };

    redisClientMock = {
      multi: jest.fn().mockReturnValue(multiMock),
    };

    redisServiceMock = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: jest.fn().mockReturnValue(redisClientMock),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationRateLimiterService,
        { provide: RedisService, useValue: redisServiceMock },
      ],
    }).compile();

    service = module.get<NotificationRateLimiterService>(NotificationRateLimiterService);
  });

  it('should return false if Redis is unhealthy (fail open)', async () => {
    redisServiceMock.isHealthy.mockReturnValue(false);
    const result = await service.isRateLimited('user-1', 'SMS');
    expect(result).toBe(false);
    expect(redisServiceMock.getClient).not.toHaveBeenCalled();
  });

  it('should return false if Redis transaction returns count below limit', async () => {
    // results[2] is ZCARD, which returns [err, count]
    multiMock.exec.mockResolvedValue([
      [null, 1],
      [null, 1],
      [null, 2], // ZCARD returns 2
      [null, 1],
    ]);

    const result = await service.isRateLimited('user-1', 'SMS');
    expect(result).toBe(false);
    expect(multiMock.zremrangebyscore).toHaveBeenCalled();
    expect(multiMock.zadd).toHaveBeenCalled();
    expect(multiMock.zcard).toHaveBeenCalled();
    expect(multiMock.expire).toHaveBeenCalled();
  });

  it('should return true if Redis transaction returns count above limit', async () => {
    // SMS limit is 10
    multiMock.exec.mockResolvedValue([
      [null, 1],
      [null, 1],
      [null, 12], // ZCARD returns 12
      [null, 1],
    ]);

    const result = await service.isRateLimited('user-1', 'SMS');
    expect(result).toBe(true);
  });

  it('should fail open and return false if Redis command fails', async () => {
    multiMock.exec.mockRejectedValue(new Error('Redis error'));
    const result = await service.isRateLimited('user-1', 'SMS');
    expect(result).toBe(false);
  });
});
