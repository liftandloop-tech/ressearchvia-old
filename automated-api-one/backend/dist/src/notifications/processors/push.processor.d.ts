import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { FcmProvider } from '../providers/push.provider';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export declare class PushProcessor extends WorkerHost {
    private readonly fcmProvider;
    private readonly circuitBreaker;
    private readonly prisma;
    private readonly queueService;
    private readonly metrics;
    private readonly logger;
    constructor(fcmProvider: FcmProvider, circuitBreaker: CircuitBreakerService, prisma: PrismaService, queueService: QueueService, metrics: MetricsService);
    process(job: Job<any>): Promise<void>;
}
