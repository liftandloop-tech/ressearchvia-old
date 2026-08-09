import { Injectable } from '@nestjs/common';
import {
  HealthIndicator,
  HealthIndicatorResult,
  HealthCheckError,
} from '@nestjs/terminus';
import { RedisService } from '../infrastructure/redis/redis.service';

@Injectable()
export class RedisHealthIndicator extends HealthIndicator {
  constructor(private readonly redisService: RedisService) {
    super();
  }

  async isHealthy(key: string): Promise<HealthIndicatorResult> {
    try {
      const isHealthy = this.redisService.isHealthy();
      if (!isHealthy) {
        throw new Error('RedisService indicates client is disconnected');
      }

      const status = await this.redisService.getClient().ping();
      if (status === 'PONG') {
        return this.getStatus(key, true);
      }
      
      throw new Error(`Redis ping returned: ${status}`);
    } catch (error) {
      throw new HealthCheckError(
        `Redis connection failed: ${error.message}`,
        this.getStatus(key, false),
      );
    }
  }
}
