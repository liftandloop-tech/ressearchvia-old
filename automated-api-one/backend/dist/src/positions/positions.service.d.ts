import { PrismaService } from '../prisma.service';
import { Position } from '@prisma/client';
export declare class PositionsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getActivePositions(userId: string): Promise<Position[]>;
    exitPosition(userId: string, positionId: string): Promise<Position>;
}
