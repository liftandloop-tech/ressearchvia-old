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
var ConsentsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConsentsService = void 0;
exports.getTodayISTString = getTodayISTString;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const client_1 = require("@prisma/client");
const audit_service_1 = require("../audit/audit.service");
const audit_event_enum_1 = require("../audit/enums/audit-event.enum");
const notifications_service_1 = require("../notifications/notifications.service");
const client_2 = require("@prisma/client");
const schedule_1 = require("@nestjs/schedule");
const subscriptions_service_1 = require("../subscriptions/subscriptions.service");
function getTodayISTString(date = new Date()) {
    return new Intl.DateTimeFormat('en-CA', {
        timeZone: 'Asia/Kolkata',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
    }).format(date);
}
let ConsentsService = ConsentsService_1 = class ConsentsService {
    prisma;
    auditService;
    notificationsService;
    subscriptionsService;
    logger = new common_1.Logger(ConsentsService_1.name);
    constructor(prisma, auditService, notificationsService, subscriptionsService) {
        this.prisma = prisma;
        this.auditService = auditService;
        this.notificationsService = notificationsService;
        this.subscriptionsService = subscriptionsService;
    }
    async hasTodayConsent(userId) {
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
                status: client_1.ConsentStatus.ACTIVE,
            },
        });
        return !!consent;
    }
    async grantConsent(userId, brokerId) {
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
                    code: normalizedCode,
                },
            });
        }
        if (!broker) {
            throw new common_1.BadRequestException(`Broker with identifier ${brokerId} not found`);
        }
        const userBroker = await this.prisma.userBroker.findFirst({
            where: {
                userId,
                brokerId: broker.id,
                status: 'ACTIVE',
            },
        });
        if (!userBroker) {
            throw new common_1.BadRequestException('User does not have an active linked account for this broker');
        }
        const todayStr = getTodayISTString();
        const todayDate = new Date(`${todayStr}T00:00:00.000Z`);
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
                    status: client_1.ConsentStatus.ACTIVE,
                    deletedAt: null,
                },
            });
        }
        else {
            consent = await this.prisma.baseClient.consent.create({
                data: {
                    userId,
                    brokerId: broker.id,
                    consentDate: todayDate,
                    status: client_1.ConsentStatus.ACTIVE,
                },
            });
        }
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.CONSENT_GRANTED, 'Consent', consent.id, { brokerCode: broker.code, consentDate: todayStr });
        await this.notificationsService.createNotification(userId, client_2.NotificationType.CONSENT_GRANTED, 'Automated Trading Consent Activated', 'Automated trading consent activated for today.');
        return consent;
    }
    async getConsentStatus(userId) {
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
        const active = consent.status === client_1.ConsentStatus.ACTIVE;
        return {
            active,
            broker: activeUserBroker.broker.code,
            consentDate: todayStr,
            status: consent.status,
        };
    }
    async revokeConsent(userId) {
        const activeUserBroker = await this.prisma.userBroker.findFirst({
            where: { userId, status: 'ACTIVE' },
        });
        if (!activeUserBroker) {
            throw new common_1.BadRequestException('No active broker connection found');
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
            throw new common_1.BadRequestException('No consent found to revoke today');
        }
        const consent = await this.prisma.consent.update({
            where: { id: existing.id },
            data: {
                status: client_1.ConsentStatus.REVOKED,
            },
        });
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.CONSENT_REVOKED, 'Consent', consent.id, { consentDate: todayStr });
        await this.notificationsService.createNotification(userId, client_2.NotificationType.CONSENT_REVOKED, 'Automated Trading Consent Revoked', 'Automated trading consent revoked. All Segment executions paused.');
        return consent;
    }
    async sendConsentReminders() {
        if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
            return;
        }
        this.logger.log('Running scheduled daily consent reminders check at 08:00 AM IST');
        const activeAllocations = await this.prisma.userSegment.findMany({
            where: { status: 'ACTIVE' },
            select: { userId: true },
        });
        const uniqueUserIds = [...new Set(activeAllocations.map((a) => a.userId))];
        for (const userIdUnknown of uniqueUserIds) {
            const userId = userIdUnknown;
            try {
                const subValidation = await this.subscriptionsService.validateSubscription(userId);
                if (!subValidation.active) {
                    continue;
                }
                const hasConsent = await this.hasTodayConsent(userId);
                if (!hasConsent) {
                    await this.notificationsService.createNotification(userId, client_2.NotificationType.CONSENT_PENDING, 'Trading Consent Required', "Today's trading consent is pending. Please approve automated trading.");
                }
            }
            catch (err) {
                this.logger.error(`Failed to process consent reminder for user ${userId}: ${err.message}`);
            }
        }
    }
};
exports.ConsentsService = ConsentsService;
__decorate([
    (0, schedule_1.Cron)('0 0 8 * * *', { timeZone: 'Asia/Kolkata' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ConsentsService.prototype, "sendConsentReminders", null);
exports.ConsentsService = ConsentsService = ConsentsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        audit_service_1.AuditService,
        notifications_service_1.NotificationsService,
        subscriptions_service_1.SubscriptionsService])
], ConsentsService);
//# sourceMappingURL=consents.service.js.map