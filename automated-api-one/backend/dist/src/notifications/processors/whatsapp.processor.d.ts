import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { WhatsAppCloudProvider } from '../providers/whatsapp.provider';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export declare class WhatsAppProcessor extends WorkerHost {
    private readonly whatsappProvider;
    private readonly circuitBreaker;
    private readonly prisma;
    private readonly queueService;
    private readonly metrics;
    private readonly logger;
    constructor(whatsappProvider: WhatsAppCloudProvider, circuitBreaker: CircuitBreakerService, prisma: PrismaService, queueService: QueueService, metrics: MetricsService);
    process(job: Job<any>): Promise<void>;
}
