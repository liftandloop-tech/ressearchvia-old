import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { ConfigService } from '@nestjs/config';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { OrderMonitoringService } from '../services/order-monitoring.service';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { QueueJobStatus } from '@prisma/client';

export interface OrderMonitoringPayload {
  orderId: string;
  tradeId: string;
  correlationId: string;
  isRecovery?: boolean;
}

/**
 * Order Monitoring Processor — consumes jobs from the `order-monitoring` queue.
 *
 * Each job payload: { orderId, tradeId, correlationId, isRecovery? }
 *
 * Concurrency is configured via ORDER_MONITORING_CONCURRENCY (default: 50).
 * Higher concurrency than placement because status polling is lighter than order submission.
 *
 * Non-terminal status returns (PENDING from broker) cause a job re-throw so BullMQ
 * applies exponential backoff and retries automatically.
 */
@Processor(Queues.ORDER_MONITORING)
export class OrderMonitoringProcessor extends WorkerHost {
  private readonly logger = new Logger(OrderMonitoringProcessor.name);
  private readonly concurrency: number;

  constructor(
    private readonly orderMonitoringService: OrderMonitoringService,
    private readonly queueService: QueueService,
    private readonly redisService: RedisService,
    private readonly configService: ConfigService,
  ) {
    super();
    this.concurrency = this.configService.get<number>('ORDER_MONITORING_CONCURRENCY', 50);
  }

  async process(job: Job<OrderMonitoringPayload>): Promise<void> {
    const { orderId, tradeId, correlationId, isRecovery } = job.data;
    const jobId = job.id ?? `monitor-${orderId}`;

    // Fail closed — never reconcile order state if Redis cache is unavailable
    this.redisService.assertHealthy();

    this.logger.log(
      `[${correlationId}] Monitoring order: orderId=${orderId} tradeId=${tradeId}` +
        (isRecovery ? ' [RECOVERY]' : ''),
    );

    try {
      const result = await this.orderMonitoringService.pollOrderStatus(orderId, correlationId);

      if (result.finalStatus === 'PENDING') {
        // Non-terminal — re-throw to trigger BullMQ exponential backoff retry
        throw new Error(
          `Order ${orderId} still pending: ${result.reason ?? 'awaiting broker confirmation'}`,
        );
      }

      // Terminal state reached
      await this.queueService.updateJobStatus(
        Queues.ORDER_MONITORING,
        jobId,
        QueueJobStatus.COMPLETED,
        job.attemptsMade,
      );

      this.logger.log(
        `[${correlationId}] Order ${orderId} reached terminal state: ${result.finalStatus}`,
      );
    } catch (err) {
      if (job.attemptsMade >= (job.opts.attempts ?? 3) - 1) {
        // Final retry exhausted — mark as DLQ candidate
        this.logger.error(
          `[${correlationId}] Order monitoring job ${jobId} exhausted all retries: ${err.message}`,
        );

        await this.queueService.updateJobStatus(
          Queues.ORDER_MONITORING,
          jobId,
          QueueJobStatus.DLQ,
          job.attemptsMade,
        );
      }

      throw err;
    }
  }
}
