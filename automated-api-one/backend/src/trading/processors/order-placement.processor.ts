import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { ConfigService } from '@nestjs/config';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { OrderPlacementService } from '../services/order-placement.service';
import { ExecutionContext } from '../interfaces/execution-context.interface';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { QueueJobStatus } from '@prisma/client';

/**
 * Order Placement Processor — consumes jobs from the `order-placement` queue.
 *
 * Each job payload: ExecutionContext (signal details + user snapshot)
 *
 * Concurrency is configured via ORDER_PLACEMENT_CONCURRENCY (default: 20).
 * This controls how many parallel broker calls can be made simultaneously.
 */
@Processor(Queues.ORDER_PLACEMENT)
export class OrderPlacementProcessor extends WorkerHost {
  private readonly logger = new Logger(OrderPlacementProcessor.name);
  private readonly concurrency: number;

  constructor(
    private readonly orderPlacementService: OrderPlacementService,
    private readonly queueService: QueueService,
    private readonly redisService: RedisService,
    private readonly configService: ConfigService,
  ) {
    super();
    this.concurrency = this.configService.get<number>('ORDER_PLACEMENT_CONCURRENCY', 20);
  }

  async process(job: Job<ExecutionContext>): Promise<void> {
    const ctx = job.data;
    const jobId = job.id ?? ctx.jobId;
    const { correlationId, snapshot } = ctx;

    // Fail closed — never place orders if Redis is unavailable
    // Re-throw causes BullMQ to apply exponential backoff until Redis recovers
    this.redisService.assertHealthy();

    this.logger.log(
      `[${correlationId}] Processing order placement: jobId=${jobId} user=${snapshot.userId}`,
    );

    try {
      const result = await this.orderPlacementService.placeEntryOrder(ctx);

      if (!result.success) {
        this.logger.warn(
          `[${correlationId}] Order placement skipped/rejected for user ${snapshot.userId}: ${result.reason}`,
        );
        // Mark as completed (not failed) — rejected orders are not errors
        await this.queueService.updateJobStatus(
          Queues.ORDER_PLACEMENT,
          jobId,
          QueueJobStatus.COMPLETED,
          job.attemptsMade,
        );
        return;
      }

      await this.queueService.updateJobStatus(
        Queues.ORDER_PLACEMENT,
        jobId,
        QueueJobStatus.COMPLETED,
        job.attemptsMade,
      );

      this.logger.log(
        `[${correlationId}] Order placement successful: tradeId=${result.tradeId} brokerOrderId=${result.brokerOrderId}`,
      );
    } catch (err) {
      this.logger.error(
        `[${correlationId}] Order placement job ${jobId} failed: ${err.message}`,
        err.stack,
      );

      await this.queueService.updateJobStatus(
        Queues.ORDER_PLACEMENT,
        jobId,
        QueueJobStatus.FAILED,
        job.attemptsMade,
      );

      throw err;
    }
  }
}
