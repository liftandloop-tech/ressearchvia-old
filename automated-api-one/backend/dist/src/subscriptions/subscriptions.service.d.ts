import { PrismaService } from '../prisma.service';
import { Subscription } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { RedisService } from '../infrastructure/redis/redis.service';
export declare class SubscriptionsService {
    private readonly prisma;
    private readonly auditService;
    private readonly redisService;
    constructor(prisma: PrismaService, auditService: AuditService, redisService: RedisService);
    validateSubscription(userId: string): Promise<{
        active: boolean;
        plan: string | null;
        expiresAt: Date | null;
    }>;
    getCurrentSubscription(userId: string): Promise<Subscription | null>;
    getSubscriptionHistory(userId: string, page?: number, limit?: number): Promise<any>;
    subscribe(userId: string, planId: string): Promise<Subscription>;
    cancelSubscription(id: string, userId: string): Promise<Subscription>;
}
