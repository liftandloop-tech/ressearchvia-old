import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { BrokerRegistry } from '../brokers/registry/broker.registry';
import { OutboxService } from '../infrastructure/outbox/outbox.service';
export declare class ReconciliationService {
    private readonly prisma;
    private readonly redisService;
    private readonly queueService;
    private readonly metrics;
    private readonly brokerRegistry;
    private readonly outboxService;
    private readonly logger;
    constructor(prisma: PrismaService, redisService: RedisService, queueService: QueueService, metrics: MetricsService, brokerRegistry: BrokerRegistry, outboxService: OutboxService);
    triggerReconciliation(operatorId?: string): Promise<string>;
    reconcileUserBroker(userId: string, runId: string): Promise<void>;
    private mapOrderStatus;
    private applyAutoResolution;
    private checkRunCompletion;
    private registerIssue;
}
