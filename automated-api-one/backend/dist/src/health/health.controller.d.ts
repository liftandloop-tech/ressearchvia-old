import { HealthCheckService, PrismaHealthIndicator } from '@nestjs/terminus';
import { PrismaService } from '../prisma.service';
import { RedisHealthIndicator } from './redis.health';
import { BrokerHealthIndicator } from './broker.health';
import { QueueService } from '../infrastructure/queues/queues.service';
import { TradingGateway } from '../websocket/gateway/trading.gateway';
export declare class HealthController {
    private readonly health;
    private readonly prismaHealth;
    private readonly prisma;
    private readonly redisHealth;
    private readonly brokerHealth;
    private readonly queueService;
    private readonly tradingGateway;
    constructor(health: HealthCheckService, prismaHealth: PrismaHealthIndicator, prisma: PrismaService, redisHealth: RedisHealthIndicator, brokerHealth: BrokerHealthIndicator, queueService: QueueService, tradingGateway: TradingGateway);
    checkAll(): Promise<import("@nestjs/terminus").HealthCheckResult<import("@nestjs/terminus").HealthIndicatorResult<string, import("@nestjs/terminus").HealthIndicatorStatus, Record<string, any>> & import("@nestjs/terminus").HealthIndicatorResult & import("@nestjs/terminus").HealthIndicatorResult<"database">, Partial<import("@nestjs/terminus").HealthIndicatorResult<string, import("@nestjs/terminus").HealthIndicatorStatus, Record<string, any>> & import("@nestjs/terminus").HealthIndicatorResult & import("@nestjs/terminus").HealthIndicatorResult<"database">> | undefined, Partial<import("@nestjs/terminus").HealthIndicatorResult<string, import("@nestjs/terminus").HealthIndicatorStatus, Record<string, any>> & import("@nestjs/terminus").HealthIndicatorResult & import("@nestjs/terminus").HealthIndicatorResult<"database">> | undefined>>;
    checkDb(): Promise<import("@nestjs/terminus").HealthCheckResult<import("@nestjs/terminus").HealthIndicatorResult<string, import("@nestjs/terminus").HealthIndicatorStatus, Record<string, any>> & import("@nestjs/terminus").HealthIndicatorResult<"database">, Partial<import("@nestjs/terminus").HealthIndicatorResult<string, import("@nestjs/terminus").HealthIndicatorStatus, Record<string, any>> & import("@nestjs/terminus").HealthIndicatorResult<"database">> | undefined, Partial<import("@nestjs/terminus").HealthIndicatorResult<string, import("@nestjs/terminus").HealthIndicatorStatus, Record<string, any>> & import("@nestjs/terminus").HealthIndicatorResult<"database">> | undefined>>;
    checkRedis(): Promise<import("@nestjs/terminus").HealthCheckResult<import("@nestjs/terminus").HealthIndicatorResult<string, import("@nestjs/terminus").HealthIndicatorStatus, Record<string, any>> & import("@nestjs/terminus").HealthIndicatorResult, Partial<import("@nestjs/terminus").HealthIndicatorResult<string, import("@nestjs/terminus").HealthIndicatorStatus, Record<string, any>> & import("@nestjs/terminus").HealthIndicatorResult> | undefined, Partial<import("@nestjs/terminus").HealthIndicatorResult<string, import("@nestjs/terminus").HealthIndicatorStatus, Record<string, any>> & import("@nestjs/terminus").HealthIndicatorResult> | undefined>>;
    checkBroker(): Promise<{
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
    checkQueues(): Promise<{
        waiting: number;
        active: number;
        failed: number;
        dlq: number;
        status: string;
        signalProcessingDepth: number;
        orderPlacementDepth: number;
        reportDepth: number;
    }>;
    checkWebsocket(): Promise<{
        status: string;
        gateway: string;
        activeConnections: number;
    }>;
    checkOutbox(): Promise<{
        status: string;
        pendingEvents: any;
        stuckEvents: any;
        queueDepth: number;
        error?: undefined;
    } | {
        status: string;
        error: any;
        pendingEvents?: undefined;
        stuckEvents?: undefined;
        queueDepth?: undefined;
    }>;
    checkReports(): Promise<{
        status: string;
        queueDepth: number;
        error?: undefined;
    } | {
        status: string;
        error: any;
        queueDepth?: undefined;
    }>;
    checkReconciliation(): Promise<{
        status: string;
        lastRun: any;
        openIssues: any;
        criticalIssues: any;
        error?: undefined;
    } | {
        status: string;
        error: any;
        lastRun?: undefined;
        openIssues?: undefined;
        criticalIssues?: undefined;
    }>;
    checkAnalytics(): Promise<{
        status: string;
        lastRun: {
            id: any;
            startedAt: any;
            completedAt: any;
            status: any;
            usersProcessed: any;
            failures: any;
            durationMs: any;
        };
        staleSnapshotsCount: number;
        error?: undefined;
    } | {
        status: string;
        error: any;
        lastRun?: undefined;
        staleSnapshotsCount?: undefined;
    }>;
}
