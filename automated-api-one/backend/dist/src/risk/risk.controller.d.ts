import { RiskService } from './risk.service';
export declare class GetRiskEventsDto {
    limit?: number;
    offset?: number;
}
export declare class ResetRiskDto {
    segmentId: string;
}
export declare class PaginatedQueryDto {
    page?: number;
    limit?: number;
}
export declare class UnlockSegmentDto {
    targetUserId?: string;
}
export declare class CreateRiskProfileDto {
    userId?: string;
    segmentId?: string;
    brokerId?: string;
    priority?: number;
    maxCapitalPerUser: number;
    maxCapitalPerSegment: number;
    maxDailyLoss: number;
    maxOpenPositions: number;
    maxPositionSize: number;
    maxExposurePerSymbol: number;
    maxExposurePerBroker: number;
    maxConcurrentOrders: number;
}
export declare class UpdateRiskProfileDto {
    userId?: string;
    segmentId?: string;
    brokerId?: string;
    priority?: number;
    maxCapitalPerUser?: number;
    maxCapitalPerSegment?: number;
    maxDailyLoss?: number;
    maxOpenPositions?: number;
    maxPositionSize?: number;
    maxExposurePerSymbol?: number;
    maxExposurePerBroker?: number;
    maxConcurrentOrders?: number;
}
export declare class RiskController {
    private readonly riskService;
    constructor(riskService: RiskService);
    getStatusForSegment(req: any, segmentId: string): Promise<{
        locked: boolean;
        dailyLoss: number;
        dailyLossLimit: number;
    }>;
    getEventsForSegment(req: any, segmentId: string, query: PaginatedQueryDto): Promise<any>;
    unlockSegment(req: any, segmentId: string, dto: UnlockSegmentDto): Promise<any>;
    createProfile(dto: CreateRiskProfileDto): Promise<any>;
    updateProfile(id: string, dto: UpdateRiskProfileDto): Promise<any>;
    getViolations(req: any, queryUserId?: string): Promise<any[]>;
    getSnapshots(req: any, queryUserId?: string): Promise<any[]>;
    getEvents(req: any, query: GetRiskEventsDto): Promise<{
        data: import("@prisma/client").RiskEvent[];
        total: number;
    }>;
    getStatus(req: any): Promise<any[]>;
    resetLock(req: any, dto: ResetRiskDto): Promise<any>;
}
