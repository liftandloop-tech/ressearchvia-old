import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';

@Injectable()
export class CacheService {
  private readonly logger = new Logger(CacheService.name);

  constructor(private readonly redisService: RedisService) {}

  async get<T>(key: string): Promise<T | null> {
    try {
      if (!this.redisService.isHealthy()) {
        this.logger.warn(`Redis is unhealthy. Cache GET bypassed for key: ${key}`);
        return null;
      }
      const val = await this.redisService.getClient().get(key);
      if (!val) return null;
      return JSON.parse(val) as T;
    } catch (err) {
      this.logger.warn(`Failed to fetch from cache for key: ${key}. Error: ${err.message}`);
      return null;
    }
  }

  async set(key: string, value: any, ttlSeconds?: number): Promise<void> {
    this.redisService.assertHealthy();
    const serialized = JSON.stringify(value);
    if (ttlSeconds) {
      await this.redisService.getClient().set(key, serialized, 'EX', ttlSeconds);
    } else {
      await this.redisService.getClient().set(key, serialized);
    }
  }

  async del(key: string): Promise<void> {
    this.redisService.assertHealthy();
    await this.redisService.getClient().del(key);
  }
}
