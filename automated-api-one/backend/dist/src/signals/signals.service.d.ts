import { PrismaService } from '../prisma.service';
import { PublishSignalDto } from './signals.controller';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { RedisService } from '../infrastructure/redis/redis.service';
export declare class SignalsService {
    private readonly prisma;
    private readonly queueService;
    private readonly metrics;
    private readonly redisService;
    constructor(prisma: PrismaService, queueService: QueueService, metrics: MetricsService, redisService: RedisService);
    publishAndEnqueue(dto: PublishSignalDto): Promise<{
        success: boolean;
        signalId: string;
    }>;
    private forwardSignalToLlBackend;
}
