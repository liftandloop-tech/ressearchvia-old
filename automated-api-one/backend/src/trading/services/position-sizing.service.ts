import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { RedisKeys } from '../../infrastructure/redis/redis-keys';
import { StrategyType, StrategyChangeSource, UserTradingStrategy } from '@prisma/client';

export interface SizingResult {
  strategyType: StrategyType;
  baseQuantity: number;
  multiplier: number;
  actualQuantity: number;
  consecutiveLosses: number;
  strategyVersion: number;
  agreementVersion: string;
  previousTradeResult: string | null;
}

export interface SystemConfigSnapshot {
  isFixed1xEnabled: boolean;
  isLossMultiplier2xEnabled: boolean;
  maxAllowedMultiplier: number;
  maxGlobalQuantity?: number | null;
  maxGlobalExposureInr?: number | null;
  maxConsecutiveLosses: number;
}

const DEFAULT_SYSTEM_CONFIG: SystemConfigSnapshot = {
  isFixed1xEnabled: true,
  isLossMultiplier2xEnabled: true,
  maxAllowedMultiplier: 16,
  maxGlobalQuantity: null,
  maxGlobalExposureInr: null,
  maxConsecutiveLosses: 5,
};

@Injectable()
export class PositionSizingService {
  private readonly logger = new Logger(PositionSizingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
  ) {}

  /**
   * Retrieves the system-wide strategy safety configuration.
   * Cached in Redis with short TTL; falls back to DB or default constants.
   */
  async getSystemConfig(): Promise<SystemConfigSnapshot> {
    const cacheKey = RedisKeys.systemStrategyConfig();

    if (this.redisService.isHealthy()) {
      try {
        const raw = await this.redisService.getClient().get(cacheKey);
        if (raw) {
          return JSON.parse(raw) as SystemConfigSnapshot;
        }
      } catch (err: any) {
        this.logger.warn(`Failed to read system strategy config from Redis: ${err.message}`);
      }
    }

    try {
      const dbConfig = await (this.prisma as any).systemStrategyConfig.findFirst({
        orderBy: { updatedAt: 'desc' },
      });

      const config: SystemConfigSnapshot = dbConfig
        ? {
            isFixed1xEnabled: dbConfig.isFixed1xEnabled,
            isLossMultiplier2xEnabled: dbConfig.isLossMultiplier2xEnabled,
            maxAllowedMultiplier: dbConfig.maxAllowedMultiplier ?? 16,
            maxGlobalQuantity: dbConfig.maxGlobalQuantity,
            maxGlobalExposureInr: dbConfig.maxGlobalExposureInr ? Number(dbConfig.maxGlobalExposureInr) : null,
            maxConsecutiveLosses: dbConfig.maxConsecutiveLosses ?? 5,
          }
        : DEFAULT_SYSTEM_CONFIG;

      if (this.redisService.isHealthy()) {
        try {
          await this.redisService.getClient().set(cacheKey, JSON.stringify(config), 'EX', 300); // 5 min TTL
        } catch (err: any) {
          this.logger.warn(`Failed to cache system strategy config: ${err.message}`);
        }
      }

      return config;
    } catch (err: any) {
      this.logger.warn(`Failed to load system config from DB, using defaults: ${err.message}`);
      return DEFAULT_SYSTEM_CONFIG;
    }
  }

  /**
   * Retrieves user's active strategy configuration and streak state.
   * Redis cache first, falling back to PostgreSQL.
   */
  async getUserStrategy(userId: string, segmentId?: string): Promise<UserTradingStrategy> {
    const cacheKey = RedisKeys.strategy(userId, segmentId);

    if (this.redisService.isHealthy()) {
      try {
        const raw = await this.redisService.getClient().get(cacheKey);
        if (raw) {
          return JSON.parse(raw) as UserTradingStrategy;
        }
      } catch (err: any) {
        this.logger.warn(`Failed to read strategy from Redis [${cacheKey}]: ${err.message}`);
      }
    }

    // DB query
    let strategy = await (this.prisma as any).userTradingStrategy.findFirst({
      where: {
        userId,
        OR: [
          { segmentId: segmentId ?? null },
          { segmentId: null },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!strategy) {
      // Default to FIXED_1X
      strategy = await (this.prisma as any).userTradingStrategy.create({
        data: {
          userId,
          segmentId: segmentId ?? null,
          strategyType: StrategyType.FIXED_1X,
          baseMultiplier: 1,
          currentMultiplier: 1,
          consecutiveLosses: 0,
          lastTradeResult: 'NONE',
          nextTradeMultiplier: 1,
          status: 'ACTIVE',
          version: 1,
          agreementVersion: 'v1.0',
          consentAccepted: false,
        },
      });
    }

    if (this.redisService.isHealthy()) {
      try {
        await this.redisService.getClient().set(cacheKey, JSON.stringify(strategy), 'EX', 86400);
      } catch (err: any) {
        this.logger.warn(`Failed to cache strategy in Redis: ${err.message}`);
      }
    }

    return strategy;
  }

  /**
   * Calculates position size and returns full snapshot metadata.
   * Enforces 16x ceiling cap and maximum quantity limits.
   */
  async calculatePositionSize(
    userId: string,
    segmentId: string,
    baseLot: number,
    entryPrice?: number,
  ): Promise<SizingResult> {
    const strategy = await this.getUserStrategy(userId, segmentId);
    const systemConfig = await this.getSystemConfig();

    let multiplier = 1;
    if (strategy.strategyType === StrategyType.FIXED_1X) {
      multiplier = 1;
    } else if (strategy.strategyType === StrategyType.LOSS_MULTIPLIER_2X) {
      // Respect configured system max allowed multiplier (e.g., 16x cap)
      multiplier = Math.min(strategy.currentMultiplier, systemConfig.maxAllowedMultiplier);
      if (multiplier < 1) multiplier = 1;
    }

    let actualQuantity = baseLot * multiplier;

    // Apply global quantity ceiling if configured
    if (systemConfig.maxGlobalQuantity && actualQuantity > systemConfig.maxGlobalQuantity) {
      this.logger.warn(
        `Quantity capped by maxGlobalQuantity (${actualQuantity} -> ${systemConfig.maxGlobalQuantity}) for user ${userId}`,
      );
      actualQuantity = systemConfig.maxGlobalQuantity;
    }

    return {
      strategyType: strategy.strategyType,
      baseQuantity: baseLot,
      multiplier,
      actualQuantity,
      consecutiveLosses: strategy.consecutiveLosses,
      strategyVersion: strategy.version,
      agreementVersion: strategy.agreementVersion,
      previousTradeResult: strategy.lastTradeResult,
    };
  }

  /**
   * Handles trade outcome (PROFIT vs LOSS) and advances or resets multiplier.
   * Fixed 1x: always 1x.
   * 2x Loss: 1x -> 2x -> 4x -> 8x -> 16x (capped) on loss; resets to 1x on profit.
   */
  async handleTradeOutcome(
    userId: string,
    segmentId: string,
    outcome: 'PROFIT' | 'LOSS',
  ): Promise<void> {
    const strategy = await this.getUserStrategy(userId, segmentId);
    const systemConfig = await this.getSystemConfig();

    if (strategy.strategyType === StrategyType.FIXED_1X) {
      const nextConsecutive = outcome === 'LOSS' ? strategy.consecutiveLosses + 1 : 0;
      await this.updateStrategyState(userId, segmentId, {
        currentMultiplier: 1,
        consecutiveLosses: nextConsecutive,
        lastTradeResult: outcome,
        nextTradeMultiplier: 1,
      });
      this.logger.log(
        `[Strategy Fixed 1x] User ${userId} outcome=${outcome}. Multiplier remains 1x. Consecutive losses: ${nextConsecutive}`,
      );
      return;
    }

    // 2x Loss Multiplier logic
    if (outcome === 'LOSS') {
      const nextConsecutive = strategy.consecutiveLosses + 1;
      const nextMultiplier = Math.min(
        strategy.currentMultiplier * 2,
        systemConfig.maxAllowedMultiplier,
      );
      const projectedNext = Math.min(
        nextMultiplier * 2,
        systemConfig.maxAllowedMultiplier,
      );

      await this.updateStrategyState(userId, segmentId, {
        currentMultiplier: nextMultiplier,
        consecutiveLosses: nextConsecutive,
        lastTradeResult: 'LOSS',
        nextTradeMultiplier: projectedNext,
      });

      this.logger.log(
        `[Strategy 2x Loss] Multiplier advanced on loss for user ${userId}: ` +
          `${strategy.currentMultiplier}x -> ${nextMultiplier}x (losses: ${nextConsecutive}, cap: ${systemConfig.maxAllowedMultiplier}x)`,
      );
    } else {
      // PROFIT resets immediately to 1x
      await this.updateStrategyState(userId, segmentId, {
        currentMultiplier: 1,
        consecutiveLosses: 0,
        lastTradeResult: 'PROFIT',
        nextTradeMultiplier: 2,
      });

      this.logger.log(
        `[Strategy 2x Loss] Multiplier reset on profit for user ${userId} -> 1x. Streak reset.`,
      );
    }
  }

  /**
   * CRITICAL RULE: Switching strategy resets to fresh 1x cycle immediately!
   * Creates an audit trail in strategy_change_history.
   */
  async switchStrategy(
    userId: string,
    segmentId: string | null | undefined,
    newStrategy: StrategyType,
    agreementVersion: string,
    changedBy: 'USER' | 'ADMIN',
    changeSource: StrategyChangeSource,
    consentId?: string,
  ): Promise<UserTradingStrategy> {
    const current = await this.getUserStrategy(userId, segmentId ?? undefined);

    // 1. Audit trail in StrategyChangeHistory
    await (this.prisma as any).strategyChangeHistory.create({
      data: {
        userId,
        previousStrategy: current.strategyType,
        newStrategy,
        previousMultiplier: current.currentMultiplier,
        newMultiplier: 1,
        previousVersion: current.version,
        newVersion: current.version + 1,
        changedBy,
        changeSource,
        consentId: consentId ?? null,
        agreementVersion,
      },
    });

    // 2. Reset and update UserTradingStrategy to clean 1x
    const updated = await (this.prisma as any).userTradingStrategy.upsert({
      where: {
        userId_segmentId: {
          userId,
          segmentId: segmentId ?? null,
        },
      },
      create: {
        userId,
        segmentId: segmentId ?? null,
        strategyType: newStrategy,
        baseMultiplier: 1,
        currentMultiplier: 1,
        consecutiveLosses: 0,
        lastTradeResult: 'NONE',
        nextTradeMultiplier: newStrategy === StrategyType.LOSS_MULTIPLIER_2X ? 2 : 1,
        version: current.version + 1,
        agreementVersion,
        consentAccepted: true,
        status: 'ACTIVE',
      },
      update: {
        strategyType: newStrategy,
        baseMultiplier: 1,
        currentMultiplier: 1,
        consecutiveLosses: 0,
        lastTradeResult: 'NONE',
        nextTradeMultiplier: newStrategy === StrategyType.LOSS_MULTIPLIER_2X ? 2 : 1,
        version: { increment: 1 },
        agreementVersion,
        consentAccepted: true,
        status: 'ACTIVE',
      },
    });

    // 3. Invalidate Redis cache
    if (this.redisService.isHealthy()) {
      try {
        await this.redisService.getClient().del(RedisKeys.strategy(userId, segmentId ?? undefined));
        await this.redisService.getClient().del(RedisKeys.strategy(userId));
        await this.redisService.getClient().del(RedisKeys.multiplier(userId, segmentId ?? ''));
      } catch (err: any) {
        this.logger.warn(`Failed to clear strategy cache on switch: ${err.message}`);
      }
    }

    this.logger.log(
      `Strategy switched for user ${userId}: ${current.strategyType} -> ${newStrategy} by ${changedBy}. ` +
        `Multiplier reset to fresh 1x. Version: ${updated.version}`,
    );

    return updated;
  }

  /**
   * Helper to persist updated streak state to DB and warm Redis.
   */
  private async updateStrategyState(
    userId: string,
    segmentId: string,
    data: Partial<UserTradingStrategy>,
  ): Promise<void> {
    const updated = await (this.prisma as any).userTradingStrategy.updateMany({
      where: {
        userId,
        OR: [
          { segmentId },
          { segmentId: null },
        ],
      },
      data,
    });

    // Also update legacy SegmentMultiplier for dual-compatibility
    try {
      await this.prisma.segmentMultiplier.upsert({
        where: { userId_segmentId: { userId, segmentId } },
        create: {
          userId,
          segmentId,
          lossStreak: (data.consecutiveLosses as number) ?? 0,
          currentMultiplier: (data.currentMultiplier as number) ?? 1,
          currentLot: (data.currentMultiplier as number) ?? 1,
        },
        update: {
          lossStreak: (data.consecutiveLosses as number) ?? 0,
          currentMultiplier: (data.currentMultiplier as number) ?? 1,
          currentLot: (data.currentMultiplier as number) ?? 1,
        },
      });
    } catch (e: any) {
      // Non-blocking
    }

    // Refresh Redis
    if (this.redisService.isHealthy()) {
      try {
        const cacheKey = RedisKeys.strategy(userId, segmentId);
        const legacyKey = RedisKeys.multiplier(userId, segmentId);
        const fresh = await (this.prisma as any).userTradingStrategy.findFirst({
          where: { userId },
          orderBy: { updatedAt: 'desc' },
        });
        if (fresh) {
          await this.redisService.getClient().set(cacheKey, JSON.stringify(fresh), 'EX', 86400);
          await this.redisService.getClient().set(
            legacyKey,
            JSON.stringify({ index: fresh.consecutiveLosses, current: fresh.currentMultiplier }),
            'EX',
            86400,
          );
        }
      } catch (err: any) {
        this.logger.warn(`Failed to update strategy cache: ${err.message}`);
      }
    }
  }

  // ==========================================
  // Legacy MultiplierService interface support
  // ==========================================
  async getState(userId: string, segmentId: string): Promise<{ index: number; current: number }> {
    const strategy = await this.getUserStrategy(userId, segmentId);
    return {
      index: strategy.consecutiveLosses,
      current: strategy.currentMultiplier,
    };
  }

  async advanceOnLoss(userId: string, segmentId: string): Promise<{ index: number; current: number }> {
    await this.handleTradeOutcome(userId, segmentId, 'LOSS');
    return this.getState(userId, segmentId);
  }

  async resetOnWin(userId: string, segmentId: string): Promise<void> {
    await this.handleTradeOutcome(userId, segmentId, 'PROFIT');
  }
}
