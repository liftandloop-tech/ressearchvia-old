import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { ResendProvider, SmtpProvider } from '../providers/email.providers';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export declare class EmailProcessor extends WorkerHost {
    private readonly resendProvider;
    private readonly smtpProvider;
    private readonly circuitBreaker;
    private readonly prisma;
    private readonly queueService;
    private readonly metrics;
    private readonly logger;
    constructor(resendProvider: ResendProvider, smtpProvider: SmtpProvider, circuitBreaker: CircuitBreakerService, prisma: PrismaService, queueService: QueueService, metrics: MetricsService);
    process(job: Job<any>): Promise<void>;
}
