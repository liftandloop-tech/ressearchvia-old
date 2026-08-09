import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../infrastructure/redis/redis.service';
import * as crypto from 'crypto';
import { NotificationChannel } from '@prisma/client';

@Injectable()
export class NotificationRateLimiterService {
  private readonly logger = new Logger(NotificationRateLimiterService.name);

  private readonly LIMITS: Record<NotificationChannel, number> = {
    SMS: 10,
    EMAIL: 30,
    WHATSAPP: 5,
    PUSH: 100,
    IN_APP: 1000,
    WEBSOCKET: 1000,
  };

  constructor(private readonly redisService: RedisService) {}

  async isRateLimited(userId: string, channel: NotificationChannel): Promise<boolean> {
    if (!this.redisService.isHealthy()) {
      this.logger.warn(`Redis is unhealthy. Bypassing rate limiting for notification channel: ${channel}`);
      return false;
    }

    const limit = this.LIMITS[channel];
    const key = `notifications:ratelimit:${userId}:${channel}`;
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
        this.logger.warn(`Notification rate limit exceeded for user ${userId} on channel ${channel}: ${count}/${limit}`);
        return true;
      }

      return false;
    } catch (err) {
      this.logger.error(`Error in notification rate limiter check for user ${userId} on channel ${channel}: ${err.message}`);
      return false; // Fail open
    }
  }
}
