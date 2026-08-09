import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { AnalyticsService } from '../analytics.service';
export declare class AnalyticsProcessor extends WorkerHost {
    private readonly analyticsService;
    private readonly logger;
    constructor(analyticsService: AnalyticsService);
    process(job: Job<{
        userId: string;
        runId?: string;
        totalUsers?: number;
        rebuildHistory?: boolean;
    }>): Promise<void>;
}
