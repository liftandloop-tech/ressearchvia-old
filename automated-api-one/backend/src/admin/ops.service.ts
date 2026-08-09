import { Injectable, BadRequestException, NotFoundException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { BrokerSessionService } from '../brokers/services/broker-session.service';
import { BrokerFactory } from '../brokers/factory/broker.factory';
import { BrokerType } from '../brokers/interfaces/broker-type.enum';
import { OperationsAction, OperationStatus, TradeStatus, QueueJobStatus, ExportState, ReconciliationIssueStatus, ReconciliationIssueType, Severity, ReconciliationStatus } from '@prisma/client';
import { Queues } from '../infrastructure/queues/queue.constants';
import { Cron } from '@nestjs/schedule';
import { ReconciliationService } from '../reconciliation/reconciliation.service';
import * as crypto from 'crypto';


import { AlertingService } from '../notifications/alerting.service';

@Injectable()
export class OpsService {
  private readonly logger = new Logger(OpsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
    private readonly brokerSessionService: BrokerSessionService,
    private readonly reconciliationService: ReconciliationService,
    private readonly alertingService: AlertingService,
    private readonly brokerFactory: BrokerFactory,
  ) {}

  private async runOperation(
    operatorId: string,
    action: OperationsAction,
    resourceType: string,
    resourceId: string,
    metadata: any,
    handler: (operationId: string) => Promise<any>,
  ): Promise<{ operationId: string }> {
    const operationId = crypto.randomUUID();
    this.metrics.incrementOperationsRequests(action);

    // Idempotency check: ops:idempotency:{action}:{resourceId} (60s TTL)
    const idempotencyKey = `ops:idempotency:${action}:${resourceId}`;
    if (this.redisService.isHealthy()) {
      const acquired = await this.redisService.getClient().set(
        idempotencyKey,
        '1',
        'EX',
        60,
        'NX',
      );
      if (acquired !== 'OK') {
        this.metrics.incrementOperationsRejected(action);
        throw new BadRequestException(
          `Operation ${action} on resource ${resourceId} is already being processed. Try again in 60 seconds.`,
        );
      }
    }

    // Create initial audit record
    let audit: any = null;
    try {
      audit = await this.prisma.operationsAudit.create({
        data: {
          operationId,
          operatorId,
          action,
          status: OperationStatus.SUCCESS, // updated on fail/reject
          resourceType,
          resourceId,
          metadata: metadata || {},
        },
      });
      this.metrics.incrementOperationsAuditRecords();
    } catch (auditErr: any) {
      this.logger.error(`Failed to create operations audit record: ${auditErr.message || auditErr}`);
      this.metrics.incrementOperationsAuditFailures();
    }

    try {
      await handler(operationId);
      this.metrics.incrementOperationsSuccess(action);
      return { operationId };
    } catch (err: any) {
      // Clear idempotency key on failure/reject to allow fast retry
      if (this.redisService.isHealthy()) {
        try {
          await this.redisService.getClient().del(idempotencyKey);
        } catch (redisErr: any) {
          this.logger.warn(`Failed to clear idempotency key ${idempotencyKey} from Redis: ${redisErr.message || redisErr}`);
        }
      }

      const isRejected = err instanceof BadRequestException;
      const status = isRejected ? OperationStatus.REJECTED : OperationStatus.FAILED;

      if (audit) {
        try {
          await this.prisma.operationsAudit.update({
            where: { id: audit.id },
            data: {
              status,
              errorMessage: err.message || String(err),
            },
          });
          this.metrics.incrementOperationsAuditRecords();
        } catch (auditErr: any) {
          this.logger.error(`Failed to update operations audit record: ${auditErr.message || auditErr}`);
          this.metrics.incrementOperationsAuditFailures();
        }
      } else {
        this.metrics.incrementOperationsAuditFailures();
      }

      if (isRejected) {
        this.metrics.incrementOperationsRejected(action);
      } else {
        this.metrics.incrementOperationsFailed(action);
      }
      throw err;
    }
  }

  @Cron('0 0 3 * * *', { name: 'ops-audit-cleanup', timeZone: 'Asia/Kolkata' })
  async cleanupOperationsAudit() {
    if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
      return;
    }
    this.logger.log('Running OperationsAudit cleanup task...');
    const retentionDate = new Date();
    retentionDate.setDate(retentionDate.getDate() - 180);

    try {
      const { count } = await this.prisma.operationsAudit.deleteMany({
        where: {
          createdAt: {
            lt: retentionDate,
          },
        },
      });
      this.logger.log(`OperationsAudit cleanup complete. Removed ${count} records older than 180 days.`);
    } catch (err: any) {
      this.logger.error(`Failed to clean up OperationsAudit records: ${err.message || err}`);
    }
  }


  async replaySignal(operatorId: string, signalId: string): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.REPLAY_SIGNAL,
      'Signal',
      signalId,
      {},
      async (operationId) => {
        const signal = await this.prisma.signal.findUnique({
          where: { id: signalId },
        });

        if (!signal) {
          throw new NotFoundException(`Signal ${signalId} not found`);
        }

        const metadata = (signal.metadata as any) || {};
        const replayCount = metadata.replayCount || 0;
        if (replayCount >= 5) {
          throw new BadRequestException(`Signal ${signalId} has exceeded the maximum replay limit of 5`);
        }
        metadata.replayCount = replayCount + 1;
        await this.prisma.signal.update({
          where: { id: signalId },
          data: { metadata },
        });

        const segment = await this.prisma.segmentMaster.findUnique({
          where: { id: signal.segmentId },
        });

        if (!segment) {
          throw new BadRequestException(`Segment ${signal.segmentId} not found`);
        }

        if (this.redisService.isHealthy()) {
          const lockKey = `lock:segment:${signal.segmentId}`;
          const isLocked = await this.redisService.getClient().exists(lockKey);
          if (isLocked === 1) {
            throw new BadRequestException(`Segment ${signal.segmentId} is currently locked`);
          }
        }

        const activeExec = await this.prisma.segmentExecution.findFirst({
          where: {
            signalId,
            state: 'PROCESSING',
          },
        });

        if (activeExec) {
          throw new BadRequestException('Signal is currently processing');
        }

        // Re-enqueue using unique job ID
        const jobId = `signal-${signalId}-${operationId}`;
        await this.queueService.addJob(
          Queues.SIGNAL_PROCESSING,
          jobId,
          { signalId },
        );
      },
    );
  }

  async replayOutboxEvent(operatorId: string, eventId: string): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.REPLAY_OUTBOX,
      'OutboxEvent',
      eventId,
      {},
      async (operationId) => {
        const original = await this.prisma.outboxEvent.findUnique({
          where: { id: eventId },
        });

        if (!original) {
          throw new NotFoundException(`OutboxEvent ${eventId} not found`);
        }

        // Clone row as immutable history strategy
        const newEvent = await this.prisma.outboxEvent.create({
          data: {
            eventType: original.eventType,
            eventKey: original.eventKey ? `${original.eventKey}:replay:${operationId}` : null,
            aggregateId: original.aggregateId,
            version: original.version,
            correlationId: original.correlationId,
            payload: original.payload || {},
            status: 'PENDING',
            attempts: 0,
          },
        });

        await this.queueService.addJob(
          Queues.OUTBOX_DISPATCHER,
          newEvent.id,
          { outboxEventId: newEvent.id },
        );
      },
    );
  }

  async getDlqMetrics(operatorId: string): Promise<any> {
    return this.queueService.getDlqMetrics();
  }

  async getDlqJobs(operatorId: string, queueName: string): Promise<any[]> {
    const q = this.queueService.getQueue(queueName);
    if (!q) {
      throw new BadRequestException(`Queue ${queueName} not found`);
    }
    const jobs = await q.getJobs(['waiting', 'active', 'failed', 'completed']);
    return jobs.map((j) => ({
      id: j.id,
      name: j.name,
      data: j.data,
      attemptsMade: j.attemptsMade,
      failedReason: j.failedReason,
    }));
  }

  async replayDlqJob(
    operatorId: string,
    queueName: string,
    jobId: string,
  ): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.DLQ_REPLAY,
      'DLQJob',
      `${queueName}:${jobId}`,
      { queueName, jobId },
      async () => {
        const dlqQueue = this.queueService.getQueue(queueName);
        if (!dlqQueue) {
          throw new BadRequestException(`Queue ${queueName} not found`);
        }

        const job = await dlqQueue.getJob(jobId);
        if (!job) {
          throw new NotFoundException(`Job ${jobId} not found in DLQ ${queueName}`);
        }

        const jobData = job.data || {};
        const replayCount = jobData.replayCount || 0;

        if (replayCount >= 3) {
          throw new BadRequestException(
            `Job ${jobId} in queue ${queueName} has exceeded the maximum replay attempts limit of 3.`,
          );
        }

        // Increment replay count
        const updatedData = {
          ...jobData,
          replayCount: replayCount + 1,
        };

        // Map DLQ to Parent Queue Name
        const parentQueue = queueName.replace('-dlq', '');
        await this.queueService.addJob(parentQueue, job.id!, updatedData);
        await job.remove();

        this.metrics.incrementDlqReplayed(parentQueue);
      },
    );
  }

  async deleteDlqJob(
    operatorId: string,
    queueName: string,
    jobId: string,
  ): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.DLQ_DELETE,
      'DLQJob',
      `${queueName}:${jobId}`,
      { queueName, jobId },
      async () => {
        const dlqQueue = this.queueService.getQueue(queueName);
        if (!dlqQueue) {
          throw new BadRequestException(`Queue ${queueName} not found`);
        }

        const job = await dlqQueue.getJob(jobId);
        if (!job) {
          throw new NotFoundException(`Job ${jobId} not found in DLQ ${queueName}`);
        }

        await job.remove();
        const parentQueue = queueName.replace('-dlq', '');
        this.metrics.incrementDlqPurged(parentQueue);
      },
    );
  }

  private isMarketHours(): boolean {
    const now = new Date();
    // Convert to Indian Standard Time (GMT+5:30)
    const utc = now.getTime() + now.getTimezoneOffset() * 60000;
    const ist = new Date(utc + 3600000 * 5.5);

    const day = ist.getDay(); // 0 = Sunday, 6 = Saturday
    if (day === 0 || day === 6) return false;

    const hours = ist.getHours();
    const minutes = ist.getMinutes();
    const timeNum = hours * 100 + minutes;

    // Market hours: 09:15 to 15:30 (915 to 1530)
    return timeNum >= 915 && timeNum <= 1530;
  }

  async pauseQueue(
    operatorId: string,
    queueName: string,
    force: boolean,
    reason?: string,
  ): Promise<{ operationId: string }> {
    const defaultReason = reason || 'Manual SRE operation';
    return this.runOperation(
      operatorId,
      OperationsAction.QUEUE_PAUSE,
      'Queue',
      queueName,
      {
        queue: queueName,
        reason: defaultReason,
        operatorId,
        timestamp: new Date().toISOString(),
      },
      async () => {
        const isOrderQueue =
          queueName === Queues.ORDER_PLACEMENT || queueName === Queues.ORDER_MONITORING;

        if (isOrderQueue && this.isMarketHours() && !force) {
          throw new BadRequestException(
            `Cannot pause ${queueName} queue during market hours without force=true`,
          );
        }

        const q = this.queueService.getQueue(queueName);
        if (!q) {
          throw new BadRequestException(`Queue ${queueName} not found`);
        }

        await q.pause();
        this.metrics.incrementQueuePausedTotal(queueName);
      },
    );
  }

  async resumeQueue(
    operatorId: string,
    queueName: string,
    reason?: string,
  ): Promise<{ operationId: string }> {
    const defaultReason = reason || 'Manual SRE operation';
    return this.runOperation(
      operatorId,
      OperationsAction.QUEUE_RESUME,
      'Queue',
      queueName,
      {
        queue: queueName,
        reason: defaultReason,
        operatorId,
        timestamp: new Date().toISOString(),
      },
      async () => {
        const q = this.queueService.getQueue(queueName);
        if (!q) {
          throw new BadRequestException(`Queue ${queueName} not found`);
        }
        await q.resume();
      },
    );
  }

  async drainQueue(
    operatorId: string,
    queueName: string,
    reason: string,
  ): Promise<{ operationId: string }> {
    if (!reason) {
      throw new BadRequestException('A reason is mandatory for draining a queue');
    }

    let drainedJobsCount = 0;

    return this.runOperation(
      operatorId,
      OperationsAction.QUEUE_DRAIN,
      'Queue',
      queueName,
      {
        reason,
        queue: queueName,
        drainedJobs: 0,
      },
      async (operationId) => {
        const q = this.queueService.getQueue(queueName);
        if (!q) {
          throw new BadRequestException(`Queue ${queueName} not found`);
        }

        const jobs = await this.prisma.queueJob.findMany({
          where: { queueName, status: QueueJobStatus.ACTIVE },
        });
        drainedJobsCount = jobs.length;

        await q.drain();

        await this.prisma.queueJob.updateMany({
          where: { queueName, status: QueueJobStatus.ACTIVE },
          data: { status: QueueJobStatus.CANCELLED, updatedAt: new Date() },
        });

        await this.prisma.operationsAudit.update({
          where: { operationId },
          data: {
            metadata: {
              reason,
              queue: queueName,
              drainedJobs: drainedJobsCount,
            },
          },
        });
      },
    );
  }

  async unlockSegment(operatorId: string, segmentId: string): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.SEGMENT_UNLOCK,
      'Segment',
      segmentId,
      {},
      async () => {
        const activeExec = await this.prisma.segmentExecution.findFirst({
          where: {
            segmentId,
            state: 'PROCESSING',
          },
        });

        if (activeExec) {
          throw new BadRequestException(
            'Cannot unlock segment with an active processing execution',
          );
        }

        if (this.redisService.isHealthy()) {
          const lockKey = `lock:segment:${segmentId}`;
          await this.redisService.getClient().del(lockKey);
        }
      },
    );
  }

  async forceBrokerSessionRefresh(
    operatorId: string,
    userBrokerId: string,
  ): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.BROKER_REFRESH,
      'UserBroker',
      userBrokerId,
      {},
      async () => {
        const userBroker = await this.prisma.userBroker.findUnique({
          where: { id: userBrokerId },
          include: { broker: true },
        });

        if (!userBroker) {
          throw new NotFoundException(`UserBroker ${userBrokerId} not found`);
        }

        if (this.redisService.isHealthy()) {
          const rateLimitKey = `ops:broker-refresh:${userBrokerId}`;
          const isRateLimited = await this.redisService.getClient().exists(rateLimitKey);
          if (isRateLimited === 1) {
            throw new BadRequestException(
              `Rate limit exceeded: session refresh for broker connection ${userBrokerId} is restricted to once per 60 seconds.`,
            );
          }
          await this.redisService.getClient().set(rateLimitKey, '1', 'EX', 60);
        }

        if (this.redisService.isHealthy()) {
          const sessionKey = `broker:session:${userBroker.userId}:${userBroker.brokerId}`;
          await this.redisService.getClient().del(sessionKey);
        }

        await this.brokerSessionService.refreshSession(userBroker.userId, userBroker.broker.code);
      },
    );
  }

  async rebuildPositions(operatorId: string, userId?: string): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.POSITION_REBUILD,
      'PositionCache',
      userId || 'ALL',
      { userId },
      async (operationId) => {
        await this.queueService.addJob(
          Queues.POSITION_REBUILD,
          `rebuild:${userId || 'all'}:${operationId}`,
          { userId },
        );
      },
    );
  }

  async enableMaintenance(operatorId: string, type: string): Promise<{ operationId: string }> {
    const validTypes = ['global', 'signals', 'subscriptions', 'reports'];
    if (!validTypes.includes(type)) {
      throw new BadRequestException(`Invalid maintenance type: ${type}`);
    }

    return this.runOperation(
      operatorId,
      OperationsAction.MAINTENANCE_ENABLE,
      'System',
      type.toUpperCase(),
      { type },
      async () => {
        if (this.redisService.isHealthy()) {
          const redisKey = `system:maintenance:${type}`;
          await this.redisService.getClient().set(redisKey, 'true');
        } else {
          throw new BadRequestException('Redis is not available');
        }
      },
    );
  }

  async disableMaintenance(operatorId: string, type: string): Promise<{ operationId: string }> {
    const validTypes = ['global', 'signals', 'subscriptions', 'reports'];
    if (!validTypes.includes(type)) {
      throw new BadRequestException(`Invalid maintenance type: ${type}`);
    }

    return this.runOperation(
      operatorId,
      OperationsAction.MAINTENANCE_DISABLE,
      'System',
      type.toUpperCase(),
      { type },
      async () => {
        if (this.redisService.isHealthy()) {
          const redisKey = `system:maintenance:${type}`;
          await this.redisService.getClient().del(redisKey);
        } else {
          throw new BadRequestException('Redis is not available');
        }
      },
    );
  }

  async stopTrading(
    operatorId: string,
    permanent?: boolean,
    reason?: string,
  ): Promise<{ operationId: string }> {
    const defaultReason = reason || 'Emergency emergency market event';
    const expiresAt = permanent ? 'never' : new Date(Date.now() + 900 * 1000).toISOString();
    const payload = JSON.stringify({
      enabled: true,
      reason: defaultReason,
      operatorId,
      expiresAt,
    });

    return this.runOperation(
      operatorId,
      OperationsAction.TRADING_STOP,
      'TradingEngine',
      'GLOBAL',
      { permanent, reason: defaultReason, expiresAt },
      async () => {
        if (this.redisService.isHealthy()) {
          if (permanent) {
            await this.redisService.getClient().set('trading:global:disabled', payload);
          } else {
            await this.redisService.getClient().set('trading:global:disabled', payload, 'EX', 900);
          }
        } else {
          throw new BadRequestException('Redis is not available');
        }
      },
    );
  }

  async startTrading(operatorId: string): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.TRADING_START,
      'TradingEngine',
      'GLOBAL',
      {},
      async () => {
        if (this.redisService.isHealthy()) {
          await this.redisService.getClient().del('trading:global:disabled');
        } else {
          throw new BadRequestException('Redis is not available');
        }
      },
    );
  }

  async exportAuditLogs(operatorId: string): Promise<{ exportId: string }> {
    const exportRecord = await this.prisma.reportExport.create({
      data: {
        userId: null,
        exportType: 'AUDIT',
        status: ExportState.REQUESTED,
      },
    });

    await this.queueService.addJob(
      Queues.REPORT_EXPORT,
      exportRecord.id,
      {
        exportId: exportRecord.id,
        userId: null,
        type: 'AUDIT',
        period: '',
      },
      5,
    );

    return { exportId: exportRecord.id };
  }

  async getAudits(
    operatorId: string,
    query: {
      action?: string;
      operatorId?: string;
      status?: string;
      from?: string;
      page?: number;
      limit?: number;
    },
  ): Promise<any> {
    const page = query.page || 1;
    const limit = Math.min(query.limit || 50, 100);
    const where: any = {
      ...(query.action ? { action: query.action as OperationsAction } : {}),
      ...(query.operatorId ? { operatorId: query.operatorId } : {}),
      ...(query.status ? { status: query.status as OperationStatus } : {}),
      ...(query.from && !isNaN(Date.parse(query.from)) ? { createdAt: { gte: new Date(query.from) } } : {}),
    };

    return this.prisma.operationsAudit.paginate({
      page,
      limit,
      where,
      orderBy: { createdAt: 'desc' },
    });
  }

  async getReconciliationRuns(): Promise<any[]> {
    return this.prisma.reconciliationRun.findMany({
      orderBy: { startedAt: 'desc' },
      include: { shards: true },
    });
  }

  async getReconciliationIssues(resolved?: boolean): Promise<any[]> {
    return this.prisma.reconciliationIssue.findMany({
      where: resolved !== undefined
        ? { status: resolved ? ReconciliationIssueStatus.RESOLVED : { not: ReconciliationIssueStatus.RESOLVED } }
        : undefined,
      orderBy: { createdAt: 'desc' },
      include: { user: true, broker: true },
    });
  }

  async getReconciliationIssuesSummary(): Promise<any> {
    const openCount = await this.prisma.reconciliationIssue.count({
      where: { status: ReconciliationIssueStatus.OPEN },
    });
    const criticalCount = await this.prisma.reconciliationIssue.count({
      where: { severity: Severity.CRITICAL, status: { not: ReconciliationIssueStatus.RESOLVED } },
    });
    const warningCount = await this.prisma.reconciliationIssue.count({
      where: { severity: Severity.WARNING, status: { not: ReconciliationIssueStatus.RESOLVED } },
    });
    const escalatedCount = await this.prisma.reconciliationIssue.count({
      where: { status: ReconciliationIssueStatus.ESCALATED },
    });

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const resolvedTodayCount = await this.prisma.reconciliationIssue.count({
      where: {
        status: ReconciliationIssueStatus.RESOLVED,
        createdAt: { gte: startOfToday }, // or lastSeenAt/updatedAt
      },
    });

    return {
      open: openCount,
      critical: criticalCount,
      warning: warningCount,
      escalated: escalatedCount,
      resolvedToday: resolvedTodayCount,
    };
  }

  async resolveReconciliationIssue(operatorId: string, issueId: string): Promise<any> {
    return this.runOperation(
      operatorId,
      OperationsAction.RECONCILIATION_RESOLVE,
      'ReconciliationIssue',
      issueId,
      { manualResolution: true },
      async () => {
        const issue = await this.prisma.reconciliationIssue.findUnique({
          where: { id: issueId },
        });

        if (!issue) {
          throw new NotFoundException(`Reconciliation issue ${issueId} not found`);
        }

        const updatedIssue = await this.prisma.reconciliationIssue.update({
          where: { id: issueId },
          data: { status: ReconciliationIssueStatus.RESOLVED },
        });

        // Trigger snapshot update
        const openIssues = await this.prisma.reconciliationIssue.count({
          where: {
            userId: issue.userId,
            brokerId: issue.brokerId,
            status: { in: [ReconciliationIssueStatus.OPEN, ReconciliationIssueStatus.INVESTIGATING, ReconciliationIssueStatus.ESCALATED] },
          },
        });

        await this.prisma.reconciliationSnapshot.upsert({
          where: { userId_brokerId: { userId: issue.userId, brokerId: issue.brokerId } },
          update: { openIssues },
          create: { userId: issue.userId, brokerId: issue.brokerId, openIssues, lastReconciledAt: new Date() },
        });

        // Invalidate portfolio analytics cache on reconciliation resolution
        if (this.redisService.isHealthy()) {
          const keys = [
            `analytics:user:${issue.userId}:portfolio`,
            `analytics:user:${issue.userId}:segments`,
            `analytics:user:${issue.userId}:broker-stats`,
          ];
          for (const key of keys) {
            await this.redisService.getClient().del(key);
          }
        }

        return updatedIssue;
      },
    );
  }

  async escalateReconciliationIssue(operatorId: string, issueId: string): Promise<any> {
    return this.runOperation(
      operatorId,
      OperationsAction.RECONCILIATION_RESOLVE, // mapped under resolve action workflow
      'ReconciliationIssue',
      issueId,
      { manualEscalation: true },
      async () => {
        const issue = await this.prisma.reconciliationIssue.findUnique({
          where: { id: issueId },
        });

        if (!issue) {
          throw new NotFoundException(`Reconciliation issue ${issueId} not found`);
        }

        const updatedIssue = await this.prisma.reconciliationIssue.update({
          where: { id: issueId },
          data: { status: ReconciliationIssueStatus.ESCALATED },
        });

        // Trigger outbox event & SRE Alert notification
        await this.prisma.outboxEvent.create({
          data: {
            eventType: 'RECONCILIATION_ISSUE',
            payload: {
              issueId,
              userId: issue.userId,
              brokerId: issue.brokerId,
              issueType: issue.issueType,
              severity: issue.severity,
              resourceId: issue.resourceId,
              status: ReconciliationIssueStatus.ESCALATED,
            },
          },
        });

        return updatedIssue;
      },
    );
  }

  async triggerReconciliationRun(operatorId: string): Promise<any> {
    return this.runOperation(
      operatorId,
      OperationsAction.RECONCILIATION_RUN,
      'System',
      'global',
      {},
      async () => {
        const runId = await this.reconciliationService.triggerReconciliation(operatorId);
        return { runId };
      },
    );
  }

  async recalculateRiskSnapshot(operatorId: string, userId: string): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.RISK_RECALCULATE,
      'RiskSnapshot',
      userId,
      { userId },
      async (operationId) => {
        const jobId = `risk-recalc-${userId}-manual-${operationId}`;
        await this.queueService.addJob(
          Queues.RISK_RECALCULATE,
          jobId,
          { userId },
        );
      },
    );
  }

  async unblockUserRisk(operatorId: string, userId: string): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.RISK_UNBLOCK,
      'UserRiskLock',
      userId,
      { userId },
      async () => {
        if (this.redisService.isHealthy()) {
          await this.redisService.getClient().del(`user:risk:blocked:${userId}`);
        }

        // Update risk snapshot to HEALTHY
        await this.prisma.riskSnapshot.updateMany({
          where: { userId },
          data: {
            state: 'HEALTHY',
            lastRecalculationStatus: 'MANUALLY_UNBLOCKED',
            lastRecalculatedAt: new Date(),
          },
        });

        // Create a risk event for audit
        await this.prisma.riskEvent.create({
          data: {
            userId,
            segmentId: '',
            eventType: 'RISK_UNBLOCKED_MANUAL',
            message: `User risk manually unblocked by operator ${operatorId}`,
          },
        });
      },
    );
  }

  async toggleGlobalEmergencyLock(
    operatorId: string,
    blocked: boolean,
    reason?: string,
  ): Promise<{ operationId: string }> {
    return this.runOperation(
      operatorId,
      OperationsAction.RISK_GLOBAL_LOCK,
      'GlobalRiskLock',
      'GLOBAL',
      { blocked, reason },
      async () => {
        if (!this.redisService.isHealthy()) {
          throw new BadRequestException('Redis is not available');
        }
        if (blocked) {
          await this.redisService.getClient().set('risk:global:blocked', 'true');
          this.logger.warn(`Global emergency risk lock activated by operator ${operatorId}. Reason: ${reason}`);
        } else {
          await this.redisService.getClient().del('risk:global:blocked');
          this.logger.warn(`Global emergency risk lock deactivated by operator ${operatorId}`);
        }
      },
    );
  }

  async acknowledgeAlert(operatorId: string, alertId: string): Promise<any> {
    return this.alertingService.acknowledgeAlert(alertId);
  }

  async resolveAlert(operatorId: string, alertId: string): Promise<any> {
    return this.alertingService.resolveAlert(alertId);
  }

  async getUserLiveBrokerData(userIdOrCode: string) {
    const userBroker = await this.prisma.userBroker.findFirst({
      where: {
        OR: [
          { userId: userIdOrCode },
          { brokerClientId: userIdOrCode },
          { user: { email: userIdOrCode } },
        ],
      },
      include: { broker: true, user: true },
    });

    if (!userBroker) {
      throw new NotFoundException(`No linked broker connection found for '${userIdOrCode}'`);
    }

    const isSessionActive = await this.brokerSessionService.validateSession(
      userBroker.userId,
      userBroker.broker.code,
    );

    if (!isSessionActive || !userBroker.accessToken) {
      return {
        user: {
          id: userBroker.user.id,
          name: userBroker.user.name,
          email: userBroker.user.email,
        },
        brokerCode: userBroker.broker.code,
        brokerClientId: userBroker.brokerClientId,
        isSessionActive: false,
        positions: [],
        holdings: [],
        orders: [],
        trades: [],
      };
    }

    const brokerType = userBroker.broker.code as unknown as BrokerType;
    const adapter = this.brokerFactory.getAdapter(brokerType);

    const [positions, holdings, orders, trades] = await Promise.all([
      adapter.getPositions(userBroker.accessToken, userBroker.brokerClientId).catch(() => []),
      adapter.getHoldings(userBroker.accessToken, userBroker.brokerClientId).catch(() => []),
      adapter.getOrders(userBroker.accessToken, userBroker.brokerClientId).catch(() => []),
      adapter.getTradeBook(userBroker.accessToken, userBroker.brokerClientId).catch(() => []),
    ]);

    return {
      user: {
        id: userBroker.user.id,
        name: userBroker.user.name,
        email: userBroker.user.email,
      },
      brokerCode: userBroker.broker.code,
      brokerClientId: userBroker.brokerClientId,
      isSessionActive: true,
      positions,
      holdings,
      orders,
      trades,
    };
  }
}

