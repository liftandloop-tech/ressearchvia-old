import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { RedisKeys } from '../../infrastructure/redis/redis-keys';

export interface PositionCache {
  userId: string;
  segmentId: string;
  tradeId: string;
  symbol: string;
  quantity: number;
  entryPrice: number;
  stopLoss: number;
  targetPrice: number;
  side: 'BUY' | 'SELL';
  cachedAt: string;
}

/** TTL for cached position data: 8 hours (trading day scope) */
const POSITION_CACHE_TTL_SECONDS = 8 * 60 * 60;

@Injectable()
export class PositionCacheService {
  private readonly logger = new Logger(PositionCacheService.name);

  constructor(private readonly redisService: RedisService) {}

  async set(data: PositionCache): Promise<void> {
    if (!this.redisService.isHealthy()) {
      this.logger.warn(
        `Redis unhealthy — skipping position cache write for user ${data.userId} / segment ${data.segmentId}`,
      );
      return;
    }

    const key = RedisKeys.position(data.userId, data.segmentId);
    try {
      await this.redisService
        .getClient()
        .set(key, JSON.stringify(data), 'EX', POSITION_CACHE_TTL_SECONDS);
      this.logger.debug(`Position cached: ${key}`);
    } catch (err) {
      this.logger.error(`Failed to cache position [${key}]: ${err.message}`);
    }
  }

  async get(userId: string, segmentId: string): Promise<PositionCache | null> {
    if (!this.redisService.isHealthy()) {
      return null;
    }

    const key = RedisKeys.position(userId, segmentId);
    try {
      const raw = await this.redisService.getClient().get(key);
      return raw ? (JSON.parse(raw) as PositionCache) : null;
    } catch (err) {
      this.logger.error(`Failed to read position cache [${key}]: ${err.message}`);
      return null;
    }
  }

  async del(userId: string, segmentId: string): Promise<void> {
    if (!this.redisService.isHealthy()) {
      return;
    }

    const key = RedisKeys.position(userId, segmentId);
    try {
      await this.redisService.getClient().del(key);
      this.logger.debug(`Position cache cleared: ${key}`);
    } catch (err) {
      this.logger.error(`Failed to delete position cache [${key}]: ${err.message}`);
    }
  }
}
