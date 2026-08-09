import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { ConfigService } from '@nestjs/config';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { OrderPlacementService } from '../services/order-placement.service';
import { ExecutionContext } from '../interfaces/execution-context.interface';
export declare class OrderPlacementProcessor extends WorkerHost {
    private readonly orderPlacementService;
    private readonly queueService;
    private readonly redisService;
    private readonly configService;
    private readonly logger;
    private readonly concurrency;
    constructor(orderPlacementService: OrderPlacementService, queueService: QueueService, redisService: RedisService, configService: ConfigService);
    process(job: Job<ExecutionContext>): Promise<void>;
}
