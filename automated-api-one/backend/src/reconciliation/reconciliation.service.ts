import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { BrokerRegistry } from '../brokers/registry/broker.registry';
import { BrokerType } from '../brokers/interfaces/broker-type.enum';
import { Queues } from '../infrastructure/queues/queue.constants';
import { OutboxService } from '../infrastructure/outbox/outbox.service';
import {
  ReconciliationStatus,
  ReconciliationIssueType,
  Severity,
  ReconciliationIssueStatus,
  OrderStatus,
  TradeStatus,
  PositionStatus,
  OperationsAction,
  OperationStatus,
} from '@prisma/client';
import * as crypto from 'crypto';

@Injectable()
export class ReconciliationService {
  private readonly logger = new Logger(ReconciliationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redisService: RedisService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
    private readonly brokerRegistry: BrokerRegistry,
    private readonly outboxService: OutboxService,
  ) {}

  /**
   * Triggers a sharded reconciliation run for all active user-brokers.
   */
  async triggerReconciliation(operatorId?: string): Promise<string> {
    const runId = crypto.randomUUID();
    const startedAt = new Date();

    // Check/acquire global run lock in Redis
    const lockKey = `reconciliation:run:${runId}`;
    if (this.redisService.isHealthy()) {
      try {
        await this.redisService.getClient().set(lockKey, '1', 'EX', 7200); // 2 hours expiry
      } catch (err) {
        this.logger.error(`Failed to set run lock in Redis: ${err.message}`);
      }
    }

    this.logger.log(`Starting reconciliation run ${runId}`);
    this.metrics.incrementReconciliationRuns();

    // Fetch all active UserBrokers (with active/valid session tokens)
    const activeUserBrokers = await this.prisma.userBroker.findMany({
      where: {
        status: 'ACTIVE',
        accessToken: { not: null },
      },
      include: {
        broker: true,
      },
    });

    const totalChecked = activeUserBrokers.length;

    // Create the ReconciliationRun record
    await this.prisma.reconciliationRun.create({
      data: {
        id: runId,
        startedAt,
        status: ReconciliationStatus.RUNNING,
        totalChecked,
        mismatchesFound: 0,
      },
    });

    if (totalChecked === 0) {
      await this.prisma.reconciliationRun.update({
        where: { id: runId },
        data: {
          status: ReconciliationStatus.COMPLETED,
          completedAt: new Date(),
        },
      });
      this.logger.log(`Reconciliation run ${runId} finished. Checked 0 users.`);
      return runId;
    }

    // Spawn sharded jobs
    for (const ub of activeUserBrokers) {
      // Create ReconciliationShard record
      await this.prisma.reconciliationShard.create({
        data: {
          runId,
          userId: ub.userId,
          status: ReconciliationStatus.RUNNING,
          startedAt: new Date(),
        },
      });

      // Enqueue BullMQ job
      const jobId = `reconciliation-run-${runId}-user-${ub.userId}`;
      await this.queueService.addJob(Queues.RECONCILIATION, jobId, {
        runId,
        userId: ub.userId,
      });
    }

    return runId;
  }

  /**
   * Reconciles a single user's active broker state against local DB state.
   */
  async reconcileUserBroker(userId: string, runId: string): Promise<void> {
    const startTime = Date.now();
    const ub = await this.prisma.userBroker.findFirst({
      where: { userId, status: 'ACTIVE' },
      include: { broker: true },
    });

    if (!ub || !ub.accessToken) {
      this.logger.warn(`No active UserBroker session for user ${userId}. Shard skipped.`);
      await this.prisma.reconciliationShard.update({
        where: { runId_userId: { runId, userId } },
        data: {
          status: ReconciliationStatus.COMPLETED,
          completedAt: new Date(),
        },
      });
      await this.checkRunCompletion(runId);
      return;
    }

    const brokerCode = ub.broker.code;
    const brokerId = ub.brokerId;
    const clientCode = ub.brokerClientId;
    const token = ub.accessToken;

    // Acquire sharded user-broker lock in Redis
    const userLockKey = `reconciliation:user:${userId}:${brokerId}`;
    if (this.redisService.isHealthy()) {
      try {
        const locked = await this.redisService.getClient().set(userLockKey, '1', 'EX', 7200, 'NX');
        if (locked !== 'OK') {
          this.logger.warn(`User broker reconciliation already running for lock: ${userLockKey}`);
          await this.prisma.reconciliationShard.update({
            where: { runId_userId: { runId, userId } },
            data: {
              status: ReconciliationStatus.FAILED,
              completedAt: new Date(),
            },
          });
          await this.checkRunCompletion(runId);
          return;
        }
      } catch (err) {
        this.logger.error(`Redis error acquiring lock ${userLockKey}: ${err.message}`);
      }
    }

    let issuesFoundCount = 0;

    try {
      // Resolve broker adapter
      let adapter: any;
      try {
        adapter = this.brokerRegistry.get(brokerCode as unknown as BrokerType);
      } catch (err) {
        throw new Error(`Failed to resolve broker adapter for ${brokerCode}: ${err.message}`);
      }

      // Read Tolerance Configurations
      const reconPnlTolerance = parseFloat(process.env.RECON_PNL_TOLERANCE_PERCENT || '0.50') / 100;
      const reconPriceTolerance = parseFloat(process.env.RECON_PRICE_TOLERANCE_PERCENT || '0.10') / 100;

      // ----------------------------------------------------
      // PHASE 1: TRADES RECONCILIATION
      // ----------------------------------------------------
      const brokerTrades = await adapter.getTradeBook(token, clientCode);
      const dbTrades = await this.prisma.trade.findMany({
        where: { userId },
        include: {
          orders: true,
          signal: true,
        },
      });

      // Match trades using matching strategy
      const dbMatchedIds = new Set<string>();
      const brokerMatchedIndices = new Set<number>();

      for (const dbTrade of dbTrades) {
        let matchedIndex = -1;

        if (dbTrade.brokerTradeId) {
          matchedIndex = brokerTrades.findIndex(
            (bt: any) => bt.tradeId === dbTrade.brokerTradeId,
          );
        }

        if (matchedIndex === -1 && dbTrade.orders && dbTrade.orders.length > 0) {
          // Fallback to match by order id
          const brokerOrderIds = dbTrade.orders.map((o: any) => o.brokerOrderId).filter(Boolean);
          matchedIndex = brokerTrades.findIndex((bt: any) =>
            brokerOrderIds.includes(bt.orderId),
          );
        }

        if (matchedIndex === -1) {
          // Fallback: match by symbol + quantity + price + timestamp (within tolerance)
          matchedIndex = brokerTrades.findIndex((bt: any, index: number) => {
            if (brokerMatchedIndices.has(index)) return false;
            const matchesSymbol = bt.symbol === dbTrade.signal?.symbol; // check symbol
            const matchesQty = bt.quantity === dbTrade.quantity;
            const priceDiff = Math.abs(bt.price - Number(dbTrade.entryPrice || 0));
            const maxPrice = Math.max(bt.price, Number(dbTrade.entryPrice || 0));
            const matchesPrice = maxPrice === 0 || priceDiff / maxPrice <= reconPriceTolerance;
            return matchesSymbol && matchesQty && matchesPrice;
          });
        }

        if (matchedIndex !== -1) {
          dbMatchedIds.add(dbTrade.id);
          brokerMatchedIndices.add(matchedIndex);

          // Check for price difference warning
          const brokerTrade = brokerTrades[matchedIndex];
          const priceDiff = Math.abs(brokerTrade.price - Number(dbTrade.entryPrice || 0));
          const maxPrice = Math.max(brokerTrade.price, Number(dbTrade.entryPrice || 0));
          if (maxPrice > 0 && priceDiff / maxPrice > reconPriceTolerance) {
            // Price Mismatch
            await this.registerIssue(
              runId,
              userId,
              brokerId,
              ReconciliationIssueType.ORDER_STATUS_MISMATCH,
              Severity.WARNING,
              dbTrade.id,
              { price: brokerTrade.price },
              { price: dbTrade.entryPrice },
            );
            issuesFoundCount++;
          }
        }
      }

      // Missing in DB (exists in broker but not matched locally)
      for (let i = 0; i < brokerTrades.length; i++) {
        if (!brokerMatchedIndices.has(i)) {
          const bt = brokerTrades[i];
          await this.registerIssue(
            runId,
            userId,
            brokerId,
            ReconciliationIssueType.TRADE_MISSING_IN_DB,
            Severity.CRITICAL,
            bt.tradeId || bt.orderId || 'unknown',
            bt,
            {},
          );
          issuesFoundCount++;
        }
      }

      // Missing in Broker (exists in DB but not matched at broker)
      for (const dbTrade of dbTrades) {
        if (!dbMatchedIds.has(dbTrade.id)) {
          await this.registerIssue(
            runId,
            userId,
            brokerId,
            ReconciliationIssueType.TRADE_MISSING_IN_BROKER,
            Severity.CRITICAL,
            dbTrade.id,
            {},
            { id: dbTrade.id, quantity: dbTrade.quantity, price: dbTrade.entryPrice },
          );
          issuesFoundCount++;
        }
      }

      // ----------------------------------------------------
      // PHASE 2: ORDERS RECONCILIATION
      // ----------------------------------------------------
      const dbOrders = await this.prisma.order.findMany({
        where: {
          trade: { userId },
          status: { in: [OrderStatus.PENDING, OrderStatus.PLACED, OrderStatus.PARTIALLY_FILLED] },
        },
        include: { trade: true },
      });

      for (const order of dbOrders) {
        if (!order.brokerOrderId) continue;

        try {
          const brokerDetails = await adapter.getOrderDetails(token, clientCode, order.brokerOrderId);
          const brokerMappedStatus = this.mapOrderStatus(brokerDetails.status);

          if (brokerMappedStatus !== order.status) {
            // Check for safe auto-resolution (e.g. PENDING/PLACED -> FILLED/REJECTED/CANCELLED)
            if (
              (order.status === OrderStatus.PENDING || order.status === OrderStatus.PLACED || order.status === OrderStatus.PARTIALLY_FILLED) &&
              (brokerMappedStatus === OrderStatus.FILLED || brokerMappedStatus === OrderStatus.REJECTED || brokerMappedStatus === OrderStatus.CANCELLED)
            ) {
              await this.applyAutoResolution(order.id, brokerMappedStatus, userId);
              await this.registerIssue(
                runId,
                userId,
                brokerId,
                ReconciliationIssueType.ORDER_STATUS_MISMATCH,
                Severity.WARNING,
                order.id,
                { status: brokerMappedStatus },
                { status: order.status },
                ReconciliationIssueStatus.RESOLVED,
              );
              this.metrics.incrementReconciliationAutoResolved(brokerCode);
            } else {
              // Non-resolvable mismatch or warning
              await this.registerIssue(
                runId,
                userId,
                brokerId,
                ReconciliationIssueType.ORDER_STATUS_MISMATCH,
                Severity.WARNING,
                order.id,
                { status: brokerMappedStatus },
                { status: order.status },
              );
              issuesFoundCount++;
            }
          }
        } catch (err) {
          this.logger.error(`Failed to fetch order details for ${order.brokerOrderId}: ${err.message}`);
        }
      }

      // ----------------------------------------------------
      // PHASE 3: POSITIONS RECONCILIATION
      // ----------------------------------------------------
      const brokerPositions = await adapter.getPositions(token, clientCode);
      const dbPositions = await this.prisma.position.findMany({
        where: { trade: { userId }, status: PositionStatus.OPEN },
      });

      const matchedSymbols = new Set<string>();

      for (const bp of brokerPositions) {
        matchedSymbols.add(bp.symbol);
        const dbPos = dbPositions.find((p) => p.symbol === bp.symbol);

        if (!dbPos) {
          // Position quantity mismatch (missing in DB but open in Broker)
          if (bp.quantity !== 0) {
            await this.registerIssue(
              runId,
              userId,
              brokerId,
              ReconciliationIssueType.POSITION_QUANTITY_MISMATCH,
              Severity.CRITICAL,
              bp.symbol,
              { quantity: bp.quantity, avgPrice: bp.avgPrice },
              { quantity: 0 },
            );
            issuesFoundCount++;
          }
        } else {
          // Compare quantities
          if (bp.quantity !== dbPos.quantity) {
            await this.registerIssue(
              runId,
              userId,
              brokerId,
              ReconciliationIssueType.POSITION_QUANTITY_MISMATCH,
              Severity.CRITICAL,
              dbPos.id,
              { quantity: bp.quantity },
              { quantity: dbPos.quantity },
            );
            issuesFoundCount++;
          }

          // Compare average price
          const priceDiff = Math.abs(bp.avgPrice - Number(dbPos.avgPrice));
          const maxPrice = Math.max(bp.avgPrice, Number(dbPos.avgPrice));
          if (maxPrice > 0 && priceDiff / maxPrice > reconPriceTolerance) {
            await this.registerIssue(
              runId,
              userId,
              brokerId,
              ReconciliationIssueType.POSITION_PNL_MISMATCH,
              Severity.WARNING,
              dbPos.id,
              { avgPrice: bp.avgPrice },
              { avgPrice: dbPos.avgPrice },
            );
            issuesFoundCount++;
          }
        }
      }

      // Open in DB but closed/missing in Broker
      for (const dbPos of dbPositions) {
        if (!matchedSymbols.has(dbPos.symbol)) {
          await this.registerIssue(
            runId,
            userId,
            brokerId,
            ReconciliationIssueType.POSITION_QUANTITY_MISMATCH,
            Severity.CRITICAL,
            dbPos.id,
            { quantity: 0 },
            { quantity: dbPos.quantity },
          );
          issuesFoundCount++;
        }
      }

      // Update Shard status to completed
      await this.prisma.reconciliationShard.update({
        where: { runId_userId: { runId, userId } },
        data: {
          status: ReconciliationStatus.COMPLETED,
          completedAt: new Date(),
          issuesFound: issuesFoundCount,
        },
      });
    } catch (error) {
      this.logger.error(`Reconciliation shard failed for user ${userId}: ${error.message}`);
      await this.prisma.reconciliationShard.update({
        where: { runId_userId: { runId, userId } },
        data: {
          status: ReconciliationStatus.FAILED,
          completedAt: new Date(),
        },
      });
    } finally {
      // Clear sharded user-broker lock in Redis
      if (this.redisService.isHealthy()) {
        try {
          await this.redisService.getClient().del(userLockKey);
        } catch (err) {
          this.logger.warn(`Failed to release user lock ${userLockKey}: ${err.message}`);
        }
      }

      // Update snapshot of open issues count
      const openIssues = await this.prisma.reconciliationIssue.count({
        where: {
          userId,
          brokerId,
          status: { in: [ReconciliationIssueStatus.OPEN, ReconciliationIssueStatus.INVESTIGATING, ReconciliationIssueStatus.ESCALATED] },
        },
      });

      await this.prisma.reconciliationSnapshot.upsert({
        where: { userId_brokerId: { userId, brokerId } },
        update: {
          openIssues,
          lastReconciledAt: new Date(),
        },
        create: {
          userId,
          brokerId,
          openIssues,
          lastReconciledAt: new Date(),
        },
      });

      // Update Open issues Gauge
      this.metrics.setReconciliationIssuesOpen('unknown', Severity.CRITICAL, brokerCode, openIssues);

      // Check run completion status
      await this.checkRunCompletion(runId);
      this.metrics.observeReconciliationDuration(Date.now() - startTime);
    }
  }

  private mapOrderStatus(brokerStatus: string): OrderStatus {
    const status = brokerStatus.toUpperCase();
    if (status === 'COMPLETE' || status === 'EXECUTED' || status === 'FILLED') return OrderStatus.FILLED;
    if (status === 'REJECTED') return OrderStatus.REJECTED;
    if (status === 'CANCELLED') return OrderStatus.CANCELLED;
    if (status === 'PARTIALLY_FILLED') return OrderStatus.PARTIALLY_FILLED;
    return OrderStatus.PLACED;
  }

  /**
   * Applies safe database status updates for auto-resolving order states.
   */
  private async applyAutoResolution(orderId: string, newStatus: OrderStatus, userId: string): Promise<void> {
    const order = await this.prisma.order.update({
      where: { id: orderId },
      data: { status: newStatus },
      include: { trade: true },
    });

    if (newStatus === OrderStatus.FILLED) {
      // Update associated trade to open/complete if needed
      await this.prisma.trade.update({
        where: { id: order.tradeId },
        data: { status: TradeStatus.OPEN },
      });

      // Create operations audit for RECOVERY_APPLIED
      await this.prisma.operationsAudit.create({
        data: {
          operationId: crypto.randomUUID(),
          operatorId: userId, // auto-resolved on behalf of the user/system
          action: OperationsAction.REPLAY_SIGNAL, // mapped as recovery operation
          status: OperationStatus.SUCCESS,
          resourceType: 'Order',
          resourceId: orderId,
          metadata: { autoResolution: true, newStatus },
        },
      });
    }
  }

  /**
   * Evaluates if all sharded tasks are done and updates the parent run.
   */
  private async checkRunCompletion(runId: string): Promise<void> {
    const run = await this.prisma.reconciliationRun.findUnique({
      where: { id: runId },
      include: { shards: true },
    });

    if (!run) return;

    const allFinished = run.shards.every(
      (s) => s.status === ReconciliationStatus.COMPLETED || s.status === ReconciliationStatus.FAILED,
    );

    if (allFinished) {
      const failedShards = run.shards.some((s) => s.status === ReconciliationStatus.FAILED);
      const totalIssues = run.shards.reduce((acc, s) => acc + s.issuesFound, 0);

      await this.prisma.reconciliationRun.update({
        where: { id: runId },
        data: {
          status: failedShards ? ReconciliationStatus.FAILED : ReconciliationStatus.COMPLETED,
          completedAt: new Date(),
          mismatchesFound: totalIssues,
        },
      });

      // Clean up run lock
      if (this.redisService.isHealthy()) {
        try {
          await this.redisService.getClient().del(`reconciliation:run:${runId}`);
        } catch (err) {
          this.logger.warn(`Failed to release run lock: ${err.message}`);
        }
      }

      this.logger.log(`Reconciliation run ${runId} finished. Mismatches: ${totalIssues}`);
    }
  }

  /**
   * Registers a reconciliation issue with fingerprint deduplication.
   */
  private async registerIssue(
    runId: string,
    userId: string,
    brokerId: string,
    issueType: ReconciliationIssueType,
    severity: Severity,
    resourceId: string,
    brokerValue: any,
    dbValue: any,
    initialStatus: ReconciliationIssueStatus = ReconciliationIssueStatus.OPEN,
  ): Promise<void> {
    // Generate deterministic sha256 fingerprint to avoid duplicate records
    const fingerprintRaw = `${userId}:${brokerId}:${issueType}:${resourceId}`;
    const fingerprint = crypto.createHash('sha256').update(fingerprintRaw).digest('hex');

    const existingIssue = await this.prisma.reconciliationIssue.findUnique({
      where: { fingerprint },
    });

    if (existingIssue && existingIssue.status !== ReconciliationIssueStatus.RESOLVED) {
      // Deduplicate: update last seen, occurrence count, and runId
      await this.prisma.reconciliationIssue.update({
        where: { id: existingIssue.id },
        data: {
          runId,
          lastSeenAt: new Date(),
          occurrenceCount: existingIssue.occurrenceCount + 1,
          brokerValue,
          dbValue,
        },
      });
    } else {
      // Create new issue record
      await this.prisma.reconciliationIssue.create({
        data: {
          runId,
          userId,
          brokerId,
          issueType,
          severity,
          resourceId,
          brokerValue,
          dbValue,
          status: initialStatus,
          fingerprint,
          occurrenceCount: 1,
        },
      });

      // Increment total issues metric
      const ub = await this.prisma.userBroker.findFirst({
        where: { userId },
        include: { broker: true },
      });
      const brokerCode = ub?.broker.code || 'unknown';
      this.metrics.incrementReconciliationIssuesTotal(issueType, severity, brokerCode);

      // Create outbox event for dashboard notification/WebSockets
      await this.outboxService.createEvent('RECONCILIATION_ISSUE', {
        userId,
        brokerId,
        issueType,
        severity,
        resourceId,
        brokerValue,
        dbValue,
      });
    }
  }
}
