import { UserExecutionSnapshot } from './user-execution-snapshot.interface';
import { OrderType } from '@prisma/client';

/**
 * Full execution context passed through the trading engine pipeline.
 * Carries signal data + user snapshot + traceability identifiers.
 */
export interface ExecutionContext {
  /** Signal correlation ID for distributed tracing */
  correlationId: string;

  /** BullMQ deterministic job ID: `job:${signalId}:${userId}` */
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

  /** Locked user state snapshot — must not be re-fetched during execution */
  snapshot: UserExecutionSnapshot;
}
