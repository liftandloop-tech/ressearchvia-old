/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment */
import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { Consent, ConsentStatus } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { AuditEventType } from '../audit/enums/audit-event.enum';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '@prisma/client';
import { Cron } from '@nestjs/schedule';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { PositionSizingService } from '../trading/services/position-sizing.service';
import { StrategyType, StrategyChangeSource } from '@prisma/client';

export function getTodayISTString(date: Date = new Date()): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kolkata',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

@Injectable()
export class ConsentsService {
  private readonly logger = new Logger(ConsentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
    private readonly notificationsService: NotificationsService,
    private readonly subscriptionsService: SubscriptionsService,
    private readonly positionSizingService: PositionSizingService,
  ) {}

  async hasTodayConsent(userId: string): Promise<boolean> {
    const activeUserBroker = await this.prisma.userBroker.findFirst({
      where: { userId, status: 'ACTIVE' },
    });

    if (!activeUserBroker) {
      return false;
    }

    const todayStr = getTodayISTString();
    const todayDate = new Date(`${todayStr}T00:00:00.000Z`);

    const consent = await this.prisma.consent.findFirst({
      where: {
        userId,
        brokerId: activeUserBroker.brokerId,
        consentDate: todayDate,
        status: ConsentStatus.ACTIVE,
      },
    });

    return !!consent;
  }

  async grantConsent(userId: string, brokerId: string): Promise<Consent> {
    // 1. Resolve brokerId (could be UUID, code, or BROKER_ prefixed code)
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(brokerId);
    let broker = isUuid
      ? await this.prisma.broker.findUnique({
          where: { id: brokerId },
        })
      : null;

    if (!broker) {
      const normalizedCode = brokerId.replace(/^BROKER_/, '');
      broker = await this.prisma.broker.findFirst({
        where: {
          code: normalizedCode as any,
        },
      });
    }

    if (!broker) {
      throw new BadRequestException(
        `Broker with identifier ${brokerId} not found`,
      );
    }

    // 2. Verify active link exists
    const userBroker = await this.prisma.userBroker.findFirst({
      where: {
        userId,
        brokerId: broker.id,
        status: 'ACTIVE',
      },
    });

    if (!userBroker) {
      throw new BadRequestException(
        'User does not have an active linked account for this broker',
      );
    }

    const todayStr = getTodayISTString();
    const todayDate = new Date(`${todayStr}T00:00:00.000Z`);

    // 3. Upsert consent record (bypass soft-delete filter using baseClient)
    const existingConsent = await this.prisma.baseClient.consent.findFirst({
      where: {
        userId,
        brokerId: broker.id,
        consentDate: todayDate,
      },
    });

    let consent;
    if (existingConsent) {
      consent = await this.prisma.baseClient.consent.update({
        where: { id: existingConsent.id },
        data: {
          status: ConsentStatus.ACTIVE,
          deletedAt: null, // Undelete/Restore the record
        },
      });
    } else {
      consent = await this.prisma.baseClient.consent.create({
        data: {
          userId,
          brokerId: broker.id,
          consentDate: todayDate,
          status: ConsentStatus.ACTIVE,
        },
      });
    }

    // 4. Log Audit Event
    await this.auditService.logEvent(
      userId,
      AuditEventType.CONSENT_GRANTED,
      'Consent',
      consent.id,
      { brokerCode: broker.code, consentDate: todayStr },
    );

    // 5. Send Notification
    await this.notificationsService.createNotification(
      userId,
      NotificationType.CONSENT_GRANTED,
      'Automated Trading Consent Activated',
      'Automated trading consent activated for today.',
    );

    return consent;
  }

  async grantConsentWithStrategy(
    userId: string,
    params: {
      brokerId: string;
      strategy?: StrategyType;
      baseMultiplier?: number;
      consentAccepted?: boolean;
      agreementVersion?: string;
      ipAddress?: string | null;
      userAgent?: string | null;
    },
  ): Promise<Consent> {
    const consent = await this.grantConsent(userId, params.brokerId);

    if (params.strategy) {
      // 1. Log statutory consent in TradingStrategyConsent
      const stratConsent = await (this.prisma as any).tradingStrategyConsent.create({
        data: {
          userId,
          brokerId: consent.brokerId,
          strategyType: params.strategy,
          baseMultiplier: params.baseMultiplier ?? 1,
          agreementVersion: params.agreementVersion ?? 'v1.0',
          consentVersion: 'v1.0',
          ipAddress: params.ipAddress,
          userAgent: params.userAgent,
          status: 'ACCEPTED',
          acceptedAt: new Date(),
        },
      });

      // 2. Check current strategy
      const currentStrategy = await this.positionSizingService.getUserStrategy(userId);
      if (currentStrategy.strategyType !== params.strategy) {
        // Strategy changed -> switch to new with fresh 1x cycle
        await this.positionSizingService.switchStrategy(
          userId,
          null,
          params.strategy,
          params.agreementVersion ?? 'v1.0',
          'USER',
          StrategyChangeSource.USER_CONSENT,
          stratConsent.id,
        );
      } else {
        // Same strategy, ensure agreementVersion & consentAccepted are marked
        await (this.prisma as any).userTradingStrategy.updateMany({
          where: { userId },
          data: {
            consentAccepted: true,
            agreementVersion: params.agreementVersion ?? 'v1.0',
            strategySelectedAt: new Date(),
          },
        });
      }
    }

    return consent;
  }

  async getUserStrategyDetails(userId: string) {
    const [strategy, systemConfig] = await Promise.all([
      this.positionSizingService.getUserStrategy(userId),
      this.positionSizingService.getSystemConfig(),
    ]);

    return {
      strategy,
      systemConfig,
    };
  }

  async changeUserStrategy(
    userId: string,
    newStrategy: StrategyType,
    agreementVersion: string,
    ipAddress?: string | null,
    userAgent?: string | null,
  ) {
    // Statutory consent record
    const consent = await (this.prisma as any).tradingStrategyConsent.create({
      data: {
        userId,
        strategyType: newStrategy,
        agreementVersion,
        consentVersion: 'v1.0',
        ipAddress,
        userAgent,
        status: 'ACCEPTED',
        acceptedAt: new Date(),
      },
    });

    const updated = await this.positionSizingService.switchStrategy(
      userId,
      null,
      newStrategy,
      agreementVersion,
      'USER',
      StrategyChangeSource.USER_SETTINGS_CHANGE,
      consent.id,
    );

    return updated;
  }

  async getStrategyHistory(userId: string) {
    return (this.prisma as any).strategyChangeHistory.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async getConsentStatus(userId: string): Promise<{
    active: boolean;
    broker: string | null;
    consentDate: string | null;
    status: string;
  }> {
    const activeUserBroker = await this.prisma.userBroker.findFirst({
      where: { userId, status: 'ACTIVE' },
      include: { broker: true },
    });

    if (!activeUserBroker) {
      return { active: false, broker: null, consentDate: null, status: 'NOT_GRANTED' };
    }

    const todayStr = getTodayISTString();
    const todayDate = new Date(`${todayStr}T00:00:00.000Z`);

    const consent = await this.prisma.consent.findFirst({
      where: {
        userId,
        brokerId: activeUserBroker.brokerId,
        consentDate: todayDate,
      },
    });

    if (!consent) {
      return {
        active: false,
        broker: activeUserBroker.broker.code,
        consentDate: todayStr,
        status: 'NOT_GRANTED',
      };
    }

    // Dynamic check
    const active = consent.status === ConsentStatus.ACTIVE;

    return {
      active,
      broker: activeUserBroker.broker.code,
      consentDate: todayStr,
      status: consent.status,
    };
  }

  async revokeConsent(userId: string): Promise<Consent> {
    const activeUserBroker = await this.prisma.userBroker.findFirst({
      where: { userId, status: 'ACTIVE' },
    });

    if (!activeUserBroker) {
      throw new BadRequestException('No active broker connection found');
    }

    const todayStr = getTodayISTString();
    const todayDate = new Date(`${todayStr}T00:00:00.000Z`);

    const existing = await this.prisma.consent.findFirst({
      where: {
        userId,
        brokerId: activeUserBroker.brokerId,
        consentDate: todayDate,
      },
    });

    if (!existing) {
      throw new BadRequestException('No consent found to revoke today');
    }

    const consent = await this.prisma.consent.update({
      where: { id: existing.id },
      data: {
        status: ConsentStatus.REVOKED,
      },
    });

    // Log Audit Event
    await this.auditService.logEvent(
      userId,
      AuditEventType.CONSENT_REVOKED,
      'Consent',
      consent.id,
      { consentDate: todayStr },
    );

    // Send Notification
    await this.notificationsService.createNotification(
      userId,
      NotificationType.CONSENT_REVOKED,
      'Automated Trading Consent Revoked',
      'Automated trading consent revoked. All Segment executions paused.',
    );

    return consent;
  }

  @Cron('0 0 8 * * *', { timeZone: 'Asia/Kolkata' })
  async sendConsentReminders() {
    if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
      return;
    }
    this.logger.log(
      'Running scheduled daily consent reminders check at 08:00 AM IST',
    );

    // 1. Fetch active segment allocations
    const activeAllocations = await this.prisma.userSegment.findMany({
      where: { status: 'ACTIVE' },
      select: { userId: true },
    });

    const uniqueUserIds = [...new Set(activeAllocations.map((a) => a.userId))];

    for (const userIdUnknown of uniqueUserIds) {
      const userId = userIdUnknown as string;
      try {
        // 2. Validate user has active subscription
        const subValidation =
          await this.subscriptionsService.validateSubscription(userId);
        if (!subValidation.active) {
          continue;
        }

        // 3. Check if user already consented for today
        const hasConsent = await this.hasTodayConsent(userId);
        if (!hasConsent) {
          // 4. Send Consent Pending reminder
          await this.notificationsService.createNotification(
            userId,
            NotificationType.CONSENT_PENDING,
            'Trading Consent Required',
            "Today's trading consent is pending. Please approve automated trading.",
          );
        }
      } catch (err) {
        this.logger.error(
          `Failed to process consent reminder for user ${userId}: ${err.message}`,
        );
      }
    }
  }
}
