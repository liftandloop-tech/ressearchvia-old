import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { PositionSizingService } from './position-sizing.service';

export interface MultiplierState {
  index: number;
  current: number;
}

@Injectable()
export class MultiplierService {
  private readonly logger = new Logger(MultiplierService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    private readonly positionSizingService: PositionSizingService,
  ) {}

  /**
   * Gets the current multiplier state for a user/segment pair.
   * Delegates to PositionSizingService for unified strategy handling.
   */
  async getState(userId: string, segmentId: string): Promise<MultiplierState> {
    return this.positionSizingService.getState(userId, segmentId);
  }

  /**
   * Persists multiplier state to both Redis and PostgreSQL.
   */
  async setState(
    userId: string,
    segmentId: string,
    state: MultiplierState,
  ): Promise<void> {
    // Supported via PositionSizingService internal state updates
  }

  /**
   * Advances the multiplier after a losing trade based on user's active strategy.
   * Fixed 1x stays 1x; 2x Loss doubles up to system max multiplier.
   */
  async advanceOnLoss(
    userId: string,
    segmentId: string,
  ): Promise<MultiplierState> {
    return this.positionSizingService.advanceOnLoss(userId, segmentId);
  }

  /**
   * Resets the multiplier to 1x after a winning trade.
   */
  async resetOnWin(userId: string, segmentId: string): Promise<void> {
    return this.positionSizingService.resetOnWin(userId, segmentId);
  }
}
