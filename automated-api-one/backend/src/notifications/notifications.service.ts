import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import {
  Notification,
  NotificationType,
  NotificationEvent,
  NotificationChannel,
  DeliveryStatus,
} from '@prisma/client';
import { NotificationRateLimiterService } from './notification-rate-limiter.service';
import { NotificationDeduplicationService } from './notification-deduplication.service';
import { NotificationTemplateService } from './notification-template.service';
import { WebsocketService } from '../websocket/services/websocket.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { Queues } from '../infrastructure/queues/queue.constants';
import { WebsocketEvent } from '../websocket/enums/websocket-event.enum';
import { isWithinQuietHours, getNextActiveTime } from './quiet-hours.utility';
import { Cron, CronExpression } from '@nestjs/schedule';

const BYPASS_QUIET_HOURS: NotificationEvent[] = [
  NotificationEvent.RISK_BLOCKED,
  NotificationEvent.STOP_LOSS_HIT,
  NotificationEvent.TARGET_HIT,
  NotificationEvent.ORDER_PLACED,
  NotificationEvent.ORDER_FILLED,
  NotificationEvent.ORDER_REJECTED,
  NotificationEvent.SYSTEM_ALERT,
];

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly rateLimiter: NotificationRateLimiterService,
    private readonly deduplication: NotificationDeduplicationService,
    private readonly templateService: NotificationTemplateService,
    private readonly websocketService: WebsocketService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
  ) {}

  async getHistory(
    userId: string,
    limit = 20,
    offset = 0,
  ): Promise<{ data: Notification[]; total: number }> {
    const [data, total] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.notification.count({
        where: { userId },
      }),
    ]);

    return { data, total };
  }

  async markAsRead(
    userId: string,
    notificationIds: string[],
  ): Promise<{ count: number }> {
    const updateResult = await this.prisma.notification.updateMany({
      where: {
        userId,
        id: {
          in: notificationIds,
        },
      },
      data: {
        delivered: true,
      },
    });

    return { count: updateResult.count };
  }

  /**
   * For backwards compatibility with existing simple tests/flows
   */
  async createNotification(
    userId: string,
    type: NotificationType,
    title: string,
    message: string,
  ): Promise<Notification> {
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        type,
        title,
        message,
        delivered: false,
      },
    });

    console.log(`\n[NOTIFICATION DISPATCH MOCK - ${type}]`);
    console.log(`To User: ${userId}`);
    console.log(`Title: ${title}`);
    console.log(`Message: ${message}\n`);

    return notification;
  }

  /**
   * Main multi-channel notification engine entrypoint
   */
  async sendNotification(
    userId: string,
    event: NotificationEvent,
    data: any,
    batchKey?: string,
  ): Promise<Notification> {
    if (data && data.fingerprint) {
      const isDup = await this.deduplication.shouldDeduplicate(data.fingerprint);
      if (isDup) {
        this.metrics.incrementNotificationDeduplicated(event.toString());
        return {} as any;
      }
    }

    const { title, body } = this.templateService.generateTemplate(event, data);

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { notificationPreferences: true },
    });

    if (!user) {
      throw new Error(`User not found: ${userId}`);
    }

    if (batchKey) {
      const existingNotification = await this.prisma.notification.findFirst({
        where: {
          userId,
          batchKey,
          deliveries: {
            some: {
              status: DeliveryStatus.PENDING,
              scheduledFor: { gte: new Date() },
            },
          },
        },
        include: { deliveries: true },
      });

      if (existingNotification) {
        const updatedMsg = this.aggregateMessage(existingNotification.message, event);
        const updatedTitle = 'Aggregated Trade Events';

        const updatedNotif = await this.prisma.notification.update({
          where: { id: existingNotification.id },
          data: {
            message: updatedMsg,
            title: updatedTitle,
          },
        });

        return updatedNotif;
      }
    }

    const notifType = this.mapEventToType(event);
    const notification = await this.prisma.notification.create({
      data: {
        userId,
        type: notifType,
        title,
        message: batchKey ? `1 ${this.getEventLabel(event)}` : body,
        batchKey,
        delivered: false,
      },
    });

    const isCritical = BYPASS_QUIET_HOURS.includes(event);
    const inQuietHours = user.quietHoursEnabled && isWithinQuietHours(
      new Date(),
      user.quietTimezone || 'Asia/Kolkata',
      user.quietStart || '22:00',
      user.quietEnd || '08:00',
    );

    const targetScheduledTime = (inQuietHours && !isCritical)
      ? getNextActiveTime(new Date(), user.quietTimezone || 'Asia/Kolkata', user.quietEnd || '08:00')
      : (batchKey ? new Date(Date.now() + 60000) : new Date());

    const isDeferred = inQuietHours && !isCritical;
    if (isDeferred) {
      this.metrics.incrementNotificationQuietHourDeferrals();
    }

    const channels: NotificationChannel[] = ['EMAIL', 'SMS', 'WHATSAPP', 'PUSH', 'WEBSOCKET'];
    for (const channel of channels) {
      const pref = user.notificationPreferences.find(p => p.eventType === event && p.channel === channel);
      const isEnabled = pref ? pref.enabled : true;

      if (!isEnabled) continue;

      const isRateLimited = await this.rateLimiter.isRateLimited(userId, channel);
      if (isRateLimited) {
        this.metrics.incrementNotificationRateLimited(channel, userId);
        continue;
      }

      const idempotencyKey = `${notification.id}:${channel}`;

      const delivery = await this.prisma.notificationDelivery.create({
        data: {
          notificationId: notification.id,
          channel,
          status: DeliveryStatus.PENDING,
          provider: this.getChannelProvider(channel),
          idempotencyKey,
          scheduledFor: targetScheduledTime,
        },
      });

      if (channel === 'WEBSOCKET') {
        const wsEvent = this.mapEventToWebsocketEvent(event);
        if (wsEvent) {
          await this.websocketService.broadcast(
            delivery.id,
            wsEvent,
            `user:${userId}`,
            { title, message: body, data },
          );
        }
        await this.prisma.notificationDelivery.update({
          where: { id: delivery.id },
          data: {
            status: DeliveryStatus.SENT,
            sentAt: new Date(),
            deliveredAt: new Date(),
          },
        });
        continue;
      }

      if (isDeferred) {
        this.metrics.incrementNotificationScheduled();
        continue;
      }

      const queueName = this.getChannelQueueName(channel);
      const delay = batchKey ? 60000 : undefined;
      const payload = this.getDeliveryPayload(channel, user, title, body, delivery.id, event, data);

      await this.queueService.addJob(queueName, delivery.id, payload, undefined, delay);
    }

    return notification;
  }

  @Cron(CronExpression.EVERY_MINUTE)
  async processScheduledNotifications(): Promise<void> {
    const now = new Date();
    const deliveries = await this.prisma.notificationDelivery.findMany({
      where: {
        status: DeliveryStatus.PENDING,
        scheduledFor: { lte: now },
      },
      include: {
        notification: {
          include: {
            user: true,
          },
        },
      },
    });

    for (const delivery of deliveries) {
      try {
        const { notification, channel } = delivery;
        const { user, title, message } = notification;

        const isRateLimited = await this.rateLimiter.isRateLimited(user.id, channel);
        if (isRateLimited) {
          this.metrics.incrementNotificationRateLimited(channel, user.id);
          await this.prisma.notificationDelivery.update({
            where: { id: delivery.id },
            data: {
              status: DeliveryStatus.FAILED,
              error: 'Rate limit exceeded during scheduled delivery',
              failedAt: new Date(),
            },
          });
          continue;
        }

        const queueName = this.getChannelQueueName(channel);
        const payload = this.getDeliveryPayload(channel, user, title, message, delivery.id, notification.type, {});
        
        await this.queueService.addJob(queueName, delivery.id, payload, undefined);
      } catch (err) {
        this.logger.error(`Failed to dispatch scheduled delivery ${delivery.id}: ${err.message}`);
      }
    }
  }

  async getPreferences(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        quietHoursEnabled: true,
        quietStart: true,
        quietEnd: true,
        quietTimezone: true,
        notificationPreferences: true,
      },
    });
    return user;
  }

  async updatePreferences(userId: string, dto: any) {
    const { preferences, quietHoursEnabled, quietStart, quietEnd, quietTimezone } = dto;

    await this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: userId },
        data: {
          ...(quietHoursEnabled !== undefined ? { quietHoursEnabled } : {}),
          ...(quietStart !== undefined ? { quietStart } : {}),
          ...(quietEnd !== undefined ? { quietEnd } : {}),
          ...(quietTimezone !== undefined ? { quietTimezone } : {}),
        },
      });

      if (preferences && preferences.length > 0) {
        for (const pref of preferences) {
          await tx.notificationPreference.upsert({
            where: {
              userId_eventType_channel: {
                userId,
                eventType: pref.eventType,
                channel: pref.channel,
              },
            },
            update: { enabled: pref.enabled },
            create: {
              userId,
              eventType: pref.eventType,
              channel: pref.channel,
              enabled: pref.enabled,
            },
          });
        }
      }
    });

    return this.getPreferences(userId);
  }

  private mapEventToType(event: NotificationEvent): NotificationType {
    switch (event) {
      case NotificationEvent.ORDER_PLACED: return NotificationType.TRADE_EXECUTED;
      case NotificationEvent.ORDER_FILLED: return NotificationType.TRADE_EXECUTED;
      case NotificationEvent.ORDER_REJECTED: return NotificationType.TRADE_EXECUTED;
      case NotificationEvent.RISK_BLOCKED: return NotificationType.TRADE_EXECUTED;
      case NotificationEvent.TARGET_HIT: return NotificationType.TARGET_HIT;
      case NotificationEvent.STOP_LOSS_HIT: return NotificationType.SL_HIT;
      default: return NotificationType.TRADE_EXECUTED;
    }
  }

  private getChannelProvider(channel: NotificationChannel): string {
    switch (channel) {
      case 'EMAIL': return 'resend';
      case 'SMS': return 'twilio';
      case 'WHATSAPP': return 'whatsapp-cloud';
      case 'PUSH': return 'fcm';
      default: return 'mock';
    }
  }

  private getChannelQueueName(channel: NotificationChannel): string {
    switch (channel) {
      case 'EMAIL': return Queues.EMAIL;
      case 'SMS': return Queues.SMS;
      case 'WHATSAPP': return Queues.WHATSAPP;
      case 'PUSH': return Queues.PUSH;
      default: return Queues.NOTIFICATION;
    }
  }

  private getDeliveryPayload(
    channel: NotificationChannel,
    user: any,
    title: string,
    body: string,
    deliveryId: string,
    event: any,
    data: any,
  ): any {
    switch (channel) {
      case 'EMAIL':
        return { deliveryId, to: user.email || 'test@example.com', subject: title, body };
      case 'SMS':
        return { deliveryId, to: user.mobile, message: body };
      case 'WHATSAPP':
        return {
          deliveryId,
          to: user.mobile,
          templateName: event.toString().toLowerCase(),
          parameters: [user.firstName || 'User', body],
        };
      case 'PUSH':
        return { deliveryId, token: 'mock-token', title, body };
      default:
        return { deliveryId, userId: user.id, title, body };
    }
  }

  private mapEventToWebsocketEvent(event: NotificationEvent): WebsocketEvent | null {
    switch (event) {
      case NotificationEvent.ORDER_PLACED: return WebsocketEvent.SIGNAL_RECEIVED;
      case NotificationEvent.ORDER_FILLED: return WebsocketEvent.ORDER_EXECUTED;
      case NotificationEvent.ORDER_REJECTED: return WebsocketEvent.ORDER_REJECTED;
      case NotificationEvent.RISK_BLOCKED: return WebsocketEvent.RISK_LOCKED;
      case NotificationEvent.TARGET_HIT: return WebsocketEvent.TARGET_HIT;
      case NotificationEvent.STOP_LOSS_HIT: return WebsocketEvent.STOPLOSS_HIT;
      case NotificationEvent.SUBSCRIPTION_EXPIRED: return WebsocketEvent.SUBSCRIPTION_EXPIRED;
      case NotificationEvent.BROKER_DISCONNECTED: return WebsocketEvent.BROKER_DISCONNECTED;
      default: return null;
    }
  }

  private aggregateMessage(existingMsg: string, newEvent: NotificationEvent): string {
    const lines = existingMsg.split('\n').filter(Boolean);
    const counts: Record<string, number> = {};
    
    for (const line of lines) {
      const match = line.match(/^(\d+)\s+(.+)$/);
      if (match) {
        const qty = parseInt(match[1], 10);
        const text = match[2];
        counts[text] = qty;
      } else {
        counts[line] = 1;
      }
    }

    const label = this.getEventLabel(newEvent);
    counts[label] = (counts[label] || 0) + 1;

    return Object.entries(counts)
      .map(([text, qty]) => `${qty} ${text}`)
      .join('\n');
  }

  private getEventLabel(event: NotificationEvent): string {
    switch (event) {
      case NotificationEvent.TARGET_HIT: return 'targets hit';
      case NotificationEvent.ORDER_FILLED: return 'orders filled';
      case NotificationEvent.ORDER_PLACED: return 'orders placed';
      case NotificationEvent.ORDER_REJECTED: return 'orders rejected';
      case NotificationEvent.RISK_BLOCKED: return 'risk violations';
      default: return 'alerts';
    }
  }
}
