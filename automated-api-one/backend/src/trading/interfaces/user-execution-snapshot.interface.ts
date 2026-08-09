/**
 * Immutable snapshot of user execution parameters captured at signal queue time.
 * This prevents race conditions caused by user settings changing between enqueue
 * and worker processing (e.g., signal arrives → queue waits → user changes multiplier).
 */
export interface UserExecutionSnapshot {
  userId: string;
  brokerId: string;
  brokerCode: string;
  brokerClientId: string;
  segmentId: string;
  subscriptionPlan: 'SPARK' | 'SPLENDID';
  multiplierIndex: number;
  multiplierValue: number;
  capitalAllocated: number;
  baseLot: number;
  effectiveLot: number;
}
