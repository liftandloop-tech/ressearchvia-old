import { PrismaService } from '../prisma.service';
import { CacheService } from '../infrastructure/cache/cache.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { QueueService } from '../infrastructure/queues/queues.service';
export declare class AnalyticsService {
    private readonly prisma;
    private readonly cacheService;
    private readonly metrics;
    private readonly queueService;
    private readonly logger;
    constructor(prisma: PrismaService, cacheService: CacheService, metrics: MetricsService, queueService: QueueService);
    recalculateAnalyticsSnapshot(userId: string): Promise<void>;
    rebuildHistoricalSnapshots(userId: string): Promise<void>;
    updatePerformanceRollups(userId: string): Promise<void>;
    getPortfolioPerformance(userId: string): Promise<any>;
    getSegmentPerformance(userId: string): Promise<any>;
    getBrokerPerformance(userId: string): Promise<any>;
    invalidateUserCache(userId: string): Promise<void>;
    handleNightlyAnalyticsRecalculation(): Promise<void>;
    handleJobCompletion(runId: string, totalUsers: number, success: boolean): Promise<void>;
    cleanupEquityCurvePoints(): Promise<void>;
    enqueueRecalculation(userId: string, rebuildHistory?: boolean): Promise<void>;
}
