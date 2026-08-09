import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { ConfigService } from '@nestjs/config';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { NotificationEvent, AlertSeverity, AlertStatus } from '@prisma/client';
import { Cron, CronExpression } from '@nestjs/schedule';
import { CircuitBreakerService } from '../infrastructure/circuit-breaker/circuit-breaker.service';

@Injectable()
export class AlertingService {
  private readonly logger = new Logger(AlertingService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly metrics: MetricsService,
    private readonly circuitBreaker: CircuitBreakerService,
  ) {}

  /**
   * Triggers an SRE alert. If an alert with the same fingerprint is already OPEN,
   * increments its occurrenceCount. Otherwise, creates a new alert.
   */
  async triggerAlert(
    event: NotificationEvent,
    fingerprint: string,
    details: any,
    severity: AlertSeverity = AlertSeverity.WARNING,
  ): Promise<any> {
    try {
      const openAlert = await this.prisma.sreAlert.findFirst({
        where: {
          fingerprint,
          status: AlertStatus.OPEN,
        },
      });

      if (openAlert) {
        const updated = await this.prisma.sreAlert.update({
          where: { id: openAlert.id },
          data: {
            occurrenceCount: { increment: 1 },
            details: details || {},
            updatedAt: new Date(),
          },
        });
        this.logger.log(`Incremented alert occurrence: ${fingerprint} (${updated.occurrenceCount})`);
        return updated;
      }

      const created = await this.prisma.sreAlert.create({
        data: {
          event,
          fingerprint,
          details: details || {},
          severity,
          status: AlertStatus.OPEN,
          occurrenceCount: 1,
          escalationLevel: 0,
        },
      });

      this.metrics.setSreAlertOpen(await this.getAlertCountByStatus(AlertStatus.OPEN));

      await this.dispatchSlackAlert(created);

      return created;
    } catch (err) {
      this.logger.error(`Failed to trigger alert for ${fingerprint}: ${err.message}`);
    }
  }

  async acknowledgeAlert(alertId: string): Promise<any> {
    const updated = await this.prisma.sreAlert.update({
      where: { id: alertId },
      data: {
        status: AlertStatus.ACKNOWLEDGED,
        updatedAt: new Date(),
      },
    });

    const openCount = await this.getAlertCountByStatus(AlertStatus.OPEN);
    const ackCount = await this.getAlertCountByStatus(AlertStatus.ACKNOWLEDGED);
    this.metrics.setSreAlertOpen(openCount);
    this.metrics.setSreAlertAcknowledged(ackCount);

    this.logger.log(`Alert acknowledged: ${alertId}`);
    return updated;
  }

  async resolveAlert(alertId: string): Promise<any> {
    const updated = await this.prisma.sreAlert.update({
      where: { id: alertId },
      data: {
        status: AlertStatus.RESOLVED,
        resolvedAt: new Date(),
        updatedAt: new Date(),
      },
    });

    const openCount = await this.getAlertCountByStatus(AlertStatus.OPEN);
    const ackCount = await this.getAlertCountByStatus(AlertStatus.ACKNOWLEDGED);
    const resolvedCount = await this.getAlertCountByStatus(AlertStatus.RESOLVED);
    this.metrics.setSreAlertOpen(openCount);
    this.metrics.setSreAlertAcknowledged(ackCount);
    this.metrics.setSreAlertResolved(resolvedCount);

    this.logger.log(`Alert resolved: ${alertId}`);
    return updated;
  }

  private async getAlertCountByStatus(status: AlertStatus): Promise<number> {
    return this.prisma.sreAlert.count({ where: { status } });
  }

  /**
   * Cron check: minutely escalation rules.
   * Slack (0 min) -> Email (5 mins) -> SMS (15 mins) -> PagerDuty (30 mins).
   */
  @Cron(CronExpression.EVERY_MINUTE)
  async escalateOpenAlerts(): Promise<void> {
    const openAlerts = await this.prisma.sreAlert.findMany({
      where: {
        status: AlertStatus.OPEN,
      },
    });

    const now = Date.now();

    for (const alert of openAlerts) {
      const elapsedMins = (now - alert.createdAt.getTime()) / 60000;
      let targetLevel = 0;

      if (elapsedMins >= 30) {
        targetLevel = 3;
      } else if (elapsedMins >= 15) {
        targetLevel = 2;
      } else if (elapsedMins >= 5) {
        targetLevel = 1;
      }

      if (targetLevel > alert.escalationLevel) {
        await this.prisma.sreAlert.update({
          where: { id: alert.id },
          data: {
            escalationLevel: targetLevel,
            lastEscalatedAt: new Date(),
          },
        });

        this.logger.log(`Escalating alert ${alert.id} to level ${targetLevel}`);

        if (targetLevel === 1) {
          await this.dispatchEmailAlert(alert);
        } else if (targetLevel === 2) {
          await this.dispatchSmsAlert(alert);
        } else if (targetLevel === 3) {
          await this.dispatchPagerDutyAlert(alert);
        }
      }
    }
  }

  private async dispatchSlackAlert(alert: any) {
    const webhookUrl = this.config.get<string>('SLACK_WEBHOOK_URL');
    this.logger.log(`[Slack Mock] Dispatching SRE alert ${alert.fingerprint} to webhook ${webhookUrl || 'not configured'}`);
  }

  private async dispatchEmailAlert(alert: any) {
    this.logger.log(`[Email Mock] Dispatching SRE alert escalation ${alert.fingerprint} to on-call email`);
  }

  private async dispatchSmsAlert(alert: any) {
    this.logger.log(`[SMS Mock] Dispatching SRE alert escalation ${alert.fingerprint} to on-call mobile`);
  }

  private async dispatchPagerDutyAlert(alert: any) {
    try {
      await this.circuitBreaker.execute('pagerduty-alerts', async () => {
        const pdRoutingKey = this.config.get<string>('PAGERDUTY_ROUTING_KEY');
        this.logger.log(`[PagerDuty Mock] Dispatching SRE alert escalation ${alert.fingerprint} to PagerDuty with routing key ${pdRoutingKey || 'not configured'}`);
      });
    } catch (err) {
      this.logger.error(`PagerDuty dispatch failed or circuit open: ${err.message}`);
    }
  }
}
