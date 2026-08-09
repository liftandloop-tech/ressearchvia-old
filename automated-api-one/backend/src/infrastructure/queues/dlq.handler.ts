import { Injectable, Logger } from '@nestjs/common';
import { QueueEventsListener, QueueEventsHost, OnQueueEvent } from '@nestjs/bullmq';
import { QueueService } from './queues.service';
import { Queues } from './queue.constants';
import { QueueJobStatus } from '@prisma/client';

@Injectable()
abstract class BaseQueueEventsListener extends QueueEventsHost {
  protected abstract readonly logger: Logger;
  protected abstract readonly queueName: string;
  protected abstract readonly dlqQueueName: string;

  constructor(protected readonly queueService: QueueService) {
    super();
  }

  @OnQueueEvent('failed')
  async onJobFailed({ jobId, failedReason }: { jobId: string; failedReason: string }) {
    this.logger.warn(`Job ${jobId} failed in queue ${this.queueName}. Reason: ${failedReason}`);

    try {
      const queue = this.queueService.getQueue(this.queueName);
      const job = await queue.getJob(jobId);

      if (!job) {
        this.logger.error(`Job ${jobId} not found in queue ${this.queueName} to evaluate retry count.`);
        return;
      }

      const attemptsMade = job.attemptsMade;
      const maxAttempts = job.opts.attempts || 1;

      this.logger.log(`Job ${jobId} attempts made: ${attemptsMade}/${maxAttempts}`);

      if (attemptsMade >= maxAttempts) {
        this.logger.error(`Job ${jobId} retries exhausted (${attemptsMade}/${maxAttempts}). Routing to DLQ: ${this.dlqQueueName}`);
        
        // 1. Update status to DLQ in DB
        await this.queueService.updateJobStatus(this.queueName, jobId, QueueJobStatus.DLQ, attemptsMade);
        
        // 2. Add to DLQ BullMQ Queue
        const dlqQueue = this.queueService.getQueue(this.dlqQueueName);
        await dlqQueue.add(jobId, job.data, { jobId });
      } else {
        // Just update attempts count in DB
        await this.queueService.updateJobStatus(this.queueName, jobId, QueueJobStatus.ACTIVE, attemptsMade);
      }
    } catch (err) {
      this.logger.error(`Failed to handle failure routing for job ${jobId}: ${err.message}`);
    }
  }

  @OnQueueEvent('completed')
  async onJobCompleted({ jobId }: { jobId: string }) {
    this.logger.log(`Job ${jobId} successfully completed in queue ${this.queueName}`);
    try {
      await this.queueService.updateJobStatus(this.queueName, jobId, QueueJobStatus.COMPLETED);
    } catch (err) {
      this.logger.error(`Failed to update DB completion for job ${jobId}: ${err.message}`);
    }
  }
}

@Injectable()
@QueueEventsListener(Queues.SIGNAL_PROCESSING)
export class SignalQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(SignalQueueEventsListener.name);
  protected readonly queueName = Queues.SIGNAL_PROCESSING;
  protected readonly dlqQueueName = Queues.SIGNAL_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.ORDER_PLACEMENT)
export class OrderPlacementQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(OrderPlacementQueueEventsListener.name);
  protected readonly queueName = Queues.ORDER_PLACEMENT;
  protected readonly dlqQueueName = Queues.ORDER_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.NOTIFICATION)
export class NotificationQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(NotificationQueueEventsListener.name);
  protected readonly queueName = Queues.NOTIFICATION;
  protected readonly dlqQueueName = Queues.NOTIFICATION_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.ORDER_MONITORING)
export class OrderMonitoringQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(OrderMonitoringQueueEventsListener.name);
  protected readonly queueName = Queues.ORDER_MONITORING;
  protected readonly dlqQueueName = Queues.ORDER_MONITORING_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.OUTBOX_DISPATCHER)
export class OutboxQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(OutboxQueueEventsListener.name);
  protected readonly queueName = Queues.OUTBOX_DISPATCHER;
  protected readonly dlqQueueName = Queues.OUTBOX_DISPATCHER_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.WEBSOCKET)
export class WebsocketQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(WebsocketQueueEventsListener.name);
  protected readonly queueName = Queues.WEBSOCKET;
  protected readonly dlqQueueName = Queues.WEBSOCKET_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.REPORT_GENERATION)
export class ReportGenerationQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(ReportGenerationQueueEventsListener.name);
  protected readonly queueName = Queues.REPORT_GENERATION;
  protected readonly dlqQueueName = Queues.REPORT_GENERATION_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.REPORT_EXPORT)
export class ReportExportQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(ReportExportQueueEventsListener.name);
  protected readonly queueName = Queues.REPORT_EXPORT;
  protected readonly dlqQueueName = Queues.REPORT_EXPORT_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.ANALYTICS_SNAPSHOT)
export class AnalyticsSnapshotQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(AnalyticsSnapshotQueueEventsListener.name);
  protected readonly queueName = Queues.ANALYTICS_SNAPSHOT;
  protected readonly dlqQueueName = Queues.ANALYTICS_SNAPSHOT_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.POSITION_REBUILD)
export class PositionRebuildQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(PositionRebuildQueueEventsListener.name);
  protected readonly queueName = Queues.POSITION_REBUILD;
  protected readonly dlqQueueName = Queues.POSITION_REBUILD_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.RECONCILIATION)
export class ReconciliationQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(ReconciliationQueueEventsListener.name);
  protected readonly queueName = Queues.RECONCILIATION;
  protected readonly dlqQueueName = Queues.RECONCILIATION_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.RISK_RECALCULATE)
export class RiskRecalculateQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(RiskRecalculateQueueEventsListener.name);
  protected readonly queueName = Queues.RISK_RECALCULATE;
  protected readonly dlqQueueName = Queues.RISK_RECALCULATE_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.ANALYTICS_RECALCULATE)
export class AnalyticsRecalculateQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(AnalyticsRecalculateQueueEventsListener.name);
  protected readonly queueName = Queues.ANALYTICS_RECALCULATE;
  protected readonly dlqQueueName = Queues.ANALYTICS_RECALCULATE_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.EMAIL)
export class EmailQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(EmailQueueEventsListener.name);
  protected readonly queueName = Queues.EMAIL;
  protected readonly dlqQueueName = Queues.EMAIL_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.SMS)
export class SmsQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(SmsQueueEventsListener.name);
  protected readonly queueName = Queues.SMS;
  protected readonly dlqQueueName = Queues.SMS_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.WHATSAPP)
export class WhatsAppQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(WhatsAppQueueEventsListener.name);
  protected readonly queueName = Queues.WHATSAPP;
  protected readonly dlqQueueName = Queues.WHATSAPP_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

@Injectable()
@QueueEventsListener(Queues.PUSH)
export class PushQueueEventsListener extends BaseQueueEventsListener {
  protected readonly logger = new Logger(PushQueueEventsListener.name);
  protected readonly queueName = Queues.PUSH;
  protected readonly dlqQueueName = Queues.PUSH_DLQ;

  constructor(queueService: QueueService) {
    super(queueService);
  }
}

