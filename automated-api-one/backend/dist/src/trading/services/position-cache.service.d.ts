import { RedisService } from '../../infrastructure/redis/redis.service';
export interface PositionCache {
    userId: string;
    segmentId: string;
    tradeId: string;
    symbol: string;
    quantity: number;
    entryPrice: number;
    stopLoss: number;
    targetPrice: number;
    side: 'BUY' | 'SELL';
    cachedAt: string;
}
export declare class PositionCacheService {
    private readonly redisService;
    private readonly logger;
    constructor(redisService: RedisService);
    set(data: PositionCache): Promise<void>;
    get(userId: string, segmentId: string): Promise<PositionCache | null>;
    del(userId: string, segmentId: string): Promise<void>;
}
