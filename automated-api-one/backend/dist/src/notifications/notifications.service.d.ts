import { PrismaService } from '../prisma.service';
import { Notification, NotificationType, NotificationEvent } from '@prisma/client';
import { NotificationRateLimiterService } from './notification-rate-limiter.service';
import { NotificationDeduplicationService } from './notification-deduplication.service';
import { NotificationTemplateService } from './notification-template.service';
import { WebsocketService } from '../websocket/services/websocket.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
export declare class NotificationsService {
    private readonly prisma;
    private readonly rateLimiter;
    private readonly deduplication;
    private readonly templateService;
    private readonly websocketService;
    private readonly queueService;
    private readonly metrics;
    private readonly logger;
    constructor(prisma: PrismaService, rateLimiter: NotificationRateLimiterService, deduplication: NotificationDeduplicationService, templateService: NotificationTemplateService, websocketService: WebsocketService, queueService: QueueService, metrics: MetricsService);
    getHistory(userId: string, limit?: number, offset?: number): Promise<{
        data: Notification[];
        total: number;
    }>;
    markAsRead(userId: string, notificationIds: string[]): Promise<{
        count: number;
    }>;
    createNotification(userId: string, type: NotificationType, title: string, message: string): Promise<Notification>;
    sendNotification(userId: string, event: NotificationEvent, data: any, batchKey?: string): Promise<Notification>;
    processScheduledNotifications(): Promise<void>;
    getPreferences(userId: string): Promise<any>;
    updatePreferences(userId: string, dto: any): Promise<any>;
    private mapEventToType;
    private getChannelProvider;
    private getChannelQueueName;
    private getDeliveryPayload;
    private mapEventToWebsocketEvent;
    private aggregateMessage;
    private getEventLabel;
}
