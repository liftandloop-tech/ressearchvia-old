import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { OutboxService } from '../infrastructure/outbox/outbox.service';
import { AnalyticsSnapshot } from '@prisma/client';
export declare class ReportsService {
    private readonly prisma;
    private readonly redisService;
    private readonly queueService;
    private readonly metrics;
    private readonly outboxService;
    private readonly storageProvider;
    private readonly logger;
    constructor(prisma: PrismaService, redisService: RedisService, queueService: QueueService, metrics: MetricsService, outboxService: OutboxService, storageProvider: any);
    parsePeriod(type: string, period: string): {
        startDate: Date;
        endDate: Date;
    };
    getReportFromCache(userId: string, type: string, period: string, segmentId?: string): Promise<any | null>;
    cacheReport(userId: string, type: string, period: string, segmentId: string | undefined, data: any): Promise<void>;
    getReportOrEnqueue(userId: string, type: 'DAILY' | 'MONTHLY', period: string, segmentId?: string): Promise<{
        status: string;
        reportId?: string;
        estimatedWait?: string;
        data?: any;
    }>;
    requestCsvExport(userId: string, type: string, period: string, segmentId?: string): Promise<{
        status: string;
        exportId: string;
    }>;
    rebuildSnapshots(payload: {
        startDate: Date;
        endDate: Date;
        userId?: string;
        segmentId?: string;
    }): Promise<void>;
    calculateAndUpsertSnapshot(userId: string, segmentId: string, date: Date): Promise<AnalyticsSnapshot>;
}
