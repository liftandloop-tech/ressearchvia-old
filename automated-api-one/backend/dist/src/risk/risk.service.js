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
var RiskService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.RiskService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const client_1 = require("@prisma/client");
const subscriptions_service_1 = require("../subscriptions/subscriptions.service");
const consents_service_1 = require("../consents/consents.service");
const broker_session_service_1 = require("../brokers/services/broker-session.service");
const broker_factory_1 = require("../brokers/factory/broker.factory");
const audit_service_1 = require("../audit/audit.service");
const audit_event_enum_1 = require("../audit/enums/audit-event.enum");
const risk_code_enum_1 = require("./enums/risk-code.enum");
const redis_service_1 = require("../infrastructure/redis/redis.service");
const queues_service_1 = require("../infrastructure/queues/queues.service");
const metrics_service_1 = require("../infrastructure/metrics/metrics.service");
const outbox_service_1 = require("../infrastructure/outbox/outbox.service");
const queue_constants_1 = require("../infrastructure/queues/queue.constants");
const schedule_1 = require("@nestjs/schedule");
let RiskService = RiskService_1 = class RiskService {
    prisma;
    subscriptionsService;
    consentsService;
    brokerSessionService;
    brokerFactory;
    auditService;
    redisService;
    queueService;
    metrics;
    outboxService;
    logger = new common_1.Logger(RiskService_1.name);
    constructor(prisma, subscriptionsService, consentsService, brokerSessionService, brokerFactory, auditService, redisService, queueService, metrics, outboxService) {
        this.prisma = prisma;
        this.subscriptionsService = subscriptionsService;
        this.consentsService = consentsService;
        this.brokerSessionService = brokerSessionService;
        this.brokerFactory = brokerFactory;
        this.auditService = auditService;
        this.redisService = redisService;
        this.queueService = queueService;
        this.metrics = metrics;
        this.outboxService = outboxService;
    }
    async validateExecution(userId, segmentId, estimatedCost) {
        const subValidation = await this.subscriptionsService.validateSubscription(userId);
        if (!subValidation.active) {
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.NO_SUBSCRIPTION, 'No active subscription');
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.NO_SUBSCRIPTION,
                reason: 'No active subscription',
            };
        }
        const hasConsent = await this.consentsService.hasTodayConsent(userId);
        if (!hasConsent) {
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.NO_CONSENT, 'Daily consent not granted');
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.NO_CONSENT,
                reason: 'Daily consent not granted',
            };
        }
        const userBroker = await this.prisma.userBroker.findFirst({
            where: { userId, status: client_1.BrokerStatus.ACTIVE },
            include: { broker: true },
        });
        if (!userBroker || !userBroker.accessToken) {
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.SESSION_EXPIRED, 'Broker not connected');
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.SESSION_EXPIRED,
                reason: 'Broker not connected',
            };
        }
        let isSessionValid = await this.brokerSessionService.validateSession(userId, userBroker.broker.code);
        if (!isSessionValid) {
            try {
                await this.brokerSessionService.refreshSession(userId, userBroker.broker.code);
                isSessionValid = await this.brokerSessionService.validateSession(userId, userBroker.broker.code);
            }
            catch (e) {
                await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.SESSION_EXPIRED, `Broker session refresh failed: ${e.message}`);
                return {
                    approved: false,
                    code: risk_code_enum_1.RiskCode.SESSION_EXPIRED,
                    reason: `Broker session refresh failed: ${e.message}`,
                };
            }
            if (!isSessionValid) {
                await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.SESSION_EXPIRED, 'Broker session validation failed after refresh');
                return {
                    approved: false,
                    code: risk_code_enum_1.RiskCode.SESSION_EXPIRED,
                    reason: 'Broker session validation failed after refresh',
                };
            }
        }
        const userSegment = await this.prisma.userSegment.findFirst({
            where: { userId, segmentId },
        });
        if (!userSegment) {
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.SEGMENT_PAUSED, 'Segment strategy not configured for user');
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.SEGMENT_PAUSED,
                reason: 'Segment strategy not configured for user',
            };
        }
        if (userSegment.status !== client_1.UserSegmentStatus.ACTIVE) {
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.SEGMENT_PAUSED, `Segment strategy status is ${userSegment.status}`);
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.SEGMENT_PAUSED,
                reason: `Segment strategy status is ${userSegment.status}`,
            };
        }
        const allocatedCapital = Number(userSegment.capital);
        if (allocatedCapital < estimatedCost) {
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.INSUFFICIENT_CAPITAL, `Allocated capital ${allocatedCapital} is less than estimated cost ${estimatedCost}`);
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.INSUFFICIENT_CAPITAL,
                reason: `Allocated capital ${allocatedCapital} is less than estimated cost ${estimatedCost}`,
            };
        }
        let brokerMargin = 0;
        try {
            const brokerType = userBroker.broker.code;
            const adapter = this.brokerFactory.getAdapter(brokerType);
            const funds = await adapter.getFunds(userBroker.accessToken, userBroker.brokerClientId);
            brokerMargin = funds.availableMargin;
        }
        catch (e) {
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.INSUFFICIENT_MARGIN, `Failed to retrieve broker margin: ${e.message}`);
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.INSUFFICIENT_MARGIN,
                reason: `Failed to retrieve broker margin: ${e.message}`,
            };
        }
        if (brokerMargin < estimatedCost) {
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.INSUFFICIENT_MARGIN, `Broker margin ${brokerMargin} is less than estimated cost ${estimatedCost}`);
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.INSUFFICIENT_MARGIN,
                reason: `Broker margin ${brokerMargin} is less than estimated cost ${estimatedCost}`,
            };
        }
        const todayStr = new Date().toISOString().split('T')[0];
        const today = new Date(`${todayStr}T00:00:00.000Z`);
        const trades = await this.prisma.trade.findMany({
            where: {
                userId,
                segmentId,
                status: client_1.TradeStatus.CLOSED,
                createdAt: { gte: today },
            },
        });
        let dailyPnl = 0;
        for (const t of trades) {
            dailyPnl += Number(t.pnl || 0);
        }
        const currentLoss = dailyPnl < 0 ? Math.abs(dailyPnl) : 0;
        const dailyLossLimit = Number(userSegment.dailyLossLimit);
        if (currentLoss >= dailyLossLimit) {
            await this.prisma.userSegment.update({
                where: { id: userSegment.id },
                data: {
                    status: client_1.UserSegmentStatus.PAUSED,
                    pausedAt: new Date(),
                    lastRiskLockAt: new Date(),
                },
            });
            await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.SEGMENT_RISK_LOCKED, 'UserSegment', userSegment.id, { dailyLossLimit, currentLoss });
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.DAILY_LOSS_LIMIT, `Daily loss limit of ${dailyLossLimit} has been reached/exceeded (Current: ${currentLoss})`);
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.DAILY_LOSS_LIMIT,
                reason: `Daily loss limit of ${dailyLossLimit} has been reached/exceeded (Current: ${currentLoss})`,
            };
        }
        const multiplierState = await this.prisma.segmentMultiplier.findFirst({
            where: { userId, segmentId },
        });
        if (multiplierState &&
            multiplierState.currentMultiplier > userSegment.maxMultiplier) {
            await this.logRejectedRisk(userId, segmentId, risk_code_enum_1.RiskCode.MULTIPLIER_LIMIT, `Multiplier ${multiplierState.currentMultiplier} exceeds max limit of ${userSegment.maxMultiplier}`);
            return {
                approved: false,
                code: risk_code_enum_1.RiskCode.MULTIPLIER_LIMIT,
                reason: `Multiplier ${multiplierState.currentMultiplier} exceeds max limit of ${userSegment.maxMultiplier}`,
            };
        }
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.RISK_APPROVED, 'SegmentMaster', segmentId, { estimatedCost });
        return { approved: true };
    }
    async logRejectedRisk(userId, segmentId, code, reason) {
        await this.prisma.riskEvent.create({
            data: {
                userId,
                segmentId,
                eventType: risk_code_enum_1.RiskCode[code],
                message: reason,
            },
        });
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.RISK_REJECTED, 'SegmentMaster', segmentId, { code: risk_code_enum_1.RiskCode[code], reason });
    }
    async getRiskEvents(userId, limit = 20, offset = 0) {
        const [data, total] = await Promise.all([
            this.prisma.riskEvent.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
                take: limit,
                skip: offset,
            }),
            this.prisma.riskEvent.count({
                where: { userId },
            }),
        ]);
        return { data, total };
    }
    async getRiskEventsForSegment(userId, segmentId, page = 1, limit = 20) {
        return this.prisma.riskEvent.paginate({
            page,
            limit,
            where: { userId, segmentId },
            orderBy: { createdAt: 'desc' },
        });
    }
    async getRiskStatus(userId) {
        const userSegments = await this.prisma.userSegment.findMany({
            where: {
                userId,
                status: {
                    in: [client_1.UserSegmentStatus.ACTIVE, client_1.UserSegmentStatus.PAUSED],
                },
            },
            include: {
                segment: true,
            },
        });
        const todayStr = new Date().toISOString().split('T')[0];
        const today = new Date(`${todayStr}T00:00:00.000Z`);
        const statusList = [];
        for (const us of userSegments) {
            const trades = await this.prisma.trade.findMany({
                where: {
                    userId,
                    segmentId: us.segmentId,
                    status: client_1.TradeStatus.CLOSED,
                    createdAt: {
                        gte: today,
                    },
                },
            });
            let dailyPnl = 0;
            for (const t of trades) {
                dailyPnl += Number(t.pnl || 0);
            }
            const currentLoss = dailyPnl < 0 ? Math.abs(dailyPnl) : 0;
            const dailyLossLimit = Number(us.dailyLossLimit);
            const isLocked = currentLoss >= dailyLossLimit ||
                us.status === client_1.UserSegmentStatus.PAUSED;
            statusList.push({
                segmentId: us.segmentId,
                segmentName: us.segment.name,
                dailyLossLimit,
                currentLoss,
                dailyPnl,
                isLocked,
                status: us.status,
            });
        }
        return statusList;
    }
    async getRiskStatusForSegment(userId, segmentId) {
        const userSegment = await this.prisma.userSegment.findFirst({
            where: { userId, segmentId },
            include: { segment: true },
        });
        if (!userSegment) {
            throw new common_1.NotFoundException('Strategy not configured for user');
        }
        const todayStr = new Date().toISOString().split('T')[0];
        const today = new Date(`${todayStr}T00:00:00.000Z`);
        const trades = await this.prisma.trade.findMany({
            where: {
                userId,
                segmentId,
                status: client_1.TradeStatus.CLOSED,
                createdAt: { gte: today },
            },
        });
        let dailyPnl = 0;
        for (const t of trades) {
            dailyPnl += Number(t.pnl || 0);
        }
        const dailyLoss = dailyPnl < 0 ? Math.abs(dailyPnl) : 0;
        const dailyLossLimit = Number(userSegment.dailyLossLimit);
        const locked = userSegment.status === client_1.UserSegmentStatus.PAUSED ||
            dailyLoss >= dailyLossLimit;
        return {
            locked,
            dailyLoss,
            dailyLossLimit,
        };
    }
    async resetRiskLock(userId, segmentId) {
        return this.unlockSegment(userId, segmentId, undefined, false);
    }
    async unlockSegment(userId, segmentId, targetUserId, isAdmin = false) {
        const actualUserId = isAdmin && targetUserId ? targetUserId : userId;
        const userSegment = await this.prisma.userSegment.findFirst({
            where: { userId: actualUserId, segmentId },
        });
        if (!userSegment) {
            throw new common_1.NotFoundException('Strategy subscription not found');
        }
        if (!isAdmin && userSegment.userId !== userId) {
            throw new common_1.ForbiddenException('You do not own this strategy');
        }
        return this.prisma.$transaction(async (tx) => {
            const updatedSegment = await tx.userSegment.update({
                where: { id: userSegment.id },
                data: {
                    status: client_1.UserSegmentStatus.ACTIVE,
                    activatedAt: new Date(),
                    pausedAt: null,
                },
            });
            const multiplier = await tx.segmentMultiplier.findFirst({
                where: {
                    userId: actualUserId,
                    segmentId,
                },
            });
            if (multiplier) {
                await tx.segmentMultiplier.update({
                    where: { id: multiplier.id },
                    data: {
                        lossStreak: 0,
                        currentMultiplier: 1,
                    },
                });
            }
            await tx.riskEvent.create({
                data: {
                    userId: actualUserId,
                    segmentId,
                    eventType: 'RISK_LOCK_RESET',
                    message: `Manual reset of strategy risk lock completed by ${isAdmin ? 'Admin' : 'Owner'}.`,
                },
            });
            await this.auditService.logEvent(actualUserId, audit_event_enum_1.AuditEventType.SEGMENT_RISK_UNLOCKED, 'UserSegment', userSegment.id, { unlockedBy: isAdmin ? 'Admin' : 'Owner', triggerUserId: userId });
            return updatedSegment;
        });
    }
    async validateCapital(userId, segmentId, estimatedCost, availableMargin) {
        const userSegment = await this.prisma.userSegment.findFirst({
            where: { userId, segmentId },
        });
        if (!userSegment) {
            return false;
        }
        if (availableMargin < estimatedCost) {
            await this.prisma.riskEvent.create({
                data: {
                    userId,
                    segmentId,
                    eventType: 'INSUFFICIENT_CAPITAL',
                    message: `Insufficient capital/margin. Available: ${availableMargin}, Required: ${estimatedCost}`,
                },
            });
            return false;
        }
        return true;
    }
    async validateLossLimit(userId, segmentId) {
        const userSegment = await this.prisma.userSegment.findFirst({
            where: { userId, segmentId },
        });
        if (!userSegment) {
            return false;
        }
        const todayStr = new Date().toISOString().split('T')[0];
        const today = new Date(`${todayStr}T00:00:00.000Z`);
        const trades = await this.prisma.trade.findMany({
            where: {
                userId,
                segmentId,
                status: client_1.TradeStatus.CLOSED,
                createdAt: { gte: today },
            },
        });
        let dailyPnl = 0;
        for (const t of trades) {
            dailyPnl += Number(t.pnl || 0);
        }
        const currentLoss = dailyPnl < 0 ? Math.abs(dailyPnl) : 0;
        const dailyLossLimit = Number(userSegment.dailyLossLimit);
        if (currentLoss >= dailyLossLimit) {
            await this.prisma.userSegment.update({
                where: { id: userSegment.id },
                data: {
                    status: client_1.UserSegmentStatus.PAUSED,
                    pausedAt: new Date(),
                    lastRiskLockAt: new Date(),
                },
            });
            await this.prisma.riskEvent.create({
                data: {
                    userId,
                    segmentId,
                    eventType: 'DAILY_LOSS_LIMIT_EXCEEDED',
                    message: `Daily loss limit reached. Locked. Current Loss: ${currentLoss}, Limit: ${dailyLossLimit}`,
                },
            });
            return false;
        }
        return true;
    }
    async evaluateRisk(userId, symbol, quantity, price, brokerId, segmentId) {
        const orderValue = Number(quantity) * Number(price);
        if (this.redisService.isHealthy()) {
            const globalBlocked = await this.redisService.getClient().get('risk:global:blocked');
            if (globalBlocked === 'true') {
                this.logger.warn(`Order blocked due to global emergency risk lock: user=${userId}`);
                await this.logViolation(userId, client_1.RiskRule.STALE_SNAPSHOT, client_1.Severity.CRITICAL, { reason: 'Global emergency risk lock' });
                return { approved: false, code: risk_code_enum_1.RiskCode.UNKNOWN, reason: 'Global emergency risk lock is active' };
            }
            const userBlocked = await this.redisService.getClient().get(`user:risk:blocked:${userId}`);
            if (userBlocked === 'true') {
                this.logger.warn(`Order blocked due to user risk lock: user=${userId}`);
                await this.logViolation(userId, client_1.RiskRule.STALE_SNAPSHOT, client_1.Severity.CRITICAL, { reason: 'User risk lock' });
                return { approved: false, code: risk_code_enum_1.RiskCode.DAILY_LOSS_LIMIT, reason: 'User risk circuit breaker is active' };
            }
        }
        const defaultMode = process.env.RISK_DEFAULT_MODE || 'BLOCK';
        const snapshot = await this.prisma.riskSnapshot.findUnique({
            where: { userId },
        });
        if (snapshot) {
            const freshnessMs = Date.now() - new Date(snapshot.updatedAt).getTime();
            if (freshnessMs > 300000) {
                this.logger.warn(`Stale risk snapshot for user ${userId}. Age: ${freshnessMs}ms`);
                const jobId = `risk-recalc-${userId}`;
                await this.queueService.addJob(queue_constants_1.Queues.RISK_RECALCULATE, jobId, { userId });
                if (defaultMode === 'BLOCK') {
                    await this.logViolation(userId, client_1.RiskRule.STALE_SNAPSHOT, client_1.Severity.CRITICAL, { freshnessMs });
                    return { approved: false, code: risk_code_enum_1.RiskCode.UNKNOWN, reason: 'Risk snapshot is stale' };
                }
                else {
                    this.logger.log(`Stale risk snapshot allowed by default mode ALLOW for user ${userId}`);
                }
            }
        }
        const applicableProfiles = await this.prisma.riskProfile.findMany({
            where: {
                OR: [
                    { userId },
                    { segmentId, userId: null, brokerId: null },
                    { brokerId, userId: null, segmentId: null },
                    { userId: null, segmentId: null, brokerId: null },
                ]
            },
            orderBy: [
                { priority: 'desc' },
                { version: 'desc' },
            ],
        });
        if (applicableProfiles.length === 0) {
            if (defaultMode === 'BLOCK') {
                this.logger.warn(`No risk profile found for user ${userId} and RISK_DEFAULT_MODE=BLOCK`);
                await this.logViolation(userId, client_1.RiskRule.NO_PROFILE, client_1.Severity.CRITICAL, { reason: 'No risk profile' });
                return { approved: false, code: risk_code_enum_1.RiskCode.UNKNOWN, reason: 'No active risk profile found' };
            }
            else {
                await this.logEvaluation(userId, true, 0, orderValue, { info: 'No profile, allowed by default' });
                return { approved: true };
            }
        }
        if (!snapshot) {
            this.logger.warn(`No risk snapshot found for user ${userId}`);
            const jobId = `risk:recalc:${userId}`;
            await this.queueService.addJob(queue_constants_1.Queues.RISK_RECALCULATE, jobId, { userId });
            if (defaultMode === 'BLOCK') {
                await this.logViolation(userId, client_1.RiskRule.NO_PROFILE, client_1.Severity.CRITICAL, { reason: 'No risk snapshot' });
                return { approved: false, code: risk_code_enum_1.RiskCode.UNKNOWN, reason: 'No risk snapshot found' };
            }
            else {
                await this.logEvaluation(userId, true, 0, orderValue, { info: 'No snapshot, allowed by default' });
                return { approved: true };
            }
        }
        const evaluatedRulesResult = {};
        for (const profile of applicableProfiles) {
            const maxCap = Number(profile.maxCapitalPerUser);
            if (maxCap > 0) {
                const potentialCapital = Number(snapshot.currentCapitalUsed) + orderValue;
                evaluatedRulesResult['MAX_CAPITAL_USER'] = { potentialCapital, maxCap };
                if (potentialCapital > maxCap) {
                    await this.logViolation(userId, client_1.RiskRule.MAX_CAPITAL_USER, client_1.Severity.CRITICAL, { potentialCapital, maxCap });
                    await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
                    return { approved: false, code: risk_code_enum_1.RiskCode.INSUFFICIENT_CAPITAL, reason: 'Exceeded Max Capital Limit' };
                }
            }
            const maxCapSeg = Number(profile.maxCapitalPerSegment);
            if (maxCapSeg > 0 && profile.segmentId === segmentId) {
                const potentialSegmentCapital = orderValue;
                evaluatedRulesResult['MAX_CAPITAL_SEGMENT'] = { potentialSegmentCapital, maxCapSeg };
                if (potentialSegmentCapital > maxCapSeg) {
                    await this.logViolation(userId, client_1.RiskRule.MAX_CAPITAL_SEGMENT, client_1.Severity.WARNING, { potentialSegmentCapital, maxCapSeg });
                    await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
                    return { approved: false, code: risk_code_enum_1.RiskCode.INSUFFICIENT_CAPITAL, reason: 'Exceeded Max Capital Per Segment' };
                }
            }
            const maxLoss = Number(profile.maxDailyLoss);
            if (maxLoss > 0) {
                const currentLoss = Number(snapshot.dailyLoss);
                evaluatedRulesResult['MAX_DAILY_LOSS'] = { currentLoss, maxLoss };
                if (currentLoss >= maxLoss) {
                    await this.logViolation(userId, client_1.RiskRule.MAX_DAILY_LOSS, client_1.Severity.CRITICAL, { currentLoss, maxLoss });
                    await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
                    if (this.redisService.isHealthy()) {
                        await this.redisService.getClient().set(`user:risk:blocked:${userId}`, 'true');
                    }
                    return { approved: false, code: risk_code_enum_1.RiskCode.DAILY_LOSS_LIMIT, reason: 'Exceeded Max Daily Loss Limit' };
                }
            }
            const maxPositions = profile.maxOpenPositions;
            if (maxPositions > 0) {
                const currentOpenPositions = snapshot.openPositionsCount;
                evaluatedRulesResult['MAX_OPEN_POSITIONS'] = { currentOpenPositions, maxPositions };
                if (currentOpenPositions >= maxPositions) {
                    await this.logViolation(userId, client_1.RiskRule.MAX_OPEN_POSITIONS, client_1.Severity.WARNING, { currentOpenPositions, maxPositions });
                    await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
                    return { approved: false, code: risk_code_enum_1.RiskCode.UNKNOWN, reason: 'Exceeded Max Open Positions Limit' };
                }
            }
            const maxPosSize = profile.maxPositionSize;
            if (maxPosSize > 0) {
                const symbolExposures = snapshot.exposurePerSymbol;
                const currentSymbolQty = symbolExposures[symbol]?.quantity || 0;
                const potentialQty = currentSymbolQty + quantity;
                evaluatedRulesResult['MAX_POSITION_SIZE'] = { potentialQty, maxPosSize };
                if (potentialQty > maxPosSize) {
                    await this.logViolation(userId, client_1.RiskRule.MAX_POSITION_SIZE, client_1.Severity.WARNING, { potentialQty, maxPosSize });
                    await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
                    return { approved: false, code: risk_code_enum_1.RiskCode.UNKNOWN, reason: 'Exceeded Max Position Size Limit' };
                }
            }
            const maxSymbolExposure = Number(profile.maxExposurePerSymbol);
            if (maxSymbolExposure > 0) {
                const symbolExposures = snapshot.exposurePerSymbol;
                const currentExposure = symbolExposures[symbol]?.exposure || 0;
                const potentialExposure = currentExposure + orderValue;
                evaluatedRulesResult['MAX_EXPOSURE_SYMBOL'] = { potentialExposure, maxSymbolExposure };
                if (potentialExposure > maxSymbolExposure) {
                    await this.logViolation(userId, client_1.RiskRule.MAX_EXPOSURE_SYMBOL, client_1.Severity.CRITICAL, { potentialExposure, maxSymbolExposure });
                    await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
                    return { approved: false, code: risk_code_enum_1.RiskCode.UNKNOWN, reason: 'Exceeded Max Exposure Per Symbol Limit' };
                }
            }
            const maxBrokerExposure = Number(profile.maxExposurePerBroker);
            if (maxBrokerExposure > 0) {
                const brokerExposures = snapshot.exposurePerBroker;
                const currentExposure = brokerExposures[brokerId] || 0;
                const potentialExposure = currentExposure + orderValue;
                evaluatedRulesResult['MAX_EXPOSURE_BROKER'] = { potentialExposure, maxBrokerExposure };
                if (potentialExposure > maxBrokerExposure) {
                    await this.logViolation(userId, client_1.RiskRule.MAX_EXPOSURE_BROKER, client_1.Severity.CRITICAL, { potentialExposure, maxBrokerExposure });
                    await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
                    return { approved: false, code: risk_code_enum_1.RiskCode.UNKNOWN, reason: 'Exceeded Max Exposure Per Broker Limit' };
                }
            }
            const maxOrders = profile.maxConcurrentOrders;
            if (maxOrders > 0) {
                const currentOrders = snapshot.concurrentOrdersCount;
                evaluatedRulesResult['MAX_CONCURRENT_ORDERS'] = { currentOrders, maxOrders };
                if (currentOrders >= maxOrders) {
                    await this.logViolation(userId, client_1.RiskRule.MAX_CONCURRENT_ORDERS, client_1.Severity.INFO, { currentOrders, maxOrders });
                    await this.logEvaluation(userId, false, profile.version, orderValue, evaluatedRulesResult);
                    return { approved: false, code: risk_code_enum_1.RiskCode.UNKNOWN, reason: 'Exceeded Max Concurrent Orders Limit' };
                }
            }
        }
        const bestProfile = applicableProfiles[0];
        await this.logEvaluation(userId, true, bestProfile.version, orderValue, evaluatedRulesResult);
        return { approved: true };
    }
    async logViolation(userId, rule, severity, details) {
        await this.prisma.riskViolation.create({
            data: {
                userId,
                ruleViolated: rule,
                severity,
                details,
            },
        });
        this.metrics.incrementRiskViolations(rule, severity);
        if (severity === client_1.Severity.CRITICAL && this.redisService.isHealthy()) {
            await this.redisService.getClient().set(`user:risk:blocked:${userId}`, 'true');
            this.metrics.incrementRiskUsersBlocked();
        }
        await this.outboxService.createEvent('RISK_VIOLATION', {
            userId,
            rule,
            severity,
            details,
        });
    }
    async logEvaluation(userId, approved, profileVersion, orderValue, evaluatedRules) {
        await this.prisma.riskEvaluation.create({
            data: {
                userId,
                approved,
                profileVersion,
                orderValue,
                evaluatedRules,
            },
        });
    }
    async recalculateRiskSnapshot(userId) {
        try {
            const openPositions = await this.prisma.position.findMany({
                where: {
                    trade: { userId },
                    status: 'OPEN',
                },
                include: {
                    trade: true,
                },
            });
            let currentCapitalUsed = 0;
            const exposurePerSymbol = {};
            const exposurePerBroker = {};
            for (const pos of openPositions) {
                const qty = Number(pos.quantity);
                const avgPrice = Number(pos.avgPrice);
                const currPrice = Number(pos.currentPrice);
                currentCapitalUsed += qty * avgPrice;
                const symbol = pos.symbol;
                if (!exposurePerSymbol[symbol]) {
                    exposurePerSymbol[symbol] = { quantity: 0, exposure: 0 };
                }
                exposurePerSymbol[symbol].quantity += qty;
                exposurePerSymbol[symbol].exposure += qty * currPrice;
                const brokerId = pos.trade.brokerId;
                exposurePerBroker[brokerId] = (exposurePerBroker[brokerId] || 0) + (qty * currPrice);
            }
            const concurrentOrdersCount = await this.prisma.order.count({
                where: {
                    trade: { userId },
                    status: { in: ['PENDING', 'PLACED', 'PARTIALLY_FILLED'] },
                },
            });
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const todayClosedTrades = await this.prisma.trade.findMany({
                where: {
                    userId,
                    status: 'CLOSED',
                    createdAt: { gte: today },
                },
            });
            let realizedPnL = 0;
            for (const t of todayClosedTrades) {
                realizedPnL += Number(t.pnl || 0);
            }
            let unrealizedPnL = 0;
            for (const pos of openPositions) {
                unrealizedPnL += Number(pos.unrealizedPnl || 0);
            }
            const netDailyPnL = realizedPnL + unrealizedPnL;
            const dailyLoss = netDailyPnL < 0 ? Math.abs(netDailyPnL) : 0;
            this.metrics.setRiskDailyPnl(userId, netDailyPnL);
            const applicableProfiles = await this.prisma.riskProfile.findMany({
                where: {
                    OR: [
                        { userId },
                        { segmentId: { not: null }, userId: null, brokerId: null },
                        { brokerId: { not: null }, userId: null, segmentId: null },
                        { userId: null, segmentId: null, brokerId: null },
                    ]
                },
                orderBy: { priority: 'desc' },
            });
            let state = 'HEALTHY';
            const activeProfile = applicableProfiles[0];
            const profileVersion = activeProfile?.version || 1;
            for (const profile of applicableProfiles) {
                const maxCap = Number(profile.maxCapitalPerUser);
                if (maxCap > 0) {
                    if (currentCapitalUsed >= maxCap) {
                        state = 'BLOCKED';
                    }
                    else if (currentCapitalUsed >= maxCap * 0.8 && state !== 'BLOCKED') {
                        state = 'WARNING';
                    }
                }
                const maxLoss = Number(profile.maxDailyLoss);
                if (maxLoss > 0) {
                    if (dailyLoss >= maxLoss) {
                        state = 'BLOCKED';
                    }
                    else if (dailyLoss >= maxLoss * 0.8 && state !== 'BLOCKED') {
                        state = 'WARNING';
                    }
                }
                const maxOpenPos = profile.maxOpenPositions;
                if (maxOpenPos > 0) {
                    if (openPositions.length >= maxOpenPos) {
                        state = 'BLOCKED';
                    }
                    else if (openPositions.length >= maxOpenPos * 0.8 && state !== 'BLOCKED') {
                        state = 'WARNING';
                    }
                }
                const maxConcurrent = profile.maxConcurrentOrders;
                if (maxConcurrent > 0) {
                    if (concurrentOrdersCount >= maxConcurrent) {
                        state = 'BLOCKED';
                    }
                    else if (concurrentOrdersCount >= maxConcurrent * 0.8 && state !== 'BLOCKED') {
                        state = 'WARNING';
                    }
                }
            }
            const redisKey = `user:risk:blocked:${userId}`;
            if (state === 'BLOCKED' && this.redisService.isHealthy()) {
                await this.redisService.getClient().set(redisKey, 'true');
                this.metrics.incrementRiskUsersBlocked();
            }
            else if (this.redisService.isHealthy()) {
                await this.redisService.getClient().del(redisKey);
            }
            const snapshot = await this.prisma.riskSnapshot.upsert({
                where: { userId },
                update: {
                    state,
                    profileVersion,
                    currentCapitalUsed,
                    dailyLoss,
                    openPositionsCount: openPositions.length,
                    exposurePerSymbol: exposurePerSymbol,
                    exposurePerBroker: exposurePerBroker,
                    concurrentOrdersCount,
                    lastRecalculatedAt: new Date(),
                    lastRecalculationStatus: 'SUCCESS',
                },
                create: {
                    userId,
                    state,
                    profileVersion,
                    currentCapitalUsed,
                    dailyLoss,
                    openPositionsCount: openPositions.length,
                    exposurePerSymbol: exposurePerSymbol,
                    exposurePerBroker: exposurePerBroker,
                    concurrentOrdersCount,
                    lastRecalculatedAt: new Date(),
                    lastRecalculationStatus: 'SUCCESS',
                },
            });
            this.metrics.setRiskState(state, 1);
            if (this.redisService.isHealthy()) {
                const keys = [
                    `analytics:user:${userId}:portfolio`,
                    `analytics:user:${userId}:segments`,
                    `analytics:user:${userId}:broker-stats`,
                ];
                for (const key of keys) {
                    await this.redisService.getClient().del(key);
                }
            }
            return snapshot;
        }
        catch (err) {
            this.logger.error(`Failed to recalculate risk snapshot for user ${userId}: ${err.message}`);
            try {
                await this.prisma.riskSnapshot.upsert({
                    where: { userId },
                    update: {
                        lastRecalculatedAt: new Date(),
                        lastRecalculationStatus: `FAILED: ${err.message.slice(0, 40)}`,
                    },
                    create: {
                        userId,
                        currentCapitalUsed: 0,
                        dailyLoss: 0,
                        openPositionsCount: 0,
                        exposurePerSymbol: {},
                        exposurePerBroker: {},
                        concurrentOrdersCount: 0,
                        lastRecalculatedAt: new Date(),
                        lastRecalculationStatus: `FAILED: ${err.message.slice(0, 40)}`,
                    },
                });
            }
            catch (dbErr) {
                this.logger.error(`Failed to write failed recalculation status to DB for user ${userId}: ${dbErr.message}`);
            }
            throw err;
        }
    }
    async cleanupEvaluations() {
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        this.logger.log(`Running nightly risk evaluations cleanup. Removing records older than: ${thirtyDaysAgo}`);
        try {
            const deleted = await this.prisma.riskEvaluation.deleteMany({
                where: {
                    createdAt: { lt: thirtyDaysAgo },
                },
            });
            this.logger.log(`Pruned ${deleted.count} old risk evaluations.`);
        }
        catch (err) {
            this.logger.error(`Failed to cleanup old risk evaluations: ${err.message}`);
        }
    }
    async createProfile(data) {
        return this.prisma.riskProfile.create({
            data: {
                userId: data.userId || null,
                segmentId: data.segmentId || null,
                brokerId: data.brokerId || null,
                priority: data.priority ?? 0,
                version: 1,
                maxCapitalPerUser: new client_1.Prisma.Decimal(data.maxCapitalPerUser),
                maxCapitalPerSegment: new client_1.Prisma.Decimal(data.maxCapitalPerSegment),
                maxDailyLoss: new client_1.Prisma.Decimal(data.maxDailyLoss),
                maxOpenPositions: data.maxOpenPositions,
                maxPositionSize: data.maxPositionSize,
                maxExposurePerSymbol: new client_1.Prisma.Decimal(data.maxExposurePerSymbol),
                maxExposurePerBroker: new client_1.Prisma.Decimal(data.maxExposurePerBroker),
                maxConcurrentOrders: data.maxConcurrentOrders,
            },
        });
    }
    async updateProfile(id, data) {
        const existing = await this.prisma.riskProfile.findUnique({
            where: { id },
        });
        if (!existing) {
            throw new common_1.NotFoundException(`Risk profile with ID ${id} not found`);
        }
        const updatedData = {};
        if (data.userId !== undefined)
            updatedData.userId = data.userId || null;
        if (data.segmentId !== undefined)
            updatedData.segmentId = data.segmentId || null;
        if (data.brokerId !== undefined)
            updatedData.brokerId = data.brokerId || null;
        if (data.priority !== undefined)
            updatedData.priority = data.priority;
        if (data.maxCapitalPerUser !== undefined)
            updatedData.maxCapitalPerUser = new client_1.Prisma.Decimal(data.maxCapitalPerUser);
        if (data.maxCapitalPerSegment !== undefined)
            updatedData.maxCapitalPerSegment = new client_1.Prisma.Decimal(data.maxCapitalPerSegment);
        if (data.maxDailyLoss !== undefined)
            updatedData.maxDailyLoss = new client_1.Prisma.Decimal(data.maxDailyLoss);
        if (data.maxOpenPositions !== undefined)
            updatedData.maxOpenPositions = data.maxOpenPositions;
        if (data.maxPositionSize !== undefined)
            updatedData.maxPositionSize = data.maxPositionSize;
        if (data.maxExposurePerSymbol !== undefined)
            updatedData.maxExposurePerSymbol = new client_1.Prisma.Decimal(data.maxExposurePerSymbol);
        if (data.maxExposurePerBroker !== undefined)
            updatedData.maxExposurePerBroker = new client_1.Prisma.Decimal(data.maxExposurePerBroker);
        if (data.maxConcurrentOrders !== undefined)
            updatedData.maxConcurrentOrders = data.maxConcurrentOrders;
        return this.prisma.riskProfile.update({
            where: { id },
            data: {
                ...updatedData,
                version: { increment: 1 },
            },
        });
    }
    async getViolations(userId) {
        return this.prisma.riskViolation.findMany({
            where: userId ? { userId } : {},
            orderBy: { createdAt: 'desc' },
        });
    }
    async getSnapshots(userId) {
        return this.prisma.riskSnapshot.findMany({
            where: userId ? { userId } : {},
            orderBy: { updatedAt: 'desc' },
        });
    }
};
exports.RiskService = RiskService;
__decorate([
    (0, schedule_1.Cron)('0 2 * * *'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], RiskService.prototype, "cleanupEvaluations", null);
exports.RiskService = RiskService = RiskService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        subscriptions_service_1.SubscriptionsService,
        consents_service_1.ConsentsService,
        broker_session_service_1.BrokerSessionService,
        broker_factory_1.BrokerFactory,
        audit_service_1.AuditService,
        redis_service_1.RedisService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService,
        outbox_service_1.OutboxService])
], RiskService);
//# sourceMappingURL=risk.service.js.map