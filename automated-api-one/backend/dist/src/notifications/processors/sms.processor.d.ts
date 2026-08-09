import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { TwilioProvider, Msg91Provider } from '../providers/sms.providers';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export declare class SmsProcessor extends WorkerHost {
    private readonly twilioProvider;
    private readonly msg91Provider;
    private readonly circuitBreaker;
    private readonly prisma;
    private readonly queueService;
    private readonly metrics;
    private readonly logger;
    constructor(twilioProvider: TwilioProvider, msg91Provider: Msg91Provider, circuitBreaker: CircuitBreakerService, prisma: PrismaService, queueService: QueueService, metrics: MetricsService);
    process(job: Job<any>): Promise<void>;
}
