import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { RiskService } from './risk.service';
export declare class RiskProcessor extends WorkerHost {
    private readonly riskService;
    private readonly logger;
    constructor(riskService: RiskService);
    process(job: Job<{
        userId: string;
    }>): Promise<void>;
}
