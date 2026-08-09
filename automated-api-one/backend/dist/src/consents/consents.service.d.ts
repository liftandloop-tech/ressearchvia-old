import { PrismaService } from '../prisma.service';
import { Consent } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
export declare function getTodayISTString(date?: Date): string;
export declare class ConsentsService {
    private readonly prisma;
    private readonly auditService;
    private readonly notificationsService;
    private readonly subscriptionsService;
    private readonly logger;
    constructor(prisma: PrismaService, auditService: AuditService, notificationsService: NotificationsService, subscriptionsService: SubscriptionsService);
    hasTodayConsent(userId: string): Promise<boolean>;
    grantConsent(userId: string, brokerId: string): Promise<Consent>;
    getConsentStatus(userId: string): Promise<{
        active: boolean;
        broker: string | null;
        consentDate: string | null;
        status: string;
    }>;
    revokeConsent(userId: string): Promise<Consent>;
    sendConsentReminders(): Promise<void>;
}
