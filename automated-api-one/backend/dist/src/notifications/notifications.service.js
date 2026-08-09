"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var NotificationsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const client_1 = require("@prisma/client");
const notification_rate_limiter_service_1 = require("./notification-rate-limiter.service");
const notification_deduplication_service_1 = require("./notification-deduplication.service");
const notification_template_service_1 = require("./notification-template.service");
const websocket_service_1 = require("../websocket/services/websocket.service");
const queues_service_1 = require("../infrastructure/queues/queues.service");
const metrics_service_1 = require("../infrastructure/metrics/metrics.service");
const queue_constants_1 = require("../infrastructure/queues/queue.constants");
const websocket_event_enum_1 = require("../websocket/enums/websocket-event.enum");
const quiet_hours_utility_1 = require("./quiet-hours.utility");
const schedule_1 = require("@nestjs/schedule");
const BYPASS_QUIET_HOURS = [
    client_1.NotificationEvent.RISK_BLOCKED,
    client_1.NotificationEvent.STOP_LOSS_HIT,
    client_1.NotificationEvent.TARGET_HIT,
    client_1.NotificationEvent.ORDER_PLACED,
    client_1.NotificationEvent.ORDER_FILLED,
    client_1.NotificationEvent.ORDER_REJECTED,
    client_1.NotificationEvent.SYSTEM_ALERT,
];
let NotificationsService = NotificationsService_1 = class NotificationsService {
    prisma;
    rateLimiter;
    deduplication;
    templateService;
    websocketService;
    queueService;
    metrics;
    logger = new common_1.Logger(NotificationsService_1.name);
    constructor(prisma, rateLimiter, deduplication, templateService, websocketService, queueService, metrics) {
        this.prisma = prisma;
        this.rateLimiter = rateLimiter;
        this.deduplication = deduplication;
        this.templateService = templateService;
        this.websocketService = websocketService;
        this.queueService = queueService;
        this.metrics = metrics;
    }
    async getHistory(userId, limit = 20, offset = 0) {
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
    async markAsRead(userId, notificationIds) {
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
    async createNotification(userId, type, title, message) {
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
    async sendNotification(userId, event, data, batchKey) {
        if (data && data.fingerprint) {
            const isDup = await this.deduplication.shouldDeduplicate(data.fingerprint);
            if (isDup) {
                this.metrics.incrementNotificationDeduplicated(event.toString());
                return {};
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
                            status: client_1.DeliveryStatus.PENDING,
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
        const inQuietHours = user.quietHoursEnabled && (0, quiet_hours_utility_1.isWithinQuietHours)(new Date(), user.quietTimezone || 'Asia/Kolkata', user.quietStart || '22:00', user.quietEnd || '08:00');
        const targetScheduledTime = (inQuietHours && !isCritical)
            ? (0, quiet_hours_utility_1.getNextActiveTime)(new Date(), user.quietTimezone || 'Asia/Kolkata', user.quietEnd || '08:00')
            : (batchKey ? new Date(Date.now() + 60000) : new Date());
        const isDeferred = inQuietHours && !isCritical;
        if (isDeferred) {
            this.metrics.incrementNotificationQuietHourDeferrals();
        }
        const channels = ['EMAIL', 'SMS', 'WHATSAPP', 'PUSH', 'WEBSOCKET'];
        for (const channel of channels) {
            const pref = user.notificationPreferences.find(p => p.eventType === event && p.channel === channel);
            const isEnabled = pref ? pref.enabled : true;
            if (!isEnabled)
                continue;
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
                    status: client_1.DeliveryStatus.PENDING,
                    provider: this.getChannelProvider(channel),
                    idempotencyKey,
                    scheduledFor: targetScheduledTime,
                },
            });
            if (channel === 'WEBSOCKET') {
                const wsEvent = this.mapEventToWebsocketEvent(event);
                if (wsEvent) {
                    await this.websocketService.broadcast(delivery.id, wsEvent, `user:${userId}`, { title, message: body, data });
                }
                await this.prisma.notificationDelivery.update({
                    where: { id: delivery.id },
                    data: {
                        status: client_1.DeliveryStatus.SENT,
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
    async processScheduledNotifications() {
        const now = new Date();
        const deliveries = await this.prisma.notificationDelivery.findMany({
            where: {
                status: client_1.DeliveryStatus.PENDING,
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
                            status: client_1.DeliveryStatus.FAILED,
                            error: 'Rate limit exceeded during scheduled delivery',
                            failedAt: new Date(),
                        },
                    });
                    continue;
                }
                const queueName = this.getChannelQueueName(channel);
                const payload = this.getDeliveryPayload(channel, user, title, message, delivery.id, notification.type, {});
                await this.queueService.addJob(queueName, delivery.id, payload, undefined);
            }
            catch (err) {
                this.logger.error(`Failed to dispatch scheduled delivery ${delivery.id}: ${err.message}`);
            }
        }
    }
    async getPreferences(userId) {
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
    async updatePreferences(userId, dto) {
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
    mapEventToType(event) {
        switch (event) {
            case client_1.NotificationEvent.ORDER_PLACED: return client_1.NotificationType.TRADE_EXECUTED;
            case client_1.NotificationEvent.ORDER_FILLED: return client_1.NotificationType.TRADE_EXECUTED;
            case client_1.NotificationEvent.ORDER_REJECTED: return client_1.NotificationType.TRADE_EXECUTED;
            case client_1.NotificationEvent.RISK_BLOCKED: return client_1.NotificationType.TRADE_EXECUTED;
            case client_1.NotificationEvent.TARGET_HIT: return client_1.NotificationType.TARGET_HIT;
            case client_1.NotificationEvent.STOP_LOSS_HIT: return client_1.NotificationType.SL_HIT;
            default: return client_1.NotificationType.TRADE_EXECUTED;
        }
    }
    getChannelProvider(channel) {
        switch (channel) {
            case 'EMAIL': return 'resend';
            case 'SMS': return 'twilio';
            case 'WHATSAPP': return 'whatsapp-cloud';
            case 'PUSH': return 'fcm';
            default: return 'mock';
        }
    }
    getChannelQueueName(channel) {
        switch (channel) {
            case 'EMAIL': return queue_constants_1.Queues.EMAIL;
            case 'SMS': return queue_constants_1.Queues.SMS;
            case 'WHATSAPP': return queue_constants_1.Queues.WHATSAPP;
            case 'PUSH': return queue_constants_1.Queues.PUSH;
            default: return queue_constants_1.Queues.NOTIFICATION;
        }
    }
    getDeliveryPayload(channel, user, title, body, deliveryId, event, data) {
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
    mapEventToWebsocketEvent(event) {
        switch (event) {
            case client_1.NotificationEvent.ORDER_PLACED: return websocket_event_enum_1.WebsocketEvent.SIGNAL_RECEIVED;
            case client_1.NotificationEvent.ORDER_FILLED: return websocket_event_enum_1.WebsocketEvent.ORDER_EXECUTED;
            case client_1.NotificationEvent.ORDER_REJECTED: return websocket_event_enum_1.WebsocketEvent.ORDER_REJECTED;
            case client_1.NotificationEvent.RISK_BLOCKED: return websocket_event_enum_1.WebsocketEvent.RISK_LOCKED;
            case client_1.NotificationEvent.TARGET_HIT: return websocket_event_enum_1.WebsocketEvent.TARGET_HIT;
            case client_1.NotificationEvent.STOP_LOSS_HIT: return websocket_event_enum_1.WebsocketEvent.STOPLOSS_HIT;
            case client_1.NotificationEvent.SUBSCRIPTION_EXPIRED: return websocket_event_enum_1.WebsocketEvent.SUBSCRIPTION_EXPIRED;
            case client_1.NotificationEvent.BROKER_DISCONNECTED: return websocket_event_enum_1.WebsocketEvent.BROKER_DISCONNECTED;
            default: return null;
        }
    }
    aggregateMessage(existingMsg, newEvent) {
        const lines = existingMsg.split('\n').filter(Boolean);
        const counts = {};
        for (const line of lines) {
            const match = line.match(/^(\d+)\s+(.+)$/);
            if (match) {
                const qty = parseInt(match[1], 10);
                const text = match[2];
                counts[text] = qty;
            }
            else {
                counts[line] = 1;
            }
        }
        const label = this.getEventLabel(newEvent);
        counts[label] = (counts[label] || 0) + 1;
        return Object.entries(counts)
            .map(([text, qty]) => `${qty} ${text}`)
            .join('\n');
    }
    getEventLabel(event) {
        switch (event) {
            case client_1.NotificationEvent.TARGET_HIT: return 'targets hit';
            case client_1.NotificationEvent.ORDER_FILLED: return 'orders filled';
            case client_1.NotificationEvent.ORDER_PLACED: return 'orders placed';
            case client_1.NotificationEvent.ORDER_REJECTED: return 'orders rejected';
            case client_1.NotificationEvent.RISK_BLOCKED: return 'risk violations';
            default: return 'alerts';
        }
    }
};
exports.NotificationsService = NotificationsService;
__decorate([
    (0, schedule_1.Cron)(schedule_1.CronExpression.EVERY_MINUTE),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], NotificationsService.prototype, "processScheduledNotifications", null);
exports.NotificationsService = NotificationsService = NotificationsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        notification_rate_limiter_service_1.NotificationRateLimiterService,
        notification_deduplication_service_1.NotificationDeduplicationService,
        notification_template_service_1.NotificationTemplateService,
        websocket_service_1.WebsocketService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService])
], NotificationsService);
//# sourceMappingURL=notifications.service.js.map