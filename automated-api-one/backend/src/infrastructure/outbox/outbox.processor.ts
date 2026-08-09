import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';
import { Job } from 'bullmq';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../redis/redis.service';
import { QueueService } from '../queues/queues.service';
import { Queues } from '../queues/queue.constants';
import { OutboxStatus } from '@prisma/client';
import { MetricsService } from '../metrics/metrics.service';

const EVENT_ROUTING: Record<string, string | string[]> = {
  ORDER_PLACED: Queues.NOTIFICATION,
  ORDER_FILLED: Queues.NOTIFICATION,
  ORDER_REJECTED: Queues.NOTIFICATION,
  ORDER_CANCELLED: Queues.NOTIFICATION,
  ORDER_FAILED: Queues.NOTIFICATION,

  POSITION_UPDATED: Queues.WEBSOCKET,

  TARGET_HIT: Queues.NOTIFICATION,
  STOPLOSS_HIT: Queues.NOTIFICATION,

  CONSENT_GRANTED: Queues.NOTIFICATION,
  CONSENT_REVOKED: Queues.NOTIFICATION,

  SUBSCRIPTION_ACTIVATED: Queues.NOTIFICATION,
  SUBSCRIPTION_RENEWED: Queues.NOTIFICATION,
  SUBSCRIPTION_CANCELLED: Queues.NOTIFICATION,

  BROKER_DISCONNECTED: [
    Queues.NOTIFICATION,
    Queues.WEBSOCKET,
  ],

  // Internal/Legacy mappings:
  TRADE_OPENED: [
    Queues.NOTIFICATION,
    Queues.ORDER_MONITORING,
  ],
  TRADE_CLOSED: Queues.NOTIFICATION,
  TRADE_EXECUTED: Queues.NOTIFICATION,
  ORDER_PLACEMENT: Queues.ORDER_PLACEMENT,
  ORDER_MONITORING: Queues.ORDER_MONITORING,
  SIGNAL_PUBLISHED: Queues.SIGNAL_PROCESSING,
  RISK_VIOLATION: Queues.NOTIFICATION,
  RECONCILIATION_ISSUE: [
    Queues.NOTIFICATION,
    Queues.WEBSOCKET,
  ],
};

@Processor(Queues.OUTBOX_DISPATCHER, {
  concurrency: 10,
})
export class OutboxProcessor extends WorkerHost {
  private readonly logger = new Logger(OutboxProcessor.name);
  private isCronProcessing = false;

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    private readonly queueService: QueueService,
    private readonly configService: ConfigService,
    private readonly metrics: MetricsService,
  ) {
    super();
  }

  /**
   * BullMQ processor job consumer.
   * Dispatches outbox events sequentially and reliably.
   */
  async process(job: Job<{ outboxEventId: string }>): Promise<void> {
    const { outboxEventId } = job.data;

    // Fail closed — never process outbox events if Redis is unreachable
    this.redisService.assertHealthy();

    const event = await this.prisma.outboxEvent.findUnique({
      where: { id: outboxEventId },
    });

    if (!event) {
      this.logger.warn(`Outbox event ${outboxEventId} not found in database. Skipping.`);
      return;
    }

    if (event.status === OutboxStatus.PROCESSED) {
      this.logger.debug(`Outbox event ${outboxEventId} already processed. Skipping.`);
      return;
    }

    // Update status to PROCESSING in DB
    await this.prisma.outboxEvent.update({
      where: { id: outboxEventId },
      data: { status: OutboxStatus.PROCESSING },
    });

    // Event Deduplication with Redis SETNX using eventKey (7 days TTL)
    if (event.eventKey) {
      const redisKey = `outbox:idempotency:${event.eventKey}`;
      try {
        const isNew = await this.redisService
          .getClient()
          .set(redisKey, '1', 'PX', 604800000, 'NX'); // 7 days expiry
        if (!isNew) {
          this.logger.warn(
            `Outbox event ${outboxEventId} with key ${event.eventKey} is duplicate. Deduplicating.`,
          );
          await this.prisma.outboxEvent.update({
            where: { id: outboxEventId },
            data: {
              status: OutboxStatus.PROCESSED,
              processedAt: new Date(),
            },
          });
          return;
        }
      } catch (err) {
        this.logger.error(
          `Redis idempotency check failed for key ${event.eventKey}: ${err.message}. Failing job to retry.`,
        );
        await this.prisma.outboxEvent.update({
          where: { id: outboxEventId },
          data: { status: OutboxStatus.PENDING },
        });
        throw err;
      }
    }

    try {
      const targetQueues = this.determineQueues(event.eventType);

      // Dispatch to all target queues
      for (const queueName of targetQueues) {
        await this.queueService.addJob(queueName, event.id, event.payload);
      }

      // Trigger asynchronous portfolio risk snapshot rebuild on key events
      const riskRecalculateEvents = [
        'ORDER_PLACED',
        'ORDER_FILLED',
        'ORDER_REJECTED',
        'ORDER_CANCELLED',
        'ORDER_FAILED',
        'TRADE_OPENED',
        'TRADE_CLOSED',
        'TRADE_EXECUTED',
      ];
      if (riskRecalculateEvents.includes(event.eventType)) {
        const payload = event.payload as any;
        const userId = payload?.userId;
        if (userId) {
          const jobId = `risk-recalc-${userId}`;
          try {
            await this.queueService.addJob(Queues.RISK_RECALCULATE, jobId, { userId });
          } catch (err) {
            this.logger.error(`Failed to enqueue risk recalculation job for user ${userId}: ${err.message}`);
          }
        }
      }

      // Mark as processed in DB
      await this.prisma.outboxEvent.update({
        where: { id: outboxEventId },
        data: {
          status: OutboxStatus.PROCESSED,
          processedAt: new Date(),
          attempts: job.attemptsMade + 1,
        },
      });

      this.metrics.incrementOutboxEventsProcessed();

      this.logger.log(
        `Successfully dispatched outbox event ${outboxEventId} of type ${event.eventType} to [${targetQueues.join(', ')}]`,
      );
    } catch (err) {
      const attempts = job.attemptsMade + 1;
      const maxAttempts = job.opts.attempts || 5;
      const status = attempts >= maxAttempts ? OutboxStatus.FAILED : OutboxStatus.PENDING;

      this.logger.error(
        `Failed to dispatch outbox event ${outboxEventId} (Attempt ${attempts}/${maxAttempts}): ${err.message}`,
      );

      await this.prisma.outboxEvent.update({
        where: { id: outboxEventId },
        data: {
          attempts,
          status,
        },
      });

      if (status === OutboxStatus.FAILED) {
        this.metrics.incrementOutboxEventsDlq();
      } else {
        this.metrics.incrementOutboxEventsFailed();
      }

      throw err; // Re-throw to trigger BullMQ retry backoff
    }
  }

  /**
   * Fallback poller cron: runs every 30 seconds to recover any PENDING outbox events
   * that missed the immediate BullMQ enqueue trigger, and resets any stuck PROCESSING events.
   */
  @Cron('*/30 * * * * *')
  async fallbackPoll() {
    if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
      return;
    }
    if (this.isCronProcessing) return;
    if (!this.redisService.isHealthy()) return;

    this.isCronProcessing = true;
    try {
      // 1. Recover events stuck in PROCESSING for more than 5 minutes back to PENDING
      const fiveMinutesAgo = new Date(Date.now() - 300000);
      const stuckProcessing = await this.prisma.outboxEvent.findMany({
        where: {
          status: OutboxStatus.PROCESSING,
          createdAt: { lte: fiveMinutesAgo },
        },
        take: 50,
      });

      for (const event of stuckProcessing) {
        this.logger.warn(`Outbox event ${event.id} stuck in PROCESSING. Resetting to PENDING.`);
        await this.prisma.outboxEvent.update({
          where: { id: event.id },
          data: { status: OutboxStatus.PENDING },
        });
      }

      // 2. Poll and enqueue stuck PENDING events
      const tenSecondsAgo = new Date(Date.now() - 10000);
      const stuckEvents = await this.prisma.outboxEvent.findMany({
        where: {
          status: OutboxStatus.PENDING,
          createdAt: { lte: tenSecondsAgo },
        },
        orderBy: { createdAt: 'asc' },
        take: 50,
      });

      if (stuckEvents.length > 0) {
        this.logger.log(
          `Fallback poller found ${stuckEvents.length} stuck PENDING outbox events. Re-enqueuing...`,
        );
        for (const event of stuckEvents) {
          try {
            await this.queueService.addJob(
              Queues.OUTBOX_DISPATCHER,
              event.id,
              { 
                outboxEventId: event.id,
                eventType: event.eventType,
                eventKey: event.eventKey || null,
              },
            );
          } catch (err) {
            this.logger.error(
              `Fallback poller failed to re-enqueue event ${event.id}: ${err.message}`,
            );
          }
        }
      }
    } catch (err) {
      this.logger.error(`Fallback outbox poller error: ${err.message}`);
    } finally {
      this.isCronProcessing = false;
    }
  }

  /**
   * Event routing table mapping event types to target queues.
   */
  private determineQueues(eventType: string): string[] {
    const routes = EVENT_ROUTING[eventType];
    if (!routes) {
      this.logger.warn(
        `Unknown outbox event type: ${eventType}. Fallback to trade-execution.`,
      );
      return [Queues.SIGNAL_PROCESSING];
    }
    return Array.isArray(routes) ? routes : [routes];
  }
}
