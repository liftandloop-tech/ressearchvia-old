import { Test, TestingModule } from '@nestjs/testing';
import { PositionCacheService, PositionCache } from './position-cache.service';
import { RedisService } from '../../infrastructure/redis/redis.service';

const mockRedisClient = {
  set: jest.fn(),
  get: jest.fn(),
  del: jest.fn(),
};

const mockRedisService = {
  isHealthy: jest.fn(),
  getClient: jest.fn().mockReturnValue(mockRedisClient),
};

describe('PositionCacheService', () => {
  let service: PositionCacheService;

  const samplePosition: PositionCache = {
    userId: 'user-1',
    segmentId: 'seg-1',
    tradeId: 'trade-1',
    symbol: 'NIFTY50',
    quantity: 10,
    entryPrice: 22000,
    stopLoss: 21800,
    targetPrice: 22300,
    side: 'BUY',
    cachedAt: '2024-01-01T09:00:00.000Z',
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PositionCacheService,
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<PositionCacheService>(PositionCacheService);
    jest.clearAllMocks();
  });

  describe('set()', () => {
    it('should write position to Redis when healthy', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.set.mockResolvedValue('OK');

      await service.set(samplePosition);

      expect(mockRedisClient.set).toHaveBeenCalledWith(
        `position:user-1:seg-1`,
        JSON.stringify(samplePosition),
        'EX',
        expect.any(Number),
      );
    });

    it('should skip write when Redis is unhealthy', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);

      await service.set(samplePosition);

      expect(mockRedisClient.set).not.toHaveBeenCalled();
    });

    it('should not throw on Redis error', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.set.mockRejectedValue(new Error('Redis timeout'));

      await expect(service.set(samplePosition)).resolves.not.toThrow();
    });
  });

  describe('get()', () => {
    it('should return deserialized position from Redis', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.get.mockResolvedValue(JSON.stringify(samplePosition));

      const result = await service.get('user-1', 'seg-1');

      expect(result).toEqual(samplePosition);
    });

    it('should return null on cache miss', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.get.mockResolvedValue(null);

      const result = await service.get('user-1', 'seg-1');

      expect(result).toBeNull();
    });

    it('should return null when Redis is unhealthy', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);

      const result = await service.get('user-1', 'seg-1');

      expect(result).toBeNull();
      expect(mockRedisClient.get).not.toHaveBeenCalled();
    });
  });

  describe('del()', () => {
    it('should delete position key from Redis', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.del.mockResolvedValue(1);

      await service.del('user-1', 'seg-1');

      expect(mockRedisClient.del).toHaveBeenCalledWith('position:user-1:seg-1');
    });

    it('should skip delete when Redis is unhealthy', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);

      await service.del('user-1', 'seg-1');

      expect(mockRedisClient.del).not.toHaveBeenCalled();
    });
  });
});
