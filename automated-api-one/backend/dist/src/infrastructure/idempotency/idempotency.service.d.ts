import { PrismaService } from '../../prisma.service';
import { RedisService } from '../redis/redis.service';
import { IdempotencyStatus } from '@prisma/client';
export declare class IdempotencyService {
    private readonly prisma;
    private readonly redisService;
    private readonly logger;
    constructor(prisma: PrismaService, redisService: RedisService);
    checkAndLock(key: string, type: string, ttlSeconds: number): Promise<boolean>;
    updateStatus(key: string, status: IdempotencyStatus): Promise<void>;
    tryAcquire(key: string, type: string): Promise<boolean>;
    markFailed(key: string): Promise<void>;
    markSuccess(key: string): Promise<void>;
}
