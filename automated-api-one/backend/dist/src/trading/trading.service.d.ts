import { SignalOrchestratorService } from './services/signal-orchestrator.service';
import { SignalState } from '@prisma/client';
export declare class TradingService {
    private readonly orchestrator;
    private readonly logger;
    constructor(orchestrator: SignalOrchestratorService);
    executeSignal(signalId: string, segmentId: string): Promise<{
        success: boolean;
        state: SignalState;
        correlationId: string;
        totalUsers: number;
        successUsers: number;
        rejectedUsers: number;
    }>;
}
