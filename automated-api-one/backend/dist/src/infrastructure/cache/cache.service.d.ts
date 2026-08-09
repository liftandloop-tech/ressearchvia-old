import { RedisService } from '../redis/redis.service';
export declare class CacheService {
    private readonly redisService;
    private readonly logger;
    constructor(redisService: RedisService);
    get<T>(key: string): Promise<T | null>;
    set(key: string, value: any, ttlSeconds?: number): Promise<void>;
    del(key: string): Promise<void>;
}
