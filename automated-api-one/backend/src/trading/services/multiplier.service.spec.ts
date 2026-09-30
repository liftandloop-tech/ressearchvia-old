import { Test, TestingModule } from '@nestjs/testing';
import { MultiplierService, MultiplierState } from './multiplier.service';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { PositionSizingService } from './position-sizing.service';

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

const mockPositionSizingService = {
  getState: jest.fn().mockResolvedValue({ index: 0, current: 1 }),
  advanceOnLoss: jest.fn().mockResolvedValue({ index: 1, current: 2 }),
  resetOnWin: jest.fn().mockResolvedValue(undefined),
};

describe('MultiplierService', () => {
  let service: MultiplierService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MultiplierService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: RedisService, useValue: mockRedisService },
        { provide: PositionSizingService, useValue: mockPositionSizingService },
      ],
    }).compile();

    service = module.get<MultiplierService>(MultiplierService);
    jest.clearAllMocks();
  });

  describe('getState()', () => {
    it('should delegate getState to PositionSizingService', async () => {
      mockPositionSizingService.getState.mockResolvedValueOnce({ index: 1, current: 2 });
      const result = await service.getState('user-1', 'seg-1');

      expect(mockPositionSizingService.getState).toHaveBeenCalledWith('user-1', 'seg-1');
      expect(result).toEqual({ index: 1, current: 2 });
    });
  });

  describe('advanceOnLoss()', () => {
    it('should delegate advanceOnLoss to PositionSizingService', async () => {
      mockPositionSizingService.advanceOnLoss.mockResolvedValueOnce({ index: 2, current: 4 });
      const result = await service.advanceOnLoss('user-1', 'seg-1');

      expect(mockPositionSizingService.advanceOnLoss).toHaveBeenCalledWith('user-1', 'seg-1');
      expect(result).toEqual({ index: 2, current: 4 });
    });
  });

  describe('resetOnWin()', () => {
    it('should delegate resetOnWin to PositionSizingService', async () => {
      mockPositionSizingService.resetOnWin.mockResolvedValueOnce(undefined);
      await service.resetOnWin('user-1', 'seg-1');

      expect(mockPositionSizingService.resetOnWin).toHaveBeenCalledWith('user-1', 'seg-1');
    });
  });
});
