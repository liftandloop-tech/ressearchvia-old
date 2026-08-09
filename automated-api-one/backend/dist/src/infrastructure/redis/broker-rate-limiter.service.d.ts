import { ConfigService } from '@nestjs/config';
import { RedisService } from './redis.service';
export declare class BrokerRateLimitException extends Error {
    constructor(broker: string, limit: number);
}
export declare class BrokerRateLimiterService {
    private readonly redisService;
    private readonly configService;
    private readonly logger;
    constructor(redisService: RedisService, configService: ConfigService);
    throttle(broker: string, operationType?: 'trading' | 'market'): Promise<boolean>;
}
