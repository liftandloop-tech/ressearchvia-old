import { SegmentsService } from './segments.service';
export declare class ActivateSegmentDto {
    segmentId: string;
    capital: number;
    backupCapital: number;
    baseLot: number;
    maxMultiplier: number;
    dailyLossLimit: number;
}
export declare class PauseSegmentDto {
    segmentId: string;
}
export declare class SegmentsController {
    private readonly segmentsService;
    constructor(segmentsService: SegmentsService);
    listSegments(): Promise<any[]>;
    getActiveSegments(req: any): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.UserSegmentStatus;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        segmentId: string;
        capital: import("@prisma/client-runtime-utils").Decimal;
        backupCapital: import("@prisma/client-runtime-utils").Decimal;
        baseLot: number;
        maxMultiplier: number;
        dailyLossLimit: import("@prisma/client-runtime-utils").Decimal;
        activatedAt: Date | null;
        pausedAt: Date | null;
        lastRiskLockAt: Date | null;
    }[]>;
    activateSegment(req: any, dto: ActivateSegmentDto): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.UserSegmentStatus;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        segmentId: string;
        capital: import("@prisma/client-runtime-utils").Decimal;
        backupCapital: import("@prisma/client-runtime-utils").Decimal;
        baseLot: number;
        maxMultiplier: number;
        dailyLossLimit: import("@prisma/client-runtime-utils").Decimal;
        activatedAt: Date | null;
        pausedAt: Date | null;
        lastRiskLockAt: Date | null;
    }>;
    pauseSegment(req: any, dto: PauseSegmentDto): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.UserSegmentStatus;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        segmentId: string;
        capital: import("@prisma/client-runtime-utils").Decimal;
        backupCapital: import("@prisma/client-runtime-utils").Decimal;
        baseLot: number;
        maxMultiplier: number;
        dailyLossLimit: import("@prisma/client-runtime-utils").Decimal;
        activatedAt: Date | null;
        pausedAt: Date | null;
        lastRiskLockAt: Date | null;
    }>;
}
