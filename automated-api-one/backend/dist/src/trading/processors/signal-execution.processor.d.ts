import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { SignalOrchestratorService } from '../services/signal-orchestrator.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export declare class SignalExecutionProcessor extends WorkerHost {
    private readonly orchestrator;
    private readonly queueService;
    private readonly metrics;
    private readonly logger;
    constructor(orchestrator: SignalOrchestratorService, queueService: QueueService, metrics: MetricsService);
    process(job: Job<{
        signalId: string;
    }>): Promise<void>;
}
