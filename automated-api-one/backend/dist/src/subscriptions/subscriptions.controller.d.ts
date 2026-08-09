import { SubscriptionsService } from './subscriptions.service';
export declare class SubscribeDto {
    planId: string;
}
export declare class HistoryQueryDto {
    page?: number;
    limit?: number;
}
export declare class SubscriptionsController {
    private readonly subscriptionsService;
    constructor(subscriptionsService: SubscriptionsService);
    getPlans(): {
        id: string;
        name: string;
        durationDays: number;
    }[];
    getCurrent(req: any): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.SubscriptionStatus;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        planId: string;
        startDate: Date;
        endDate: Date;
    } | null>;
    getStatus(req: any): Promise<{
        active: boolean;
        plan: string | null;
        expiresAt: Date | null;
    }>;
    getHistory(req: any, query: HistoryQueryDto): Promise<any>;
    subscribeBase(req: any, dto: SubscribeDto): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.SubscriptionStatus;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        planId: string;
        startDate: Date;
        endDate: Date;
    }>;
    subscribeLegacy(req: any, dto: SubscribeDto): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.SubscriptionStatus;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        planId: string;
        startDate: Date;
        endDate: Date;
    }>;
    cancel(req: any, id: string): Promise<{
        id: string;
        status: import("@prisma/client").$Enums.SubscriptionStatus;
        createdAt: Date;
        updatedAt: Date;
        deletedAt: Date | null;
        userId: string;
        planId: string;
        startDate: Date;
        endDate: Date;
    }>;
}
