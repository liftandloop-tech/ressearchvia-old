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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var SignalOrchestratorService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SignalOrchestratorService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma.service");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const idempotency_service_1 = require("../../infrastructure/idempotency/idempotency.service");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const multiplier_service_1 = require("./multiplier.service");
const audit_service_1 = require("../../audit/audit.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const client_1 = require("@prisma/client");
const p_limit_1 = __importDefault(require("p-limit"));
const crypto_1 = require("crypto");
const axios_1 = __importDefault(require("axios"));
const SUPPORTED_PLANS = ['SPARK', 'SPLENDID'];
let SignalOrchestratorService = SignalOrchestratorService_1 = class SignalOrchestratorService {
    prisma;
    queueService;
    idempotencyService;
    redisService;
    multiplierService;
    auditService;
    logger = new common_1.Logger(SignalOrchestratorService_1.name);
    constructor(prisma, queueService, idempotencyService, redisService, multiplierService, auditService) {
        this.prisma = prisma;
        this.queueService = queueService;
        this.idempotencyService = idempotencyService;
        this.redisService = redisService;
        this.multiplierService = multiplierService;
        this.auditService = auditService;
    }
    validateTransition(current, next) {
        const validTransitions = {
            [client_1.SignalState.RECEIVED]: [client_1.SignalState.VALIDATED, client_1.SignalState.FAILED],
            [client_1.SignalState.VALIDATED]: [client_1.SignalState.PROCESSING, client_1.SignalState.FAILED],
            [client_1.SignalState.PROCESSING]: [client_1.SignalState.PROCESSING, client_1.SignalState.COMPLETED, client_1.SignalState.PARTIALLY_COMPLETED, client_1.SignalState.FAILED],
            [client_1.SignalState.COMPLETED]: [],
            [client_1.SignalState.PARTIALLY_COMPLETED]: [],
            [client_1.SignalState.FAILED]: [],
        };
        const allowed = validTransitions[current] || [];
        if (!allowed.includes(next)) {
            throw new Error(`Invalid SignalState transition: ${current} -> ${next}`);
        }
    }
    async updateExecutionState(executionId, nextState, additionalData = {}) {
        const current = await this.prisma.segmentExecution.findUnique({
            where: { id: executionId },
            select: { state: true },
        });
        if (!current) {
            throw new Error(`SegmentExecution ${executionId} not found`);
        }
        this.validateTransition(current.state, nextState);
        return this.prisma.segmentExecution.update({
            where: { id: executionId },
            data: {
                state: nextState,
                ...additionalData,
            },
        });
    }
    async processSignal(signalId) {
        const correlationId = (0, crypto_1.randomUUID)();
        this.logger.log(`[${correlationId}] Processing signal ${signalId}`);
        this.redisService.assertHealthy();
        const isTradingDisabled = await this.redisService.getClient().get('trading:global:disabled');
        if (isTradingDisabled === 'true') {
            this.logger.warn(`[${correlationId}] Signal processing/fan-out blocked due to global trading kill switch`);
            throw new common_1.ServiceUnavailableException('Trading is disabled globally via kill switch');
        }
        const isGlobalRiskBlocked = await this.redisService.getClient().get('risk:global:blocked');
        if (isGlobalRiskBlocked === 'true') {
            this.logger.warn(`[${correlationId}] Signal processing/fan-out blocked due to global emergency risk lock`);
            throw new common_1.ServiceUnavailableException('Trading is disabled globally via global emergency risk lock');
        }
        const idempotencyKey = `signal:fanout:${signalId}`;
        const isNew = await this.idempotencyService.tryAcquire(idempotencyKey, 'SIGNAL_FANOUT');
        if (!isNew) {
            this.logger.warn(`[${correlationId}] Signal ${signalId} already processed (idempotent skip)`);
            return {
                state: client_1.SignalState.COMPLETED,
                totalUsers: 0,
                successUsers: 0,
                rejectedUsers: 0,
                correlationId,
            };
        }
        const signal = await this.prisma.signal.findUnique({
            where: { id: signalId },
            include: { segmentRelation: true },
        });
        if (!signal) {
            this.logger.error(`[${correlationId}] Signal ${signalId} not found`);
            await this.idempotencyService.markFailed(idempotencyKey);
            return { state: client_1.SignalState.FAILED, totalUsers: 0, successUsers: 0, rejectedUsers: 0, correlationId };
        }
        const execution = await this.prisma.segmentExecution.create({
            data: {
                correlationId,
                segmentId: signal.segmentId,
                signalId,
                state: client_1.SignalState.RECEIVED,
                totalUsers: 0,
                processedUsers: 0,
                successfulUsers: 0,
                failedUsers: 0,
            },
        });
        if (!signal.segmentRelation) {
            this.logger.error(`[${correlationId}] Signal ${signalId} has no associated segment relation`);
            await this.updateExecutionState(execution.id, client_1.SignalState.FAILED, {
                errorSummary: 'No associated segment relation found',
            });
            await this.idempotencyService.markFailed(idempotencyKey);
            return { state: client_1.SignalState.FAILED, totalUsers: 0, successUsers: 0, rejectedUsers: 0, correlationId };
        }
        await this.updateExecutionState(execution.id, client_1.SignalState.VALIDATED);
        await this.updateExecutionState(execution.id, client_1.SignalState.PROCESSING);
        this.logger.log(`[${correlationId}] Starting paginated fan-out for signal ${signalId}`);
        const { successUsers, rejectedUsers, totalUsers, errorSummary } = await this.paginatedFanOut(signal, correlationId, execution.id);
        const finalState = totalUsers === 0
            ? client_1.SignalState.COMPLETED
            : rejectedUsers === 0
                ? client_1.SignalState.COMPLETED
                : successUsers === 0
                    ? client_1.SignalState.FAILED
                    : client_1.SignalState.PARTIALLY_COMPLETED;
        const completedAt = new Date();
        const processingDurationMs = completedAt.getTime() - execution.startedAt.getTime();
        await this.updateExecutionState(execution.id, finalState, {
            totalUsers,
            processedUsers: totalUsers,
            successfulUsers: successUsers,
            failedUsers: rejectedUsers,
            completedAt,
            errorSummary,
            processingDurationMs,
        });
        await this.idempotencyService.markSuccess(idempotencyKey);
        this.logger.log(`[${correlationId}] Signal ${signalId} fan-out complete. ` +
            `State=${finalState} Total=${totalUsers} Success=${successUsers} Failed=${rejectedUsers}`);
        await this.sendAppliedStatusUpdate(signal.id, totalUsers, successUsers, signal.side, signal.symbol);
        return {
            state: finalState,
            totalUsers,
            successUsers,
            rejectedUsers,
            correlationId,
        };
    }
    async sendAppliedStatusUpdate(signalId, totalUsers, successUsers, side, symbol) {
        const baseUrl = process.env.LL_BACKEND_URL || 'http://localhost:8080';
        const apiKey = process.env.AUTOMATED_API_KEY || 'default_secret_key';
        try {
            const updateText = `Trade Applied: Successfully placed orders for ${successUsers} users out of ${totalUsers} for ${side} ${symbol}.`;
            await axios_1.default.post(`${baseUrl}/api/reports/automated-trading-call`, {
                rawSignalId: signalId,
                isAppliedUpdate: true,
                updateText,
                symbol,
                side,
            }, {
                headers: {
                    'x-api-key': apiKey,
                },
                timeout: 5000,
            });
            this.logger.log(`[Integration] Successfully sent applied status update for signal ${signalId} to l-l-backend`);
        }
        catch (error) {
            this.logger.error(`[Integration] Failed to send applied status update to l-l-backend: ${error.message}`);
        }
    }
    async paginatedFanOut(signal, correlationId, executionId) {
        const BATCH_SIZE = 500;
        const limit = (0, p_limit_1.default)(50);
        let totalUsers = 0;
        let successUsers = 0;
        let rejectedUsers = 0;
        let lastCursorId;
        const errors = [];
        while (true) {
            const batch = await this.fetchSubscriberBatch(signal.segmentId, BATCH_SIZE, lastCursorId);
            if (batch.length === 0)
                break;
            totalUsers += batch.length;
            lastCursorId = batch[batch.length - 1].userSegmentId;
            const results = await Promise.allSettled(batch.map((subscriber) => limit(async () => {
                try {
                    const enqueued = await this.enqueueForUser(signal, subscriber, correlationId);
                    return { status: enqueued ? 'success' : 'rejected' };
                }
                catch (err) {
                    const msg = `User ${subscriber.userId}: ${err.message}`;
                    return { status: 'rejected', error: msg };
                }
            })));
            for (const result of results) {
                if (result.status === 'fulfilled') {
                    if (result.value.status === 'success') {
                        successUsers++;
                    }
                    else {
                        rejectedUsers++;
                        if (result.value.error) {
                            errors.push(result.value.error);
                        }
                    }
                }
                else {
                    rejectedUsers++;
                    errors.push(result.reason?.message || 'Unknown error');
                }
            }
            await this.updateExecutionState(executionId, client_1.SignalState.PROCESSING, {
                totalUsers,
                processedUsers: totalUsers,
                successfulUsers: successUsers,
                failedUsers: rejectedUsers,
            });
            this.logger.debug(`[${correlationId}] Batch processed: ${batch.length} users. ` +
                `Running totals — success=${successUsers} failed=${rejectedUsers}`);
            if (batch.length < BATCH_SIZE)
                break;
        }
        const errorSummary = errors.length > 0 ? errors.slice(0, 100).join('; ') : undefined;
        return { totalUsers, successUsers, rejectedUsers, errorSummary };
    }
    async fetchSubscriberBatch(segmentId, take, afterId) {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const userSegments = await this.prisma.userSegment.findMany({
            where: {
                segmentId,
                status: client_1.UserSegmentStatus.ACTIVE,
                deletedAt: null,
                user: {
                    subscriptions: {
                        some: {
                            status: client_1.SubscriptionStatus.ACTIVE,
                            startDate: { lte: new Date() },
                            endDate: { gte: new Date() },
                        },
                    },
                    consents: {
                        some: {
                            consentDate: { gte: today },
                            status: client_1.ConsentStatus.ACTIVE,
                        },
                    },
                    userBrokers: {
                        some: { status: client_1.BrokerStatus.ACTIVE },
                    },
                },
            },
            include: {
                user: {
                    include: {
                        subscriptions: {
                            where: {
                                status: client_1.SubscriptionStatus.ACTIVE,
                                startDate: { lte: new Date() },
                                endDate: { gte: new Date() },
                            },
                            take: 1,
                            orderBy: { startDate: 'desc' },
                        },
                        userBrokers: {
                            where: { status: client_1.BrokerStatus.ACTIVE },
                            include: { broker: true },
                            take: 1,
                        },
                    },
                },
            },
            orderBy: { id: 'asc' },
            take,
            ...(afterId ? { cursor: { id: afterId }, skip: 1 } : {}),
        });
        const rows = [];
        for (const us of userSegments) {
            const activeUserBroker = us.user.userBrokers[0];
            const activeSub = us.user.subscriptions[0];
            if (!activeUserBroker || !activeSub)
                continue;
            const planName = this.resolvePlan(activeSub.planId);
            if (!planName)
                continue;
            rows.push({
                userSegmentId: us.id,
                userId: us.userId,
                segmentId: us.segmentId,
                brokerId: activeUserBroker.brokerId,
                brokerCode: activeUserBroker.broker.code,
                brokerClientId: activeUserBroker.brokerClientId,
                capital: Number(us.capital),
                baseLot: us.baseLot,
                plan: planName,
            });
        }
        return rows;
    }
    async enqueueForUser(signal, subscriber, correlationId) {
        if (this.redisService.isHealthy()) {
            const userBlocked = await this.redisService.getClient().get(`user:risk:blocked:${subscriber.userId}`);
            if (userBlocked === 'true') {
                this.logger.warn(`[${correlationId}] Skip fanning out to user ${subscriber.userId} due to risk lock`);
                return false;
            }
        }
        const jobId = `job-${signal.id}-${subscriber.userId}`;
        const multiplierState = await this.multiplierService.getState(subscriber.userId, signal.segmentId);
        const multiplier = multiplierState.current;
        let effectiveLot;
        if (signal.segmentRelation?.name?.toUpperCase() === 'EQUITY CASH') {
            const entryPrice = Number(signal.entryPrice);
            if (!entryPrice || entryPrice <= 0) {
                throw new Error('Invalid entry price for EQUITY CASH signal');
            }
            effectiveLot = Math.floor((subscriber.baseLot * multiplier) / entryPrice);
            if (effectiveLot < 1) {
                throw new Error('Calculated quantity is zero');
            }
        }
        else {
            effectiveLot = subscriber.baseLot * multiplier;
        }
        const snapshot = {
            userId: subscriber.userId,
            brokerId: subscriber.brokerId,
            brokerCode: subscriber.brokerCode,
            brokerClientId: subscriber.brokerClientId,
            segmentId: signal.segmentId,
            subscriptionPlan: subscriber.plan,
            multiplierIndex: multiplierState.index,
            multiplierValue: multiplier,
            capitalAllocated: subscriber.capital,
            baseLot: subscriber.baseLot,
            effectiveLot,
        };
        const ctx = {
            correlationId,
            jobId,
            signalId: signal.id,
            segmentId: signal.segmentId,
            symbol: signal.symbol,
            exchange: signal.exchange,
            side: signal.side,
            orderType: signal.orderType,
            entryPrice: Number(signal.entryPrice),
            stopLoss: Number(signal.stopLoss),
            targetPrice: Number(signal.targetPrice),
            snapshot,
        };
        await this.queueService.addJob(queue_constants_1.Queues.ORDER_PLACEMENT, jobId, ctx);
        this.logger.debug(`[${correlationId}] Enqueued job ${jobId} for user ${subscriber.userId} ` +
            `(lot=${snapshot.effectiveLot} multiplier=${multiplierState.current}x)`);
        return true;
    }
    resolvePlan(planId) {
        return 'SPARK';
    }
};
exports.SignalOrchestratorService = SignalOrchestratorService;
exports.SignalOrchestratorService = SignalOrchestratorService = SignalOrchestratorService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        queues_service_1.QueueService,
        idempotency_service_1.IdempotencyService,
        redis_service_1.RedisService,
        multiplier_service_1.MultiplierService,
        audit_service_1.AuditService])
], SignalOrchestratorService);
//# sourceMappingURL=signal-orchestrator.service.js.map