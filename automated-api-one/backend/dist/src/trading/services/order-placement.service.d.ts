import { PrismaService } from '../../prisma.service';
import { BrokerFactory } from '../../brokers/factory/broker.factory';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { BrokerRateLimiterService } from '../../infrastructure/redis/broker-rate-limiter.service';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { AuditService } from '../../audit/audit.service';
import { PositionCacheService } from './position-cache.service';
import { ExecutionContext } from '../interfaces/execution-context.interface';
import { ConfigService } from '@nestjs/config';
import { RiskService } from '../../risk/risk.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export interface PlacementResult {
    success: boolean;
    tradeId?: string;
    orderId?: string;
    brokerOrderId?: string;
    reason?: string;
}
export declare class OrderPlacementService {
    private readonly prisma;
    private readonly brokerFactory;
    private readonly circuitBreaker;
    private readonly rateLimiter;
    private readonly outbox;
    private readonly redisService;
    private readonly auditService;
    private readonly positionCache;
    private readonly configService;
    private readonly metrics;
    private readonly riskService;
    private readonly logger;
    private readonly brokerTimeoutMs;
    constructor(prisma: PrismaService, brokerFactory: BrokerFactory, circuitBreaker: CircuitBreakerService, rateLimiter: BrokerRateLimiterService, outbox: OutboxService, redisService: RedisService, auditService: AuditService, positionCache: PositionCacheService, configService: ConfigService, metrics: MetricsService, riskService: RiskService);
    placeEntryOrder(ctx: ExecutionContext): Promise<PlacementResult>;
    private resolveBrokerToken;
}
