"use strict";
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
exports.PositionSizingService = void 0;
var common_1 = require("@nestjs/common");
var redis_keys_1 = require("../../infrastructure/redis/redis-keys");
var client_1 = require("@prisma/client");
var DEFAULT_SYSTEM_CONFIG = {
    isFixed1xEnabled: true,
    isLossMultiplier2xEnabled: true,
    maxAllowedMultiplier: 16,
    maxGlobalQuantity: null,
    maxGlobalExposureInr: null,
    maxConsecutiveLosses: 5,
};
var PositionSizingService = function () {
    var _classDecorators = [(0, common_1.Injectable)()];
    var _classDescriptor;
    var _classExtraInitializers = [];
    var _classThis;
    var PositionSizingService = _classThis = /** @class */ (function () {
        function PositionSizingService_1(prisma, redisService) {
            this.prisma = prisma;
            this.redisService = redisService;
            this.logger = new common_1.Logger(PositionSizingService.name);
        }
        /**
         * Retrieves the system-wide strategy safety configuration.
         * Cached in Redis with short TTL; falls back to DB or default constants.
         */
        PositionSizingService_1.prototype.getSystemConfig = function () {
            return __awaiter(this, void 0, void 0, function () {
                var cacheKey, raw, err_1, dbConfig, config, err_2, err_3;
                var _a, _b;
                return __generator(this, function (_c) {
                    switch (_c.label) {
                        case 0:
                            cacheKey = redis_keys_1.RedisKeys.systemStrategyConfig();
                            if (!this.redisService.isHealthy()) return [3 /*break*/, 4];
                            _c.label = 1;
                        case 1:
                            _c.trys.push([1, 3, , 4]);
                            return [4 /*yield*/, this.redisService.getClient().get(cacheKey)];
                        case 2:
                            raw = _c.sent();
                            if (raw) {
                                return [2 /*return*/, JSON.parse(raw)];
                            }
                            return [3 /*break*/, 4];
                        case 3:
                            err_1 = _c.sent();
                            this.logger.warn("Failed to read system strategy config from Redis: ".concat(err_1.message));
                            return [3 /*break*/, 4];
                        case 4:
                            _c.trys.push([4, 10, , 11]);
                            return [4 /*yield*/, this.prisma.systemStrategyConfig.findFirst({
                                    orderBy: { updatedAt: 'desc' },
                                })];
                        case 5:
                            dbConfig = _c.sent();
                            config = dbConfig
                                ? {
                                    isFixed1xEnabled: dbConfig.isFixed1xEnabled,
                                    isLossMultiplier2xEnabled: dbConfig.isLossMultiplier2xEnabled,
                                    maxAllowedMultiplier: (_a = dbConfig.maxAllowedMultiplier) !== null && _a !== void 0 ? _a : 16,
                                    maxGlobalQuantity: dbConfig.maxGlobalQuantity,
                                    maxGlobalExposureInr: dbConfig.maxGlobalExposureInr ? Number(dbConfig.maxGlobalExposureInr) : null,
                                    maxConsecutiveLosses: (_b = dbConfig.maxConsecutiveLosses) !== null && _b !== void 0 ? _b : 5,
                                }
                                : DEFAULT_SYSTEM_CONFIG;
                            if (!this.redisService.isHealthy()) return [3 /*break*/, 9];
                            _c.label = 6;
                        case 6:
                            _c.trys.push([6, 8, , 9]);
                            return [4 /*yield*/, this.redisService.getClient().set(cacheKey, JSON.stringify(config), 'EX', 300)];
                        case 7:
                            _c.sent(); // 5 min TTL
                            return [3 /*break*/, 9];
                        case 8:
                            err_2 = _c.sent();
                            this.logger.warn("Failed to cache system strategy config: ".concat(err_2.message));
                            return [3 /*break*/, 9];
                        case 9: return [2 /*return*/, config];
                        case 10:
                            err_3 = _c.sent();
                            this.logger.warn("Failed to load system config from DB, using defaults: ".concat(err_3.message));
                            return [2 /*return*/, DEFAULT_SYSTEM_CONFIG];
                        case 11: return [2 /*return*/];
                    }
                });
            });
        };
        /**
         * Retrieves user's active strategy configuration and streak state.
         * Redis cache first, falling back to PostgreSQL.
         */
        PositionSizingService_1.prototype.getUserStrategy = function (userId, segmentId) {
            return __awaiter(this, void 0, void 0, function () {
                var cacheKey, raw, err_4, strategy, err_5;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0:
                            cacheKey = redis_keys_1.RedisKeys.strategy(userId, segmentId);
                            if (!this.redisService.isHealthy()) return [3 /*break*/, 4];
                            _a.label = 1;
                        case 1:
                            _a.trys.push([1, 3, , 4]);
                            return [4 /*yield*/, this.redisService.getClient().get(cacheKey)];
                        case 2:
                            raw = _a.sent();
                            if (raw) {
                                return [2 /*return*/, JSON.parse(raw)];
                            }
                            return [3 /*break*/, 4];
                        case 3:
                            err_4 = _a.sent();
                            this.logger.warn("Failed to read strategy from Redis [".concat(cacheKey, "]: ").concat(err_4.message));
                            return [3 /*break*/, 4];
                        case 4: return [4 /*yield*/, this.prisma.userTradingStrategy.findFirst({
                                where: {
                                    userId: userId,
                                    OR: [
                                        { segmentId: segmentId !== null && segmentId !== void 0 ? segmentId : null },
                                        { segmentId: null },
                                    ],
                                },
                                orderBy: { createdAt: 'desc' },
                            })];
                        case 5:
                            strategy = _a.sent();
                            if (!!strategy) return [3 /*break*/, 7];
                            return [4 /*yield*/, this.prisma.userTradingStrategy.create({
                                    data: {
                                        userId: userId,
                                        segmentId: segmentId !== null && segmentId !== void 0 ? segmentId : null,
                                        strategyType: client_1.StrategyType.FIXED_1X,
                                        baseMultiplier: 1,
                                        currentMultiplier: 1,
                                        consecutiveLosses: 0,
                                        lastTradeResult: 'NONE',
                                        nextTradeMultiplier: 1,
                                        status: 'ACTIVE',
                                        version: 1,
                                        agreementVersion: 'v1.0',
                                        consentAccepted: false,
                                    },
                                })];
                        case 6:
                            // Default to FIXED_1X
                            strategy = _a.sent();
                            _a.label = 7;
                        case 7:
                            if (!this.redisService.isHealthy()) return [3 /*break*/, 11];
                            _a.label = 8;
                        case 8:
                            _a.trys.push([8, 10, , 11]);
                            return [4 /*yield*/, this.redisService.getClient().set(cacheKey, JSON.stringify(strategy), 'EX', 86400)];
                        case 9:
                            _a.sent();
                            return [3 /*break*/, 11];
                        case 10:
                            err_5 = _a.sent();
                            this.logger.warn("Failed to cache strategy in Redis: ".concat(err_5.message));
                            return [3 /*break*/, 11];
                        case 11: return [2 /*return*/, strategy];
                    }
                });
            });
        };
        /**
         * Calculates position size and returns full snapshot metadata.
         * Enforces 16x ceiling cap and maximum quantity limits.
         */
        PositionSizingService_1.prototype.calculatePositionSize = function (userId, segmentId, baseLot, entryPrice) {
            return __awaiter(this, void 0, void 0, function () {
                var strategy, systemConfig, multiplier, actualQuantity;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0: return [4 /*yield*/, this.getUserStrategy(userId, segmentId)];
                        case 1:
                            strategy = _a.sent();
                            return [4 /*yield*/, this.getSystemConfig()];
                        case 2:
                            systemConfig = _a.sent();
                            multiplier = 1;
                            if (strategy.strategyType === client_1.StrategyType.FIXED_1X) {
                                multiplier = 1;
                            }
                            else if (strategy.strategyType === client_1.StrategyType.LOSS_MULTIPLIER_2X) {
                                // Respect configured system max allowed multiplier (e.g., 16x cap)
                                multiplier = Math.min(strategy.currentMultiplier, systemConfig.maxAllowedMultiplier);
                                if (multiplier < 1)
                                    multiplier = 1;
                            }
                            actualQuantity = baseLot * multiplier;
                            // Apply global quantity ceiling if configured
                            if (systemConfig.maxGlobalQuantity && actualQuantity > systemConfig.maxGlobalQuantity) {
                                this.logger.warn("Quantity capped by maxGlobalQuantity (".concat(actualQuantity, " -> ").concat(systemConfig.maxGlobalQuantity, ") for user ").concat(userId));
                                actualQuantity = systemConfig.maxGlobalQuantity;
                            }
                            return [2 /*return*/, {
                                    strategyType: strategy.strategyType,
                                    baseQuantity: baseLot,
                                    multiplier: multiplier,
                                    actualQuantity: actualQuantity,
                                    consecutiveLosses: strategy.consecutiveLosses,
                                    strategyVersion: strategy.version,
                                    agreementVersion: strategy.agreementVersion,
                                    previousTradeResult: strategy.lastTradeResult,
                                }];
                    }
                });
            });
        };
        /**
         * Handles trade outcome (PROFIT vs LOSS) and advances or resets multiplier.
         * Fixed 1x: always 1x.
         * 2x Loss: 1x -> 2x -> 4x -> 8x -> 16x (capped) on loss; resets to 1x on profit.
         */
        PositionSizingService_1.prototype.handleTradeOutcome = function (userId, segmentId, outcome) {
            return __awaiter(this, void 0, void 0, function () {
                var strategy, systemConfig, nextConsecutive, nextConsecutive, nextMultiplier, projectedNext;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0: return [4 /*yield*/, this.getUserStrategy(userId, segmentId)];
                        case 1:
                            strategy = _a.sent();
                            return [4 /*yield*/, this.getSystemConfig()];
                        case 2:
                            systemConfig = _a.sent();
                            if (!(strategy.strategyType === client_1.StrategyType.FIXED_1X)) return [3 /*break*/, 4];
                            nextConsecutive = outcome === 'LOSS' ? strategy.consecutiveLosses + 1 : 0;
                            return [4 /*yield*/, this.updateStrategyState(userId, segmentId, {
                                    currentMultiplier: 1,
                                    consecutiveLosses: nextConsecutive,
                                    lastTradeResult: outcome,
                                    nextTradeMultiplier: 1,
                                })];
                        case 3:
                            _a.sent();
                            this.logger.log("[Strategy Fixed 1x] User ".concat(userId, " outcome=").concat(outcome, ". Multiplier remains 1x. Consecutive losses: ").concat(nextConsecutive));
                            return [2 /*return*/];
                        case 4:
                            if (!(outcome === 'LOSS')) return [3 /*break*/, 6];
                            nextConsecutive = strategy.consecutiveLosses + 1;
                            nextMultiplier = Math.min(strategy.currentMultiplier * 2, systemConfig.maxAllowedMultiplier);
                            projectedNext = Math.min(nextMultiplier * 2, systemConfig.maxAllowedMultiplier);
                            return [4 /*yield*/, this.updateStrategyState(userId, segmentId, {
                                    currentMultiplier: nextMultiplier,
                                    consecutiveLosses: nextConsecutive,
                                    lastTradeResult: 'LOSS',
                                    nextTradeMultiplier: projectedNext,
                                })];
                        case 5:
                            _a.sent();
                            this.logger.log("[Strategy 2x Loss] Multiplier advanced on loss for user ".concat(userId, ": ") +
                                "".concat(strategy.currentMultiplier, "x -> ").concat(nextMultiplier, "x (losses: ").concat(nextConsecutive, ", cap: ").concat(systemConfig.maxAllowedMultiplier, "x)"));
                            return [3 /*break*/, 8];
                        case 6: 
                        // PROFIT resets immediately to 1x
                        return [4 /*yield*/, this.updateStrategyState(userId, segmentId, {
                                currentMultiplier: 1,
                                consecutiveLosses: 0,
                                lastTradeResult: 'PROFIT',
                                nextTradeMultiplier: 2,
                            })];
                        case 7:
                            // PROFIT resets immediately to 1x
                            _a.sent();
                            this.logger.log("[Strategy 2x Loss] Multiplier reset on profit for user ".concat(userId, " -> 1x. Streak reset."));
                            _a.label = 8;
                        case 8: return [2 /*return*/];
                    }
                });
            });
        };
        /**
         * CRITICAL RULE: Switching strategy resets to fresh 1x cycle immediately!
         * Creates an audit trail in strategy_change_history.
         */
        PositionSizingService_1.prototype.switchStrategy = function (userId, segmentId, newStrategy, agreementVersion, changedBy, changeSource, consentId) {
            return __awaiter(this, void 0, void 0, function () {
                var current, updated, err_6;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0: return [4 /*yield*/, this.getUserStrategy(userId, segmentId !== null && segmentId !== void 0 ? segmentId : undefined)];
                        case 1:
                            current = _a.sent();
                            // 1. Audit trail in StrategyChangeHistory
                            return [4 /*yield*/, this.prisma.strategyChangeHistory.create({
                                    data: {
                                        userId: userId,
                                        previousStrategy: current.strategyType,
                                        newStrategy: newStrategy,
                                        previousMultiplier: current.currentMultiplier,
                                        newMultiplier: 1,
                                        previousVersion: current.version,
                                        newVersion: current.version + 1,
                                        changedBy: changedBy,
                                        changeSource: changeSource,
                                        consentId: consentId !== null && consentId !== void 0 ? consentId : null,
                                        agreementVersion: agreementVersion,
                                    },
                                })];
                        case 2:
                            // 1. Audit trail in StrategyChangeHistory
                            _a.sent();
                            return [4 /*yield*/, this.prisma.userTradingStrategy.upsert({
                                    where: {
                                        userId_segmentId: {
                                            userId: userId,
                                            segmentId: segmentId !== null && segmentId !== void 0 ? segmentId : null,
                                        },
                                    },
                                    create: {
                                        userId: userId,
                                        segmentId: segmentId !== null && segmentId !== void 0 ? segmentId : null,
                                        strategyType: newStrategy,
                                        baseMultiplier: 1,
                                        currentMultiplier: 1,
                                        consecutiveLosses: 0,
                                        lastTradeResult: 'NONE',
                                        nextTradeMultiplier: newStrategy === client_1.StrategyType.LOSS_MULTIPLIER_2X ? 2 : 1,
                                        version: current.version + 1,
                                        agreementVersion: agreementVersion,
                                        consentAccepted: true,
                                        status: 'ACTIVE',
                                    },
                                    update: {
                                        strategyType: newStrategy,
                                        baseMultiplier: 1,
                                        currentMultiplier: 1,
                                        consecutiveLosses: 0,
                                        lastTradeResult: 'NONE',
                                        nextTradeMultiplier: newStrategy === client_1.StrategyType.LOSS_MULTIPLIER_2X ? 2 : 1,
                                        version: { increment: 1 },
                                        agreementVersion: agreementVersion,
                                        consentAccepted: true,
                                        status: 'ACTIVE',
                                    },
                                })];
                        case 3:
                            updated = _a.sent();
                            if (!this.redisService.isHealthy()) return [3 /*break*/, 9];
                            _a.label = 4;
                        case 4:
                            _a.trys.push([4, 8, , 9]);
                            return [4 /*yield*/, this.redisService.getClient().del(redis_keys_1.RedisKeys.strategy(userId, segmentId !== null && segmentId !== void 0 ? segmentId : undefined))];
                        case 5:
                            _a.sent();
                            return [4 /*yield*/, this.redisService.getClient().del(redis_keys_1.RedisKeys.strategy(userId))];
                        case 6:
                            _a.sent();
                            return [4 /*yield*/, this.redisService.getClient().del(redis_keys_1.RedisKeys.multiplier(userId, segmentId !== null && segmentId !== void 0 ? segmentId : ''))];
                        case 7:
                            _a.sent();
                            return [3 /*break*/, 9];
                        case 8:
                            err_6 = _a.sent();
                            this.logger.warn("Failed to clear strategy cache on switch: ".concat(err_6.message));
                            return [3 /*break*/, 9];
                        case 9:
                            this.logger.log("Strategy switched for user ".concat(userId, ": ").concat(current.strategyType, " -> ").concat(newStrategy, " by ").concat(changedBy, ". ") +
                                "Multiplier reset to fresh 1x. Version: ".concat(updated.version));
                            return [2 /*return*/, updated];
                    }
                });
            });
        };
        /**
         * Helper to persist updated streak state to DB and warm Redis.
         */
        PositionSizingService_1.prototype.updateStrategyState = function (userId, segmentId, data) {
            return __awaiter(this, void 0, void 0, function () {
                var updated, e_1, cacheKey, legacyKey, fresh, err_7;
                var _a, _b, _c, _d, _e, _f;
                return __generator(this, function (_g) {
                    switch (_g.label) {
                        case 0: return [4 /*yield*/, this.prisma.userTradingStrategy.updateMany({
                                where: {
                                    userId: userId,
                                    OR: [
                                        { segmentId: segmentId },
                                        { segmentId: null },
                                    ],
                                },
                                data: data,
                            })];
                        case 1:
                            updated = _g.sent();
                            _g.label = 2;
                        case 2:
                            _g.trys.push([2, 4, , 5]);
                            return [4 /*yield*/, this.prisma.segmentMultiplier.upsert({
                                    where: { userId_segmentId: { userId: userId, segmentId: segmentId } },
                                    create: {
                                        userId: userId,
                                        segmentId: segmentId,
                                        lossStreak: (_a = data.consecutiveLosses) !== null && _a !== void 0 ? _a : 0,
                                        currentMultiplier: (_b = data.currentMultiplier) !== null && _b !== void 0 ? _b : 1,
                                        currentLot: (_c = data.currentMultiplier) !== null && _c !== void 0 ? _c : 1,
                                    },
                                    update: {
                                        lossStreak: (_d = data.consecutiveLosses) !== null && _d !== void 0 ? _d : 0,
                                        currentMultiplier: (_e = data.currentMultiplier) !== null && _e !== void 0 ? _e : 1,
                                        currentLot: (_f = data.currentMultiplier) !== null && _f !== void 0 ? _f : 1,
                                    },
                                })];
                        case 3:
                            _g.sent();
                            return [3 /*break*/, 5];
                        case 4:
                            e_1 = _g.sent();
                            return [3 /*break*/, 5];
                        case 5:
                            if (!this.redisService.isHealthy()) return [3 /*break*/, 12];
                            _g.label = 6;
                        case 6:
                            _g.trys.push([6, 11, , 12]);
                            cacheKey = redis_keys_1.RedisKeys.strategy(userId, segmentId);
                            legacyKey = redis_keys_1.RedisKeys.multiplier(userId, segmentId);
                            return [4 /*yield*/, this.prisma.userTradingStrategy.findFirst({
                                    where: { userId: userId },
                                    orderBy: { updatedAt: 'desc' },
                                })];
                        case 7:
                            fresh = _g.sent();
                            if (!fresh) return [3 /*break*/, 10];
                            return [4 /*yield*/, this.redisService.getClient().set(cacheKey, JSON.stringify(fresh), 'EX', 86400)];
                        case 8:
                            _g.sent();
                            return [4 /*yield*/, this.redisService.getClient().set(legacyKey, JSON.stringify({ index: fresh.consecutiveLosses, current: fresh.currentMultiplier }), 'EX', 86400)];
                        case 9:
                            _g.sent();
                            _g.label = 10;
                        case 10: return [3 /*break*/, 12];
                        case 11:
                            err_7 = _g.sent();
                            this.logger.warn("Failed to update strategy cache: ".concat(err_7.message));
                            return [3 /*break*/, 12];
                        case 12: return [2 /*return*/];
                    }
                });
            });
        };
        // ==========================================
        // Legacy MultiplierService interface support
        // ==========================================
        PositionSizingService_1.prototype.getState = function (userId, segmentId) {
            return __awaiter(this, void 0, void 0, function () {
                var strategy;
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0: return [4 /*yield*/, this.getUserStrategy(userId, segmentId)];
                        case 1:
                            strategy = _a.sent();
                            return [2 /*return*/, {
                                    index: strategy.consecutiveLosses,
                                    current: strategy.currentMultiplier,
                                }];
                    }
                });
            });
        };
        PositionSizingService_1.prototype.advanceOnLoss = function (userId, segmentId) {
            return __awaiter(this, void 0, void 0, function () {
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0: return [4 /*yield*/, this.handleTradeOutcome(userId, segmentId, 'LOSS')];
                        case 1:
                            _a.sent();
                            return [2 /*return*/, this.getState(userId, segmentId)];
                    }
                });
            });
        };
        PositionSizingService_1.prototype.resetOnWin = function (userId, segmentId) {
            return __awaiter(this, void 0, void 0, function () {
                return __generator(this, function (_a) {
                    switch (_a.label) {
                        case 0: return [4 /*yield*/, this.handleTradeOutcome(userId, segmentId, 'PROFIT')];
                        case 1:
                            _a.sent();
                            return [2 /*return*/];
                    }
                });
            });
        };
        return PositionSizingService_1;
    }());
    __setFunctionName(_classThis, "PositionSizingService");
    (function () {
        var _metadata = typeof Symbol === "function" && Symbol.metadata ? Object.create(null) : void 0;
        __esDecorate(null, _classDescriptor = { value: _classThis }, _classDecorators, { kind: "class", name: _classThis.name, metadata: _metadata }, null, _classExtraInitializers);
        PositionSizingService = _classThis = _classDescriptor.value;
        if (_metadata) Object.defineProperty(_classThis, Symbol.metadata, { enumerable: true, configurable: true, writable: true, value: _metadata });
        __runInitializers(_classThis, _classExtraInitializers);
    })();
    return PositionSizingService = _classThis;
}();
exports.PositionSizingService = PositionSizingService;
