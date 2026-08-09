import { OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
export declare enum PlatformMode {
    NORMAL = "NORMAL",
    REDIS_DEGRADED = "REDIS_DEGRADED"
}
export declare class RedisDegradedException extends Error {
    constructor(message?: string);
}
export declare class RedisService implements OnModuleInit, OnModuleDestroy {
    private readonly configService;
    private readonly logger;
    private client;
    private isConnected;
    private mode;
    constructor(configService: ConfigService);
    onModuleInit(): Promise<void>;
    onModuleDestroy(): Promise<void>;
    getClient(): Redis;
    isHealthy(): boolean;
    getPlatformMode(): PlatformMode;
    assertHealthy(): void;
}
