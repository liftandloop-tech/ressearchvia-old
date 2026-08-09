import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { ReportsService } from '../reports.service';
export declare class ReportGenerationProcessor extends WorkerHost {
    private readonly prisma;
    private readonly redisService;
    private readonly metrics;
    private readonly outboxService;
    private readonly reportsService;
    private readonly storageProvider;
    private readonly logger;
    constructor(prisma: PrismaService, redisService: RedisService, metrics: MetricsService, outboxService: OutboxService, reportsService: ReportsService, storageProvider: any);
    process(job: Job<any, any, string>): Promise<any>;
}
export declare class ReportExportProcessor extends WorkerHost {
    private readonly prisma;
    private readonly reportsService;
    private readonly outboxService;
    private readonly storageProvider;
    private readonly logger;
    constructor(prisma: PrismaService, reportsService: ReportsService, outboxService: OutboxService, storageProvider: any);
    process(job: Job<any, any, string>): Promise<any>;
}
