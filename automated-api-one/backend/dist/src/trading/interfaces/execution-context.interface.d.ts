import { UserExecutionSnapshot } from './user-execution-snapshot.interface';
import { OrderType } from '@prisma/client';
export interface ExecutionContext {
    correlationId: string;
    jobId: string;
    signalId: string;
    segmentId: string;
    symbol: string;
    exchange: string;
    side: 'BUY' | 'SELL';
    orderType: OrderType;
    entryPrice: number;
    stopLoss: number;
    targetPrice: number;
    snapshot: UserExecutionSnapshot;
}
