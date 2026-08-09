import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { IdempotencyService } from '../../infrastructure/idempotency/idempotency.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MultiplierService } from './multiplier.service';
import { AuditService } from '../../audit/audit.service';
import { AuditEventType } from '../../audit/enums/audit-event.enum';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { UserExecutionSnapshot } from '../interfaces/user-execution-snapshot.interface';
import { ExecutionContext } from '../interfaces/execution-context.interface';
import { Signal, UserSegmentStatus, SubscriptionStatus, ConsentStatus, BrokerStatus, SignalState } from '@prisma/client';
import pLimit from 'p-limit';
import { randomUUID } from 'crypto';
import axios from 'axios';

const SUPPORTED_PLANS = ['SPARK', 'SPLENDID'] as const;
type PlanType = (typeof SUPPORTED_PLANS)[number];

@Injectable()
export class SignalOrchestratorService {
  private readonly logger = new Logger(SignalOrchestratorService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly queueService: QueueService,
    private readonly idempotencyService: IdempotencyService,
    private readonly redisService: RedisService,
    private readonly multiplierService: MultiplierService,
    private readonly auditService: AuditService,
  ) {}

  /**
   * Primary entry point: processes an incoming signal and fans out order
   * placement jobs to all eligible users subscribed to this segment.
   *
   * Architecture guarantees:
   * - Idempotency key prevents duplicate processing of same signal
   * - Redis health assertion before any queue write
   * - p-limit(50) caps concurrent subscriber processing
   * - Each user gets a deterministic BullMQ job ID (prevents duplicate workers)
   * - Execution state snapshot is captured per user at fan-out time
   */
  private validateTransition(current: SignalState, next: SignalState) {
    const validTransitions: Record<SignalState, SignalState[]> = {
      [SignalState.RECEIVED]: [SignalState.VALIDATED, SignalState.FAILED],
      [SignalState.VALIDATED]: [SignalState.PROCESSING, SignalState.FAILED],
      [SignalState.PROCESSING]: [SignalState.PROCESSING, SignalState.COMPLETED, SignalState.PARTIALLY_COMPLETED, SignalState.FAILED],
      [SignalState.COMPLETED]: [],
      [SignalState.PARTIALLY_COMPLETED]: [],
      [SignalState.FAILED]: [],
    };

    const allowed = validTransitions[current] || [];
    if (!allowed.includes(next)) {
      throw new Error(`Invalid SignalState transition: ${current} -> ${next}`);
    }
  }

  private async updateExecutionState(
    executionId: string,
    nextState: SignalState,
    additionalData: any = {},
  ) {
    const current = await this.prisma.segmentExecution.findUnique({
      where: { id: executionId },
      select: { state: true },
    });
    if (!current) {
      throw new Error(`SegmentExecution ${executionId} not found`);
    }
    this.validateTransition(current.state, nextState);
    return this.prisma.segmentExecution.update({
      where: { id: executionId },
      data: {
        state: nextState,
        ...additionalData,
      },
    });
  }

  /**
   * Primary entry point: processes an incoming signal and fans out order
   * placement jobs to all eligible users subscribed to this segment.
   *
   * Architecture guarantees:
   * - Idempotency key prevents duplicate processing of same signal
   * - Redis health assertion before any queue write
   * - p-limit(50) caps concurrent subscriber processing
   * - Each user gets a deterministic BullMQ job ID (prevents duplicate workers)
   * - Execution state snapshot is captured per user at fan-out time
   */
  async processSignal(signalId: string): Promise<{
    state: SignalState;
    totalUsers: number;
    successUsers: number;
    rejectedUsers: number;
    correlationId: string;
  }> {
    const correlationId = randomUUID();

    this.logger.log(`[${correlationId}] Processing signal ${signalId}`);

    // 1. Assert Redis is healthy — trading engine requires Redis
    this.redisService.assertHealthy();

    // Check global trading kill switch
    const isTradingDisabled = await this.redisService.getClient().get('trading:global:disabled');
    if (isTradingDisabled === 'true') {
      this.logger.warn(`[${correlationId}] Signal processing/fan-out blocked due to global trading kill switch`);
      throw new ServiceUnavailableException('Trading is disabled globally via kill switch');
    }

    // Check global emergency risk lock
    const isGlobalRiskBlocked = await this.redisService.getClient().get('risk:global:blocked');
    if (isGlobalRiskBlocked === 'true') {
      this.logger.warn(`[${correlationId}] Signal processing/fan-out blocked due to global emergency risk lock`);
      throw new ServiceUnavailableException('Trading is disabled globally via global emergency risk lock');
    }

    // 2. Idempotency check — prevent duplicate fan-out for same signal
    const idempotencyKey = `signal:fanout:${signalId}`;
    const isNew = await this.idempotencyService.tryAcquire(idempotencyKey, 'SIGNAL_FANOUT');
    if (!isNew) {
      this.logger.warn(`[${correlationId}] Signal ${signalId} already processed (idempotent skip)`);
      return {
        state: SignalState.COMPLETED,
        totalUsers: 0,
        successUsers: 0,
        rejectedUsers: 0,
        correlationId,
      };
    }

    // 3. Load signal
    const signal = await this.prisma.signal.findUnique({
      where: { id: signalId },
      include: { segmentRelation: true },
    });

    if (!signal) {
      this.logger.error(`[${correlationId}] Signal ${signalId} not found`);
      await this.idempotencyService.markFailed(idempotencyKey);
      return { state: SignalState.FAILED, totalUsers: 0, successUsers: 0, rejectedUsers: 0, correlationId };
    }

    // 4. Initialize SegmentExecution tracking in RECEIVED state
    const execution = await this.prisma.segmentExecution.create({
      data: {
        correlationId,
        segmentId: signal.segmentId,
        signalId,
        state: SignalState.RECEIVED,
        totalUsers: 0,
        processedUsers: 0,
        successfulUsers: 0,
        failedUsers: 0,
      },
    });

    // Validate that the segment is active / valid
    if (!signal.segmentRelation) {
      this.logger.error(`[${correlationId}] Signal ${signalId} has no associated segment relation`);
      await this.updateExecutionState(execution.id, SignalState.FAILED, {
        errorSummary: 'No associated segment relation found',
      });
      await this.idempotencyService.markFailed(idempotencyKey);
      return { state: SignalState.FAILED, totalUsers: 0, successUsers: 0, rejectedUsers: 0, correlationId };
    }

    // Transition to VALIDATED
    await this.updateExecutionState(execution.id, SignalState.VALIDATED);

    // Transition to PROCESSING
    await this.updateExecutionState(execution.id, SignalState.PROCESSING);

    this.logger.log(`[${correlationId}] Starting paginated fan-out for signal ${signalId}`);

    // 5. Fan out in pages — never load all subscribers into memory at once
    const { successUsers, rejectedUsers, totalUsers, errorSummary } = await this.paginatedFanOut(
      signal,
      correlationId,
      execution.id,
    );

    const finalState =
      totalUsers === 0
        ? SignalState.COMPLETED
        : rejectedUsers === 0
          ? SignalState.COMPLETED
          : successUsers === 0
            ? SignalState.FAILED
            : SignalState.PARTIALLY_COMPLETED;

    const completedAt = new Date();
    const processingDurationMs = completedAt.getTime() - execution.startedAt.getTime();

    // 6. Complete segment execution summary
    await this.updateExecutionState(execution.id, finalState, {
      totalUsers,
      processedUsers: totalUsers,
      successfulUsers: successUsers,
      failedUsers: rejectedUsers,
      completedAt,
      errorSummary,
      processingDurationMs,
    });

    // 7. Mark idempotency key as succeeded
    await this.idempotencyService.markSuccess(idempotencyKey);

    this.logger.log(
      `[${correlationId}] Signal ${signalId} fan-out complete. ` +
        `State=${finalState} Total=${totalUsers} Success=${successUsers} Failed=${rejectedUsers}`,
    );

    // Send applied status update to l-l-backend
    await this.sendAppliedStatusUpdate(signal.id, totalUsers, successUsers, signal.side, signal.symbol);

    return {
      state: finalState,
      totalUsers,
      successUsers,
      rejectedUsers,
      correlationId,
    };
  }

  private async sendAppliedStatusUpdate(
    signalId: string,
    totalUsers: number,
    successUsers: number,
    side: string,
    symbol: string,
  ): Promise<void> {
    const baseUrl = process.env.LL_BACKEND_URL || 'http://localhost:8080';
    const apiKey = process.env.AUTOMATED_API_KEY || 'default_secret_key';

    try {
      const updateText = `Trade Applied: Successfully placed orders for ${successUsers} users out of ${totalUsers} for ${side} ${symbol}.`;
      await axios.post(
        `${baseUrl}/api/reports/automated-trading-call`,
        {
          rawSignalId: signalId,
          isAppliedUpdate: true,
          updateText,
          symbol,
          side,
        },
        {
          headers: {
            'x-api-key': apiKey,
          },
          timeout: 5000,
        },
      );
      this.logger.log(`[Integration] Successfully sent applied status update for signal ${signalId} to l-l-backend`);
    } catch (error) {
      this.logger.error(
        `[Integration] Failed to send applied status update to l-l-backend: ${error.message}`,
      );
    }
  }

  /**
   * Processes subscribers in cursor-paginated batches to cap peak memory usage.
   *
   * At 10,000 subscribers, loading all at once risks ~50MB heap spikes.
   * Cursor pagination keeps memory bounded at BATCH_SIZE rows per iteration.
   *
   * p-limit(50) constrains concurrent enqueue operations within each batch.
   */
  private async paginatedFanOut(
    signal: Signal & { segmentRelation: any },
    correlationId: string,
    executionId: string,
  ): Promise<{ totalUsers: number; successUsers: number; rejectedUsers: number; errorSummary?: string }> {
    const BATCH_SIZE = 500;
    const limit = pLimit(50);

    let totalUsers = 0;
    let successUsers = 0;
    let rejectedUsers = 0;
    let lastCursorId: string | undefined;
    const errors: string[] = [];

    while (true) {
      const batch = await this.fetchSubscriberBatch(
        signal.segmentId,
        BATCH_SIZE,
        lastCursorId,
      );

      if (batch.length === 0) break;

      totalUsers += batch.length;
      lastCursorId = batch[batch.length - 1].userSegmentId;

      const results = await Promise.allSettled(
        batch.map((subscriber) =>
          limit(async () => {
            try {
              const enqueued = await this.enqueueForUser(signal, subscriber, correlationId);
              return { status: enqueued ? 'success' : 'rejected' };
            } catch (err) {
              const msg = `User ${subscriber.userId}: ${err.message}`;
              return { status: 'rejected', error: msg };
            }
          }),
        ),
      );

      for (const result of results) {
        if (result.status === 'fulfilled') {
          if (result.value.status === 'success') {
            successUsers++;
          } else {
            rejectedUsers++;
            if (result.value.error) {
              errors.push(result.value.error);
            }
          }
        } else {
          rejectedUsers++;
          errors.push(result.reason?.message || 'Unknown error');
        }
      }

      // Update database progress tracking for this batch with state validation
      await this.updateExecutionState(executionId, SignalState.PROCESSING, {
        totalUsers,
        processedUsers: totalUsers,
        successfulUsers: successUsers,
        failedUsers: rejectedUsers,
      });

      this.logger.debug(
        `[${correlationId}] Batch processed: ${batch.length} users. ` +
          `Running totals — success=${successUsers} failed=${rejectedUsers}`,
      );

      // Short-circuit if batch was smaller than page size (final page)
      if (batch.length < BATCH_SIZE) break;
    }

    const errorSummary = errors.length > 0 ? errors.slice(0, 100).join('; ') : undefined;

    return { totalUsers, successUsers, rejectedUsers, errorSummary };
  }

  /**
   * Fetches a single page of eligible subscribers using cursor-based pagination.
   */
  private async fetchSubscriberBatch(
    segmentId: string,
    take: number,
    afterId?: string,
  ): Promise<(SubscriberRow & { userSegmentId: string })[]> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const userSegments = await this.prisma.userSegment.findMany({
      where: {
        segmentId,
        status: UserSegmentStatus.ACTIVE,
        deletedAt: null,
        user: {
          subscriptions: {
            some: {
              status: SubscriptionStatus.ACTIVE,
              startDate: { lte: new Date() },
              endDate: { gte: new Date() },
            },
          },
          consents: {
            some: {
              consentDate: { gte: today },
              status: ConsentStatus.ACTIVE,
            },
          },
          userBrokers: {
            some: { status: BrokerStatus.ACTIVE },
          },
        },
      },
      include: {
        user: {
          include: {
            subscriptions: {
              where: {
                status: SubscriptionStatus.ACTIVE,
                startDate: { lte: new Date() },
                endDate: { gte: new Date() },
              },
              take: 1,
              orderBy: { startDate: 'desc' },
            },
            userBrokers: {
              where: { status: BrokerStatus.ACTIVE },
              include: { broker: true },
              take: 1,
            },
          },
        },
      },
      orderBy: { id: 'asc' },
      take,
      ...(afterId ? { cursor: { id: afterId }, skip: 1 } : {}),
    });

    const rows: (SubscriberRow & { userSegmentId: string })[] = [];

    for (const us of userSegments) {
      const activeUserBroker = us.user.userBrokers[0];
      const activeSub = us.user.subscriptions[0];
      if (!activeUserBroker || !activeSub) continue;

      const planName = this.resolvePlan(activeSub.planId);
      if (!planName) continue;

      rows.push({
        userSegmentId: us.id,
        userId: us.userId,
        segmentId: us.segmentId,
        brokerId: activeUserBroker.brokerId,
        brokerCode: activeUserBroker.broker.code as string,
        brokerClientId: activeUserBroker.brokerClientId,
        capital: Number(us.capital),
        baseLot: us.baseLot,
        plan: planName,
      });
    }

    return rows;
  }

  /**
   * Builds a UserExecutionSnapshot and enqueues an order placement job.
   * Returns true if enqueued, false if skipped (eligibility check failed).
   */
  private async enqueueForUser(
    signal: Signal & { segmentRelation: any },
    subscriber: SubscriberRow,
    correlationId: string,
  ): Promise<boolean> {
    // Check user-level risk lock
    if (this.redisService.isHealthy()) {
      const userBlocked = await this.redisService.getClient().get(`user:risk:blocked:${subscriber.userId}`);
      if (userBlocked === 'true') {
        this.logger.warn(`[${correlationId}] Skip fanning out to user ${subscriber.userId} due to risk lock`);
        return false;
      }
    }

    // Deterministic job ID prevents duplicate worker processing
    const jobId = `job-${signal.id}-${subscriber.userId}`;
    // Capture immutable snapshot at enqueue time
    const multiplierState = await this.multiplierService.getState(
      subscriber.userId,
      signal.segmentId,
    );

    const multiplier = multiplierState.current;
    let effectiveLot: number;

    if (signal.segmentRelation?.name?.toUpperCase() === 'EQUITY CASH') {
      const entryPrice = Number(signal.entryPrice);
      if (!entryPrice || entryPrice <= 0) {
        throw new Error('Invalid entry price for EQUITY CASH signal');
      }
      effectiveLot = Math.floor((subscriber.baseLot * multiplier) / entryPrice);
      if (effectiveLot < 1) {
        throw new Error('Calculated quantity is zero');
      }
    } else {
      effectiveLot = subscriber.baseLot * multiplier;
    }

    const snapshot: UserExecutionSnapshot = {
      userId: subscriber.userId,
      brokerId: subscriber.brokerId,
      brokerCode: subscriber.brokerCode,
      brokerClientId: subscriber.brokerClientId,
      segmentId: signal.segmentId,
      subscriptionPlan: subscriber.plan,
      multiplierIndex: multiplierState.index,
      multiplierValue: multiplier,
      capitalAllocated: subscriber.capital,
      baseLot: subscriber.baseLot,
      effectiveLot,
    };

    const ctx: ExecutionContext = {
      correlationId,
      jobId,
      signalId: signal.id,
      segmentId: signal.segmentId,
      symbol: signal.symbol,
      exchange: signal.exchange,
      side: signal.side as 'BUY' | 'SELL',
      orderType: (signal as any).orderType,
      entryPrice: Number(signal.entryPrice),
      stopLoss: Number(signal.stopLoss),
      targetPrice: Number(signal.targetPrice),
      snapshot,
    };

    await this.queueService.addJob(Queues.ORDER_PLACEMENT, jobId, ctx);

    this.logger.debug(
      `[${correlationId}] Enqueued job ${jobId} for user ${subscriber.userId} ` +
        `(lot=${snapshot.effectiveLot} multiplier=${multiplierState.current}x)`,
    );

    return true;
  }

  /**
   * Resolves a planId to a plan type string.
   * In production this should query the plan table; here we derive from planId prefix.
   */
  private resolvePlan(planId: string): PlanType | null {
    // TODO: Query the Plan table when it exists
    // For now we default to SPARK as both plans are eligible for trading
    return 'SPARK';
  }
}

interface SubscriberRow {
  userId: string;
  segmentId: string;
  brokerId: string;
  brokerCode: string;
  brokerClientId: string;
  capital: number;
  baseLot: number;
  plan: PlanType;
}
