import { NotificationsService } from './notifications.service';
import { NotificationType, NotificationEvent, NotificationChannel } from '@prisma/client';
export declare class GetNotificationsDto {
    limit?: number;
    offset?: number;
}
export declare class MarkReadDto {
    notificationIds: string[];
}
export declare class SimulateNotificationDto {
    type: NotificationType;
    title: string;
    message: string;
}
export declare class UpdatePreferenceItemDto {
    eventType: NotificationEvent;
    channel: NotificationChannel;
    enabled: boolean;
}
export declare class UpdatePreferencesDto {
    preferences?: UpdatePreferenceItemDto[];
    quietHoursEnabled?: boolean;
    quietStart?: string;
    quietEnd?: string;
    quietTimezone?: string;
}
export declare class NotificationsController {
    private readonly notificationsService;
    constructor(notificationsService: NotificationsService);
    getNotifications(req: any, query: GetNotificationsDto): Promise<{
        data: import("@prisma/client").Notification[];
        total: number;
    }>;
    markRead(req: any, dto: MarkReadDto): Promise<{
        count: number;
    }>;
    simulateNotification(req: any, dto: SimulateNotificationDto): Promise<{
        id: string;
        createdAt: Date;
        userId: string;
        type: import("@prisma/client").$Enums.NotificationType;
        title: string;
        message: string;
        delivered: boolean;
        batchKey: string | null;
    }>;
    getPreferences(req: any): Promise<any>;
    updatePreferences(req: any, dto: UpdatePreferencesDto): Promise<any>;
}
