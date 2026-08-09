import { MetricsService } from './metrics.service';
import { QueueService } from '../queues/queues.service';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../redis/redis.service';
export declare class MetricsCollectorService {
    private readonly metrics;
    private readonly queueService;
    private readonly prisma;
    private readonly redisService;
    private readonly logger;
    constructor(metrics: MetricsService, queueService: QueueService, prisma: PrismaService, redisService: RedisService);
    collectGauges(): Promise<void>;
}
