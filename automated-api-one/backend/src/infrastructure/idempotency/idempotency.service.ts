import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../redis/redis.service';
import { RedisKeys } from '../redis/redis-keys';
import { IdempotencyStatus } from '@prisma/client';

@Injectable()
export class IdempotencyService {
  private readonly logger = new Logger(IdempotencyService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
  ) {}

  /**
   * Checks if an operation with a key has already run.
   * If not, locks it in Redis and creates a PENDING db record.
   * @returns true if unique and locked, false if duplicate
   */
  async checkAndLock(
    key: string,
    type: string,
    ttlSeconds: number,
  ): Promise<boolean> {
    this.redisService.assertHealthy();
    const redisKey = RedisKeys.idempotency(key);

    try {
      // 1. Redis-first SETNX check
      const result = await this.redisService.getClient().set(
        redisKey,
        '1',
        'EX',
        ttlSeconds,
        'NX',
      );

      if (result !== 'OK') {
        this.logger.warn(`Duplicate request detected via Redis for key: ${key}`);
        return false;
      }

      // 2. Persist database log record
      try {
        await this.prisma.idempotencyKey.create({
          data: {
            key,
            type,
            status: IdempotencyStatus.PENDING,
          },
        });
        return true;
      } catch (dbErr) {
        // Handle Prisma unique constraint violation (P2002)
        if (dbErr.code === 'P2002') {
          this.logger.warn(`Duplicate request detected via Database for key: ${key}`);
          // Rollback Redis lock since DB already recorded completion/attempt
          await this.redisService.getClient().del(redisKey).catch(() => {});
          return false;
        }
        throw dbErr;
      }
    } catch (err) {
      this.logger.error(`Idempotency check failed for key: ${key}. Error: ${err.message}`);
      throw err;
    }
  }

  /**
   * Updates the idempotency database record status.
   */
  async updateStatus(key: string, status: IdempotencyStatus): Promise<void> {
    try {
      await this.prisma.idempotencyKey.update({
        where: { key },
        data: { status },
      });
    } catch (err) {
      this.logger.error(`Failed to update idempotency status for key: ${key}. Error: ${err.message}`);
    }
  }

  /**
   * Convenience wrapper: acquires idempotency key with a 24-hour TTL.
   * Returns true if this is the first (unique) attempt, false if duplicate.
   */
  async tryAcquire(key: string, type: string): Promise<boolean> {
    return this.checkAndLock(key, type, 86400);
  }

  /**
   * Marks an idempotency key as FAILED (allows consumers to retry if needed).
   */
  async markFailed(key: string): Promise<void> {
    return this.updateStatus(key, IdempotencyStatus.FAILED);
  }

  /**
   * Marks an idempotency key as SUCCESS (prevents future duplicate processing).
   */
  async markSuccess(key: string): Promise<void> {
    return this.updateStatus(key, IdempotencyStatus.SUCCESS);
  }
}
