import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { RedisKeys } from '../../infrastructure/redis/redis-keys';

export interface MultiplierState {
  index: number;
  current: number;
}

/** Default multiplier progression when no custom config found (1x → 2x → 4x → 8x) */
const DEFAULT_PROGRESSION = [1, 2, 4, 8];

@Injectable()
export class MultiplierService {
  private readonly logger = new Logger(MultiplierService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
  ) {}

  /**
   * Gets the current multiplier state for a user/segment pair.
   * Redis is primary source; falls back to PostgreSQL on cache miss.
   */
  async getState(userId: string, segmentId: string): Promise<MultiplierState> {
    const cacheKey = RedisKeys.multiplier(userId, segmentId);

    if (this.redisService.isHealthy()) {
      try {
        const raw = await this.redisService.getClient().get(cacheKey);
        if (raw) {
          return JSON.parse(raw) as MultiplierState;
        }
      } catch (err) {
        this.logger.warn(
          `Failed to read multiplier from Redis [${cacheKey}]: ${err.message}`,
        );
      }
    }

    // Fallback: load from DB
    const dbRecord = await this.prisma.segmentMultiplier.findFirst({
      where: { userId, segmentId },
    });

    if (!dbRecord) {
      // Initialize with default state
      const state: MultiplierState = { index: 0, current: DEFAULT_PROGRESSION[0] };
      await this.setState(userId, segmentId, state);
      return state;
    }

    const state: MultiplierState = {
      index: dbRecord.lossStreak,
      current: dbRecord.currentMultiplier,
    };

    // Warm Redis cache
    await this.setState(userId, segmentId, state);
    return state;
  }

  /**
   * Persists multiplier state to both Redis and PostgreSQL atomically.
   */
  async setState(
    userId: string,
    segmentId: string,
    state: MultiplierState,
  ): Promise<void> {
    // Write to Redis cache
    if (this.redisService.isHealthy()) {
      try {
        const cacheKey = RedisKeys.multiplier(userId, segmentId);
        await this.redisService
          .getClient()
          .set(cacheKey, JSON.stringify(state), 'EX', 86400); // 24h TTL
      } catch (err) {
        this.logger.warn(`Failed to write multiplier to Redis: ${err.message}`);
      }
    }

    // Persist to DB
    await this.prisma.segmentMultiplier.upsert({
      where: {
        userId_segmentId: { userId, segmentId },
      },
      create: {
        userId,
        segmentId,
        lossStreak: state.index,
        currentMultiplier: state.current,
        currentLot: state.current,
      },
      update: {
        lossStreak: state.index,
        currentMultiplier: state.current,
        currentLot: state.current,
      },
    });
  }

  /**
   * Advances the multiplier to the next step in the progression sequence
   * after a losing trade. Respects the user's maxMultiplier cap.
   */
  async advanceOnLoss(
    userId: string,
    segmentId: string,
  ): Promise<MultiplierState> {
    const userSegment = await this.prisma.userSegment.findFirst({
      where: { userId, segmentId },
    });

    const maxMultiplier = userSegment?.maxMultiplier ?? 8;
    const current = await this.getState(userId, segmentId);

    // Determine progression — use DB configured progression or default
    const progression = DEFAULT_PROGRESSION;
    const nextIndex = Math.min(current.index + 1, progression.length - 1);
    const nextValue = Math.min(progression[nextIndex], maxMultiplier);

    const nextState: MultiplierState = { index: nextIndex, current: nextValue };
    await this.setState(userId, segmentId, nextState);

    this.logger.log(
      `Multiplier advanced on loss: userId=${userId} segmentId=${segmentId} ` +
        `${current.current}x → ${nextState.current}x (index: ${nextState.index})`,
    );

    return nextState;
  }

  /**
   * Resets the multiplier to 1x after a winning trade.
   */
  async resetOnWin(userId: string, segmentId: string): Promise<void> {
    const resetState: MultiplierState = { index: 0, current: DEFAULT_PROGRESSION[0] };
    await this.setState(userId, segmentId, resetState);

    this.logger.log(
      `Multiplier reset on win: userId=${userId} segmentId=${segmentId} → 1x`,
    );
  }
}
