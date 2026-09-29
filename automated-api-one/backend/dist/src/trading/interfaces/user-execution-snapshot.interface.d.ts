import { StrategyType } from "@prisma/client";
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
    strategyType?: StrategyType;
    strategyVersion?: number;
    baseQuantity?: number;
    actualQuantity?: number;
    consecutiveLossesAtEntry?: number;
    previousTradeResult?: string | null;
    agreementVersion?: string;
}
