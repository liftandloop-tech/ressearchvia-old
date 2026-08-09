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
Object.defineProperty(exports, "__esModule", { value: true });
exports.SubscriptionsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const client_1 = require("@prisma/client");
const plans_constants_1 = require("./plans.constants");
const audit_service_1 = require("../audit/audit.service");
const audit_event_enum_1 = require("../audit/enums/audit-event.enum");
const redis_service_1 = require("../infrastructure/redis/redis.service");
let SubscriptionsService = class SubscriptionsService {
    prisma;
    auditService;
    redisService;
    constructor(prisma, auditService, redisService) {
        this.prisma = prisma;
        this.auditService = auditService;
        this.redisService = redisService;
    }
    async validateSubscription(userId) {
        const now = new Date();
        const sub = await this.prisma.subscription.findFirst({
            where: {
                userId,
                status: client_1.SubscriptionStatus.ACTIVE,
                startDate: { lte: now },
                endDate: { gte: now },
            },
            orderBy: { endDate: 'desc' },
        });
        if (!sub) {
            return { active: false, plan: null, expiresAt: null };
        }
        let planName = null;
        if (sub.planId === plans_constants_1.PLANS.SPARK.id) {
            planName = plans_constants_1.PLANS.SPARK.name;
        }
        else if (sub.planId === plans_constants_1.PLANS.SPLENDID.id) {
            planName = plans_constants_1.PLANS.SPLENDID.name;
        }
        return {
            active: true,
            plan: planName,
            expiresAt: sub.endDate,
        };
    }
    async getCurrentSubscription(userId) {
        const now = new Date();
        return this.prisma.subscription.findFirst({
            where: {
                userId,
                status: client_1.SubscriptionStatus.ACTIVE,
                startDate: { lte: now },
                endDate: { gte: now },
            },
            orderBy: { endDate: 'desc' },
        });
    }
    async getSubscriptionHistory(userId, page = 1, limit = 20) {
        return this.prisma.subscription.paginate({
            page,
            limit,
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
    }
    async subscribe(userId, planId) {
        if (this.redisService.isHealthy()) {
            const isGlobalMaint = await this.redisService.getClient().get('system:maintenance:global');
            const isSubsMaint = await this.redisService.getClient().get('system:maintenance:subscriptions');
            if (isGlobalMaint === 'true' || isSubsMaint === 'true') {
                throw new common_1.ServiceUnavailableException('Subscriptions are currently disabled due to system maintenance');
            }
        }
        let plan;
        if (planId === plans_constants_1.PLANS.SPARK.id) {
            plan = plans_constants_1.PLANS.SPARK;
        }
        else if (planId === plans_constants_1.PLANS.SPLENDID.id) {
            plan = plans_constants_1.PLANS.SPLENDID;
        }
        else {
            throw new common_1.BadRequestException('Invalid plan ID');
        }
        const now = new Date();
        const durationDays = plan.durationDays;
        const activeSub = await this.prisma.subscription.findFirst({
            where: {
                userId,
                status: client_1.SubscriptionStatus.ACTIVE,
                endDate: { gte: now },
            },
            orderBy: { endDate: 'desc' },
        });
        let startDate = now;
        let isRenewal = false;
        if (activeSub) {
            if (activeSub.planId === planId) {
                startDate = new Date(activeSub.endDate.getTime() + 1000);
                isRenewal = true;
            }
            else {
                await this.prisma.subscription.update({
                    where: { id: activeSub.id },
                    data: { status: client_1.SubscriptionStatus.CANCELLED },
                });
                await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.SUBSCRIPTION_CANCELLED, 'Subscription', activeSub.id, { planId: activeSub.planId, reason: 'Plan Switch' });
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
                status: client_1.SubscriptionStatus.ACTIVE,
            },
        });
        await this.auditService.logEvent(userId, isRenewal
            ? audit_event_enum_1.AuditEventType.SUBSCRIPTION_RENEWED
            : audit_event_enum_1.AuditEventType.SUBSCRIPTION_ACTIVATED, 'Subscription', newSub.id, { planId, durationDays });
        return newSub;
    }
    async cancelSubscription(id, userId) {
        const existing = await this.prisma.subscription.findUnique({
            where: { id },
        });
        if (!existing) {
            throw new common_1.NotFoundException('Subscription not found');
        }
        if (existing.userId !== userId) {
            throw new common_1.ForbiddenException('You do not own this subscription');
        }
        const updated = await this.prisma.subscription.update({
            where: { id },
            data: {
                status: client_1.SubscriptionStatus.CANCELLED,
            },
        });
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.SUBSCRIPTION_CANCELLED, 'Subscription', updated.id, { planId: updated.planId, reason: 'User Cancelled' });
        return updated;
    }
};
exports.SubscriptionsService = SubscriptionsService;
exports.SubscriptionsService = SubscriptionsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        audit_service_1.AuditService,
        redis_service_1.RedisService])
], SubscriptionsService);
//# sourceMappingURL=subscriptions.service.js.map