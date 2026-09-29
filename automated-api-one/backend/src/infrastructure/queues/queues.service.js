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
var __spreadArray = (this && this.__spreadArray) || function (to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
};
var _a;
Object.defineProperty(exports, "__esModule", { value: true });
exports.QueueService = void 0;
var common_1 = require("@nestjs/common");
var bullmq_1 = require("bullmq");
var queue_constants_1 = require("./queue.constants");
var client_1 = require("@prisma/client");
var QUEUE_LIMITS = (_a = {},
    _a[queue_constants_1.Queues.ORDER_PLACEMENT] = 50000,
    _a[queue_constants_1.Queues.ORDER_MONITORING] = 100000,
    _a[queue_constants_1.Queues.NOTIFICATION] = 250000,
    _a);
var QueueService = function () {
    var _classDecorators = [(0, common_1.Injectable)()];
    var _classDescriptor;
    var _classExtraInitializers = [];
    var _classThis;
    var QueueService = _classThis = /** @class */ (function () {
        function QueueService_1(prisma, redisService, signalQueue, orderPlacementQueue, orderMonitoringQueue, notificationQueue, signalDlq, orderDlq, orderMonitoringDlq, notificationDlq, outboxDispatcherQueue, outboxDispatcherDlq, websocketQueue, websocketDlq, reportGenerationQueue, reportGenerationDlq, reportExportQueue, reportExportDlq, analyticsSnapshotQueue, analyticsSnapshotDlq, positionRebuildQueue, positionRebuildDlq, reconciliationQueue, reconciliationDlq, riskRecalculateQueue, riskRecalculateDlq, analyticsRecalculateQueue, analyticsRecalculateDlq, emailQueue, emailDlq, smsQueue, smsDlq, whatsappQueue, whatsappDlq, pushQueue, pushDlq) {
            this.prisma = prisma;
            this.redisService = redisService;
            this.signalQueue = signalQueue;
            this.orderPlacementQueue = orderPlacementQueue;
            this.orderMonitoringQueue = orderMonitoringQueue;
            this.notificationQueue = notificationQueue;
            this.signalDlq = signalDlq;
            this.orderDlq = orderDlq;
            this.orderMonitoringDlq = orderMonitoringDlq;
            this.notificationDlq = notificationDlq;
            this.outboxDispatcherQueue = outboxDispatcherQueue;
            this.outboxDispatcherDlq = outboxDispatcherDlq;
            this.websocketQueue = websocketQueue;
            this.websocketDlq = websocketDlq;
            this.reportGenerationQueue = reportGenerationQueue;
            this.reportGenerationDlq = reportGenerationDlq;
            this.reportExportQueue = reportExportQueue;
            this.reportExportDlq = reportExportDlq;
            this.analyticsSnapshotQueue = analyticsSnapshotQueue;
            this.analyticsSnapshotDlq = analyticsSnapshotDlq;
            this.positionRebuildQueue = positionRebuildQueue;
            this.positionRebuildDlq = positionRebuildDlq;
            this.reconciliationQueue = reconciliationQueue;
            this.reconciliationDlq = reconciliationDlq;
            this.riskRecalculateQueue = riskRecalculateQueue;
            this.riskRecalculateDlq = riskRecalculateDlq;
            this.analyticsRecalculateQueue = analyticsRecalculateQueue;
            this.analyticsRecalculateDlq = analyticsRecalculateDlq;
            this.emailQueue = emailQueue;
            this.emailDlq = emailDlq;
            this.smsQueue = smsQueue;
            this.smsDlq = smsDlq;
            this.whatsappQueue = whatsappQueue;
            this.whatsappDlq = whatsappDlq;
            this.pushQueue = pushQueue;
            this.pushDlq = pushDlq;
            this.logger = new common_1.Logger(QueueService.name);
            this.shardedSnapshotQueues = new Map();
            this.flowProducer = new bullmq_1.FlowProducer({
                connection: this.redisService.getClient(),
            });
        }
        QueueService_1.prototype.getFlowProducer = function () {
            return this.flowProducer;
        };
        QueueService_1.prototype.getQueue = function (queueName) {
            switch (queueName) {
                case queue_constants_1.Queues.SIGNAL_PROCESSING:
                    return this.signalQueue;
                case queue_constants_1.Queues.ORDER_PLACEMENT:
                    return this.orderPlacementQueue;
                case queue_constants_1.Queues.ORDER_MONITORING:
                    return this.orderMonitoringQueue;
                case queue_constants_1.Queues.NOTIFICATION:
                    return this.notificationQueue;
                case queue_constants_1.Queues.SIGNAL_DLQ:
                    return this.signalDlq;
                case queue_constants_1.Queues.ORDER_DLQ:
                    return this.orderDlq;
                case queue_constants_1.Queues.ORDER_MONITORING_DLQ:
                    return this.orderMonitoringDlq;
                case queue_constants_1.Queues.NOTIFICATION_DLQ:
                    return this.notificationDlq;
                case queue_constants_1.Queues.OUTBOX_DISPATCHER:
                    return this.outboxDispatcherQueue;
                case queue_constants_1.Queues.OUTBOX_DISPATCHER_DLQ:
                    return this.outboxDispatcherDlq;
                case queue_constants_1.Queues.WEBSOCKET:
                    return this.websocketQueue;
                case queue_constants_1.Queues.WEBSOCKET_DLQ:
                    return this.websocketDlq;
                case queue_constants_1.Queues.REPORT_GENERATION:
                    return this.reportGenerationQueue;
                case queue_constants_1.Queues.REPORT_GENERATION_DLQ:
                    return this.reportGenerationDlq;
                case queue_constants_1.Queues.REPORT_EXPORT:
                    return this.reportExportQueue;
                case queue_constants_1.Queues.REPORT_EXPORT_DLQ:
                    return this.reportExportDlq;
                case queue_constants_1.Queues.ANALYTICS_SNAPSHOT:
                    return this.analyticsSnapshotQueue;
                case queue_constants_1.Queues.ANALYTICS_SNAPSHOT_DLQ:
                    return this.analyticsSnapshotDlq;
                case queue_constants_1.Queues.POSITION_REBUILD:
                    return this.positionRebuildQueue;
                case queue_constants_1.Queues.POSITION_REBUILD_DLQ:
                    return this.positionRebuildDlq;
                case queue_constants_1.Queues.RECONCILIATION:
                    return this.reconciliationQueue;
                case queue_constants_1.Queues.RECONCILIATION_DLQ:
                    return this.reconciliationDlq;
                case queue_constants_1.Queues.RISK_RECALCULATE:
                    return this.riskRecalculateQueue;
                case queue_constants_1.Queues.RISK_RECALCULATE_DLQ:
                    return this.riskRecalculateDlq;
                case queue_constants_1.Queues.ANALYTICS_RECALCULATE:
                    return this.analyticsRecalculateQueue;
                case queue_constants_1.Queues.ANALYTICS_RECALCULATE_DLQ:
                    return this.analyticsRecalculateDlq;
                case queue_constants_1.Queues.EMAIL:
                    return this.emailQueue;
                case queue_constants_1.Queues.EMAIL_DLQ:
                    return this.emailDlq;
                case queue_constants_1.Queues.SMS:
                    return this.smsQueue;
                case queue_constants_1.Queues.SMS_DLQ:
                    return this.smsDlq;
                case queue_constants_1.Queues.WHATSAPP:
                    return this.whatsappQueue;
                case queue_constants_1.Queues.WHATSAPP_DLQ:
                    return this.whatsappDlq;
                case queue_constants_1.Queues.PUSH:
                    return this.pushQueue;
                case queue_constants_1.Queues.PUSH_DLQ:
                    return this.pushDlq;
                default:
                    if (queueName.startsWith('analytics-snapshot-dlq-')) {
                        var q = this.shardedSnapshotQueues.get(queueName);
                        if (!q) {
                            q = new bullmq_1.Queue(queueName, { connection: this.redisService.getClient() });
                            this.shardedSnapshotQueues.set(queueName, q);
                        }
                        return q;
                    }
                    if (queueName.startsWith('analytics-snapshot-')) {
                        var q = this.shardedSnapshotQueues.get(queueName);
                        if (!q) {
                            q = new bullmq_1.Queue(queueName, { connection: this.redisService.getClient() });
                            this.shardedSnapshotQueues.set(queueName, q);
                        }
                        return q;
                    }
                    throw new Error("Queue '".concat(queueName, "' not found"));
            }
        };
        /**
         * Enqueues a job into a BullMQ queue and records it in the database.
         */
        QueueService_1.prototype.addJob = function (queueName, jobId, payload, priority, delay) {
            return __awaiter(this, void 0, void 0, function () {
                var queue, limit, waiting, err_1;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            this.redisService.assertHealthy();
                            queue = this.getQueue(queueName);
                            limit = QUEUE_LIMITS[queueName];
                            if (!(limit !== undefined)) return [3 /*break*/, 2];
                            return [4 /*yield*/, queue.getWaitingCount()];
                        case 1:
                            waiting = _a.sent();
                            if (waiting >= limit) {
                                this.logger.warn("Queue '".concat(queueName, "' backpressure limit exceeded: waiting=").concat(waiting, ", limit=").concat(limit));
                                throw new common_1.ServiceUnavailableException("Queue '".concat(queueName, "' is overloaded"));
                            }
                            _a.label = 2;
                        case 2:
                            _a.trys.push([2, 5, , 6]);
                            // 1. Record job in database
                            return [4 /*yield*/, this.prisma.queueJob.upsert({
                                    where: {
                                        queueName_jobId: { queueName: queueName, jobId: jobId },
                                    },
                                    update: {
                                        payload: payload || {},
                                        status: client_1.QueueJobStatus.ACTIVE,
                                        attempts: 0,
                                        updatedAt: new Date(),
                                    },
                                    create: {
                                        queueName: queueName,
                                        jobId: jobId,
                                        payload: payload || {},
                                        status: client_1.QueueJobStatus.ACTIVE,
                                        attempts: 0,
                                    },
                                })];
                        case 3:
                            // 1. Record job in database
                            _a.sent();
                            // 2. Publish to BullMQ
                            return [4 /*yield*/, queue.add(jobId, payload, {
                                    jobId: jobId,
                                    priority: priority,
                                    delay: delay,
                                    attempts: 3,
                                    backoff: {
                                        type: 'exponential',
                                        delay: 1000,
                                    },
                                })];
                        case 4:
                            // 2. Publish to BullMQ
                            _a.sent();
                            this.logger.log("Enqueued job ".concat(jobId, " to queue ").concat(queueName, " (Priority: ").concat(priority || 'none', ", Delay: ").concat(delay || 'none', ")"));
                            return [3 /*break*/, 6];
                        case 5:
                            err_1 = _a.sent();
                            this.logger.error("Failed to add job ".concat(jobId, " to queue ").concat(queueName, ": ").concat(err_1.message));
                            throw err_1;
                        case 6: return [2 /*return*/];
                    }
                });
            });
        };
        /**
         * Updates job status and attempts count inside the QueueJob database table.
         */
        QueueService_1.prototype.updateJobStatus = function (queueName, jobId, status, attempts) {
            return __awaiter(this, void 0, void 0, function () {
                var err_2;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            _a.trys.push([0, 2, , 3]);
                            return [4 /*yield*/, this.prisma.queueJob.update({
                                    where: {
                                        queueName_jobId: { queueName: queueName, jobId: jobId },
                                    },
                                    data: __assign(__assign({ status: status }, (attempts !== undefined ? { attempts: attempts } : {})), { updatedAt: new Date() }),
                                })];
                        case 1:
                            _a.sent();
                            return [3 /*break*/, 3];
                        case 2:
                            err_2 = _a.sent();
                            this.logger.error("Failed to update DB status for job ".concat(jobId, " in queue ").concat(queueName, ": ").concat(err_2.message));
                            return [3 /*break*/, 3];
                        case 3: return [2 /*return*/];
                    }
                });
            });
        };
        /**
         * Returns aggregated queue counts across active queues and DLQs.
         */
        QueueService_1.prototype.getAggregatedMetrics = function () {
            return __awaiter(this, void 0, void 0, function () {
                var waiting, active, failed, dlq, mainQueues, _i, mainQueues_1, name_1, q, _a, _b, _c, err_3, dlqQueues, _d, dlqQueues_1, name_2, q, _e, err_4;
                return __generator(this, function (_f) {
                    switch (_f.label) {
                        case 0:
                            waiting = 0;
                            active = 0;
                            failed = 0;
                            dlq = 0;
                            mainQueues = __spreadArray([
                                queue_constants_1.Queues.SIGNAL_PROCESSING,
                                queue_constants_1.Queues.ORDER_PLACEMENT,
                                queue_constants_1.Queues.ORDER_MONITORING,
                                queue_constants_1.Queues.NOTIFICATION,
                                queue_constants_1.Queues.OUTBOX_DISPATCHER,
                                queue_constants_1.Queues.WEBSOCKET,
                                queue_constants_1.Queues.REPORT_GENERATION,
                                queue_constants_1.Queues.REPORT_EXPORT,
                                queue_constants_1.Queues.POSITION_REBUILD,
                                queue_constants_1.Queues.RECONCILIATION,
                                queue_constants_1.Queues.RISK_RECALCULATE,
                                queue_constants_1.Queues.ANALYTICS_RECALCULATE,
                                queue_constants_1.Queues.EMAIL,
                                queue_constants_1.Queues.SMS,
                                queue_constants_1.Queues.WHATSAPP,
                                queue_constants_1.Queues.PUSH
                            ], Array.from({ length: 10 }, function (_, i) { return "analytics-snapshot-".concat(i); }), true);
                            _i = 0, mainQueues_1 = mainQueues;
                            _f.label = 1;
                        case 1:
                            if (!(_i < mainQueues_1.length)) return [3 /*break*/, 8];
                            name_1 = mainQueues_1[_i];
                            _f.label = 2;
                        case 2:
                            _f.trys.push([2, 6, , 7]);
                            q = this.getQueue(name_1);
                            _a = waiting;
                            return [4 /*yield*/, q.getWaitingCount()];
                        case 3:
                            waiting = _a + _f.sent();
                            _b = active;
                            return [4 /*yield*/, q.getActiveCount()];
                        case 4:
                            active = _b + _f.sent();
                            _c = failed;
                            return [4 /*yield*/, q.getFailedCount()];
                        case 5:
                            failed = _c + _f.sent();
                            return [3 /*break*/, 7];
                        case 6:
                            err_3 = _f.sent();
                            this.logger.warn("Failed to count metrics for queue ".concat(name_1, ": ").concat(err_3.message));
                            return [3 /*break*/, 7];
                        case 7:
                            _i++;
                            return [3 /*break*/, 1];
                        case 8:
                            dlqQueues = __spreadArray([
                                queue_constants_1.Queues.SIGNAL_DLQ,
                                queue_constants_1.Queues.ORDER_DLQ,
                                queue_constants_1.Queues.ORDER_MONITORING_DLQ,
                                queue_constants_1.Queues.NOTIFICATION_DLQ,
                                queue_constants_1.Queues.OUTBOX_DISPATCHER_DLQ,
                                queue_constants_1.Queues.WEBSOCKET_DLQ,
                                queue_constants_1.Queues.REPORT_GENERATION_DLQ,
                                queue_constants_1.Queues.REPORT_EXPORT_DLQ,
                                queue_constants_1.Queues.POSITION_REBUILD_DLQ,
                                queue_constants_1.Queues.RECONCILIATION_DLQ,
                                queue_constants_1.Queues.RISK_RECALCULATE_DLQ,
                                queue_constants_1.Queues.ANALYTICS_RECALCULATE_DLQ,
                                queue_constants_1.Queues.EMAIL_DLQ,
                                queue_constants_1.Queues.SMS_DLQ,
                                queue_constants_1.Queues.WHATSAPP_DLQ,
                                queue_constants_1.Queues.PUSH_DLQ
                            ], Array.from({ length: 10 }, function (_, i) { return "analytics-snapshot-dlq-".concat(i); }), true);
                            _d = 0, dlqQueues_1 = dlqQueues;
                            _f.label = 9;
                        case 9:
                            if (!(_d < dlqQueues_1.length)) return [3 /*break*/, 14];
                            name_2 = dlqQueues_1[_d];
                            _f.label = 10;
                        case 10:
                            _f.trys.push([10, 12, , 13]);
                            q = this.getQueue(name_2);
                            _e = dlq;
                            return [4 /*yield*/, q.getJobCountByTypes('waiting', 'active', 'failed', 'completed')];
                        case 11:
                            dlq = _e + _f.sent();
                            return [3 /*break*/, 13];
                        case 12:
                            err_4 = _f.sent();
                            this.logger.warn("Failed to count metrics for DLQ ".concat(name_2, ": ").concat(err_4.message));
                            return [3 /*break*/, 13];
                        case 13:
                            _d++;
                            return [3 /*break*/, 9];
                        case 14: return [2 /*return*/, { waiting: waiting, active: active, failed: failed, dlq: dlq }];
                    }
                });
            });
        };
        /**
         * Returns DLQ-specific queue counts.
         */
        QueueService_1.prototype.getDlqMetrics = function () {
            return __awaiter(this, void 0, void 0, function () {
                var getCount, shardedSnapshotDlqSum, i, q, _a, _b, _c, signalDlq, orderPlacementDlq, orderMonitoringDlq, notificationDlq, outboxDispatcherDlq, websocketDlq, reportGenerationDlq, reportExportDlq, positionRebuildDlq, reconciliationDlq, riskRecalculateDlq, analyticsRecalculateDlq, emailDlq, smsDlq, whatsappDlq, pushDlq;
                var _this = this;
                return __generator(this, function (_d) {
                    switch (_d.label) {
                        case 0:
                            getCount = function (queue) { return __awaiter(_this, void 0, void 0, function () {
                                var _a;
                                return __generator(this, function (_b) {
                                    switch (_b.label) {
                                        case 0:
                                            _b.trys.push([0, 2, , 3]);
                                            return [4 /*yield*/, queue.getJobCountByTypes('waiting', 'active', 'failed', 'completed')];
                                        case 1: return [2 /*return*/, _b.sent()];
                                        case 2:
                                            _a = _b.sent();
                                            return [2 /*return*/, 0];
                                        case 3: return [2 /*return*/];
                                    }
                                });
                            }); };
                            shardedSnapshotDlqSum = 0;
                            i = 0;
                            _d.label = 1;
                        case 1:
                            if (!(i < 10)) return [3 /*break*/, 6];
                            _d.label = 2;
                        case 2:
                            _d.trys.push([2, 4, , 5]);
                            q = this.getQueue("analytics-snapshot-dlq-".concat(i));
                            _a = shardedSnapshotDlqSum;
                            return [4 /*yield*/, getCount(q)];
                        case 3:
                            shardedSnapshotDlqSum = _a + _d.sent();
                            return [3 /*break*/, 5];
                        case 4:
                            _b = _d.sent();
                            return [3 /*break*/, 5];
                        case 5:
                            i++;
                            return [3 /*break*/, 1];
                        case 6: return [4 /*yield*/, Promise.all([
                                getCount(this.signalDlq),
                                getCount(this.orderDlq),
                                getCount(this.orderMonitoringDlq),
                                getCount(this.notificationDlq),
                                getCount(this.outboxDispatcherDlq),
                                getCount(this.websocketDlq),
                                getCount(this.reportGenerationDlq),
                                getCount(this.reportExportDlq),
                                getCount(this.positionRebuildDlq),
                                getCount(this.reconciliationDlq),
                                getCount(this.riskRecalculateDlq),
                                getCount(this.analyticsRecalculateDlq),
                                getCount(this.emailDlq),
                                getCount(this.smsDlq),
                                getCount(this.whatsappDlq),
                                getCount(this.pushDlq),
                            ])];
                        case 7:
                            _c = _d.sent(), signalDlq = _c[0], orderPlacementDlq = _c[1], orderMonitoringDlq = _c[2], notificationDlq = _c[3], outboxDispatcherDlq = _c[4], websocketDlq = _c[5], reportGenerationDlq = _c[6], reportExportDlq = _c[7], positionRebuildDlq = _c[8], reconciliationDlq = _c[9], riskRecalculateDlq = _c[10], analyticsRecalculateDlq = _c[11], emailDlq = _c[12], smsDlq = _c[13], whatsappDlq = _c[14], pushDlq = _c[15];
                            return [2 /*return*/, {
                                    signalDlq: signalDlq,
                                    orderPlacementDlq: orderPlacementDlq,
                                    orderMonitoringDlq: orderMonitoringDlq,
                                    notificationDlq: notificationDlq,
                                    outboxDispatcherDlq: outboxDispatcherDlq,
                                    websocketDlq: websocketDlq,
                                    reportGenerationDlq: reportGenerationDlq,
                                    reportExportDlq: reportExportDlq,
                                    positionRebuildDlq: positionRebuildDlq,
                                    reconciliationDlq: reconciliationDlq,
                                    riskRecalculateDlq: riskRecalculateDlq,
                                    analyticsRecalculateDlq: analyticsRecalculateDlq,
                                    emailDlq: emailDlq,
                                    smsDlq: smsDlq,
                                    whatsappDlq: whatsappDlq,
                                    pushDlq: pushDlq,
                                    analyticsSnapshotDlq: shardedSnapshotDlqSum,
                                }];
                    }
                });
            });
        };
        return QueueService_1;
    }());
    __setFunctionName(_classThis, "QueueService");
    (function () {
        var _metadata = typeof Symbol === "function" && Symbol.metadata ? Object.create(null) : void 0;
        __esDecorate(null, _classDescriptor = { value: _classThis }, _classDecorators, { kind: "class", name: _classThis.name, metadata: _metadata }, null, _classExtraInitializers);
        QueueService = _classThis = _classDescriptor.value;
        if (_metadata) Object.defineProperty(_classThis, Symbol.metadata, { enumerable: true, configurable: true, writable: true, value: _metadata });
        __runInitializers(_classThis, _classExtraInitializers);
    })();
    return QueueService = _classThis;
}();
exports.QueueService = QueueService;
