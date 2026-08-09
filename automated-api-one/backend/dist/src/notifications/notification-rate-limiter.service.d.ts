import { RedisService } from '../infrastructure/redis/redis.service';
import { NotificationChannel } from '@prisma/client';
export declare class NotificationRateLimiterService {
    private readonly redisService;
    private readonly logger;
    private readonly LIMITS;
    constructor(redisService: RedisService);
    isRateLimited(userId: string, channel: NotificationChannel): Promise<boolean>;
}
