import { Test, TestingModule } from '@nestjs/testing';
import { NotificationDeduplicationService } from './notification-deduplication.service';
import { RedisService } from '../infrastructure/redis/redis.service';

describe('NotificationDeduplicationService', () => {
  let service: NotificationDeduplicationService;
  let redisServiceMock: any;
  let redisClientMock: any;

  beforeEach(async () => {
    redisClientMock = {
      set: jest.fn(),
    };

    redisServiceMock = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: jest.fn().mockReturnValue(redisClientMock),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationDeduplicationService,
        { provide: RedisService, useValue: redisServiceMock },
      ],
    }).compile();

    service = module.get<NotificationDeduplicationService>(NotificationDeduplicationService);
  });

  it('should return false if Redis is unhealthy (fail open)', async () => {
    redisServiceMock.isHealthy.mockReturnValue(false);
    const result = await service.shouldDeduplicate('test-fingerprint');
    expect(result).toBe(false);
    expect(redisClientMock.set).not.toHaveBeenCalled();
  });

  it('should return false (no deduplication) if fingerprint is new and SET NX returns OK', async () => {
    redisClientMock.set.mockResolvedValue('OK');
    const result = await service.shouldDeduplicate('test-fingerprint');
    expect(result).toBe(false);
    expect(redisClientMock.set).toHaveBeenCalledWith(
      'notifications:dedup:test-fingerprint',
      '1',
      'EX',
      60,
      'NX',
    );
  });

  it('should return true (deduplicated) if fingerprint exists and SET NX returns null', async () => {
    redisClientMock.set.mockResolvedValue(null);
    const result = await service.shouldDeduplicate('test-fingerprint');
    expect(result).toBe(true);
  });

  it('should fail open and return false if Redis command fails', async () => {
    redisClientMock.set.mockRejectedValue(new Error('Redis error'));
    const result = await service.shouldDeduplicate('test-fingerprint');
    expect(result).toBe(false);
  });
});
