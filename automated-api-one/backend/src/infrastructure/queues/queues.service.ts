import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue, FlowProducer } from 'bullmq';
import { PrismaService } from '../../prisma.service';
import { RedisService } from '../redis/redis.service';
import { Queues } from './queue.constants';
import { QueueJobStatus } from '@prisma/client';

const QUEUE_LIMITS: Record<string, number> = {
  [Queues.ORDER_PLACEMENT]: 50000,
  [Queues.ORDER_MONITORING]: 100000,
  [Queues.NOTIFICATION]: 250000,
};

@Injectable()
export class QueueService {
  private readonly logger = new Logger(QueueService.name);
  private readonly flowProducer: FlowProducer;
  private readonly shardedSnapshotQueues = new Map<string, Queue>();

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    @InjectQueue(Queues.SIGNAL_PROCESSING) private readonly signalQueue: Queue,
    @InjectQueue(Queues.ORDER_PLACEMENT) private readonly orderPlacementQueue: Queue,
    @InjectQueue(Queues.ORDER_MONITORING) private readonly orderMonitoringQueue: Queue,
    @InjectQueue(Queues.NOTIFICATION) private readonly notificationQueue: Queue,
    @InjectQueue(Queues.SIGNAL_DLQ) private readonly signalDlq: Queue,
    @InjectQueue(Queues.ORDER_DLQ) private readonly orderDlq: Queue,
    @InjectQueue(Queues.ORDER_MONITORING_DLQ) private readonly orderMonitoringDlq: Queue,
    @InjectQueue(Queues.NOTIFICATION_DLQ) private readonly notificationDlq: Queue,
    @InjectQueue(Queues.OUTBOX_DISPATCHER) private readonly outboxDispatcherQueue: Queue,
    @InjectQueue(Queues.OUTBOX_DISPATCHER_DLQ) private readonly outboxDispatcherDlq: Queue,
    @InjectQueue(Queues.WEBSOCKET) private readonly websocketQueue: Queue,
    @InjectQueue(Queues.WEBSOCKET_DLQ) private readonly websocketDlq: Queue,
    @InjectQueue(Queues.REPORT_GENERATION) private readonly reportGenerationQueue: Queue,
    @InjectQueue(Queues.REPORT_GENERATION_DLQ) private readonly reportGenerationDlq: Queue,
    @InjectQueue(Queues.REPORT_EXPORT) private readonly reportExportQueue: Queue,
    @InjectQueue(Queues.REPORT_EXPORT_DLQ) private readonly reportExportDlq: Queue,
    @InjectQueue(Queues.ANALYTICS_SNAPSHOT) private readonly analyticsSnapshotQueue: Queue,
    @InjectQueue(Queues.ANALYTICS_SNAPSHOT_DLQ) private readonly analyticsSnapshotDlq: Queue,
    @InjectQueue(Queues.POSITION_REBUILD) private readonly positionRebuildQueue: Queue,
    @InjectQueue(Queues.POSITION_REBUILD_DLQ) private readonly positionRebuildDlq: Queue,
    @InjectQueue(Queues.RECONCILIATION) private readonly reconciliationQueue: Queue,
    @InjectQueue(Queues.RECONCILIATION_DLQ) private readonly reconciliationDlq: Queue,
    @InjectQueue(Queues.RISK_RECALCULATE) private readonly riskRecalculateQueue: Queue,
    @InjectQueue(Queues.RISK_RECALCULATE_DLQ) private readonly riskRecalculateDlq: Queue,
    @InjectQueue(Queues.ANALYTICS_RECALCULATE) private readonly analyticsRecalculateQueue: Queue,
    @InjectQueue(Queues.ANALYTICS_RECALCULATE_DLQ) private readonly analyticsRecalculateDlq: Queue,
    @InjectQueue(Queues.EMAIL) private readonly emailQueue: Queue,
    @InjectQueue(Queues.EMAIL_DLQ) private readonly emailDlq: Queue,
    @InjectQueue(Queues.SMS) private readonly smsQueue: Queue,
    @InjectQueue(Queues.SMS_DLQ) private readonly smsDlq: Queue,
    @InjectQueue(Queues.WHATSAPP) private readonly whatsappQueue: Queue,
    @InjectQueue(Queues.WHATSAPP_DLQ) private readonly whatsappDlq: Queue,
    @InjectQueue(Queues.PUSH) private readonly pushQueue: Queue,
    @InjectQueue(Queues.PUSH_DLQ) private readonly pushDlq: Queue,
  ) {
    this.flowProducer = new FlowProducer({
      connection: this.redisService.getClient() as any,
    });
  }

  getFlowProducer(): FlowProducer {
    return this.flowProducer;
  }

  getQueue(queueName: string): Queue {
    switch (queueName) {
      case Queues.SIGNAL_PROCESSING:
        return this.signalQueue;
      case Queues.ORDER_PLACEMENT:
        return this.orderPlacementQueue;
      case Queues.ORDER_MONITORING:
        return this.orderMonitoringQueue;
      case Queues.NOTIFICATION:
        return this.notificationQueue;
      case Queues.SIGNAL_DLQ:
        return this.signalDlq;
      case Queues.ORDER_DLQ:
        return this.orderDlq;
      case Queues.ORDER_MONITORING_DLQ:
        return this.orderMonitoringDlq;
      case Queues.NOTIFICATION_DLQ:
        return this.notificationDlq;
      case Queues.OUTBOX_DISPATCHER:
        return this.outboxDispatcherQueue;
      case Queues.OUTBOX_DISPATCHER_DLQ:
        return this.outboxDispatcherDlq;
      case Queues.WEBSOCKET:
        return this.websocketQueue;
      case Queues.WEBSOCKET_DLQ:
        return this.websocketDlq;
      case Queues.REPORT_GENERATION:
        return this.reportGenerationQueue;
      case Queues.REPORT_GENERATION_DLQ:
        return this.reportGenerationDlq;
      case Queues.REPORT_EXPORT:
        return this.reportExportQueue;
      case Queues.REPORT_EXPORT_DLQ:
        return this.reportExportDlq;
      case Queues.ANALYTICS_SNAPSHOT:
        return this.analyticsSnapshotQueue;
      case Queues.ANALYTICS_SNAPSHOT_DLQ:
        return this.analyticsSnapshotDlq;
      case Queues.POSITION_REBUILD:
        return this.positionRebuildQueue;
      case Queues.POSITION_REBUILD_DLQ:
        return this.positionRebuildDlq;
      case Queues.RECONCILIATION:
        return this.reconciliationQueue;
      case Queues.RECONCILIATION_DLQ:
        return this.reconciliationDlq;
      case Queues.RISK_RECALCULATE:
        return this.riskRecalculateQueue;
      case Queues.RISK_RECALCULATE_DLQ:
        return this.riskRecalculateDlq;
      case Queues.ANALYTICS_RECALCULATE:
        return this.analyticsRecalculateQueue;
      case Queues.ANALYTICS_RECALCULATE_DLQ:
        return this.analyticsRecalculateDlq;
      case Queues.EMAIL:
        return this.emailQueue;
      case Queues.EMAIL_DLQ:
        return this.emailDlq;
      case Queues.SMS:
        return this.smsQueue;
      case Queues.SMS_DLQ:
        return this.smsDlq;
      case Queues.WHATSAPP:
        return this.whatsappQueue;
      case Queues.WHATSAPP_DLQ:
        return this.whatsappDlq;
      case Queues.PUSH:
        return this.pushQueue;
      case Queues.PUSH_DLQ:
        return this.pushDlq;
      default:
        if (queueName.startsWith('analytics-snapshot-dlq-')) {
          let q = this.shardedSnapshotQueues.get(queueName);
          if (!q) {
            q = new Queue(queueName, { connection: this.redisService.getClient() as any });
            this.shardedSnapshotQueues.set(queueName, q);
          }
          return q;
        }
        if (queueName.startsWith('analytics-snapshot-')) {
          let q = this.shardedSnapshotQueues.get(queueName);
          if (!q) {
            q = new Queue(queueName, { connection: this.redisService.getClient() as any });
            this.shardedSnapshotQueues.set(queueName, q);
          }
          return q;
        }
        throw new Error(`Queue '${queueName}' not found`);
    }
  }

  /**
   * Enqueues a job into a BullMQ queue and records it in the database.
   */
  async addJob(
    queueName: string,
    jobId: string,
    payload: any,
    priority?: number,
    delay?: number,
  ): Promise<void> {
    this.redisService.assertHealthy();
    const queue = this.getQueue(queueName);

    const limit = QUEUE_LIMITS[queueName];
    if (limit !== undefined) {
      const waiting = await queue.getWaitingCount();
      if (waiting >= limit) {
        this.logger.warn(`Queue '${queueName}' backpressure limit exceeded: waiting=${waiting}, limit=${limit}`);
        throw new ServiceUnavailableException(`Queue '${queueName}' is overloaded`);
      }
    }

    try {
      // 1. Record job in database
      await this.prisma.queueJob.upsert({
        where: {
          queueName_jobId: { queueName, jobId },
        },
        update: {
          payload: payload || {},
          status: QueueJobStatus.ACTIVE,
          attempts: 0,
          updatedAt: new Date(),
        },
        create: {
          queueName,
          jobId,
          payload: payload || {},
          status: QueueJobStatus.ACTIVE,
          attempts: 0,
        },
      });

      // 2. Publish to BullMQ
      await queue.add(jobId, payload, {
        jobId,
        priority,
        delay,
        attempts: 3,
        backoff: {
          type: 'exponential',
          delay: 1000,
        },
      });

      this.logger.log(`Enqueued job ${jobId} to queue ${queueName} (Priority: ${priority || 'none'}, Delay: ${delay || 'none'})`);
    } catch (err) {
      this.logger.error(`Failed to add job ${jobId} to queue ${queueName}: ${err.message}`);
      throw err;
    }
  }

  /**
   * Updates job status and attempts count inside the QueueJob database table.
   */
  async updateJobStatus(
    queueName: string,
    jobId: string,
    status: QueueJobStatus,
    attempts?: number,
  ): Promise<void> {
    try {
      await this.prisma.queueJob.update({
        where: {
          queueName_jobId: { queueName, jobId },
        },
        data: {
          status,
          ...(attempts !== undefined ? { attempts } : {}),
          updatedAt: new Date(),
        },
      });
    } catch (err) {
      this.logger.error(`Failed to update DB status for job ${jobId} in queue ${queueName}: ${err.message}`);
    }
  }

  /**
   * Returns aggregated queue counts across active queues and DLQs.
   */
  async getAggregatedMetrics() {
    let waiting = 0;
    let active = 0;
    let failed = 0;
    let dlq = 0;

    const mainQueues = [
      Queues.SIGNAL_PROCESSING,
      Queues.ORDER_PLACEMENT,
      Queues.ORDER_MONITORING,
      Queues.NOTIFICATION,
      Queues.OUTBOX_DISPATCHER,
      Queues.WEBSOCKET,
      Queues.REPORT_GENERATION,
      Queues.REPORT_EXPORT,
      Queues.POSITION_REBUILD,
      Queues.RECONCILIATION,
      Queues.RISK_RECALCULATE,
      Queues.ANALYTICS_RECALCULATE,
      Queues.EMAIL,
      Queues.SMS,
      Queues.WHATSAPP,
      Queues.PUSH,
      ...Array.from({ length: 10 }, (_, i) => `analytics-snapshot-${i}`),
    ];

    for (const name of mainQueues) {
      try {
        const q = this.getQueue(name);
        waiting += await q.getWaitingCount();
        active += await q.getActiveCount();
        failed += await q.getFailedCount();
      } catch (err) {
        this.logger.warn(`Failed to count metrics for queue ${name}: ${err.message}`);
      }
    }

    const dlqQueues = [
      Queues.SIGNAL_DLQ,
      Queues.ORDER_DLQ,
      Queues.ORDER_MONITORING_DLQ,
      Queues.NOTIFICATION_DLQ,
      Queues.OUTBOX_DISPATCHER_DLQ,
      Queues.WEBSOCKET_DLQ,
      Queues.REPORT_GENERATION_DLQ,
      Queues.REPORT_EXPORT_DLQ,
      Queues.POSITION_REBUILD_DLQ,
      Queues.RECONCILIATION_DLQ,
      Queues.RISK_RECALCULATE_DLQ,
      Queues.ANALYTICS_RECALCULATE_DLQ,
      Queues.EMAIL_DLQ,
      Queues.SMS_DLQ,
      Queues.WHATSAPP_DLQ,
      Queues.PUSH_DLQ,
      ...Array.from({ length: 10 }, (_, i) => `analytics-snapshot-dlq-${i}`),
    ];

    for (const name of dlqQueues) {
      try {
        const q = this.getQueue(name);
        dlq += await q.getJobCountByTypes('waiting', 'active', 'failed', 'completed');
      } catch (err) {
        this.logger.warn(`Failed to count metrics for DLQ ${name}: ${err.message}`);
      }
    }

    return { waiting, active, failed, dlq };
  }

  /**
   * Returns DLQ-specific queue counts.
   */
  async getDlqMetrics() {
    const getCount = async (queue: Queue) => {
      try {
        return await queue.getJobCountByTypes('waiting', 'active', 'failed', 'completed');
      } catch {
        return 0;
      }
    };

    let shardedSnapshotDlqSum = 0;
    for (let i = 0; i < 10; i++) {
      try {
        const q = this.getQueue(`analytics-snapshot-dlq-${i}`);
        shardedSnapshotDlqSum += await getCount(q);
      } catch {}
    }

    const [
      signalDlq,
      orderPlacementDlq,
      orderMonitoringDlq,
      notificationDlq,
      outboxDispatcherDlq,
      websocketDlq,
      reportGenerationDlq,
      reportExportDlq,
      positionRebuildDlq,
      reconciliationDlq,
      riskRecalculateDlq,
      analyticsRecalculateDlq,
      emailDlq,
      smsDlq,
      whatsappDlq,
      pushDlq,
    ] = await Promise.all([
      getCount(this.signalDlq),
      getCount(this.orderDlq),
      getCount(this.orderMonitoringDlq),
      getCount(this.notificationDlq),
      getCount(this.outboxDispatcherDlq),
      getCount(this.websocketDlq),
      getCount(this.reportGenerationDlq),
      getCount(this.reportExportDlq),
      getCount(this.positionRebuildDlq),
      getCount(this.reconciliationDlq),
      getCount(this.riskRecalculateDlq),
      getCount(this.analyticsRecalculateDlq),
      getCount(this.emailDlq),
      getCount(this.smsDlq),
      getCount(this.whatsappDlq),
      getCount(this.pushDlq),
    ]);

    return {
      signalDlq,
      orderPlacementDlq,
      orderMonitoringDlq,
      notificationDlq,
      outboxDispatcherDlq,
      websocketDlq,
      reportGenerationDlq,
      reportExportDlq,
      positionRebuildDlq,
      reconciliationDlq,
      riskRecalculateDlq,
      analyticsRecalculateDlq,
      emailDlq,
      smsDlq,
      whatsappDlq,
      pushDlq,
      analyticsSnapshotDlq: shardedSnapshotDlqSum,
    };
  }
}
