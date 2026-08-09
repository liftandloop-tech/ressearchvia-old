import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { OrderStatus, TradeStatus } from '@prisma/client';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';

const NON_TERMINAL_ORDER_STATUSES = [
  OrderStatus.PENDING,
  OrderStatus.PLACED,
  OrderStatus.PARTIALLY_FILLED,
];

/**
 * Runs once on application startup to recover any orders/trades that were
 * left in non-terminal states from a previous crash or deployment.
 *
 * Recovery flow:
 *   1. Find all PENDING / PLACED / PARTIALLY_FILLED orders (cursor-paginated)
 *   2. Re-enqueue them into the order-monitoring queue
 *   3. The monitoring worker will poll broker status and reconcile
 *
 * Architecture guarantees:
 * - Cursor pagination: recovers ALL non-terminal orders regardless of count
 *   (50,000 orders after a long outage = 100 pages of 500, not a data-loss cliff)
 * - Configurable batch size via RECOVERY_BATCH_SIZE env var (default: 500)
 * - Configurable total cap via RECOVERY_MAX_ORDERS (default: 50,000)
 *   — protects against runaway recovery loops after extreme outage durations
 * - Gracefully skips when Redis is unavailable
 */
@Injectable()
export class ExecutionRecoveryService implements OnApplicationBootstrap {
  private readonly logger = new Logger(ExecutionRecoveryService.name);
  private readonly batchSize: number;
  private readonly maxOrders: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly queueService: QueueService,
    private readonly redisService: RedisService,
    private readonly configService: ConfigService,
    private readonly metrics: MetricsService,
  ) {
    this.batchSize = this.configService.get<number>('RECOVERY_BATCH_SIZE', 500);
    this.maxOrders = this.configService.get<number>('RECOVERY_MAX_ORDERS', 50_000);
  }

  async onApplicationBootstrap(): Promise<void> {
    if (!this.redisService.isHealthy()) {
      this.logger.warn(
        'Redis is not available on startup — skipping execution recovery. ' +
          'Orders in non-terminal states will not be re-monitored until Redis recovers.',
      );
      return;
    }

    this.logger.log('Running startup execution recovery scan...');

    try {
      this.metrics.incrementRecoveryJobs();
      await this.recoverPendingOrders();
    } catch (err) {
      this.metrics.incrementRecoveryJobsFailed();
      this.logger.error(`Execution recovery scan failed: ${err.message}`);
    }
  }

  private async recoverPendingOrders(): Promise<void> {
    let recovered = 0;
    let failed = 0;
    let totalScanned = 0;
    let lastCursorId: string | undefined;

    this.logger.log(
      `Recovery scan config: batchSize=${this.batchSize} maxOrders=${this.maxOrders}`,
    );

    // Cursor-paginated loop — handles any number of pending orders
    while (true) {
      if (totalScanned >= this.maxOrders) {
        this.logger.warn(
          `Recovery halted at RECOVERY_MAX_ORDERS limit (${this.maxOrders}). ` +
            `${totalScanned} orders scanned. Remaining orders will be picked up on the next deployment.`,
        );
        break;
      }

      const batch = await this.prisma.order.findMany({
        where: {
          status: { in: NON_TERMINAL_ORDER_STATUSES },
          trade: {
            status: { in: [TradeStatus.PENDING, TradeStatus.OPEN] },
          },
        },
        select: {
          id: true,
          tradeId: true,
          correlationId: true,
        },
        orderBy: { createdAt: 'asc' },
        take: this.batchSize,
        ...(lastCursorId ? { cursor: { id: lastCursorId }, skip: 1 } : {}),
      });

      if (batch.length === 0) break;

      totalScanned += batch.length;
      lastCursorId = batch[batch.length - 1].id;

      for (const order of batch) {
        const jobId = `recovery-${order.id}`;
        try {
          await this.queueService.addJob(Queues.ORDER_MONITORING, jobId, {
            orderId: order.id,
            tradeId: order.tradeId,
            correlationId: order.correlationId ?? `recovery-${order.id}`,
            isRecovery: true,
          });
          recovered++;
          this.metrics.incrementRecoveryOrdersRecovered(1);
        } catch (err) {
          this.logger.error(
            `Failed to re-enqueue order ${order.id} during recovery: ${err.message}`,
          );
          failed++;
        }
      }

      this.logger.debug(
        `Recovery page processed: ${batch.length} orders. ` +
          `Running — recovered=${recovered} failed=${failed} scanned=${totalScanned}`,
      );

      // Final page check
      if (batch.length < this.batchSize) break;
    }

    if (totalScanned === 0) {
      this.logger.log('Execution recovery: no pending orders found.');
    } else {
      this.logger.log(
        `Execution recovery complete. ` +
          `Scanned=${totalScanned} Recovered=${recovered} Failed=${failed}`,
      );
    }
  }
}
