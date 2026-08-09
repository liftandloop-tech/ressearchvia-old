import { OnModuleDestroy } from '@nestjs/common';
import { RedisService } from '../redis/redis.service';
export declare class DistributedLockService implements OnModuleDestroy {
    private readonly redisService;
    private readonly logger;
    private activeRenewals;
    constructor(redisService: RedisService);
    onModuleDestroy(): void;
    acquireLock(key: string, ttlMs: number, options?: {
        autoRenew?: boolean;
    }): Promise<string | null>;
    releaseLock(key: string, token: string): Promise<boolean>;
    extendLock(key: string, token: string, ttlMs: number): Promise<boolean>;
    private startHeartbeat;
    private stopHeartbeat;
}
