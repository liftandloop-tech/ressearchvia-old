import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { Subscription, SubscriptionStatus } from '@prisma/client';
import { PLANS } from './plans.constants';
import { AuditService } from '../audit/audit.service';
import { AuditEventType } from '../audit/enums/audit-event.enum';
import { RedisService } from '../infrastructure/redis/redis.service';

@Injectable()
export class SubscriptionsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
    private readonly redisService: RedisService,
  ) {}

  async validateSubscription(
    userId: string,
  ): Promise<{ active: boolean; plan: string | null; expiresAt: Date | null }> {
    const now = new Date();
    const sub = await this.prisma.subscription.findFirst({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
        startDate: { lte: now },
        endDate: { gte: now },
      },
      orderBy: { endDate: 'desc' },
    });

    if (!sub) {
      return { active: false, plan: null, expiresAt: null };
    }

    let planName: string | null = null;
    if (sub.planId === PLANS.SPARK.id) {
      planName = PLANS.SPARK.name;
    } else if (sub.planId === PLANS.SPLENDID.id) {
      planName = PLANS.SPLENDID.name;
    }

    return {
      active: true,
      plan: planName,
      expiresAt: sub.endDate,
    };
  }

  async getCurrentSubscription(userId: string): Promise<Subscription | null> {
    const now = new Date();
    return this.prisma.subscription.findFirst({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
        startDate: { lte: now },
        endDate: { gte: now },
      },
      orderBy: { endDate: 'desc' },
    });
  }

  async getSubscriptionHistory(userId: string, page = 1, limit = 20) {
    return this.prisma.subscription.paginate({
      page,
      limit,
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async subscribe(userId: string, planId: string): Promise<Subscription> {
    if (this.redisService.isHealthy()) {
      const isGlobalMaint = await this.redisService.getClient().get('system:maintenance:global');
      const isSubsMaint = await this.redisService.getClient().get('system:maintenance:subscriptions');
      if (isGlobalMaint === 'true' || isSubsMaint === 'true') {
        throw new ServiceUnavailableException('Subscriptions are currently disabled due to system maintenance');
      }
    }

    let plan;
    if (planId === PLANS.SPARK.id) {
      plan = PLANS.SPARK;
    } else if (planId === PLANS.SPLENDID.id) {
      plan = PLANS.SPLENDID;
    } else {
      throw new BadRequestException('Invalid plan ID');
    }

    const now = new Date();
    const durationDays = plan.durationDays;

    // Check for active subscription
    const activeSub = await this.prisma.subscription.findFirst({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
        endDate: { gte: now },
      },
      orderBy: { endDate: 'desc' },
    });

    let startDate = now;
    let isRenewal = false;

    if (activeSub) {
      if (activeSub.planId === planId) {
        // Renewal: extend the endDate (+1s to avoid overlap)
        startDate = new Date(activeSub.endDate.getTime() + 1000);
        isRenewal = true;
      } else {
        // Plan Switch: cancel current immediately and start new today
        await this.prisma.subscription.update({
          where: { id: activeSub.id },
          data: { status: SubscriptionStatus.CANCELLED },
        });

        // Audit the cancellation of the old subscription
        await this.auditService.logEvent(
          userId,
          AuditEventType.SUBSCRIPTION_CANCELLED,
          'Subscription',
          activeSub.id,
          { planId: activeSub.planId, reason: 'Plan Switch' },
        );
      }
    }

    const endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + durationDays);

    const newSub = await this.prisma.subscription.create({
      data: {
        userId,
        planId,
        startDate,
        endDate,
        status: SubscriptionStatus.ACTIVE,
      },
    });

    // Audit the new activation / renewal
    await this.auditService.logEvent(
      userId,
      isRenewal
        ? AuditEventType.SUBSCRIPTION_RENEWED
        : AuditEventType.SUBSCRIPTION_ACTIVATED,
      'Subscription',
      newSub.id,
      { planId, durationDays },
    );

    return newSub;
  }

  async cancelSubscription(id: string, userId: string): Promise<Subscription> {
    const existing = await this.prisma.subscription.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException('Subscription not found');
    }

    if (existing.userId !== userId) {
      throw new ForbiddenException('You do not own this subscription');
    }

    const updated = await this.prisma.subscription.update({
      where: { id },
      data: {
        status: SubscriptionStatus.CANCELLED,
      },
    });

    await this.auditService.logEvent(
      userId,
      AuditEventType.SUBSCRIPTION_CANCELLED,
      'Subscription',
      updated.id,
      { planId: updated.planId, reason: 'User Cancelled' },
    );

    return updated;
  }
}
