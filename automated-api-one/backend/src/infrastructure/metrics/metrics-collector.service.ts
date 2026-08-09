import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { MetricsService } from './metrics.service';
import { QueueService } from '../queues/queues.service';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../redis/redis.service';
import { Queues } from '../queues/queue.constants';
import { TradeStatus, ReportState, ExportState } from '@prisma/client';

@Injectable()
export class MetricsCollectorService {
  private readonly logger = new Logger(MetricsCollectorService.name);

  constructor(
    private readonly metrics: MetricsService,
    private readonly queueService: QueueService,
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
  ) {}

  @Cron('*/15 * * * * *') // Run every 15 seconds
  async collectGauges() {
    // 1. Collect Queue and DLQ depths
    try {
      const targetQueues = [
        Queues.SIGNAL_PROCESSING,
        Queues.ORDER_PLACEMENT,
        Queues.ORDER_MONITORING,
        Queues.NOTIFICATION,
        Queues.OUTBOX_DISPATCHER,
        Queues.WEBSOCKET,
        Queues.REPORT_GENERATION,
        Queues.REPORT_EXPORT,
      ];

      // Add sharded snapshot queues (0-9)
      for (let i = 0; i < 10; i++) {
        targetQueues.push(`analytics-snapshot-${i}`);
      }

      for (const queueName of targetQueues) {
        try {
          const queue = this.queueService.getQueue(queueName);
          if (queue) {
            const waiting = await queue.getWaitingCount();
            const active = await queue.getActiveCount();
            const failed = await queue.getFailedCount();
            
            this.metrics.setQueueDepth(queueName, waiting);
            this.metrics.setQueueProcessing(queueName, active);
            this.metrics.setQueueFailed(queueName, failed);
          }
        } catch (queueErr) {
          this.logger.warn(`Failed to collect queue metrics for ${queueName}: ${queueErr.message}`);
        }
      }
    } catch (err) {
      this.logger.error(`Failed to collect queue metrics: ${err.message}`);
    }

    // 2. Collect DLQ depths
    try {
      const targetDlqs = [
        Queues.SIGNAL_DLQ,
        Queues.ORDER_DLQ,
        Queues.ORDER_MONITORING_DLQ,
        Queues.NOTIFICATION_DLQ,
        Queues.OUTBOX_DISPATCHER_DLQ,
        Queues.WEBSOCKET_DLQ,
        Queues.REPORT_GENERATION_DLQ,
        Queues.REPORT_EXPORT_DLQ,
      ];

      // Add sharded DLQs (0-9)
      for (let i = 0; i < 10; i++) {
        targetDlqs.push(`analytics-snapshot-dlq-${i}`);
      }

      for (const dlqName of targetDlqs) {
        try {
          const queue = this.queueService.getQueue(dlqName);
          if (queue) {
            const waiting = await queue.getWaitingCount();
            this.metrics.setQueueDlqDepth(dlqName, waiting);
          }
        } catch (queueErr) {
          this.logger.warn(`Failed to collect DLQ depth for ${dlqName}: ${queueErr.message}`);
        }
      }
    } catch (err) {
      this.logger.error(`Failed to collect DLQ metrics: ${err.message}`);
    }

    // 3. Redis Health breakdown & Latency
    if (this.redisService.isHealthy()) {
      try {
        const client = this.redisService.getClient();

        // Measure latency
        const start = Date.now();
        await client.ping().catch(() => {});
        this.metrics.observeRedisLatency(Date.now() - start);

        // Fetch INFO stats
        const info = await client.info();
        
        const usedMemoryMatch = info.match(/used_memory:(\d+)/);
        if (usedMemoryMatch) {
          this.metrics.setRedisMemoryUsage(parseInt(usedMemoryMatch[1], 10));
        }

        const connectedClientsMatch = info.match(/connected_clients:(\d+)/);
        if (connectedClientsMatch) {
          this.metrics.setRedisConnectedClients(parseInt(connectedClientsMatch[1], 10));
        }

        // Count active locks (keys starting with lock:, report:lock:, analytics:snapshot:lock:)
        const lockKeys = await client.keys('lock:*').catch(() => []);
        const reportLockKeys = await client.keys('report:lock:*').catch(() => []);
        const snapshotLockKeys = await client.keys('analytics:snapshot:lock:*').catch(() => []);
        const totalActiveLocks = lockKeys.length + reportLockKeys.length + snapshotLockKeys.length;
        this.metrics.setDistributedLocksActive(totalActiveLocks);

        // Count active idempotency keys (e.g., outbox:idempotency:*, signal:idempotency:*, order:idempotency:*)
        const outboxIdempotencyKeys = await client.keys('outbox:idempotency:*').catch(() => []);
        const reportIdempotencyKeys = await client.keys('report:idempotency:*').catch(() => []);
        const totalIdempotencyKeys = outboxIdempotencyKeys.length + reportIdempotencyKeys.length;
        this.metrics.setRedisIdempotencyKeysActive(totalIdempotencyKeys);
      } catch (redisErr) {
        this.logger.warn(`Failed to collect Redis telemetry metrics: ${redisErr.message}`);
      }
    }

    // 4. Collect Database Business KPIs
    try {
      const openPositionsCount = await this.prisma.trade.count({
        where: { status: TradeStatus.OPEN },
      });
      this.metrics.setOpenPositions(openPositionsCount);
    } catch (err) {
      this.logger.error(`Failed to collect open positions metric: ${err.message}`);
    }

    try {
      const activeSubscribers = await this.prisma.user.count({
        where: {
          subscriptions: {
            some: { status: 'ACTIVE' },
          },
        },
      });
      this.metrics.setSubscribersActive(activeSubscribers);

      const sparkSubscribers = await this.prisma.subscription.count({
        where: {
          planId: '11111111-e29b-41d4-a716-446655440001',
          status: 'ACTIVE',
        },
      });
      this.metrics.setSparkSubscriptions(sparkSubscribers);

      const splendidSubscribers = await this.prisma.subscription.count({
        where: {
          planId: '11111111-e29b-41d4-a716-446655440002',
          status: 'ACTIVE',
        },
      });
      this.metrics.setSplendidSubscriptions(splendidSubscribers);

      // Active segments counts
      const activeSegs = await this.prisma.userSegment.count({
        where: { status: 'ACTIVE' },
      });
      this.metrics.setSegmentsActive(activeSegs);
      this.metrics.setActiveSegments(activeSegs);

      const pausedSegs = await this.prisma.userSegment.count({
        where: { status: 'PAUSED' },
      });
      this.metrics.setSegmentsPaused(pausedSegs);

      const lockedSegs = await this.prisma.userSegment.count({
        where: {
          status: 'PAUSED',
          lastRiskLockAt: { not: null },
        },
      });
      this.metrics.setSegmentsRiskLocked(lockedSegs);

      // Today's active consents
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const activeConsents = await this.prisma.consent.count({
        where: {
          status: 'ACTIVE',
          updatedAt: { gte: today },
        },
      });
      this.metrics.setConsentsActiveToday(activeConsents);
    } catch (dbErr) {
      this.logger.warn(`Failed to collect database KPI metrics: ${dbErr.message}`);
    }

    // 5. Collect Outbox event telemetry
    try {
      const pendingCount = await this.prisma.outboxEvent.count({
        where: { status: 'PENDING' },
      });
      this.metrics.setOutboxEventsPending(pendingCount);

      const processingCount = await this.prisma.outboxEvent.count({
        where: { status: 'PROCESSING' },
      });
      this.metrics.setOutboxEventsProcessing(processingCount);

      const failedCount = await this.prisma.outboxEvent.count({
        where: { status: 'FAILED' },
      });
      this.metrics.setOutboxEventsFailed(failedCount);
    } catch (outboxErr) {
      this.logger.warn(`Failed to collect outbox telemetry: ${outboxErr.message}`);
    }
  }
}

