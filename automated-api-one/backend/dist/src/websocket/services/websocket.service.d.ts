import { TradingGateway } from '../gateway/trading.gateway';
import { WebsocketEvent } from '../enums/websocket-event.enum';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export declare class WebsocketService {
    private readonly gateway;
    private readonly redisService;
    private readonly metrics;
    private readonly logger;
    constructor(gateway: TradingGateway, redisService: RedisService, metrics: MetricsService);
    broadcast<T>(eventId: string, event: WebsocketEvent, room: string, payload: T): Promise<boolean>;
    private acquireEventLock;
}
