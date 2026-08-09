import { PrismaService } from '../../prisma.service';
import { BrokerFactory } from '../../brokers/factory/broker.factory';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { AuditService } from '../../audit/audit.service';
import { PositionCacheService } from './position-cache.service';
import { MultiplierService } from './multiplier.service';
import { ConfigService } from '@nestjs/config';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export interface MonitoringResult {
    finalStatus: 'FILLED' | 'CANCELLED' | 'REJECTED' | 'EXPIRED' | 'PENDING';
    brokerOrderId: string;
    reason?: string;
}
export declare class OrderMonitoringService {
    private readonly prisma;
    private readonly brokerFactory;
    private readonly circuitBreaker;
    private readonly outbox;
    private readonly auditService;
    private readonly positionCache;
    private readonly multiplierService;
    private readonly configService;
    private readonly metrics;
    private readonly logger;
    private readonly brokerTimeoutMs;
    constructor(prisma: PrismaService, brokerFactory: BrokerFactory, circuitBreaker: CircuitBreakerService, outbox: OutboxService, auditService: AuditService, positionCache: PositionCacheService, multiplierService: MultiplierService, configService: ConfigService, metrics: MetricsService);
    pollOrderStatus(orderId: string, correlationId: string): Promise<MonitoringResult>;
    private reconcileFilled;
    private reconcileFailed;
}
