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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var BrokerSessionService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.BrokerSessionService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma.service");
const broker_factory_1 = require("../factory/broker.factory");
const audit_service_1 = require("../../audit/audit.service");
const audit_event_enum_1 = require("../../audit/enums/audit-event.enum");
const schedule_1 = require("@nestjs/schedule");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const redis_keys_1 = require("../../infrastructure/redis/redis-keys");
const common_2 = require("@nestjs/common");
const egress_service_1 = require("../../egress/egress.service");
let BrokerSessionService = BrokerSessionService_1 = class BrokerSessionService {
    prisma;
    brokerFactory;
    auditService;
    redisService;
    egressService;
    logger = new common_1.Logger(BrokerSessionService_1.name);
    constructor(prisma, brokerFactory, auditService, redisService, egressService) {
        this.prisma = prisma;
        this.brokerFactory = brokerFactory;
        this.auditService = auditService;
        this.redisService = redisService;
        this.egressService = egressService;
    }
    async storeSession(userId, brokerCode, session, userBrokerId) {
        const updatedBroker = await this.prisma.userBroker.update({
            where: { id: userBrokerId },
            data: {
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                tokenExpiry: session.tokenExpiry,
            },
            select: { brokerId: true },
        });
        let egressCreds = null;
        if (this.egressService) {
            try {
                egressCreds = await this.egressService.getOrCreateUserEgress(userId);
                this.logger.log(`[BrokerSession] Egress IP ${egressCreds.publicIp} verified for user ${userId}`);
            }
            catch (eErr) {
                this.logger.warn(`[BrokerSession] Egress preparation notice for user ${userId}: ${eErr.message}`);
            }
        }
        if (this.redisService.isHealthy() && session.accessToken) {
            try {
                const fullBroker = await this.prisma.userBroker.findUnique({
                    where: { id: userBrokerId },
                });
                const sessionKey = redis_keys_1.RedisKeys.brokerSession(userId, updatedBroker.brokerId);
                const payload = JSON.stringify({
                    accessToken: session.accessToken,
                    proxyIp: egressCreds?.publicIp || fullBroker?.proxyIp || null,
                    proxyPort: egressCreds?.proxyPort || fullBroker?.proxyPort || null,
                    proxyUsername: egressCreds?.proxyUsername || fullBroker?.proxyUsername || null,
                    proxyPassword: egressCreds?.token || fullBroker?.proxyPassword || null,
                    proxyHostname: egressCreds?.proxyHost || fullBroker?.proxyHostname || null,
                });
                const midnightIst = new Date();
                midnightIst.setUTCHours(18, 30, 0, 0);
                if (midnightIst < new Date())
                    midnightIst.setUTCDate(midnightIst.getUTCDate() + 1);
                const ttlSeconds = Math.floor((midnightIst.getTime() - Date.now()) / 1000);
                await this.redisService.getClient().set(sessionKey, payload, 'EX', ttlSeconds);
                this.logger.log(`[BrokerSession] Cached token and proxy credentials for user ${userId} in Redis (TTL: ${ttlSeconds}s)`);
            }
            catch (err) {
                this.logger.warn(`[BrokerSession] Redis write failed for user ${userId}: ${err.message}`);
            }
        }
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.BROKER_CONNECTED, 'UserBroker', userBrokerId, {
            brokerCode,
            userBrokerId,
            tokenExpiry: session.tokenExpiry,
        });
    }
    async refreshSession(userId, brokerCode) {
        const broker = await this.prisma.broker.findFirst({
            where: { code: brokerCode },
        });
        if (!broker) {
            throw new common_1.NotFoundException(`Broker ${brokerCode} not found in database`);
        }
        const userBroker = await this.prisma.userBroker.findFirst({
            where: { userId, brokerId: broker.id },
        });
        if (!userBroker || !userBroker.accessToken || !userBroker.refreshToken) {
            throw new common_1.BadRequestException('No active broker session to refresh');
        }
        const brokerType = brokerCode;
        const adapter = this.brokerFactory.getAdapter(brokerType);
        try {
            const newSession = await adapter.refreshSession(userBroker.accessToken, userBroker.refreshToken);
            await this.prisma.userBroker.update({
                where: { id: userBroker.id },
                data: {
                    accessToken: newSession.accessToken,
                    refreshToken: newSession.refreshToken,
                    tokenExpiry: newSession.tokenExpiry,
                },
            });
            await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.BROKER_SESSION_REFRESHED, 'UserBroker', userBroker.id, {
                brokerCode,
                userBrokerId: userBroker.id,
                tokenExpiry: newSession.tokenExpiry,
            });
            return newSession;
        }
        catch (error) {
            this.logger.error(`Broker session refresh failed for user ${userId}: ${error.message}`);
            await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.BROKER_SESSION_FAILED, 'UserBroker', userBroker.id, {
                brokerCode,
                userBrokerId: userBroker.id,
                error: error.message,
            });
            throw error;
        }
    }
    async invalidateSession(userId, brokerCode) {
        const broker = await this.prisma.broker.findFirst({
            where: { code: brokerCode },
        });
        if (!broker)
            return;
        const userBroker = await this.prisma.userBroker.findFirst({
            where: { userId, brokerId: broker.id },
        });
        if (!userBroker)
            return;
        if (this.redisService.isHealthy()) {
            try {
                const sessionKey = redis_keys_1.RedisKeys.brokerSession(userId, broker.id);
                await this.redisService.getClient().del(sessionKey);
                this.logger.log(`[BrokerSession] Cleared Redis cache for user ${userId} broker ${brokerCode}`);
            }
            catch (err) {
                this.logger.warn(`[BrokerSession] Redis clear failed for user ${userId}: ${err.message}`);
            }
        }
        await this.prisma.userBroker.update({
            where: { id: userBroker.id },
            data: {
                accessToken: null,
                refreshToken: null,
                tokenExpiry: null,
            },
        });
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.BROKER_DISCONNECTED, 'UserBroker', userBroker.id, {
            brokerCode,
            userBrokerId: userBroker.id,
        });
    }
    isSessionExpired(tokenExpiry) {
        if (!tokenExpiry)
            return true;
        return new Date() > tokenExpiry;
    }
    async validateSession(userId, brokerCode) {
        const broker = await this.prisma.broker.findFirst({
            where: { code: brokerCode },
        });
        if (!broker)
            return false;
        const userBroker = await this.prisma.userBroker.findFirst({
            where: { userId, brokerId: broker.id },
        });
        if (!userBroker)
            return false;
        const isExpired = this.isSessionExpired(userBroker.tokenExpiry);
        if (isExpired && userBroker.accessToken) {
            await this.prisma.userBroker.update({
                where: { id: userBroker.id },
                data: {
                    accessToken: null,
                    refreshToken: null,
                    tokenExpiry: null,
                },
            });
            await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.BROKER_SESSION_EXPIRED, 'UserBroker', userBroker.id, {
                brokerCode,
                expiredAt: userBroker.tokenExpiry,
            });
            return false;
        }
        if (!userBroker.accessToken) {
            return false;
        }
        const brokerType = brokerCode;
        const adapter = this.brokerFactory.getAdapter(brokerType);
        return adapter.validateSession(userBroker.accessToken);
    }
    async cleanupExpiredAuthStates() {
        this.logger.log('Cleaning up expired broker auth state records...');
        const result = await this.prisma.brokerAuthState.deleteMany({
            where: {
                expiresAt: {
                    lt: new Date(),
                },
            },
        });
        if (result.count > 0) {
            this.logger.log(`Pruned ${result.count} expired auth state records.`);
        }
    }
};
exports.BrokerSessionService = BrokerSessionService;
__decorate([
    (0, schedule_1.Cron)(schedule_1.CronExpression.EVERY_HOUR),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], BrokerSessionService.prototype, "cleanupExpiredAuthStates", null);
exports.BrokerSessionService = BrokerSessionService = BrokerSessionService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(4, (0, common_2.Optional)()),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        broker_factory_1.BrokerFactory,
        audit_service_1.AuditService,
        redis_service_1.RedisService,
        egress_service_1.EgressService])
], BrokerSessionService);
//# sourceMappingURL=broker-session.service.js.map