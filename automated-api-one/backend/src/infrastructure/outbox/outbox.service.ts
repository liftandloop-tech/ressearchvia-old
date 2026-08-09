import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { OutboxEvent, OutboxStatus } from '@prisma/client';
import { QueueService } from '../queues/queues.service';
import { Queues } from '../queues/queue.constants';
import { MetricsService } from '../metrics/metrics.service';

@Injectable()
export class OutboxService {
  private readonly logger = new Logger(OutboxService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
  ) {}

  /**
   * Creates an outbox event. Supports passing an optional Prisma transaction client.
   * If tx is provided, DOES NOT enqueue the job immediately (caller must enqueue it post-commit).
   */
  async createEvent(
    eventType: string,
    payload: any,
    tx?: any,
    options?: {
      eventKey?: string;
      aggregateId?: string;
      version?: number;
      correlationId?: string;
    },
  ): Promise<OutboxEvent> {
    const db = tx || this.prisma;
    const correlationId = options?.correlationId || payload?.correlationId || null;
    const version = options?.version || payload?.version || 1;
    const eventKey = options?.eventKey || null;
    const aggregateId = options?.aggregateId || null;

    const event = await db.outboxEvent.create({
      data: {
        eventType,
        eventKey,
        aggregateId,
        version,
        correlationId,
        payload: payload || {},
        status: OutboxStatus.PENDING,
        attempts: 0,
      },
    });

    this.metrics.incrementOutboxEventsCreated();

    // Enqueue job to continuous outbox-dispatcher queue ONLY if NOT inside transaction
    if (!tx) {
      await this.enqueueEvent(event.id);
    }

    return event;
  }

  /**
   * Enqueues an outbox event job manually. Useful after transaction commit.
   */
  async enqueueEvent(eventId: string): Promise<void> {
    try {
      await this.queueService.addJob(
        Queues.OUTBOX_DISPATCHER,
        eventId,
        { outboxEventId: eventId },
      );
    } catch (err) {
      this.logger.error(
        `Failed to enqueue outbox dispatcher job for event ${eventId}: ${err.message}`,
      );
    }
  }
}
