import { RedisService } from '../infrastructure/redis/redis.service';
export declare class NotificationDeduplicationService {
    private readonly redisService;
    private readonly logger;
    constructor(redisService: RedisService);
    shouldDeduplicate(fingerprint: string, ttlSeconds?: number): Promise<boolean>;
}
