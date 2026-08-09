import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { ConfigService } from '@nestjs/config';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { OrderMonitoringService } from '../services/order-monitoring.service';
export interface OrderMonitoringPayload {
    orderId: string;
    tradeId: string;
    correlationId: string;
    isRecovery?: boolean;
}
export declare class OrderMonitoringProcessor extends WorkerHost {
    private readonly orderMonitoringService;
    private readonly queueService;
    private readonly redisService;
    private readonly configService;
    private readonly logger;
    private readonly concurrency;
    constructor(orderMonitoringService: OrderMonitoringService, queueService: QueueService, redisService: RedisService, configService: ConfigService);
    process(job: Job<OrderMonitoringPayload>): Promise<void>;
}
