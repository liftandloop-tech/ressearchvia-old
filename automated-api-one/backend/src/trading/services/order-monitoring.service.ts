import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma.service';
import { BrokerFactory } from '../../brokers/factory/broker.factory';
import { BrokerType } from '../../brokers/interfaces/broker-type.enum';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { OutboxService } from '../../infrastructure/outbox/outbox.service';
import { AuditService } from '../../audit/audit.service';
import { AuditEventType } from '../../audit/enums/audit-event.enum';
import { PositionCacheService } from './position-cache.service';
import { MultiplierService } from './multiplier.service';
import { ConfigService } from '@nestjs/config';
import { OrderStatus, TradeStatus } from '@prisma/client';

import { MetricsService } from '../../infrastructure/metrics/metrics.service';

export interface MonitoringResult {
  finalStatus: 'FILLED' | 'CANCELLED' | 'REJECTED' | 'EXPIRED' | 'PENDING';
  brokerOrderId: string;
  reason?: string;
}

@Injectable()
export class OrderMonitoringService {
  private readonly logger = new Logger(OrderMonitoringService.name);
  private readonly brokerTimeoutMs: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly brokerFactory: BrokerFactory,
    private readonly circuitBreaker: CircuitBreakerService,
    private readonly outbox: OutboxService,
    private readonly auditService: AuditService,
    private readonly positionCache: PositionCacheService,
    private readonly multiplierService: MultiplierService,
    private readonly configService: ConfigService,
    private readonly metrics: MetricsService,
  ) {
    this.brokerTimeoutMs = this.configService.get<number>('BROKER_TIMEOUT_MS', 5000);
  }

  /**
   * Polls broker for the latest status of an open order and reconciles
   * the Trade/Order state accordingly.
   *
   * Triggers multiplier advance on FAILED/REJECTED, reset on FILLED.
   */
  async pollOrderStatus(
    orderId: string,
    correlationId: string,
  ): Promise<MonitoringResult> {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { trade: true },
    });

    if (!order) {
      this.logger.warn(`[${correlationId}] Order ${orderId} not found for monitoring`);
      return { finalStatus: 'PENDING', brokerOrderId: '', reason: 'Order not found' };
    }

    if (!order.brokerOrderId) {
      return { finalStatus: 'PENDING', brokerOrderId: '', reason: 'No broker order ID' };
    }

    const trade = order.trade;

    // Get broker credentials
    const userBroker = await this.prisma.userBroker.findFirst({
      where: { userId: trade.userId, brokerId: trade.brokerId },
      include: { broker: true },
    });

    if (!userBroker?.accessToken) {
      return { finalStatus: 'PENDING', brokerOrderId: order.brokerOrderId!, reason: 'No broker session' };
    }

    const brokerCode = userBroker.broker.code as unknown as BrokerType;
    const adapter = this.brokerFactory.getAdapter(brokerCode);

    // Poll broker with circuit breaker + timeout
    let brokerStatus: string;
    try {
      const statusResult = await this.circuitBreaker.execute(
        userBroker.broker.code as string,
        () =>
          Promise.race([
            adapter.getOrderStatus(
              userBroker.accessToken!,
              userBroker.brokerClientId,
              order.brokerOrderId!,
            ),
            new Promise<never>((_, reject) =>
              setTimeout(
                () => reject(new Error(`Status poll timeout after ${this.brokerTimeoutMs}ms`)),
                this.brokerTimeoutMs,
              ),
            ),
          ]),
      );
      brokerStatus = statusResult.status;
    } catch (err) {
      this.logger.warn(
        `[${correlationId}] Failed to poll order ${orderId}: ${err.message}`,
      );
      return {
        finalStatus: 'PENDING',
        brokerOrderId: order.brokerOrderId!,
        reason: err.message,
      };
    }

    // Reconcile terminal states
    if (brokerStatus === 'FILLED' || brokerStatus === 'COMPLETE' || brokerStatus === 'EXECUTED') {
      await this.reconcileFilled(order.id, trade.id, trade.userId, trade.segmentId, correlationId);
      return { finalStatus: 'FILLED', brokerOrderId: order.brokerOrderId! };
    }

    if (['CANCELLED', 'REJECTED', 'EXPIRED'].includes(brokerStatus)) {
      const mapped = brokerStatus as 'CANCELLED' | 'REJECTED' | 'EXPIRED';
      await this.reconcileFailed(order.id, trade.id, trade.userId, trade.segmentId, mapped, correlationId);
      return { finalStatus: mapped, brokerOrderId: order.brokerOrderId! };
    }

    // Non-terminal — still waiting
    return { finalStatus: 'PENDING', brokerOrderId: order.brokerOrderId! };
  }

  private async reconcileFilled(
    orderId: string,
    tradeId: string,
    userId: string,
    segmentId: string,
    correlationId: string,
  ): Promise<void> {
    const event = await this.prisma.$transaction(async (tx) => {
      await tx.order.update({
        where: { id: orderId },
        data: { status: OrderStatus.FILLED },
      });

      await tx.trade.update({
        where: { id: tradeId },
        data: { status: TradeStatus.OPEN },
      });

      const evt = await this.outbox.createEvent(
        'ORDER_FILLED',
        { version: 1, correlationId, orderId, tradeId, userId, segmentId },
        tx,
      );
      return evt;
    });

    await this.outbox.enqueueEvent(event.id);

    this.metrics.incrementOrdersFilled();

    // Reset multiplier on successful fill
    await this.multiplierService.resetOnWin(userId, segmentId);

    await this.auditService.logEvent(
      userId,
      AuditEventType.ORDER_FILLED,
      'Order',
      orderId,
      { correlationId, tradeId },
    );
  }

  private async reconcileFailed(
    orderId: string,
    tradeId: string,
    userId: string,
    segmentId: string,
    failStatus: 'CANCELLED' | 'REJECTED' | 'EXPIRED',
    correlationId: string,
  ): Promise<void> {
    const orderStatusMap: Record<string, OrderStatus> = {
      CANCELLED: OrderStatus.CANCELLED,
      REJECTED: OrderStatus.REJECTED,
      EXPIRED: OrderStatus.EXPIRED,
    };

    const event = await this.prisma.$transaction(async (tx) => {
      await tx.order.update({
        where: { id: orderId },
        data: { status: orderStatusMap[failStatus] },
      });

      await tx.trade.update({
        where: { id: tradeId },
        data: { status: TradeStatus.FAILED },
      });

      const evt = await this.outbox.createEvent(
        'ORDER_FAILED',
        { version: 1, correlationId, orderId, tradeId, userId, segmentId, failStatus },
        tx,
      );
      return evt;
    });

    await this.outbox.enqueueEvent(event.id);

    this.metrics.incrementOrdersRejected();

    // Advance multiplier on failed order
    await this.multiplierService.advanceOnLoss(userId, segmentId);

    // Clear stale position cache
    await this.positionCache.del(userId, segmentId);

    this.logger.warn(
      `[${correlationId}] Order ${orderId} terminal status: ${failStatus}. Multiplier advanced.`,
    );
  }
}
