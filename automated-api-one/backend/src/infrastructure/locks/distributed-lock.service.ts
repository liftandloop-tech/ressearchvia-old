import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
import * as crypto from 'crypto';

@Injectable()
export class DistributedLockService implements OnModuleDestroy {
  private readonly logger = new Logger(DistributedLockService.name);
  private activeRenewals = new Map<string, NodeJS.Timeout>();

  constructor(private readonly redisService: RedisService) {}

  onModuleDestroy() {
    // Clean up all running renewal timers on shutdown
    for (const timer of this.activeRenewals.values()) {
      clearInterval(timer);
    }
    this.activeRenewals.clear();
  }

  /**
   * Acquires a lock on a key.
   * @param key Redis lock key
   * @param ttlMs Lock time-to-live in milliseconds
   * @param options Auto-renewal options
   * @returns The lock token string if successful, null if failed
   */
  async acquireLock(
    key: string,
    ttlMs: number,
    options?: { autoRenew?: boolean },
  ): Promise<string | null> {
    this.redisService.assertHealthy();
    const token = crypto.randomUUID();

    try {
      // SET key token NX PX ttlMs
      const result = await this.redisService.getClient().set(
        key,
        token,
        'PX',
        ttlMs,
        'NX',
      );

      if (result === 'OK') {
        if (options?.autoRenew) {
          this.startHeartbeat(key, token, ttlMs);
        }
        return token;
      }
      return null;
    } catch (err) {
      this.logger.error(`Failed to acquire lock for key: ${key}. Error: ${err.message}`);
      throw err;
    }
  }

  /**
   * Releases a lock using a safe Lua script to verify ownership.
   */
  async releaseLock(key: string, token: string): Promise<boolean> {
    this.redisService.assertHealthy();
    this.stopHeartbeat(key);

    const script = `
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
      else
        return 0
      end
    `;

    try {
      const result = await this.redisService.getClient().eval(
        script,
        1,
        key,
        token,
      );
      return result === 1;
    } catch (err) {
      this.logger.error(`Failed to release lock for key: ${key}. Error: ${err.message}`);
      throw err;
    }
  }

  /**
   * Extends the TTL of a lock if ownership token matches.
   */
  async extendLock(key: string, token: string, ttlMs: number): Promise<boolean> {
    this.redisService.assertHealthy();

    const script = `
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("pexpire", KEYS[1], ARGV[2])
      else
        return 0
      end
    `;

    try {
      const result = await this.redisService.getClient().eval(
        script,
        1,
        key,
        token,
        ttlMs,
      );
      return result === 1;
    } catch (err) {
      this.logger.error(`Failed to extend lock for key: ${key}. Error: ${err.message}`);
      return false;
    }
  }

  private startHeartbeat(key: string, token: string, ttlMs: number) {
    this.stopHeartbeat(key); // Pre-emptive cleanup

    // Run heartbeat renewal at 1/3 of the lock TTL duration
    const intervalMs = Math.max(100, Math.floor(ttlMs / 3));

    const timer = setInterval(async () => {
      try {
        const extended = await this.extendLock(key, token, ttlMs);
        if (!extended) {
          this.logger.warn(`Failed to renew heartbeat lock for ${key}. Clearing timer.`);
          this.stopHeartbeat(key);
        }
      } catch (err) {
        this.logger.error(`Heartbeat renewal failed for ${key}: ${err.message}`);
        this.stopHeartbeat(key);
      }
    }, intervalMs);

    this.activeRenewals.set(key, timer);
  }

  private stopHeartbeat(key: string) {
    const timer = this.activeRenewals.get(key);
    if (timer) {
      clearInterval(timer);
      this.activeRenewals.delete(key);
    }
  }
}
