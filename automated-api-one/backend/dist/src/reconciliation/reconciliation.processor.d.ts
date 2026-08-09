import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { ReconciliationService } from './reconciliation.service';
export declare class ReconciliationProcessor extends WorkerHost {
    private readonly reconciliationService;
    private readonly logger;
    constructor(reconciliationService: ReconciliationService);
    process(job: Job<any, any, string>): Promise<any>;
}
