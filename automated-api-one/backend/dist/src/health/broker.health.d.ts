import { HealthIndicator, HealthIndicatorResult } from '@nestjs/terminus';
import { ConfigService } from '@nestjs/config';
import { BrokerFactory } from '../brokers/factory/broker.factory';
export declare class BrokerHealthIndicator extends HealthIndicator {
    private readonly configService;
    private readonly brokerFactory;
    constructor(configService: ConfigService, brokerFactory: BrokerFactory);
    getCustomHealth(): Promise<{
        status: string;
        broker: string;
        reachable: boolean;
        authenticationValid: boolean;
        responseTimeMs: number;
        message: string;
    } | {
        status: string;
        broker: string;
        reachable: boolean;
        authenticationValid: boolean;
        responseTimeMs: number;
        message?: undefined;
    }>;
    isHealthy(key: string): Promise<HealthIndicatorResult>;
}
