import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { RedisService } from './redis.service';
import * as crypto from 'crypto';

export class BrokerRateLimitException extends Error {
  constructor(broker: string, limit: number) {
    super(`Rate limit of ${limit} requests/min exceeded for broker: ${broker}`);
    this.name = 'BrokerRateLimitException';
  }
}

@Injectable()
export class BrokerRateLimiterService {
  private readonly logger = new Logger(BrokerRateLimiterService.name);

  constructor(
    private readonly redisService: RedisService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Applies rate limiting for a broker.
   * Throws BrokerRateLimitException if threshold is exceeded.
   * Returns true on success.
   */
  async throttle(broker: string, operationType: 'trading' | 'market' = 'trading'): Promise<boolean> {
    if (!this.redisService.isHealthy()) {
      this.logger.warn(`Redis is unhealthy. Bypassing rate limiting for broker: ${broker}:${operationType}`);
      return true;
    }

    const defaultLimit = operationType === 'trading' ? 120 : 60;
    const limit = this.configService.get<number>(
      operationType === 'trading' ? 'BROKER_RATE_LIMIT_TRADING_PER_MINUTE' : 'BROKER_RATE_LIMIT_MARKET_PER_MINUTE',
      defaultLimit,
    );
    const key = `broker:ratelimit:${broker}:${operationType}`;
    const now = Date.now();
    const clearBefore = now - 60000; // 1 minute sliding window

    try {
      const client = this.redisService.getClient();
      const multi = client.multi();
      
      multi.zremrangebyscore(key, 0, clearBefore);
      multi.zadd(key, now, `${now}-${crypto.randomUUID()}`);
      multi.zcard(key);
      multi.expire(key, 60);

      const results = await multi.exec();
      if (!results) {
        throw new Error('Redis transaction execution returned null');
      }

      // results[2] is the ZCARD result. format is [err, result]
      const count = results[2][1] as number;

      if (count > limit) {
        this.logger.warn(`Rate limit tripped for broker ${broker}:${operationType}: ${count}/${limit} reqs/min`);
        throw new BrokerRateLimitException(`${broker}:${operationType}`, limit);
      }

      return true;
    } catch (err) {
      if (err instanceof BrokerRateLimitException) {
        throw err;
      }
      this.logger.error(`Error in rate limiter check for ${broker}:${operationType}: ${err.message}`);
      // Fail open to avoid blocking trades on internal Redis script errors
      return true;
    }
  }
}
