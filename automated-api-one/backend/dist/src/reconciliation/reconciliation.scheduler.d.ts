import { ReconciliationService } from './reconciliation.service';
export declare class ReconciliationScheduler {
    private readonly reconciliationService;
    private readonly logger;
    constructor(reconciliationService: ReconciliationService);
    runScheduledReconciliation(): Promise<void>;
}
