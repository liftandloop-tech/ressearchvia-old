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
