import { WorkerHost } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';
import { Job } from 'bullmq';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../redis/redis.service';
import { QueueService } from '../queues/queues.service';
import { MetricsService } from '../metrics/metrics.service';
export declare class OutboxProcessor extends WorkerHost {
    private readonly prisma;
    private readonly redisService;
    private readonly queueService;
    private readonly configService;
    private readonly metrics;
    private readonly logger;
    private isCronProcessing;
    constructor(prisma: PrismaService, redisService: RedisService, queueService: QueueService, configService: ConfigService, metrics: MetricsService);
    process(job: Job<{
        outboxEventId: string;
    }>): Promise<void>;
    fallbackPoll(): Promise<void>;
    private determineQueues;
}
