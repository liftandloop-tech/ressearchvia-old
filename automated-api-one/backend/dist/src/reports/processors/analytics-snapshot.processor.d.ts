import { WorkerHost } from '@nestjs/bullmq';
import { OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../../prisma.service';
import { ReportsService } from '../reports.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
export declare class AnalyticsSnapshotProcessor extends WorkerHost implements OnModuleInit, OnModuleDestroy {
    private readonly prisma;
    private readonly reportsService;
    private readonly redisService;
    private readonly logger;
    private workers;
    constructor(prisma: PrismaService, reportsService: ReportsService, redisService: RedisService);
    onModuleInit(): void;
    onModuleDestroy(): Promise<void>;
    process(job: Job<any, any, string>): Promise<any>;
    processJob(job: Job<any, any, string>): Promise<any>;
}
