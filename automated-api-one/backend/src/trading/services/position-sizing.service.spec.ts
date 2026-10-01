import { Test, TestingModule } from '@nestjs/testing';
import { PositionSizingService } from './position-sizing.service';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { mockPrismaService } from '../../../test/mocks/prisma.mock';
import { StrategyType, StrategyChangeSource } from '@prisma/client';

describe('PositionSizingService', () => {
  let service: PositionSizingService;
  let prismaMock: any;
  let redisMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    redisMock = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue(null),
        set: jest.fn().mockResolvedValue('OK'),
        del: jest.fn().mockResolvedValue(1),
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PositionSizingService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: RedisService, useValue: redisMock },
      ],
    }).compile();

    service = module.get<PositionSizingService>(PositionSizingService);
  });

  describe('calculatePositionSize', () => {
    it('should calculate 1x position size for FIXED_1X strategy', async () => {
      prismaMock.userTradingStrategy.findFirst.mockResolvedValue({
        id: 'strat-1',
        userId: 'u1',
        strategyType: StrategyType.FIXED_1X,
        currentMultiplier: 1,
        consecutiveLosses: 0,
        version: 1,
        agreementVersion: 'v1.0',
        lastTradeResult: 'NONE',
      });

      const sizing = await service.calculatePositionSize('u1', 'seg-1', 2);
      expect(sizing.strategyType).toBe(StrategyType.FIXED_1X);
      expect(sizing.multiplier).toBe(1);
      expect(sizing.baseQuantity).toBe(2);
      expect(sizing.actualQuantity).toBe(2);
    });

    it('should respect multiplier for LOSS_MULTIPLIER_2X strategy', async () => {
      prismaMock.userTradingStrategy.findFirst.mockResolvedValue({
        id: 'strat-2',
        userId: 'u1',
        strategyType: StrategyType.LOSS_MULTIPLIER_2X,
        currentMultiplier: 4,
        consecutiveLosses: 2,
        version: 1,
        agreementVersion: 'v1.0',
        lastTradeResult: 'LOSS',
      });

      const sizing = await service.calculatePositionSize('u1', 'seg-1', 3);
      expect(sizing.strategyType).toBe(StrategyType.LOSS_MULTIPLIER_2X);
      expect(sizing.multiplier).toBe(4);
      expect(sizing.baseQuantity).toBe(3);
      expect(sizing.actualQuantity).toBe(12); // 3 * 4
    });

    it('should cap multiplier at 16x ceiling for LOSS_MULTIPLIER_2X', async () => {
      prismaMock.userTradingStrategy.findFirst.mockResolvedValue({
        id: 'strat-3',
        userId: 'u1',
        strategyType: StrategyType.LOSS_MULTIPLIER_2X,
        currentMultiplier: 32, // exceeds cap
        consecutiveLosses: 5,
        version: 1,
        agreementVersion: 'v1.0',
        lastTradeResult: 'LOSS',
      });

      const sizing = await service.calculatePositionSize('u1', 'seg-1', 1);
      expect(sizing.multiplier).toBe(16); // capped at 16
      expect(sizing.actualQuantity).toBe(16);
    });
  });

  describe('handleTradeOutcome', () => {
    it('should double multiplier on loss up to 16x cap in LOSS_MULTIPLIER_2X', async () => {
      prismaMock.userTradingStrategy.findFirst.mockResolvedValue({
        id: 'strat-2x',
        userId: 'u1',
        strategyType: StrategyType.LOSS_MULTIPLIER_2X,
        currentMultiplier: 2,
        consecutiveLosses: 1,
        version: 1,
      });

      prismaMock.userTradingStrategy.updateMany.mockResolvedValue({ count: 1 });

      await service.handleTradeOutcome('u1', 'seg-1', 'LOSS');

      expect(prismaMock.userTradingStrategy.updateMany).toHaveBeenCalledWith({
        where: {
          userId: 'u1',
          OR: [{ segmentId: 'seg-1' }, { segmentId: null }],
        },
        data: expect.objectContaining({
          currentMultiplier: 4,
          consecutiveLosses: 2,
          lastTradeResult: 'LOSS',
          nextTradeMultiplier: 8,
        }),
      });
    });

    it('should reset multiplier to 1x on profit in LOSS_MULTIPLIER_2X', async () => {
      prismaMock.userTradingStrategy.findFirst.mockResolvedValue({
        id: 'strat-2x',
        userId: 'u1',
        strategyType: StrategyType.LOSS_MULTIPLIER_2X,
        currentMultiplier: 8,
        consecutiveLosses: 3,
        version: 1,
      });

      prismaMock.userTradingStrategy.updateMany.mockResolvedValue({ count: 1 });

      await service.handleTradeOutcome('u1', 'seg-1', 'PROFIT');

      expect(prismaMock.userTradingStrategy.updateMany).toHaveBeenCalledWith({
        where: {
          userId: 'u1',
          OR: [{ segmentId: 'seg-1' }, { segmentId: null }],
        },
        data: expect.objectContaining({
          currentMultiplier: 1,
          consecutiveLosses: 0,
          lastTradeResult: 'PROFIT',
          nextTradeMultiplier: 2,
        }),
      });
    });

    it('should keep multiplier at 1x in FIXED_1X even after loss', async () => {
      prismaMock.userTradingStrategy.findFirst.mockResolvedValue({
        id: 'strat-1x',
        userId: 'u1',
        strategyType: StrategyType.FIXED_1X,
        currentMultiplier: 1,
        consecutiveLosses: 0,
        version: 1,
      });

      prismaMock.userTradingStrategy.updateMany.mockResolvedValue({ count: 1 });

      await service.handleTradeOutcome('u1', 'seg-1', 'LOSS');

      expect(prismaMock.userTradingStrategy.updateMany).toHaveBeenCalledWith({
        where: {
          userId: 'u1',
          OR: [{ segmentId: 'seg-1' }, { segmentId: null }],
        },
        data: expect.objectContaining({
          currentMultiplier: 1,
          consecutiveLosses: 1,
          lastTradeResult: 'LOSS',
          nextTradeMultiplier: 1,
        }),
      });
    });
  });

  describe('switchStrategy', () => {
    it('should immediately reset to fresh 1x cycle when switching strategy', async () => {
      prismaMock.userTradingStrategy.findFirst.mockResolvedValue({
        id: 'strat-old',
        userId: 'u1',
        strategyType: StrategyType.FIXED_1X,
        currentMultiplier: 1,
        consecutiveLosses: 0,
        version: 1,
      });

      prismaMock.userTradingStrategy.upsert.mockResolvedValue({
        id: 'strat-new',
        userId: 'u1',
        strategyType: StrategyType.LOSS_MULTIPLIER_2X,
        currentMultiplier: 1,
        consecutiveLosses: 0,
        version: 2,
      });

      prismaMock.strategyChangeHistory = {
        create: jest.fn().mockResolvedValue({}),
      };

      const result = await service.switchStrategy(
        'u1',
        'seg-1',
        StrategyType.LOSS_MULTIPLIER_2X,
        'v1.1',
        'USER',
        StrategyChangeSource.USER_SETTINGS_CHANGE,
      );

      expect(result.strategyType).toBe(StrategyType.LOSS_MULTIPLIER_2X);
      expect(result.currentMultiplier).toBe(1);
      expect(result.consecutiveLosses).toBe(0);
      expect(prismaMock.strategyChangeHistory.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          userId: 'u1',
          previousStrategy: StrategyType.FIXED_1X,
          newStrategy: StrategyType.LOSS_MULTIPLIER_2X,
          changedBy: 'USER',
          newMultiplier: 1,
        }),
      });
    });
  });
});
