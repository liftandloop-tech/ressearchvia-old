import { Test, TestingModule } from '@nestjs/testing';
import { CacheService } from './cache.service';
import { RedisService } from '../redis/redis.service';

describe('CacheService', () => {
  let service: CacheService;
  let redisService: RedisService;
  let clientMock: any;

  beforeEach(async () => {
    clientMock = {
      get: jest.fn(),
      set: jest.fn(),
      del: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CacheService,
        {
          provide: RedisService,
          useValue: {
            isHealthy: jest.fn().mockReturnValue(true),
            getClient: jest.fn().mockReturnValue(clientMock),
            assertHealthy: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<CacheService>(CacheService);
    redisService = module.get<RedisService>(RedisService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('get', () => {
    it('should retrieve and parse values on hit', async () => {
      clientMock.get.mockResolvedValue(JSON.stringify({ test: 'data' }));
      const res = await service.get<{ test: string }>('test_key');
      expect(res).toEqual({ test: 'data' });
      expect(clientMock.get).toHaveBeenCalledWith('test_key');
    });

    it('should return null on cache miss', async () => {
      clientMock.get.mockResolvedValue(null);
      const res = await service.get('test_key');
      expect(res).toBeNull();
    });

    it('should fallback to null if Redis is unhealthy', async () => {
      jest.spyOn(redisService, 'isHealthy').mockReturnValue(false);
      const res = await service.get('test_key');
      expect(res).toBeNull();
      expect(clientMock.get).not.toHaveBeenCalled();
    });

    it('should fallback to null if client get throws', async () => {
      clientMock.get.mockRejectedValue(new Error('Redis command failed'));
      const res = await service.get('test_key');
      expect(res).toBeNull();
    });
  });

  describe('set', () => {
    it('should set value with TTL if provided', async () => {
      clientMock.set.mockResolvedValue('OK');
      await service.set('test_key', { a: 1 }, 60);
      expect(redisService.assertHealthy).toHaveBeenCalled();
      expect(clientMock.set).toHaveBeenCalledWith('test_key', JSON.stringify({ a: 1 }), 'EX', 60);
    });

    it('should set value without TTL if not provided', async () => {
      clientMock.set.mockResolvedValue('OK');
      await service.set('test_key', { a: 1 });
      expect(clientMock.set).toHaveBeenCalledWith('test_key', JSON.stringify({ a: 1 }));
    });
  });

  describe('del', () => {
    it('should delete key', async () => {
      clientMock.del.mockResolvedValue(1);
      await service.del('test_key');
      expect(redisService.assertHealthy).toHaveBeenCalled();
      expect(clientMock.del).toHaveBeenCalledWith('test_key');
    });
  });
});
