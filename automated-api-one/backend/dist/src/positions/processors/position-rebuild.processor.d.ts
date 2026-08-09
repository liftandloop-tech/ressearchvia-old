import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { PrismaService } from '../../prisma.service';
import { PositionCacheService } from '../../trading/services/position-cache.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
export declare class PositionRebuildProcessor extends WorkerHost {
    private readonly prisma;
    private readonly positionCacheService;
    private readonly queueService;
    private readonly logger;
    constructor(prisma: PrismaService, positionCacheService: PositionCacheService, queueService: QueueService);
    process(job: Job<{
        userId?: string;
        segmentId?: string;
    }>): Promise<void>;
    private rebuildSegment;
}
