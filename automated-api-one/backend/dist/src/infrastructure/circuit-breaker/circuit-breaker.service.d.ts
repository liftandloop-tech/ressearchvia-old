import { RedisService } from '../redis/redis.service';
import { ConfigService } from '@nestjs/config';
import { MetricsService } from '../metrics/metrics.service';
export declare enum CircuitState {
    CLOSED = "CLOSED",
    OPEN = "OPEN",
    HALF_OPEN = "HALF_OPEN"
}
export declare class BrokerUnavailableException extends Error {
    constructor(message?: string);
}
export declare class CircuitBreakerService {
    private readonly redisService;
    private readonly configService;
    private readonly metrics;
    private readonly logger;
    private memStates;
    private readonly cooldownMs;
    private readonly failureThreshold;
    constructor(redisService: RedisService, configService: ConfigService, metrics: MetricsService);
    private setCircuitStateGauge;
    private getCircuitInfo;
    private setCircuitInfo;
    execute<T>(broker: string, operation: () => Promise<T>): Promise<T>;
    private onSuccess;
    private onFailure;
}
