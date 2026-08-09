import { Test, TestingModule } from '@nestjs/testing';
import { MultiplierService, MultiplierState } from './multiplier.service';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';

const mockRedisClient = {
  get: jest.fn(),
  set: jest.fn(),
};

const mockRedisService = {
  isHealthy: jest.fn(),
  getClient: jest.fn().mockReturnValue(mockRedisClient),
};

const mockPrisma = {
  segmentMultiplier: {
    findFirst: jest.fn(),
    upsert: jest.fn(),
  },
  userSegment: {
    findFirst: jest.fn(),
  },
};

describe('MultiplierService', () => {
  let service: MultiplierService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MultiplierService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<MultiplierService>(MultiplierService);
    jest.clearAllMocks();
  });

  describe('getState()', () => {
    it('should return cached multiplier from Redis', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      const cached: MultiplierState = { index: 1, current: 2 };
      mockRedisClient.get.mockResolvedValue(JSON.stringify(cached));

      const result = await service.getState('user-1', 'seg-1');

      expect(result).toEqual(cached);
      expect(mockPrisma.segmentMultiplier.findFirst).not.toHaveBeenCalled();
    });

    it('should fallback to DB on Redis cache miss', async () => {
      mockRedisService.isHealthy.mockReturnValue(true);
      mockRedisClient.get.mockResolvedValue(null);
      mockRedisClient.set.mockResolvedValue('OK');
      mockPrisma.segmentMultiplier.findFirst.mockResolvedValue({
        lossStreak: 2,
        currentMultiplier: 4,
        currentLot: 4,
      });

      const result = await service.getState('user-1', 'seg-1');

      expect(result).toEqual({ index: 2, current: 4 });
    });

    it('should initialize with defaults when no DB record exists', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);
      mockPrisma.segmentMultiplier.findFirst.mockResolvedValue(null);
      mockPrisma.segmentMultiplier.upsert.mockResolvedValue({});

      const result = await service.getState('user-1', 'seg-1');

      expect(result).toEqual({ index: 0, current: 1 });
    });
  });

  describe('advanceOnLoss()', () => {
    it('should advance multiplier index and cap at maxMultiplier', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);
      mockPrisma.userSegment.findFirst.mockResolvedValue({ maxMultiplier: 4 });
      mockPrisma.segmentMultiplier.findFirst.mockResolvedValue({
        lossStreak: 1,
        currentMultiplier: 2,
        currentLot: 2,
      });
      mockPrisma.segmentMultiplier.upsert.mockResolvedValue({});

      const result = await service.advanceOnLoss('user-1', 'seg-1');

      // Default progression: [1, 2, 4, 8], index 1 → 2, value 4, capped at maxMultiplier=4
      expect(result.index).toBe(2);
      expect(result.current).toBe(4);
    });

    it('should not exceed maxMultiplier on consecutive losses', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);
      mockPrisma.userSegment.findFirst.mockResolvedValue({ maxMultiplier: 4 });
      mockPrisma.segmentMultiplier.findFirst.mockResolvedValue({
        lossStreak: 3,
        currentMultiplier: 8,
        currentLot: 8,
      });
      mockPrisma.segmentMultiplier.upsert.mockResolvedValue({});

      const result = await service.advanceOnLoss('user-1', 'seg-1');

      // Index stays capped at last progression index (3)
      expect(result.current).toBeLessThanOrEqual(4);
    });
  });

  describe('resetOnWin()', () => {
    it('should reset multiplier state to index=0, current=1', async () => {
      mockRedisService.isHealthy.mockReturnValue(false);
      mockPrisma.segmentMultiplier.upsert.mockResolvedValue({});

      await service.resetOnWin('user-1', 'seg-1');

      expect(mockPrisma.segmentMultiplier.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          update: expect.objectContaining({ lossStreak: 0, currentMultiplier: 1 }),
        }),
      );
    });
  });
});
