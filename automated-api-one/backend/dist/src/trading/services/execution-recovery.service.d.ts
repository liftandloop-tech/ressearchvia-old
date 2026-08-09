import { OnApplicationBootstrap } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
export declare class ExecutionRecoveryService implements OnApplicationBootstrap {
    private readonly prisma;
    private readonly queueService;
    private readonly redisService;
    private readonly configService;
    private readonly metrics;
    private readonly logger;
    private readonly batchSize;
    private readonly maxOrders;
    constructor(prisma: PrismaService, queueService: QueueService, redisService: RedisService, configService: ConfigService, metrics: MetricsService);
    onApplicationBootstrap(): Promise<void>;
    private recoverPendingOrders;
}
