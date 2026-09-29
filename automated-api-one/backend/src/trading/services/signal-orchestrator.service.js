"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __esDecorate = (this && this.__esDecorate) || function (ctor, descriptorIn, decorators, contextIn, initializers, extraInitializers) {
    function accept(f) { if (f !== void 0 && typeof f !== "function") throw new TypeError("Function expected"); return f; }
    var kind = contextIn.kind, key = kind === "getter" ? "get" : kind === "setter" ? "set" : "value";
    var target = !descriptorIn && ctor ? contextIn["static"] ? ctor : ctor.prototype : null;
    var descriptor = descriptorIn || (target ? Object.getOwnPropertyDescriptor(target, contextIn.name) : {});
    var _, done = false;
    for (var i = decorators.length - 1; i >= 0; i--) {
        var context = {};
        for (var p in contextIn) context[p] = p === "access" ? {} : contextIn[p];
        for (var p in contextIn.access) context.access[p] = contextIn.access[p];
        context.addInitializer = function (f) { if (done) throw new TypeError("Cannot add initializers after decoration has completed"); extraInitializers.push(accept(f || null)); };
        var result = (0, decorators[i])(kind === "accessor" ? { get: descriptor.get, set: descriptor.set } : descriptor[key], context);
        if (kind === "accessor") {
            if (result === void 0) continue;
            if (result === null || typeof result !== "object") throw new TypeError("Object expected");
            if (_ = accept(result.get)) descriptor.get = _;
            if (_ = accept(result.set)) descriptor.set = _;
            if (_ = accept(result.init)) initializers.unshift(_);
        }
        else if (_ = accept(result)) {
            if (kind === "field") initializers.unshift(_);
            else descriptor[key] = _;
        }
    }
    if (target) Object.defineProperty(target, contextIn.name, descriptor);
    done = true;
};
var __runInitializers = (this && this.__runInitializers) || function (thisArg, initializers, value) {
    var useValue = arguments.length > 2;
    for (var i = 0; i < initializers.length; i++) {
        value = useValue ? initializers[i].call(thisArg, value) : initializers[i].call(thisArg);
    }
    return useValue ? value : void 0;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
var __setFunctionName = (this && this.__setFunctionName) || function (f, name, prefix) {
    if (typeof name === "symbol") name = name.description ? "[".concat(name.description, "]") : "";
    return Object.defineProperty(f, "name", { configurable: true, value: prefix ? "".concat(prefix, " ", name) : name });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SignalOrchestratorService = void 0;
var common_1 = require("@nestjs/common");
var queue_constants_1 = require("../../infrastructure/queues/queue.constants");
var client_1 = require("@prisma/client");
var p_limit_1 = require("p-limit");
var crypto_1 = require("crypto");
var axios_1 = require("axios");
var SUPPORTED_PLANS = ['SPARK', 'SPLENDID'];
var SignalOrchestratorService = function () {
    var _classDecorators = [(0, common_1.Injectable)()];
    var _classDescriptor;
    var _classExtraInitializers = [];
    var _classThis;
    var SignalOrchestratorService = _classThis = /** @class */ (function () {
        function SignalOrchestratorService_1(prisma, queueService, idempotencyService, redisService, multiplierService, positionSizingService, auditService) {
            this.prisma = prisma;
            this.queueService = queueService;
            this.idempotencyService = idempotencyService;
            this.redisService = redisService;
            this.multiplierService = multiplierService;
            this.positionSizingService = positionSizingService;
            this.auditService = auditService;
            this.logger = new common_1.Logger(SignalOrchestratorService.name);
        }
        /**
         * Primary entry point: processes an incoming signal and fans out order
         * placement jobs to all eligible users subscribed to this segment.
         *
         * Architecture guarantees:
         * - Idempotency key prevents duplicate processing of same signal
         * - Redis health assertion before any queue write
         * - p-limit(50) caps concurrent subscriber processing
         * - Each user gets a deterministic BullMQ job ID (prevents duplicate workers)
         * - Execution state snapshot is captured per user at fan-out time
         */
        SignalOrchestratorService_1.prototype.validateTransition = function (current, next) {
            var _a;
            var validTransitions = (_a = {},
                _a[client_1.SignalState.RECEIVED] = [client_1.SignalState.VALIDATED, client_1.SignalState.FAILED],
                _a[client_1.SignalState.VALIDATED] = [client_1.SignalState.PROCESSING, client_1.SignalState.FAILED],
                _a[client_1.SignalState.PROCESSING] = [client_1.SignalState.PROCESSING, client_1.SignalState.COMPLETED, client_1.SignalState.PARTIALLY_COMPLETED, client_1.SignalState.FAILED],
                _a[client_1.SignalState.COMPLETED] = [],
                _a[client_1.SignalState.PARTIALLY_COMPLETED] = [],
                _a[client_1.SignalState.FAILED] = [],
                _a);
            var allowed = validTransitions[current] || [];
            if (!allowed.includes(next)) {
                throw new Error("Invalid SignalState transition: ".concat(current, " -> ").concat(next));
            }
        };
        SignalOrchestratorService_1.prototype.updateExecutionState = function (executionId_1, nextState_1) {
            return __awaiter(this, arguments, void 0, function (executionId, nextState, additionalData) {
                var current;
                if (additionalData === void 0) { additionalData = {}; }
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0: return [4 /*yield*/, this.prisma.segmentExecution.findUnique({
                                where: { id: executionId },
                                select: { state: true },
                            })];
                        case 1:
                            current = _a.sent();
                            if (!current) {
                                throw new Error("SegmentExecution ".concat(executionId, " not found"));
                            }
                            this.validateTransition(current.state, nextState);
                            return [2 /*return*/, this.prisma.segmentExecution.update({
                                    where: { id: executionId },
                                    data: __assign({ state: nextState }, additionalData),
                                })];
                    }
                });
            });
        };
        /**
         * Primary entry point: processes an incoming signal and fans out order
         * placement jobs to all eligible users subscribed to this segment.
         *
         * Architecture guarantees:
         * - Idempotency key prevents duplicate processing of same signal
         * - Redis health assertion before any queue write
         * - p-limit(50) caps concurrent subscriber processing
         * - Each user gets a deterministic BullMQ job ID (prevents duplicate workers)
         * - Execution state snapshot is captured per user at fan-out time
         */
        SignalOrchestratorService_1.prototype.processSignal = function (signalId) {
            return __awaiter(this, void 0, void 0, function () {
                var correlationId, isTradingDisabled, isGlobalRiskBlocked, idempotencyKey, isNew, signal, execution, _a, successUsers, rejectedUsers, totalUsers, errorSummary, finalState, completedAt, processingDurationMs;
                return __generator(this, function (_b) {
                    switch (_b.label) {
                        case 0:
                            correlationId = (0, crypto_1.randomUUID)();
                            this.logger.log("[".concat(correlationId, "] Processing signal ").concat(signalId));
                            // 1. Assert Redis is healthy — trading engine requires Redis
                            this.redisService.assertHealthy();
                            return [4 /*yield*/, this.redisService.getClient().get('trading:global:disabled')];
                        case 1:
                            isTradingDisabled = _b.sent();
                            if (isTradingDisabled === 'true') {
                                this.logger.warn("[".concat(correlationId, "] Signal processing/fan-out blocked due to global trading kill switch"));
                                throw new common_1.ServiceUnavailableException('Trading is disabled globally via kill switch');
                            }
                            return [4 /*yield*/, this.redisService.getClient().get('risk:global:blocked')];
                        case 2:
                            isGlobalRiskBlocked = _b.sent();
                            if (isGlobalRiskBlocked === 'true') {
                                this.logger.warn("[".concat(correlationId, "] Signal processing/fan-out blocked due to global emergency risk lock"));
                                throw new common_1.ServiceUnavailableException('Trading is disabled globally via global emergency risk lock');
                            }
                            idempotencyKey = "signal:fanout:".concat(signalId);
                            return [4 /*yield*/, this.idempotencyService.tryAcquire(idempotencyKey, 'SIGNAL_FANOUT')];
                        case 3:
                            isNew = _b.sent();
                            if (!isNew) {
                                this.logger.warn("[".concat(correlationId, "] Signal ").concat(signalId, " already processed (idempotent skip)"));
                                return [2 /*return*/, {
                                        state: client_1.SignalState.COMPLETED,
                                        totalUsers: 0,
                                        successUsers: 0,
                                        rejectedUsers: 0,
                                        correlationId: correlationId,
                                    }];
                            }
                            return [4 /*yield*/, this.prisma.signal.findUnique({
                                    where: { id: signalId },
                                    include: { segmentRelation: true },
                                })];
                        case 4:
                            signal = _b.sent();
                            if (!!signal) return [3 /*break*/, 6];
                            this.logger.error("[".concat(correlationId, "] Signal ").concat(signalId, " not found"));
                            return [4 /*yield*/, this.idempotencyService.markFailed(idempotencyKey)];
                        case 5:
                            _b.sent();
                            return [2 /*return*/, { state: client_1.SignalState.FAILED, totalUsers: 0, successUsers: 0, rejectedUsers: 0, correlationId: correlationId }];
                        case 6: return [4 /*yield*/, this.prisma.segmentExecution.create({
                                data: {
                                    correlationId: correlationId,
                                    segmentId: signal.segmentId,
                                    signalId: signalId,
                                    state: client_1.SignalState.RECEIVED,
                                    totalUsers: 0,
                                    processedUsers: 0,
                                    successfulUsers: 0,
                                    failedUsers: 0,
                                },
                            })];
                        case 7:
                            execution = _b.sent();
                            if (!!signal.segmentRelation) return [3 /*break*/, 10];
                            this.logger.error("[".concat(correlationId, "] Signal ").concat(signalId, " has no associated segment relation"));
                            return [4 /*yield*/, this.updateExecutionState(execution.id, client_1.SignalState.FAILED, {
                                    errorSummary: 'No associated segment relation found',
                                })];
                        case 8:
                            _b.sent();
                            return [4 /*yield*/, this.idempotencyService.markFailed(idempotencyKey)];
                        case 9:
                            _b.sent();
                            return [2 /*return*/, { state: client_1.SignalState.FAILED, totalUsers: 0, successUsers: 0, rejectedUsers: 0, correlationId: correlationId }];
                        case 10: 
                        // Transition to VALIDATED
                        return [4 /*yield*/, this.updateExecutionState(execution.id, client_1.SignalState.VALIDATED)];
                        case 11:
                            // Transition to VALIDATED
                            _b.sent();
                            // Transition to PROCESSING
                            return [4 /*yield*/, this.updateExecutionState(execution.id, client_1.SignalState.PROCESSING)];
                        case 12:
                            // Transition to PROCESSING
                            _b.sent();
                            this.logger.log("[".concat(correlationId, "] Starting paginated fan-out for signal ").concat(signalId));
                            return [4 /*yield*/, this.paginatedFanOut(signal, correlationId, execution.id)];
                        case 13:
                            _a = _b.sent(), successUsers = _a.successUsers, rejectedUsers = _a.rejectedUsers, totalUsers = _a.totalUsers, errorSummary = _a.errorSummary;
                            finalState = totalUsers === 0
                                ? client_1.SignalState.COMPLETED
                                : rejectedUsers === 0
                                    ? client_1.SignalState.COMPLETED
                                    : successUsers === 0
                                        ? client_1.SignalState.FAILED
                                        : client_1.SignalState.PARTIALLY_COMPLETED;
                            completedAt = new Date();
                            processingDurationMs = completedAt.getTime() - execution.startedAt.getTime();
                            // 6. Complete segment execution summary
                            return [4 /*yield*/, this.updateExecutionState(execution.id, finalState, {
                                    totalUsers: totalUsers,
                                    processedUsers: totalUsers,
                                    successfulUsers: successUsers,
                                    failedUsers: rejectedUsers,
                                    completedAt: completedAt,
                                    errorSummary: errorSummary,
                                    processingDurationMs: processingDurationMs,
                                })];
                        case 14:
                            // 6. Complete segment execution summary
                            _b.sent();
                            // 7. Mark idempotency key as succeeded
                            return [4 /*yield*/, this.idempotencyService.markSuccess(idempotencyKey)];
                        case 15:
                            // 7. Mark idempotency key as succeeded
                            _b.sent();
                            this.logger.log("[".concat(correlationId, "] Signal ").concat(signalId, " fan-out complete. ") +
                                "State=".concat(finalState, " Total=").concat(totalUsers, " Success=").concat(successUsers, " Failed=").concat(rejectedUsers));
                            // Send applied status update to l-l-backend
                            return [4 /*yield*/, this.sendAppliedStatusUpdate(signal.id, totalUsers, successUsers, signal.side, signal.symbol)];
                        case 16:
                            // Send applied status update to l-l-backend
                            _b.sent();
                            return [2 /*return*/, {
                                    state: finalState,
                                    totalUsers: totalUsers,
                                    successUsers: successUsers,
                                    rejectedUsers: rejectedUsers,
                                    correlationId: correlationId,
                                }];
                    }
                });
            });
        };
        SignalOrchestratorService_1.prototype.sendAppliedStatusUpdate = function (signalId, totalUsers, successUsers, side, symbol) {
            return __awaiter(this, void 0, void 0, function () {
                var baseUrl, apiKey, updateText, error_1;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            baseUrl = process.env.LL_BACKEND_URL || 'http://localhost:8080';
                            apiKey = process.env.AUTOMATED_API_KEY || 'default_secret_key';
                            _a.label = 1;
                        case 1:
                            _a.trys.push([1, 3, , 4]);
                            updateText = "Trade Applied: Successfully placed orders for ".concat(successUsers, " users out of ").concat(totalUsers, " for ").concat(side, " ").concat(symbol, ".");
                            return [4 /*yield*/, axios_1.default.post("".concat(baseUrl, "/api/reports/automated-trading-call"), {
                                    rawSignalId: signalId,
                                    isAppliedUpdate: true,
                                    updateText: updateText,
                                    symbol: symbol,
                                    side: side,
                                }, {
                                    headers: {
                                        'x-api-key': apiKey,
                                    },
                                    timeout: 5000,
                                })];
                        case 2:
                            _a.sent();
                            this.logger.log("[Integration] Successfully sent applied status update for signal ".concat(signalId, " to l-l-backend"));
                            return [3 /*break*/, 4];
                        case 3:
                            error_1 = _a.sent();
                            this.logger.error("[Integration] Failed to send applied status update to l-l-backend: ".concat(error_1.message));
                            return [3 /*break*/, 4];
                        case 4: return [2 /*return*/];
                    }
                });
            });
        };
        /**
         * Processes subscribers in cursor-paginated batches to cap peak memory usage.
         *
         * At 10,000 subscribers, loading all at once risks ~50MB heap spikes.
         * Cursor pagination keeps memory bounded at BATCH_SIZE rows per iteration.
         *
         * p-limit(50) constrains concurrent enqueue operations within each batch.
         */
        SignalOrchestratorService_1.prototype.paginatedFanOut = function (signal, correlationId, executionId) {
            return __awaiter(this, void 0, void 0, function () {
                var BATCH_SIZE, limit, totalUsers, successUsers, rejectedUsers, lastCursorId, errors, batch, results, _i, results_1, result, errorSummary;
                var _this = this;
                var _a;
                return __generator(this, function (_b) {
                    switch (_b.label) {
                        case 0:
                            BATCH_SIZE = 500;
                            limit = (0, p_limit_1.default)(50);
                            totalUsers = 0;
                            successUsers = 0;
                            rejectedUsers = 0;
                            errors = [];
                            _b.label = 1;
                        case 1:
                            if (!true) return [3 /*break*/, 5];
                            return [4 /*yield*/, this.fetchSubscriberBatch(signal.segmentId, BATCH_SIZE, lastCursorId)];
                        case 2:
                            batch = _b.sent();
                            if (batch.length === 0)
                                return [3 /*break*/, 5];
                            totalUsers += batch.length;
                            lastCursorId = batch[batch.length - 1].userSegmentId;
                            return [4 /*yield*/, Promise.allSettled(batch.map(function (subscriber) {
                                    return limit(function () { return __awaiter(_this, void 0, void 0, function () {
                                        var enqueued, err_1, msg;
                                        return __generator(this, function (_a) {
                                            switch (_a.label) {
                                                case 0:
                                                    _a.trys.push([0, 2, , 3]);
                                                    return [4 /*yield*/, this.enqueueForUser(signal, subscriber, correlationId)];
                                                case 1:
                                                    enqueued = _a.sent();
                                                    return [2 /*return*/, { status: enqueued ? 'success' : 'rejected' }];
                                                case 2:
                                                    err_1 = _a.sent();
                                                    msg = "User ".concat(subscriber.userId, ": ").concat(err_1.message);
                                                    return [2 /*return*/, { status: 'rejected', error: msg }];
                                                case 3: return [2 /*return*/];
                                            }
                                        });
                                    }); });
                                }))];
                        case 3:
                            results = _b.sent();
                            for (_i = 0, results_1 = results; _i < results_1.length; _i++) {
                                result = results_1[_i];
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
                                    errors.push(((_a = result.reason) === null || _a === void 0 ? void 0 : _a.message) || 'Unknown error');
                                }
                            }
                            // Update database progress tracking for this batch with state validation
                            return [4 /*yield*/, this.updateExecutionState(executionId, client_1.SignalState.PROCESSING, {
                                    totalUsers: totalUsers,
                                    processedUsers: totalUsers,
                                    successfulUsers: successUsers,
                                    failedUsers: rejectedUsers,
                                })];
                        case 4:
                            // Update database progress tracking for this batch with state validation
                            _b.sent();
                            this.logger.debug("[".concat(correlationId, "] Batch processed: ").concat(batch.length, " users. ") +
                                "Running totals \u2014 success=".concat(successUsers, " failed=").concat(rejectedUsers));
                            // Short-circuit if batch was smaller than page size (final page)
                            if (batch.length < BATCH_SIZE)
                                return [3 /*break*/, 5];
                            return [3 /*break*/, 1];
                        case 5:
                            errorSummary = errors.length > 0 ? errors.slice(0, 100).join('; ') : undefined;
                            return [2 /*return*/, { totalUsers: totalUsers, successUsers: successUsers, rejectedUsers: rejectedUsers, errorSummary: errorSummary }];
                    }
                });
            });
        };
        /**
         * Fetches a single page of eligible subscribers using cursor-based pagination.
         */
        SignalOrchestratorService_1.prototype.fetchSubscriberBatch = function (segmentId, take, afterId) {
            return __awaiter(this, void 0, void 0, function () {
                var today, userSegments, rows, _i, userSegments_1, us, activeUserBroker, activeSub, planName;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            today = new Date();
                            today.setHours(0, 0, 0, 0);
                            return [4 /*yield*/, this.prisma.userSegment.findMany(__assign({ where: {
                                        segmentId: segmentId,
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
                                    }, include: {
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
                                    }, orderBy: { id: 'asc' }, take: take }, (afterId ? { cursor: { id: afterId }, skip: 1 } : {})))];
                        case 1:
                            userSegments = _a.sent();
                            rows = [];
                            for (_i = 0, userSegments_1 = userSegments; _i < userSegments_1.length; _i++) {
                                us = userSegments_1[_i];
                                activeUserBroker = us.user.userBrokers[0];
                                activeSub = us.user.subscriptions[0];
                                if (!activeUserBroker || !activeSub)
                                    continue;
                                planName = this.resolvePlan(activeSub.planId);
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
                            return [2 /*return*/, rows];
                    }
                });
            });
        };
        /**
         * Builds a UserExecutionSnapshot and enqueues an order placement job.
         * Returns true if enqueued, false if skipped (eligibility check failed).
         */
        SignalOrchestratorService_1.prototype.enqueueForUser = function (signal, subscriber, correlationId) {
            return __awaiter(this, void 0, void 0, function () {
                var userBlocked, jobId, sizing, multiplier, effectiveLot, entryPrice, snapshot, ctx;
                var _a, _b;
                return __generator(this, function (_c) {
                    switch (_c.label) {
                        case 0:
                            if (!this.redisService.isHealthy()) return [3 /*break*/, 2];
                            return [4 /*yield*/, this.redisService.getClient().get("user:risk:blocked:".concat(subscriber.userId))];
                        case 1:
                            userBlocked = _c.sent();
                            if (userBlocked === 'true') {
                                this.logger.warn("[".concat(correlationId, "] Skip fanning out to user ").concat(subscriber.userId, " due to risk lock"));
                                return [2 /*return*/, false];
                            }
                            _c.label = 2;
                        case 2:
                            jobId = "job-".concat(signal.id, "-").concat(subscriber.userId);
                            return [4 /*yield*/, this.positionSizingService.calculatePositionSize(subscriber.userId, signal.segmentId, subscriber.baseLot, Number(signal.entryPrice))];
                        case 3:
                            sizing = _c.sent();
                            multiplier = sizing.multiplier;
                            if (((_b = (_a = signal.segmentRelation) === null || _a === void 0 ? void 0 : _a.name) === null || _b === void 0 ? void 0 : _b.toUpperCase()) === 'EQUITY CASH') {
                                entryPrice = Number(signal.entryPrice);
                                if (!entryPrice || entryPrice <= 0) {
                                    throw new Error('Invalid entry price for EQUITY CASH signal');
                                }
                                effectiveLot = Math.floor((subscriber.baseLot * multiplier) / entryPrice);
                                if (effectiveLot < 1) {
                                    throw new Error('Calculated quantity is zero');
                                }
                            }
                            else {
                                effectiveLot = sizing.actualQuantity;
                            }
                            snapshot = {
                                userId: subscriber.userId,
                                brokerId: subscriber.brokerId,
                                brokerCode: subscriber.brokerCode,
                                brokerClientId: subscriber.brokerClientId,
                                segmentId: signal.segmentId,
                                subscriptionPlan: subscriber.plan,
                                multiplierIndex: sizing.consecutiveLosses,
                                multiplierValue: multiplier,
                                capitalAllocated: subscriber.capital,
                                baseLot: subscriber.baseLot,
                                effectiveLot: effectiveLot,
                                strategyType: sizing.strategyType,
                                strategyVersion: sizing.strategyVersion,
                                baseQuantity: sizing.baseQuantity,
                                actualQuantity: effectiveLot,
                                consecutiveLossesAtEntry: sizing.consecutiveLosses,
                                previousTradeResult: sizing.previousTradeResult,
                                agreementVersion: sizing.agreementVersion,
                            };
                            ctx = {
                                correlationId: correlationId,
                                jobId: jobId,
                                signalId: signal.id,
                                segmentId: signal.segmentId,
                                symbol: signal.symbol,
                                exchange: signal.exchange,
                                side: signal.side,
                                orderType: signal.orderType,
                                entryPrice: Number(signal.entryPrice),
                                stopLoss: Number(signal.stopLoss),
                                targetPrice: Number(signal.targetPrice),
                                snapshot: snapshot,
                            };
                            return [4 /*yield*/, this.queueService.addJob(queue_constants_1.Queues.ORDER_PLACEMENT, jobId, ctx)];
                        case 4:
                            _c.sent();
                            this.logger.debug("[".concat(correlationId, "] Enqueued job ").concat(jobId, " for user ").concat(subscriber.userId, " ") +
                                "(lot=".concat(snapshot.effectiveLot, " multiplier=").concat(multiplier, "x)"));
                            return [2 /*return*/, true];
                    }
                });
            });
        };
        /**
         * Resolves a planId to a plan type string.
         * In production this should query the plan table; here we derive from planId prefix.
         */
        SignalOrchestratorService_1.prototype.resolvePlan = function (planId) {
            // TODO: Query the Plan table when it exists
            // For now we default to SPARK as both plans are eligible for trading
            return 'SPARK';
        };
        return SignalOrchestratorService_1;
    }());
    __setFunctionName(_classThis, "SignalOrchestratorService");
    (function () {
        var _metadata = typeof Symbol === "function" && Symbol.metadata ? Object.create(null) : void 0;
        __esDecorate(null, _classDescriptor = { value: _classThis }, _classDecorators, { kind: "class", name: _classThis.name, metadata: _metadata }, null, _classExtraInitializers);
        SignalOrchestratorService = _classThis = _classDescriptor.value;
        if (_metadata) Object.defineProperty(_classThis, Symbol.metadata, { enumerable: true, configurable: true, writable: true, value: _metadata });
        __runInitializers(_classThis, _classExtraInitializers);
    })();
    return SignalOrchestratorService = _classThis;
}();
exports.SignalOrchestratorService = SignalOrchestratorService;
