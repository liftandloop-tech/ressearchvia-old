import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import {
  RiskEvent,
  UserSegmentStatus,
  TradeStatus,
  Prisma,
  BrokerStatus,
  RiskState,
  RiskViolationStatus,
  RiskRule,
  Severity,
  OrderStatus,
} from '@prisma/client';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { ConsentsService } from '../consents/consents.service';
import { BrokerSessionService } from '../brokers/services/broker-session.service';
import { BrokerFactory } from '../brokers/factory/broker.factory';
import { AuditService } from '../audit/audit.service';
import { AuditEventType } from '../audit/enums/audit-event.enum';
import { RiskDecision } from './interfaces/risk-decision.interface';
import { RiskCode } from './enums/risk-code.enum';
import { BrokerType } from '../brokers/interfaces/broker-type.enum';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { OutboxService } from '../infrastructure/outbox/outbox.service';
import { Queues } from '../infrastructure/queues/queue.constants';
import { Cron } from '@nestjs/schedule';

@Injectable()
export class RiskService {
  private readonly logger = new Logger(RiskService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly subscriptionsService: SubscriptionsService,
    private readonly consentsService: ConsentsService,
    private readonly brokerSessionService: BrokerSessionService,
    private readonly brokerFactory: BrokerFactory,
    private readonly auditService: AuditService,
    private readonly redisService: RedisService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
    private readonly outboxService: OutboxService,
  ) {}

  async validateExecution(
    userId: string,
    segmentId: string,
    estimatedCost: number,
  ): Promise<RiskDecision> {
    // 1. Subscription Validation
    const subValidation =
      await this.subscriptionsService.validateSubscription(userId);
    if (!subValidation.active) {
      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.NO_SUBSCRIPTION,
        'No active subscription',
      );
      return {
        approved: false,
        code: RiskCode.NO_SUBSCRIPTION,
        reason: 'No active subscription',
      };
    }

    // 2. Daily Consent Validation
    const hasConsent = await this.consentsService.hasTodayConsent(userId);
    if (!hasConsent) {
      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.NO_CONSENT,
        'Daily consent not granted',
      );
      return {
        approved: false,
        code: RiskCode.NO_CONSENT,
        reason: 'Daily consent not granted',
      };
    }

    // 3. Broker Session Validation
    const userBroker = await this.prisma.userBroker.findFirst({
      where: { userId, status: BrokerStatus.ACTIVE },
      include: { broker: true },
    });
    if (!userBroker || !userBroker.accessToken) {
      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.SESSION_EXPIRED,
        'Broker not connected',
      );
      return {
        approved: false,
        code: RiskCode.SESSION_EXPIRED,
        reason: 'Broker not connected',
      };
    }

    let isSessionValid = await this.brokerSessionService.validateSession(
      userId,
      userBroker.broker.code,
    );
    if (!isSessionValid) {
      try {
        await this.brokerSessionService.refreshSession(
          userId,
          userBroker.broker.code,
        );
        isSessionValid = await this.brokerSessionService.validateSession(
          userId,
          userBroker.broker.code,
        );
      } catch (e) {
        await this.logRejectedRisk(
          userId,
          segmentId,
          RiskCode.SESSION_EXPIRED,
          `Broker session refresh failed: ${e.message}`,
        );
        return {
          approved: false,
          code: RiskCode.SESSION_EXPIRED,
          reason: `Broker session refresh failed: ${e.message}`,
        };
      }
      if (!isSessionValid) {
        await this.logRejectedRisk(
          userId,
          segmentId,
          RiskCode.SESSION_EXPIRED,
          'Broker session validation failed after refresh',
        );
        return {
          approved: false,
          code: RiskCode.SESSION_EXPIRED,
          reason: 'Broker session validation failed after refresh',
        };
      }
    }

    // Retrieve user segment details
    const userSegment = await this.prisma.userSegment.findFirst({
      where: { userId, segmentId },
    });
    if (!userSegment) {
      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.SEGMENT_PAUSED,
        'Segment strategy not configured for user',
      );
      return {
        approved: false,
        code: RiskCode.SEGMENT_PAUSED,
        reason: 'Segment strategy not configured for user',
      };
    }

    // 8. Segment Status Validation (placed here since we need the segment status)
    if (userSegment.status !== UserSegmentStatus.ACTIVE) {
      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.SEGMENT_PAUSED,
        `Segment strategy status is ${userSegment.status}`,
      );
      return {
        approved: false,
        code: RiskCode.SEGMENT_PAUSED,
        reason: `Segment strategy status is ${userSegment.status}`,
      };
    }

    // 4. Capital Validation
    const allocatedCapital = Number(userSegment.capital);
    if (allocatedCapital < estimatedCost) {
      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.INSUFFICIENT_CAPITAL,
        `Allocated capital ${allocatedCapital} is less than estimated cost ${estimatedCost}`,
      );
      return {
        approved: false,
        code: RiskCode.INSUFFICIENT_CAPITAL,
        reason: `Allocated capital ${allocatedCapital} is less than estimated cost ${estimatedCost}`,
      };
    }

    // 5. Margin Validation
    let brokerMargin = 0;
    try {
      const brokerType = userBroker.broker.code as unknown as BrokerType;
      const adapter = this.brokerFactory.getAdapter(brokerType);
      const funds = await adapter.getFunds(
        userBroker.accessToken,
        userBroker.brokerClientId,
      );
      brokerMargin = funds.availableMargin;
    } catch (e) {
      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.INSUFFICIENT_MARGIN,
        `Failed to retrieve broker margin: ${e.message}`,
      );
      return {
        approved: false,
        code: RiskCode.INSUFFICIENT_MARGIN,
        reason: `Failed to retrieve broker margin: ${e.message}`,
      };
    }

    if (brokerMargin < estimatedCost) {
      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.INSUFFICIENT_MARGIN,
        `Broker margin ${brokerMargin} is less than estimated cost ${estimatedCost}`,
      );
      return {
        approved: false,
        code: RiskCode.INSUFFICIENT_MARGIN,
        reason: `Broker margin ${brokerMargin} is less than estimated cost ${estimatedCost}`,
      };
    }

    // 6. Daily Loss Validation
    const todayStr = new Date().toISOString().split('T')[0];
    const today = new Date(`${todayStr}T00:00:00.000Z`);

    const trades = await this.prisma.trade.findMany({
      where: {
        userId,
        segmentId,
        status: TradeStatus.CLOSED,
        createdAt: { gte: today },
      },
    });

    let dailyPnl = 0;
    for (const t of trades) {
      dailyPnl += Number(t.pnl || 0);
    }

    const currentLoss = dailyPnl < 0 ? Math.abs(dailyPnl) : 0;
    const dailyLossLimit = Number(userSegment.dailyLossLimit);

    if (currentLoss >= dailyLossLimit) {
      // Risk Lock: Pause the segment immediately
      await this.prisma.userSegment.update({
        where: { id: userSegment.id },
        data: {
          status: UserSegmentStatus.PAUSED,
          pausedAt: new Date(),
          lastRiskLockAt: new Date(),
        },
      });

      // Audit locked event
      await this.auditService.logEvent(
        userId,
        AuditEventType.SEGMENT_RISK_LOCKED,
        'UserSegment',
        userSegment.id,
        { dailyLossLimit, currentLoss },
      );

      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.DAILY_LOSS_LIMIT,
        `Daily loss limit of ${dailyLossLimit} has been reached/exceeded (Current: ${currentLoss})`,
      );
      return {
        approved: false,
        code: RiskCode.DAILY_LOSS_LIMIT,
        reason: `Daily loss limit of ${dailyLossLimit} has been reached/exceeded (Current: ${currentLoss})`,
      };
    }

    // 7. Multiplier Validation
    const multiplierState = await this.prisma.segmentMultiplier.findFirst({
      where: { userId, segmentId },
    });

    if (
      multiplierState &&
      multiplierState.currentMultiplier > userSegment.maxMultiplier
    ) {
      await this.logRejectedRisk(
        userId,
        segmentId,
        RiskCode.MULTIPLIER_LIMIT,
        `Multiplier ${multiplierState.currentMultiplier} exceeds max limit of ${userSegment.maxMultiplier}`,
      );
      return {
        approved: false,
        code: RiskCode.MULTIPLIER_LIMIT,
        reason: `Multiplier ${multiplierState.currentMultiplier} exceeds max limit of ${userSegment.maxMultiplier}`,
      };
    }

    // 9. Risk Decision (Approved)
    await this.auditService.logEvent(
      userId,
      AuditEventType.RISK_APPROVED,
      'SegmentMaster',
      segmentId,
      { estimatedCost },
    );

    return { approved: true };
  }

  private async logRejectedRisk(
    userId: string,
    segmentId: string,
    code: RiskCode,
    reason: string,
  ): Promise<void> {
    // Create RiskEvent record
    await this.prisma.riskEvent.create({
      data: {
        userId,
        segmentId,
        eventType: RiskCode[code],
        message: reason,
      },
    });

    // Log AuditEvent RISK_REJECTED
    await this.auditService.logEvent(
      userId,
      AuditEventType.RISK_REJECTED,
      'SegmentMaster',
      segmentId,
      { code: RiskCode[code], reason },
    );
  }

  async getRiskEvents(
    userId: string,
    limit = 20,
    offset = 0,
  ): Promise<{ data: RiskEvent[]; total: number }> {
    const [data, total] = await Promise.all([
      this.prisma.riskEvent.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.riskEvent.count({
        where: { userId },
      }),
    ]);

    return { data, total };
  }

  async getRiskEventsForSegment(
    userId: string,
    segmentId: string,
    page = 1,
    limit = 20,
  ) {
    return this.prisma.riskEvent.paginate({
      page,
      limit,
      where: { userId, segmentId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getRiskStatus(userId: string) {
    const userSegments = await this.prisma.userSegment.findMany({
      where: {
        userId,
        status: {
          in: [UserSegmentStatus.ACTIVE, UserSegmentStatus.PAUSED],
        },
      },
      include: {
        segment: true,
      },
    });

    const todayStr = new Date().toISOString().split('T')[0];
    const today = new Date(`${todayStr}T00:00:00.000Z`);

    const statusList: any[] = [];

    for (const us of userSegments) {
      const trades = await this.prisma.trade.findMany({
        where: {
          userId,
          segmentId: us.segmentId,
          status: TradeStatus.CLOSED,
          createdAt: {
            gte: today,
          },
        },
      });

      let dailyPnl = 0;
      for (const t of trades) {
        dailyPnl += Number(t.pnl || 0);
      }

      const currentLoss = dailyPnl < 0 ? Math.abs(dailyPnl) : 0;
      const dailyLossLimit = Number(us.dailyLossLimit);
      const isLocked =
        currentLoss >= dailyLossLimit ||
        us.status === UserSegmentStatus.PAUSED;

      statusList.push({
        segmentId: us.segmentId,
        segmentName: us.segment.name,
        dailyLossLimit,
        currentLoss,
        dailyPnl,
        isLocked,
        status: us.status,
      });
    }

    return statusList;
  }

  async getRiskStatusForSegment(userId: string, segmentId: string) {
    const userSegment = await this.prisma.userSegment.findFirst({
      where: { userId, segmentId },
      include: { segment: true },
    });
    if (!userSegment) {
      throw new NotFoundException('Strategy not configured for user');
    }

    const todayStr = new Date().toISOString().split('T')[0];
    const today = new Date(`${todayStr}T00:00:00.000Z`);

    const trades = await this.prisma.trade.findMany({
      where: {
        userId,
        segmentId,
        status: TradeStatus.CLOSED,
        createdAt: { gte: today },
      },
    });

    let dailyPnl = 0;
    for (const t of trades) {
      dailyPnl += Number(t.pnl || 0);
    }

    const dailyLoss = dailyPnl < 0 ? Math.abs(dailyPnl) : 0;
    const dailyLossLimit = Number(userSegment.dailyLossLimit);
    const locked =
      userSegment.status === UserSegmentStatus.PAUSED ||
      dailyLoss >= dailyLossLimit;

    return {
      locked,
      dailyLoss,
      dailyLossLimit,
    };
  }

  async resetRiskLock(userId: string, segmentId: string): Promise<any> {
    return this.unlockSegment(userId, segmentId, undefined, false);
  }

  async unlockSegment(
    userId: string,
    segmentId: string,
    targetUserId?: string,
    isAdmin = false,
  ): Promise<any> {
    const actualUserId = isAdmin && targetUserId ? targetUserId : userId;

    const userSegment = await this.prisma.userSegment.findFirst({
      where: { userId: actualUserId, segmentId },
    });

    if (!userSegment) {
      throw new NotFoundException('Strategy subscription not found');
    }

    if (!isAdmin && userSegment.userId !== userId) {
      throw new ForbiddenException('You do not own this strategy');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Reset user strategy state
      const updatedSegment = await tx.userSegment.update({
        where: { id: userSegment.id },
        data: {
          status: UserSegmentStatus.ACTIVE,
          activatedAt: new Date(),
          pausedAt: null,
        },
      });

      // 2. Reset lot multiplier states
      const multiplier = await tx.segmentMultiplier.findFirst({
        where: {
          userId: actualUserId,
          segmentId,
        },
      });

      if (multiplier) {
        await tx.segmentMultiplier.update({
          where: { id: multiplier.id },
          data: {
            lossStreak: 0,
            currentMultiplier: 1,
          },
        });
      }

      // 3. Log risk unlock event
      await tx.riskEvent.create({
        data: {
          userId: actualUserId,
          segmentId,
          eventType: 'RISK_LOCK_RESET',
          message: `Manual reset of strategy risk lock completed by ${isAdmin ? 'Admin' : 'Owner'}.`,
        },
      });

      // 4. Log AuditEvent SEGMENT_RISK_UNLOCKED
      await this.auditService.logEvent(
        actualUserId,
        AuditEventType.SEGMENT_RISK_UNLOCKED,
        'UserSegment',
        userSegment.id,
        { unlockedBy: isAdmin ? 'Admin' : 'Owner', triggerUserId: userId },
      );

      return updatedSegment;
    });
  }

  // Preserve legacy validation helpers to support existing specs
  async validateCapital(
    userId: string,
    segmentId: string,
    estimatedCost: number,
    availableMargin: number,
  ): Promise<boolean> {
    const userSegment = await this.prisma.userSegment.findFirst({
      where: { userId, segmentId },
    });

    if (!userSegment) {
      return false;
    }

    if (availableMargin < estimatedCost) {
      await this.prisma.riskEvent.create({
        data: {
          userId,
          segmentId,
          eventType: 'INSUFFICIENT_CAPITAL',
          message: `Insufficient capital/margin. Available: ${availableMargin}, Required: ${estimatedCost}`,
        },
      });
      return false;
    }

    return true;
  }

  async validateLossLimit(
    userId: string,
    segmentId: string,
  ): Promise<boolean> {
    const userSegment = await this.prisma.userSegment.findFirst({
      where: { userId, segmentId },
    });

    if (!userSegment) {
      return false;
    }

    const todayStr = new Date().toISOString().split('T')[0];
    const today = new Date(`${todayStr}T00:00:00.000Z`);

    const trades = await this.prisma.trade.findMany({
      where: {
        userId,
        segmentId,
        status: TradeStatus.CLOSED,
        createdAt: { gte: today },
      },
    });

    let dailyPnl = 0;
    for (const t of trades) {
      dailyPnl += Number(t.pnl || 0);
    }

    const currentLoss = dailyPnl < 0 ? Math.abs(dailyPnl) : 0;
    const dailyLossLimit = Number(userSegment.dailyLossLimit);

    if (currentLoss >= dailyLossLimit) {
      await this.prisma.userSegment.update({
        where: { id: userSegment.id },
        data: {
          status: UserSegmentStatus.PAUSED,
          pausedAt: new Date(),
          lastRiskLockAt: new Date(),
        },
      });

      await this.prisma.riskEvent.create({
        data: {
          userId,
          segmentId,
          eventType: 'DAILY_LOSS_LIMIT_EXCEEDED',
          message: `Daily loss limit reached. Locked. Current Loss: ${currentLoss}, Limit: ${dailyLossLimit}`,
        },
      });
      return false;
    }

    return true;
  }

  async evaluateRisk(
    userId: string,
    symbol: string,
    quantity: number,
    price: number,
    brokerId: string,
    segmentId: string,
  ): Promise<RiskDecision> {
    const orderValue = Number(quantity) * Number(price);

    // 1. Emergency locks checks first
    if (this.redisService.isHealthy()) {
      const globalBlocked = await this.redisService.getClient().get('risk:global:blocked');
      if (globalBlocked === 'true') {
        this.logger.warn(`Order blocked due to global emergency risk lock: user=${userId}`);
        await this.logViolation(userId, RiskRule.STALE_SNAPSHOT, Severity.CRITICAL, { reason: 'Global emergency risk lock' });
        return { approved: false, code: RiskCode.UNKNOWN, reason: 'Global emergency risk lock is active' };
      }

      const userBlocked = await this.redisService.getClient().get(`user:risk:blocked:${userId}`);
      if (userBlocked === 'true') {
        this.logger.warn(`Order blocked due to user risk lock: user=${userId}`);
        await this.logViolation(userId, RiskRule.STALE_SNAPSHOT, Severity.CRITICAL, { reason: 'User risk lock' });
        return { approved: false, code: RiskCode.DAILY_LOSS_LIMIT, reason: 'User risk circuit breaker is active' };
      }
    }

    const defaultMode = process.env.RISK_DEFAULT_MODE || 'BLOCK';

    // 2. Fetch RiskSnapshot
    const snapshot = await this.prisma.riskSnapshot.findUnique({
      where: { userId },
    });

    // Freshness check:
    if (snapshot) {
      const freshnessMs = Date.now() - new Date(snapshot.updatedAt).getTime();
      if (freshnessMs > 300000) { // 5 minutes
        this.logger.warn(`Stale risk snapshot for user ${userId}. Age: ${freshnessMs}ms`);
        // Trigger background recalculate
        const jobId = `risk-recalc-${userId}`;
        await this.queueService.addJob(Queues.RISK_RECALCULATE, jobId, { userId });
        
        if (defaultMode === 'BLOCK') {
          await this.logViolation(userId, RiskRule.STALE_SNAPSHOT, Severity.CRITICAL, { freshnessMs });
          return { approved: false, code: RiskCode.UNKNOWN, reason: 'Risk snapshot is stale' };
        } else {
          this.logger.log(`Stale risk snapshot allowed by default mode ALLOW for user ${userId}`);
        }
      }
    }

    // 3. Fetch applicable RiskProfiles
    const applicableProfiles = await this.prisma.riskProfile.findMany({
      where: {
        OR: [
          { userId },
          { segmentId, userId: null, brokerId: null },
          { brokerId, userId: null, segmentId: null },
          { userId: null, segmentId: null, brokerId: null }, // global fallback
        ]
      },
      orderBy: [
        { priority: 'desc' },
        { version: 'desc' },
      ],
    });

    if (applicableProfiles.length === 0) {
      if (defaultMode === 'BLOCK') {
        this.logger.warn(`No risk profile found for user ${userId} and RISK_DEFAULT_MODE=BLOCK`);
        await this.logViolation(userId, RiskRule.NO_PROFILE, Severity.CRITICAL, { reason: 'No risk profile' });
        return { approved: false, code: RiskCode.UNKNOWN, reason: 'No active risk profile found' };
      } else {
        // Log evaluation as approved
        await this.logEvaluation(userId, true, 0, orderValue, { info: 'No profile, allowed by default' });
        return { approved: true };
      }
    }

    // Snapshot is required if profiles exist and limits are set
    if (!snapshot) {
      this.logger.warn(`No risk snapshot found for user ${userId}`);
      // Trigger background recalculate
      const jobId = `risk:recalc:${userId}`;
      await this.queueService.addJob(Queues.RISK_RECALCULATE, jobId, { userId });
      if (defaultMode === 'BLOCK') {
        await this.logViolation(userId, RiskRule.NO_PROFILE, Severity.CRITICAL, { reason: 'No risk snapshot' });
        return { approved: false, code: RiskCode.UNKNOWN, reason: 'No risk snapshot found' };
      } else {
        await this.logEvaluation(userId, true, 0, orderValue, { info: 'No snapshot, allowed by default' });
        return { approved: true };
      }
    }

    const evaluatedRulesResult: Record<string, any> = {};

    // Evaluate profiles
    for (const profile of applicableProfiles) {
      // Rule 1: Max Capital Per User
      const maxCap = Number(profile.maxCapitalPerUser);
      if (maxCap > 0) {
        const potentialCapital = Number(snapshot.currentCapitalUsed) + orderValue;
        evaluatedRulesResult['MAX_CAPITAL_USER'] = { potentialCapital, maxCap };
        if (potentialCapital > maxCap) {
          await this.logViolation(userId, RiskRule.MAX_CAPITAL_USER, Severity.CRITICAL, { potentialCapital, maxCap });
          await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
          return { approved: false, code: RiskCode.INSUFFICIENT_CAPITAL, reason: 'Exceeded Max Capital Limit' };
        }
      }

      // Rule 2: Max Capital Per Segment
      const maxCapSeg = Number(profile.maxCapitalPerSegment);
      if (maxCapSeg > 0 && profile.segmentId === segmentId) {
        const potentialSegmentCapital = orderValue; // Simplified per-segment order limit
        evaluatedRulesResult['MAX_CAPITAL_SEGMENT'] = { potentialSegmentCapital, maxCapSeg };
        if (potentialSegmentCapital > maxCapSeg) {
          await this.logViolation(userId, RiskRule.MAX_CAPITAL_SEGMENT, Severity.WARNING, { potentialSegmentCapital, maxCapSeg });
          await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
          return { approved: false, code: RiskCode.INSUFFICIENT_CAPITAL, reason: 'Exceeded Max Capital Per Segment' };
        }
      }

      // Rule 3: Max Daily Loss
      const maxLoss = Number(profile.maxDailyLoss);
      if (maxLoss > 0) {
        const currentLoss = Number(snapshot.dailyLoss);
        evaluatedRulesResult['MAX_DAILY_LOSS'] = { currentLoss, maxLoss };
        if (currentLoss >= maxLoss) {
          await this.logViolation(userId, RiskRule.MAX_DAILY_LOSS, Severity.CRITICAL, { currentLoss, maxLoss });
          await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
          // Lock user
          if (this.redisService.isHealthy()) {
            await this.redisService.getClient().set(`user:risk:blocked:${userId}`, 'true');
          }
          return { approved: false, code: RiskCode.DAILY_LOSS_LIMIT, reason: 'Exceeded Max Daily Loss Limit' };
        }
      }

      // Rule 4: Max Open Positions
      const maxPositions = profile.maxOpenPositions;
      if (maxPositions > 0) {
        const currentOpenPositions = snapshot.openPositionsCount;
        evaluatedRulesResult['MAX_OPEN_POSITIONS'] = { currentOpenPositions, maxPositions };
        if (currentOpenPositions >= maxPositions) {
          await this.logViolation(userId, RiskRule.MAX_OPEN_POSITIONS, Severity.WARNING, { currentOpenPositions, maxPositions });
          await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
          return { approved: false, code: RiskCode.UNKNOWN, reason: 'Exceeded Max Open Positions Limit' };
        }
      }

      // Rule 5: Max Position Size (for the current symbol)
      const maxPosSize = profile.maxPositionSize;
      if (maxPosSize > 0) {
        const symbolExposures = snapshot.exposurePerSymbol as Record<string, any>;
        const currentSymbolQty = symbolExposures[symbol]?.quantity || 0;
        const potentialQty = currentSymbolQty + quantity;
        evaluatedRulesResult['MAX_POSITION_SIZE'] = { potentialQty, maxPosSize };
        if (potentialQty > maxPosSize) {
          await this.logViolation(userId, RiskRule.MAX_POSITION_SIZE, Severity.WARNING, { potentialQty, maxPosSize });
          await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
          return { approved: false, code: RiskCode.UNKNOWN, reason: 'Exceeded Max Position Size Limit' };
        }
      }

      // Rule 6: Max Exposure Per Symbol
      const maxSymbolExposure = Number(profile.maxExposurePerSymbol);
      if (maxSymbolExposure > 0) {
        const symbolExposures = snapshot.exposurePerSymbol as Record<string, any>;
        const currentExposure = symbolExposures[symbol]?.exposure || 0;
        const potentialExposure = currentExposure + orderValue;
        evaluatedRulesResult['MAX_EXPOSURE_SYMBOL'] = { potentialExposure, maxSymbolExposure };
        if (potentialExposure > maxSymbolExposure) {
          await this.logViolation(userId, RiskRule.MAX_EXPOSURE_SYMBOL, Severity.CRITICAL, { potentialExposure, maxSymbolExposure });
          await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
          return { approved: false, code: RiskCode.UNKNOWN, reason: 'Exceeded Max Exposure Per Symbol Limit' };
        }
      }

      // Rule 7: Max Exposure Per Broker
      const maxBrokerExposure = Number(profile.maxExposurePerBroker);
      if (maxBrokerExposure > 0) {
        const brokerExposures = snapshot.exposurePerBroker as Record<string, any>;
        const currentExposure = brokerExposures[brokerId] || 0;
        const potentialExposure = currentExposure + orderValue;
        evaluatedRulesResult['MAX_EXPOSURE_BROKER'] = { potentialExposure, maxBrokerExposure };
        if (potentialExposure > maxBrokerExposure) {
          await this.logViolation(userId, RiskRule.MAX_EXPOSURE_BROKER, Severity.CRITICAL, { potentialExposure, maxBrokerExposure });
          await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
          return { approved: false, code: RiskCode.UNKNOWN, reason: 'Exceeded Max Exposure Per Broker Limit' };
        }
      }

      // Rule 8: Max Concurrent Orders
      const maxOrders = profile.maxConcurrentOrders;
      if (maxOrders > 0) {
        const currentOrders = snapshot.concurrentOrdersCount;
        evaluatedRulesResult['MAX_CONCURRENT_ORDERS'] = { currentOrders, maxOrders };
        if (currentOrders >= maxOrders) {
          await this.logViolation(userId, RiskRule.MAX_CONCURRENT_ORDERS, Severity.INFO, { currentOrders, maxOrders });
          await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
          return { approved: false, code: RiskCode.UNKNOWN, reason: 'Exceeded Max Concurrent Orders Limit' };
        }
      }
    }

    // Approved!
    const bestProfile = applicableProfiles[0];
    await this.logEvaluation(userId, true, bestProfile.version, orderValue, evaluatedRulesResult);
    return { approved: true };
  }

  private async logViolation(
    userId: string,
    rule: RiskRule,
    severity: Severity,
    details: any,
  ): Promise<void> {
    await this.prisma.riskViolation.create({
      data: {
        userId,
        ruleViolated: rule,
        severity,
        details,
      },
    });

    this.metrics.incrementRiskViolations(rule, severity);

    // If critical, trigger the user circuit breaker in Redis
    if (severity === Severity.CRITICAL && this.redisService.isHealthy()) {
      await this.redisService.getClient().set(`user:risk:blocked:${userId}`, 'true');
      this.metrics.incrementRiskUsersBlocked();
    }

    // Publish outbox event
    await this.outboxService.createEvent('RISK_VIOLATION', {
      userId,
      rule,
      severity,
      details,
    });
  }

  private async logEvaluation(
    userId: string,
    approved: boolean,
    profileVersion: number,
    orderValue: number,
    evaluatedRules: any,
  ): Promise<void> {
    await this.prisma.riskEvaluation.create({
      data: {
        userId,
        approved,
        profileVersion,
        orderValue,
        evaluatedRules,
      },
    });
  }

  async recalculateRiskSnapshot(userId: string): Promise<any> {
    try {
      // 1. Fetch active open positions
      const openPositions = await this.prisma.position.findMany({
        where: {
          trade: { userId },
          status: 'OPEN',
        },
        include: {
          trade: true,
        },
      });

      // 2. Aggregate currentCapitalUsed, exposurePerSymbol, exposurePerBroker
      let currentCapitalUsed = 0;
      const exposurePerSymbol: Record<string, { quantity: number; exposure: number }> = {};
      const exposurePerBroker: Record<string, number> = {};

      for (const pos of openPositions) {
        const qty = Number(pos.quantity);
        const avgPrice = Number(pos.avgPrice);
        const currPrice = Number(pos.currentPrice);

        currentCapitalUsed += qty * avgPrice;

        const symbol = pos.symbol;
        if (!exposurePerSymbol[symbol]) {
          exposurePerSymbol[symbol] = { quantity: 0, exposure: 0 };
        }
        exposurePerSymbol[symbol].quantity += qty;
        exposurePerSymbol[symbol].exposure += qty * currPrice;

        const brokerId = pos.trade.brokerId;
        exposurePerBroker[brokerId] = (exposurePerBroker[brokerId] || 0) + (qty * currPrice);
      }

      // 3. Aggregate concurrentOrdersCount
      const concurrentOrdersCount = await this.prisma.order.count({
        where: {
          trade: { userId },
          status: { in: ['PENDING', 'PLACED', 'PARTIALLY_FILLED'] },
        },
      });

      // 4. Aggregate dailyLoss
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const todayClosedTrades = await this.prisma.trade.findMany({
        where: {
          userId,
          status: 'CLOSED',
          createdAt: { gte: today },
        },
      });

      let realizedPnL = 0;
      for (const t of todayClosedTrades) {
        realizedPnL += Number(t.pnl || 0);
      }

      let unrealizedPnL = 0;
      for (const pos of openPositions) {
        unrealizedPnL += Number(pos.unrealizedPnl || 0);
      }

      const netDailyPnL = realizedPnL + unrealizedPnL;
      const dailyLoss = netDailyPnL < 0 ? Math.abs(netDailyPnL) : 0;

      // Update metrics
      this.metrics.setRiskDailyPnl(userId, netDailyPnL);

      // 5. Fetch applicable profiles to evaluate state
      const applicableProfiles = await this.prisma.riskProfile.findMany({
        where: {
          OR: [
            { userId },
            { segmentId: { not: null }, userId: null, brokerId: null },
            { brokerId: { not: null }, userId: null, segmentId: null },
            { userId: null, segmentId: null, brokerId: null }, // global fallback
          ]
        },
        orderBy: { priority: 'desc' },
      });

      let state: RiskState = 'HEALTHY';
      const activeProfile = applicableProfiles[0];
      const profileVersion = activeProfile?.version || 1;

      for (const profile of applicableProfiles) {
        // Check Max Capital User
        const maxCap = Number(profile.maxCapitalPerUser);
        if (maxCap > 0) {
          if (currentCapitalUsed >= maxCap) {
            state = 'BLOCKED';
          } else if (currentCapitalUsed >= maxCap * 0.8 && state !== 'BLOCKED') {
            state = 'WARNING';
          }
        }

        // Check Max Daily Loss
        const maxLoss = Number(profile.maxDailyLoss);
        if (maxLoss > 0) {
          if (dailyLoss >= maxLoss) {
            state = 'BLOCKED';
          } else if (dailyLoss >= maxLoss * 0.8 && state !== 'BLOCKED') {
            state = 'WARNING';
          }
        }

        // Check Max Open Positions
        const maxOpenPos = profile.maxOpenPositions;
        if (maxOpenPos > 0) {
          if (openPositions.length >= maxOpenPos) {
            state = 'BLOCKED';
          } else if (openPositions.length >= maxOpenPos * 0.8 && state !== 'BLOCKED') {
            state = 'WARNING';
          }
        }

        // Check Max Concurrent Orders
        const maxConcurrent = profile.maxConcurrentOrders;
        if (maxConcurrent > 0) {
          if (concurrentOrdersCount >= maxConcurrent) {
            state = 'BLOCKED';
          } else if (concurrentOrdersCount >= maxConcurrent * 0.8 && state !== 'BLOCKED') {
            state = 'WARNING';
          }
        }
      }

      // 6. Update user risk circuit breaker in Redis
      const redisKey = `user:risk:blocked:${userId}`;
      if (state === 'BLOCKED' && this.redisService.isHealthy()) {
        await this.redisService.getClient().set(redisKey, 'true');
        this.metrics.incrementRiskUsersBlocked();
      } else if (this.redisService.isHealthy()) {
        await this.redisService.getClient().del(redisKey);
      }

      // 7. Upsert RiskSnapshot
      const snapshot = await this.prisma.riskSnapshot.upsert({
        where: { userId },
        update: {
          state,
          profileVersion,
          currentCapitalUsed,
          dailyLoss,
          openPositionsCount: openPositions.length,
          exposurePerSymbol: exposurePerSymbol as any,
          exposurePerBroker: exposurePerBroker as any,
          concurrentOrdersCount,
          lastRecalculatedAt: new Date(),
          lastRecalculationStatus: 'SUCCESS',
        },
        create: {
          userId,
          state,
          profileVersion,
          currentCapitalUsed,
          dailyLoss,
          openPositionsCount: openPositions.length,
          exposurePerSymbol: exposurePerSymbol as any,
          exposurePerBroker: exposurePerBroker as any,
          concurrentOrdersCount,
          lastRecalculatedAt: new Date(),
          lastRecalculationStatus: 'SUCCESS',
        },
      });

      // Update state metrics
      this.metrics.setRiskState(state, 1);

      // Invalidate portfolio analytics cache
      if (this.redisService.isHealthy()) {
        const keys = [
          `analytics:user:${userId}:portfolio`,
          `analytics:user:${userId}:segments`,
          `analytics:user:${userId}:broker-stats`,
        ];
        for (const key of keys) {
          await this.redisService.getClient().del(key);
        }
      }

      return snapshot;
    } catch (err) {
      this.logger.error(`Failed to recalculate risk snapshot for user ${userId}: ${err.message}`);
      try {
        await this.prisma.riskSnapshot.upsert({
          where: { userId },
          update: {
            lastRecalculatedAt: new Date(),
            lastRecalculationStatus: `FAILED: ${err.message.slice(0, 40)}`,
          },
          create: {
            userId,
            currentCapitalUsed: 0,
            dailyLoss: 0,
            openPositionsCount: 0,
            exposurePerSymbol: {},
            exposurePerBroker: {},
            concurrentOrdersCount: 0,
            lastRecalculatedAt: new Date(),
            lastRecalculationStatus: `FAILED: ${err.message.slice(0, 40)}`,
          },
        });
      } catch (dbErr) {
        this.logger.error(`Failed to write failed recalculation status to DB for user ${userId}: ${dbErr.message}`);
      }
      throw err;
    }
  }

  @Cron('0 2 * * *')
  async cleanupEvaluations(): Promise<void> {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    this.logger.log(`Running nightly risk evaluations cleanup. Removing records older than: ${thirtyDaysAgo}`);
    try {
      const deleted = await this.prisma.riskEvaluation.deleteMany({
        where: {
          createdAt: { lt: thirtyDaysAgo },
        },
      });
      this.logger.log(`Pruned ${deleted.count} old risk evaluations.`);
    } catch (err) {
      this.logger.error(`Failed to cleanup old risk evaluations: ${err.message}`);
    }
  }

  async createProfile(data: {
    userId?: string;
    segmentId?: string;
    brokerId?: string;
    priority?: number;
    maxCapitalPerUser: number;
    maxCapitalPerSegment: number;
    maxDailyLoss: number;
    maxOpenPositions: number;
    maxPositionSize: number;
    maxExposurePerSymbol: number;
    maxExposurePerBroker: number;
    maxConcurrentOrders: number;
  }): Promise<any> {
    return this.prisma.riskProfile.create({
      data: {
        userId: data.userId || null,
        segmentId: data.segmentId || null,
        brokerId: data.brokerId || null,
        priority: data.priority ?? 0,
        version: 1,
        maxCapitalPerUser: new Prisma.Decimal(data.maxCapitalPerUser),
        maxCapitalPerSegment: new Prisma.Decimal(data.maxCapitalPerSegment),
        maxDailyLoss: new Prisma.Decimal(data.maxDailyLoss),
        maxOpenPositions: data.maxOpenPositions,
        maxPositionSize: data.maxPositionSize,
        maxExposurePerSymbol: new Prisma.Decimal(data.maxExposurePerSymbol),
        maxExposurePerBroker: new Prisma.Decimal(data.maxExposurePerBroker),
        maxConcurrentOrders: data.maxConcurrentOrders,
      },
    });
  }

  async updateProfile(
    id: string,
    data: {
      userId?: string;
      segmentId?: string;
      brokerId?: string;
      priority?: number;
      maxCapitalPerUser?: number;
      maxCapitalPerSegment?: number;
      maxDailyLoss?: number;
      maxOpenPositions?: number;
      maxPositionSize?: number;
      maxExposurePerSymbol?: number;
      maxExposurePerBroker?: number;
      maxConcurrentOrders?: number;
    },
  ): Promise<any> {
    const existing = await this.prisma.riskProfile.findUnique({
      where: { id },
    });
    if (!existing) {
      throw new NotFoundException(`Risk profile with ID ${id} not found`);
    }

    const updatedData: any = {};
    if (data.userId !== undefined) updatedData.userId = data.userId || null;
    if (data.segmentId !== undefined) updatedData.segmentId = data.segmentId || null;
    if (data.brokerId !== undefined) updatedData.brokerId = data.brokerId || null;
    if (data.priority !== undefined) updatedData.priority = data.priority;
    if (data.maxCapitalPerUser !== undefined) updatedData.maxCapitalPerUser = new Prisma.Decimal(data.maxCapitalPerUser);
    if (data.maxCapitalPerSegment !== undefined) updatedData.maxCapitalPerSegment = new Prisma.Decimal(data.maxCapitalPerSegment);
    if (data.maxDailyLoss !== undefined) updatedData.maxDailyLoss = new Prisma.Decimal(data.maxDailyLoss);
    if (data.maxOpenPositions !== undefined) updatedData.maxOpenPositions = data.maxOpenPositions;
    if (data.maxPositionSize !== undefined) updatedData.maxPositionSize = data.maxPositionSize;
    if (data.maxExposurePerSymbol !== undefined) updatedData.maxExposurePerSymbol = new Prisma.Decimal(data.maxExposurePerSymbol);
    if (data.maxExposurePerBroker !== undefined) updatedData.maxExposurePerBroker = new Prisma.Decimal(data.maxExposurePerBroker);
    if (data.maxConcurrentOrders !== undefined) updatedData.maxConcurrentOrders = data.maxConcurrentOrders;

    return this.prisma.riskProfile.update({
      where: { id },
      data: {
        ...updatedData,
        version: { increment: 1 },
      },
    });
  }

  async getViolations(userId?: string): Promise<any[]> {
    return this.prisma.riskViolation.findMany({
      where: userId ? { userId } : {},
      orderBy: { createdAt: 'desc' },
    });
  }

  async getSnapshots(userId?: string): Promise<any[]> {
    return this.prisma.riskSnapshot.findMany({
      where: userId ? { userId } : {},
      orderBy: { updatedAt: 'desc' },
    });
  }
}

