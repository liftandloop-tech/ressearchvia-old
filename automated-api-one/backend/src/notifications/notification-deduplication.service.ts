import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from '../infrastructure/redis/redis.service';

@Injectable()
export class NotificationDeduplicationService {
  private readonly logger = new Logger(NotificationDeduplicationService.name);

  constructor(private readonly redisService: RedisService) {}

  /**
   * Checks if a notification with the given fingerprint has been sent recently.
   * If not, stores the fingerprint in Redis with the given TTL (in seconds) and returns false.
   * If it has, returns true (deduplicated).
   */
  async shouldDeduplicate(fingerprint: string, ttlSeconds = 60): Promise<boolean> {
    if (!this.redisService.isHealthy()) {
      this.logger.warn(`Redis is unhealthy. Bypassing deduplication for fingerprint: ${fingerprint}`);
      return false;
    }

    const key = `notifications:dedup:${fingerprint}`;
    try {
      const client = this.redisService.getClient();
      // Use SET with NX and PX (TTL) to atomically check and set
      const result = await client.set(key, '1', 'EX', ttlSeconds, 'NX');
      if (result === 'OK') {
        return false;
      }
      this.logger.log(`Deduplicated notification with fingerprint: ${fingerprint}`);
      return true;
    } catch (err) {
      this.logger.error(`Error in notification deduplication check for ${fingerprint}: ${err.message}`);
      return false; // Fail open
    }
  }
}
