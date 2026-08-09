import { Test, TestingModule } from '@nestjs/testing';
import { DistributedLockService } from './distributed-lock.service';
import { RedisService } from '../redis/redis.service';

describe('DistributedLockService', () => {
  let service: DistributedLockService;
  let redisService: RedisService;
  let clientMock: any;

  beforeEach(async () => {
    clientMock = {
      set: jest.fn(),
      eval: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DistributedLockService,
        {
          provide: RedisService,
          useValue: {
            assertHealthy: jest.fn(),
            getClient: jest.fn().mockReturnValue(clientMock),
          },
        },
      ],
    }).compile();

    service = module.get<DistributedLockService>(DistributedLockService);
    redisService = module.get<RedisService>(RedisService);
    jest.useFakeTimers();
  });

  afterEach(() => {
    service.onModuleDestroy();
    jest.useRealTimers();
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('acquireLock', () => {
    it('should acquire lock successfully and return a token', async () => {
      clientMock.set.mockResolvedValue('OK');
      const token = await service.acquireLock('my_lock', 10000);
      expect(redisService.assertHealthy).toHaveBeenCalled();
      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(clientMock.set).toHaveBeenCalledWith('my_lock', token, 'PX', 10000, 'NX');
    });

    it('should return null if lock acquisition fails', async () => {
      clientMock.set.mockResolvedValue(null);
      const token = await service.acquireLock('my_lock', 10000);
      expect(token).toBeNull();
    });

    it('should setup auto-renewal if requested', async () => {
      clientMock.set.mockResolvedValue('OK');
      clientMock.eval.mockResolvedValue(1); // Successful extension

      const token = await service.acquireLock('my_lock', 3000, { autoRenew: true });
      expect(token).toBeDefined();

      // Interval is ttlMs / 3 = 1000ms. Fast forward 1000ms.
      await jest.advanceTimersByTimeAsync(1000);
      expect(clientMock.eval).toHaveBeenCalledWith(expect.any(String), 1, 'my_lock', token, 3000);
    });
  });

  describe('releaseLock', () => {
    it('should call eval with Lua release script', async () => {
      clientMock.eval.mockResolvedValue(1);
      const res = await service.releaseLock('my_lock', 'my_token');
      expect(res).toBe(true);
      expect(clientMock.eval).toHaveBeenCalledWith(expect.any(String), 1, 'my_lock', 'my_token');
    });

    it('should return false if lock released failed (e.g. token mismatch)', async () => {
      clientMock.eval.mockResolvedValue(0);
      const res = await service.releaseLock('my_lock', 'my_token');
      expect(res).toBe(false);
    });
  });

  describe('extendLock', () => {
    it('should call eval with Lua extension script', async () => {
      clientMock.eval.mockResolvedValue(1);
      const res = await service.extendLock('my_lock', 'my_token', 5000);
      expect(res).toBe(true);
      expect(clientMock.eval).toHaveBeenCalledWith(expect.any(String), 1, 'my_lock', 'my_token', 5000);
    });
  });
});
