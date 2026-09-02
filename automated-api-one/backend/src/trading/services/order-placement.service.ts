import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { BrokerFactory } from '../../brokers/factory/broker.factory';
import { BrokerType } from '../../brokers/interfaces/broker-type.enum';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { BrokerRateLimiterService } from '../../infrastructure/redis/broker-rate-limiter.service';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { RedisKeys } from '../../infrastructure/redis/redis-keys';
import { AuditService } from '../../audit/audit.service';
import { AuditEventType } from '../../audit/enums/audit-event.enum';
import { PositionCacheService } from './position-cache.service';
import { ExecutionContext } from '../interfaces/execution-context.interface';
import { ConfigService } from '@nestjs/config';
import { OrderType, OrderStatus, TradeStatus } from '@prisma/client';
import { RiskService } from '../../risk/risk.service';
import { EgressService } from '../../egress/egress.service';
import { Optional } from '@nestjs/common';

import { MetricsService } from '../../infrastructure/metrics/metrics.service';

export interface PlacementResult {
  success: boolean;
  tradeId?: string;
  orderId?: string;
  brokerOrderId?: string;
  reason?: string;
}

@Injectable()
export class OrderPlacementService {
  private readonly logger = new Logger(OrderPlacementService.name);
  private readonly brokerTimeoutMs: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly brokerFactory: BrokerFactory,
    private readonly circuitBreaker: CircuitBreakerService,
    private readonly rateLimiter: BrokerRateLimiterService,
    private readonly outbox: OutboxService,
    private readonly redisService: RedisService,
    private readonly auditService: AuditService,
    private readonly positionCache: PositionCacheService,
    private readonly configService: ConfigService,
    private readonly metrics: MetricsService,
    private readonly riskService: RiskService,
    @Optional() private readonly egressService?: EgressService,
  ) {
    this.brokerTimeoutMs = this.configService.get<number>('BROKER_TIMEOUT_MS', 5000);
  }

  /**
   * Places an entry order for a single user execution context.
   *
   * Execution flow:
   *   0. Synchronous Portfolio Risk check
   *   1. Rate limiter check (Redis ZSET sliding window)
   *   2. Broker API call guarded by:
   *      - Circuit breaker (fail-fast if broker is OPEN)
   *      - 5-second timeout via Promise.race (broker must not run forever)
   *   3. Prisma $transaction: Trade + Order records created atomically
   *   4. Outbox event appended inside same transaction
   *   5. Position cached in Redis on success
   */
  async placeEntryOrder(ctx: ExecutionContext): Promise<PlacementResult> {
    const { snapshot, correlationId, signalId, symbol, exchange, side, entryPrice, stopLoss, targetPrice } = ctx;
    const { userId, brokerId, brokerCode, brokerClientId, effectiveLot } = snapshot;

    this.logger.log(
      `[${correlationId}] Placing entry order: user=${userId} symbol=${symbol} lot=${effectiveLot}`,
    );

    // 0. Synchronous Portfolio Risk Check
    const riskDecision = await this.riskService.evaluateRisk(
      userId,
      symbol,
      effectiveLot,
      entryPrice,
      brokerId,
      snapshot.segmentId,
    );
    if (!riskDecision.approved) {
      this.logger.warn(`[${correlationId}] Blocked by Risk Engine: ${riskDecision.reason}`);
      return { success: false, reason: `Risk Engine block: ${riskDecision.reason}` };
    }

    // 1. Rate limiter — never place orders if broker is being hammered
    await this.rateLimiter.throttle(brokerCode);

    // 2. Resolve broker access token — Redis first, DB fallback
    const tokenInfo = await this.resolveBrokerToken(userId, brokerId, brokerClientId);
    if (!tokenInfo || !tokenInfo.accessToken) {
      this.logger.warn(`[${correlationId}] No active broker session for user ${userId}`);
      return { success: false, reason: 'No active broker session' };
    }

    const adapter = this.brokerFactory.getAdapter(brokerCode as BrokerType);

    // 3. Place order with circuit breaker + 5s timeout
    let brokerOrderId: string | undefined;
    const startPlacement = Date.now();
    try {
      this.metrics.incrementOrdersPlaced();
      this.metrics.incrementBrokerCalls(brokerCode);
      this.metrics.incrementOrderPlacementAttempts();
      const orderResult = await this.circuitBreaker.execute(
        brokerCode,
        () =>
          Promise.race([
            adapter.placeOrder(tokenInfo.accessToken!, brokerClientId, {
              symbol,
              exchange,
              side,
              quantity: effectiveLot,
              orderType: ctx.orderType,
              price: entryPrice,
              triggerPrice: stopLoss,
              squareoff: targetPrice ? Math.abs(entryPrice - targetPrice) : undefined,
              stoploss: stopLoss ? Math.abs(entryPrice - stopLoss) : undefined,
            }, tokenInfo.proxyAgent),
            new Promise<never>((_, reject) =>
              setTimeout(
                () => reject(new Error(`Broker API timeout after ${this.brokerTimeoutMs}ms`)),
                this.brokerTimeoutMs,
              ),
            ),
          ]),
      );
      if (orderResult.status === 'REJECTED' || !orderResult.brokerOrderId) {
        throw new Error(orderResult.message || 'Order rejected by broker');
      }
      brokerOrderId = orderResult.brokerOrderId;
      const duration = Date.now() - startPlacement;
      this.metrics.observeBrokerLatency(brokerCode, duration);
      this.metrics.observeOrderPlacementDuration(duration);
      this.metrics.incrementExecutionSuccess();
    } catch (err) {
      this.metrics.incrementExecutionFailed();
      this.metrics.incrementBrokerFailures(brokerCode);
      if (err.message && err.message.toLowerCase().includes('timeout')) {
        this.metrics.incrementBrokerTimeouts(brokerCode);
      }
      this.metrics.incrementOrdersRejected();

      this.logger.error(
        `[${correlationId}] Broker order placement failed for user ${userId}: ${err.message}`,
      );
      return { success: false, reason: err.message };
    }

    // 4. Atomic DB write: Trade + Order + Outbox inside one Prisma transaction
    let tradeId: string;
    let orderId: string;

    try {
      const result = await this.prisma.$transaction(async (tx) => {
        // Create Trade
        const trade = await tx.trade.create({
          data: {
            correlationId,
            userId,
            signalId,
            segmentId: snapshot.segmentId,
            brokerId,
            quantity: effectiveLot,
            multiplier: snapshot.multiplierValue,
            entryPrice,
            status: TradeStatus.OPEN,
          },
        });

        // Create Order
        const order = await tx.order.create({
          data: {
            correlationId,
            tradeId: trade.id,
            brokerOrderId,
            orderType: ctx.orderType,
            quantity: effectiveLot,
            price: entryPrice,
            status: OrderStatus.PLACED,
          },
        });

        // Append Outbox event inside same transaction
        const outboxEvent = await this.outbox.createEvent(
          'TRADE_OPENED',
          {
            version: 1,
            correlationId,
            tradeId: trade.id,
            orderId: order.id,
            userId,
            segmentId: snapshot.segmentId,
            symbol,
            side,
            quantity: effectiveLot,
            entryPrice,
            brokerOrderId,
          },
          tx,
        );

        return { trade, order, outboxEvent };
      });

      tradeId = result.trade.id;
      orderId = result.order.id;
      await this.outbox.enqueueEvent(result.outboxEvent.id);
    } catch (err) {
      this.logger.error(
        `[${correlationId}] DB transaction failed after successful broker call: ${err.message}. ` +
          `Broker order ${brokerOrderId} may need manual reconciliation.`,
      );
      return { success: false, reason: `DB write failed: ${err.message}` };
    }

    // 5. Cache position in Redis (best-effort, non-blocking)
    await this.positionCache.set({
      userId,
      segmentId: snapshot.segmentId,
      tradeId,
      symbol,
      quantity: effectiveLot,
      entryPrice,
      stopLoss: ctx.stopLoss,
      targetPrice: ctx.targetPrice,
      side,
      cachedAt: new Date().toISOString(),
    });

    // 6. Audit log
    await this.auditService.logEvent(
      userId,
      AuditEventType.TRADE_OPENED,
      'Trade',
      tradeId,
      { correlationId, brokerOrderId, symbol, side, quantity: effectiveLot, entryPrice },
    );

    this.logger.log(
      `[${correlationId}] Entry order placed: tradeId=${tradeId} orderId=${orderId} brokerOrderId=${brokerOrderId}`,
    );

    return { success: true, tradeId, orderId, brokerOrderId };
  }

  /**
   * Resolves broker access token using Redis-first, DB-fallback strategy.
   *
   * Lookup order:
   *   1. Redis `broker:session:{userId}:{brokerId}` (warm cache from BrokerSessionService)
   *   2. Database `UserBroker.accessToken` (cold path, ~2ms extra latency)
   *
   * At 10,000 concurrent orders, Redis-first prevents a thundering herd of
   * simultaneous DB reads for the same broker session records.
   */
  private async resolveBrokerToken(
    userId: string,
    brokerId: string,
    brokerClientId: string,
  ): Promise<{ accessToken: string | null; proxyAgent?: any }> {
    this.logger.log(`[resolveBrokerToken] Resolving token & proxy for user=${userId}, brokerId=${brokerId}, clientId=${brokerClientId}`);
    
    // Create HttpsProxyAgent helper inside this file or import it
    const { createProxyAgent } = require('../../infrastructure/proxy-agent.util');

    // Resolve dedicated egress proxy agent
    let proxyAgent: any = undefined;
    if (this.egressService) {
      try {
        proxyAgent = await this.egressService.getProxyAgentForUser(userId);
      } catch (err: any) {
        this.logger.warn(`[resolveBrokerToken] EgressService proxy resolution note for user ${userId}: ${err.message}`);
      }
    }

    // 1. Try Redis cache (populated by BrokerSessionService on broker connect/refresh)
    if (this.redisService.isHealthy()) {
      try {
        const sessionKey = RedisKeys.brokerSession(userId, brokerId);
        const cachedRaw = await this.redisService.getClient().get(sessionKey);
        this.logger.log(`[resolveBrokerToken] Redis check for key=${sessionKey}: exists=${!!cachedRaw}`);
        if (cachedRaw) {
          const session = JSON.parse(cachedRaw) as { accessToken: string; proxyIp?: string; proxyPort?: number; proxyUsername?: string; proxyPassword?: string };
          if (session?.accessToken) {
            this.logger.debug(`Broker session for user ${userId} resolved from Redis cache`);
            if (!proxyAgent) {
              const { createProxyAgent } = require('../../infrastructure/proxy-agent.util');
              proxyAgent = createProxyAgent({
                proxyIp: session.proxyIp || null,
                proxyPort: session.proxyPort || null,
                proxyHostname: null,
                proxyUsername: session.proxyUsername || null,
                proxyPassword: session.proxyPassword || null,
              });
            }
            return { accessToken: session.accessToken, proxyAgent };
          }
        }
      } catch (err) {
        this.logger.warn(`Redis broker session read failed for user ${userId}: ${err.message}. Falling back to DB.`);
      }
    } else {
      this.logger.log(`[resolveBrokerToken] Redis is NOT healthy`);
    }

    // 2. DB fallback
    const userBroker = await this.prisma.userBroker.findFirst({
      where: { userId, brokerId },
    });
    this.logger.log(`[resolveBrokerToken] DB fallback result: ${JSON.stringify(userBroker)}`);

    if (userBroker) {
      if (!proxyAgent) {
        const { createProxyAgent } = require('../../infrastructure/proxy-agent.util');
        proxyAgent = createProxyAgent({
          proxyIp: userBroker.proxyIp,
          proxyPort: userBroker.proxyPort,
          proxyHostname: userBroker.proxyHostname,
          proxyUsername: userBroker.proxyUsername,
          proxyPassword: userBroker.proxyPassword,
        });
      }
      return { accessToken: userBroker.accessToken, proxyAgent };
    }

    return { accessToken: null };
  }
}
