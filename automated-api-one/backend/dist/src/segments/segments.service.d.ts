import { OnModuleInit } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { UserSegment } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
export declare class SegmentsService implements OnModuleInit {
    private readonly prisma;
    private readonly auditService;
    constructor(prisma: PrismaService, auditService: AuditService);
    onModuleInit(): Promise<void>;
    private seedDefaultSegments;
    listSegments(): Promise<any[]>;
    activateSegment(userId: string, data: {
        segmentId: string;
        capital: number;
        backupCapital: number;
        baseLot: number;
        maxMultiplier: number;
        dailyLossLimit: number;
    }): Promise<UserSegment>;
    pauseSegment(userId: string, segmentId: string): Promise<UserSegment>;
    getUserSegments(userId: string): Promise<UserSegment[]>;
}
