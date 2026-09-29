import { ConsentsService } from './consents.service';
import { StrategyType } from "@prisma/client";
export declare class ConsentsController {
    private readonly consentsService;
    constructor(consentsService: ConsentsService);
    grantConsent(req: any, body: {
        brokerId: string;
        strategy?: StrategyType;
        baseMultiplier?: number;
        consentAccepted?: boolean;
        agreementVersion?: string;
    }): Promise<{
        status: import("@prisma/client").$Enums.ConsentStatus;
        consentDate: string;
        strategy: import("@prisma/client").$Enums.StrategyType;
    }>;
    getConsentStatusToday(req: any): Promise<{
        active: boolean;
        broker: string | null;
        consentDate: string | null;
        status: string;
    }>;
    getConsentStatusDashboard(req: any): Promise<{
        active: boolean;
        broker: string | null;
        consentDate: string | null;
        status: string;
    }>;
    revokeConsent(req: any): Promise<{
        status: string;
    }>;
    getUserStrategy(req: any): Promise<{
        strategy: {
            id: string;
            status: string;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
            segmentId: string | null;
            version: number;
            currentMultiplier: number;
            strategyType: import("@prisma/client").$Enums.StrategyType;
            agreementVersion: string;
            baseMultiplier: number;
            consecutiveLosses: number;
            lastTradeResult: string | null;
            nextTradeMultiplier: number;
            effectiveFrom: Date;
            effectiveTo: Date | null;
            consentAccepted: boolean;
            strategySelectedAt: Date;
        };
        systemConfig: import("../trading/services/position-sizing.service").SystemConfigSnapshot;
    }>;
    changeUserStrategy(req: any, body: {
        strategy: StrategyType;
        agreementVersion?: string;
    }): Promise<{
        success: boolean;
        message: string;
        strategy: {
            id: string;
            status: string;
            createdAt: Date;
            updatedAt: Date;
            userId: string;
            segmentId: string | null;
            version: number;
            currentMultiplier: number;
            strategyType: import("@prisma/client").$Enums.StrategyType;
            agreementVersion: string;
            baseMultiplier: number;
            consecutiveLosses: number;
            lastTradeResult: string | null;
            nextTradeMultiplier: number;
            effectiveFrom: Date;
            effectiveTo: Date | null;
            consentAccepted: boolean;
            strategySelectedAt: Date;
        };
    }>;
    getStrategyHistory(req: any): Promise<{
        history: any;
    }>;
}
