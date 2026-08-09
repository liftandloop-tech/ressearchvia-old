"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var ReconciliationService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReconciliationService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const redis_service_1 = require("../infrastructure/redis/redis.service");
const queues_service_1 = require("../infrastructure/queues/queues.service");
const metrics_service_1 = require("../infrastructure/metrics/metrics.service");
const broker_registry_1 = require("../brokers/registry/broker.registry");
const queue_constants_1 = require("../infrastructure/queues/queue.constants");
const outbox_service_1 = require("../infrastructure/outbox/outbox.service");
const client_1 = require("@prisma/client");
const crypto = __importStar(require("crypto"));
let ReconciliationService = ReconciliationService_1 = class ReconciliationService {
    prisma;
    redisService;
    queueService;
    metrics;
    brokerRegistry;
    outboxService;
    logger = new common_1.Logger(ReconciliationService_1.name);
    constructor(prisma, redisService, queueService, metrics, brokerRegistry, outboxService) {
        this.prisma = prisma;
        this.redisService = redisService;
        this.queueService = queueService;
        this.metrics = metrics;
        this.brokerRegistry = brokerRegistry;
        this.outboxService = outboxService;
    }
    async triggerReconciliation(operatorId) {
        const runId = crypto.randomUUID();
        const startedAt = new Date();
        const lockKey = `reconciliation:run:${runId}`;
        if (this.redisService.isHealthy()) {
            try {
                await this.redisService.getClient().set(lockKey, '1', 'EX', 7200);
            }
            catch (err) {
                this.logger.error(`Failed to set run lock in Redis: ${err.message}`);
            }
        }
        this.logger.log(`Starting reconciliation run ${runId}`);
        this.metrics.incrementReconciliationRuns();
        const activeUserBrokers = await this.prisma.userBroker.findMany({
            where: {
                status: 'ACTIVE',
                accessToken: { not: null },
            },
            include: {
                broker: true,
            },
        });
        const totalChecked = activeUserBrokers.length;
        await this.prisma.reconciliationRun.create({
            data: {
                id: runId,
                startedAt,
                status: client_1.ReconciliationStatus.RUNNING,
                totalChecked,
                mismatchesFound: 0,
            },
        });
        if (totalChecked === 0) {
            await this.prisma.reconciliationRun.update({
                where: { id: runId },
                data: {
                    status: client_1.ReconciliationStatus.COMPLETED,
                    completedAt: new Date(),
                },
            });
            this.logger.log(`Reconciliation run ${runId} finished. Checked 0 users.`);
            return runId;
        }
        for (const ub of activeUserBrokers) {
            await this.prisma.reconciliationShard.create({
                data: {
                    runId,
                    userId: ub.userId,
                    status: client_1.ReconciliationStatus.RUNNING,
                    startedAt: new Date(),
                },
            });
            const jobId = `reconciliation-run-${runId}-user-${ub.userId}`;
            await this.queueService.addJob(queue_constants_1.Queues.RECONCILIATION, jobId, {
                runId,
                userId: ub.userId,
            });
        }
        return runId;
    }
    async reconcileUserBroker(userId, runId) {
        const startTime = Date.now();
        const ub = await this.prisma.userBroker.findFirst({
            where: { userId, status: 'ACTIVE' },
            include: { broker: true },
        });
        if (!ub || !ub.accessToken) {
            this.logger.warn(`No active UserBroker session for user ${userId}. Shard skipped.`);
            await this.prisma.reconciliationShard.update({
                where: { runId_userId: { runId, userId } },
                data: {
                    status: client_1.ReconciliationStatus.COMPLETED,
                    completedAt: new Date(),
                },
            });
            await this.checkRunCompletion(runId);
            return;
        }
        const brokerCode = ub.broker.code;
        const brokerId = ub.brokerId;
        const clientCode = ub.brokerClientId;
        const token = ub.accessToken;
        const userLockKey = `reconciliation:user:${userId}:${brokerId}`;
        if (this.redisService.isHealthy()) {
            try {
                const locked = await this.redisService.getClient().set(userLockKey, '1', 'EX', 7200, 'NX');
                if (locked !== 'OK') {
                    this.logger.warn(`User broker reconciliation already running for lock: ${userLockKey}`);
                    await this.prisma.reconciliationShard.update({
                        where: { runId_userId: { runId, userId } },
                        data: {
                            status: client_1.ReconciliationStatus.FAILED,
                            completedAt: new Date(),
                        },
                    });
                    await this.checkRunCompletion(runId);
                    return;
                }
            }
            catch (err) {
                this.logger.error(`Redis error acquiring lock ${userLockKey}: ${err.message}`);
            }
        }
        let issuesFoundCount = 0;
        try {
            let adapter;
            try {
                adapter = this.brokerRegistry.get(brokerCode);
            }
            catch (err) {
                throw new Error(`Failed to resolve broker adapter for ${brokerCode}: ${err.message}`);
            }
            const reconPnlTolerance = parseFloat(process.env.RECON_PNL_TOLERANCE_PERCENT || '0.50') / 100;
            const reconPriceTolerance = parseFloat(process.env.RECON_PRICE_TOLERANCE_PERCENT || '0.10') / 100;
            const brokerTrades = await adapter.getTradeBook(token, clientCode);
            const dbTrades = await this.prisma.trade.findMany({
                where: { userId },
                include: {
                    orders: true,
                    signal: true,
                },
            });
            const dbMatchedIds = new Set();
            const brokerMatchedIndices = new Set();
            for (const dbTrade of dbTrades) {
                let matchedIndex = -1;
                if (dbTrade.brokerTradeId) {
                    matchedIndex = brokerTrades.findIndex((bt) => bt.tradeId === dbTrade.brokerTradeId);
                }
                if (matchedIndex === -1 && dbTrade.orders && dbTrade.orders.length > 0) {
                    const brokerOrderIds = dbTrade.orders.map((o) => o.brokerOrderId).filter(Boolean);
                    matchedIndex = brokerTrades.findIndex((bt) => brokerOrderIds.includes(bt.orderId));
                }
                if (matchedIndex === -1) {
                    matchedIndex = brokerTrades.findIndex((bt, index) => {
                        if (brokerMatchedIndices.has(index))
                            return false;
                        const matchesSymbol = bt.symbol === dbTrade.signal?.symbol;
                        const matchesQty = bt.quantity === dbTrade.quantity;
                        const priceDiff = Math.abs(bt.price - Number(dbTrade.entryPrice || 0));
                        const maxPrice = Math.max(bt.price, Number(dbTrade.entryPrice || 0));
                        const matchesPrice = maxPrice === 0 || priceDiff / maxPrice <= reconPriceTolerance;
                        return matchesSymbol && matchesQty && matchesPrice;
                    });
                }
                if (matchedIndex !== -1) {
                    dbMatchedIds.add(dbTrade.id);
                    brokerMatchedIndices.add(matchedIndex);
                    const brokerTrade = brokerTrades[matchedIndex];
                    const priceDiff = Math.abs(brokerTrade.price - Number(dbTrade.entryPrice || 0));
                    const maxPrice = Math.max(brokerTrade.price, Number(dbTrade.entryPrice || 0));
                    if (maxPrice > 0 && priceDiff / maxPrice > reconPriceTolerance) {
                        await this.registerIssue(runId, userId, brokerId, client_1.ReconciliationIssueType.ORDER_STATUS_MISMATCH, client_1.Severity.WARNING, dbTrade.id, { price: brokerTrade.price }, { price: dbTrade.entryPrice });
                        issuesFoundCount++;
                    }
                }
            }
            for (let i = 0; i < brokerTrades.length; i++) {
                if (!brokerMatchedIndices.has(i)) {
                    const bt = brokerTrades[i];
                    await this.registerIssue(runId, userId, brokerId, client_1.ReconciliationIssueType.TRADE_MISSING_IN_DB, client_1.Severity.CRITICAL, bt.tradeId || bt.orderId || 'unknown', bt, {});
                    issuesFoundCount++;
                }
            }
            for (const dbTrade of dbTrades) {
                if (!dbMatchedIds.has(dbTrade.id)) {
                    await this.registerIssue(runId, userId, brokerId, client_1.ReconciliationIssueType.TRADE_MISSING_IN_BROKER, client_1.Severity.CRITICAL, dbTrade.id, {}, { id: dbTrade.id, quantity: dbTrade.quantity, price: dbTrade.entryPrice });
                    issuesFoundCount++;
                }
            }
            const dbOrders = await this.prisma.order.findMany({
                where: {
                    trade: { userId },
                    status: { in: [client_1.OrderStatus.PENDING, client_1.OrderStatus.PLACED, client_1.OrderStatus.PARTIALLY_FILLED] },
                },
                include: { trade: true },
            });
            for (const order of dbOrders) {
                if (!order.brokerOrderId)
                    continue;
                try {
                    const brokerDetails = await adapter.getOrderDetails(token, clientCode, order.brokerOrderId);
                    const brokerMappedStatus = this.mapOrderStatus(brokerDetails.status);
                    if (brokerMappedStatus !== order.status) {
                        if ((order.status === client_1.OrderStatus.PENDING || order.status === client_1.OrderStatus.PLACED || order.status === client_1.OrderStatus.PARTIALLY_FILLED) &&
                            (brokerMappedStatus === client_1.OrderStatus.FILLED || brokerMappedStatus === client_1.OrderStatus.REJECTED || brokerMappedStatus === client_1.OrderStatus.CANCELLED)) {
                            await this.applyAutoResolution(order.id, brokerMappedStatus, userId);
                            await this.registerIssue(runId, userId, brokerId, client_1.ReconciliationIssueType.ORDER_STATUS_MISMATCH, client_1.Severity.WARNING, order.id, { status: brokerMappedStatus }, { status: order.status }, client_1.ReconciliationIssueStatus.RESOLVED);
                            this.metrics.incrementReconciliationAutoResolved(brokerCode);
                        }
                        else {
                            await this.registerIssue(runId, userId, brokerId, client_1.ReconciliationIssueType.ORDER_STATUS_MISMATCH, client_1.Severity.WARNING, order.id, { status: brokerMappedStatus }, { status: order.status });
                            issuesFoundCount++;
                        }
                    }
                }
                catch (err) {
                    this.logger.error(`Failed to fetch order details for ${order.brokerOrderId}: ${err.message}`);
                }
            }
            const brokerPositions = await adapter.getPositions(token, clientCode);
            const dbPositions = await this.prisma.position.findMany({
                where: { trade: { userId }, status: client_1.PositionStatus.OPEN },
            });
            const matchedSymbols = new Set();
            for (const bp of brokerPositions) {
                matchedSymbols.add(bp.symbol);
                const dbPos = dbPositions.find((p) => p.symbol === bp.symbol);
                if (!dbPos) {
                    if (bp.quantity !== 0) {
                        await this.registerIssue(runId, userId, brokerId, client_1.ReconciliationIssueType.POSITION_QUANTITY_MISMATCH, client_1.Severity.CRITICAL, bp.symbol, { quantity: bp.quantity, avgPrice: bp.avgPrice }, { quantity: 0 });
                        issuesFoundCount++;
                    }
                }
                else {
                    if (bp.quantity !== dbPos.quantity) {
                        await this.registerIssue(runId, userId, brokerId, client_1.ReconciliationIssueType.POSITION_QUANTITY_MISMATCH, client_1.Severity.CRITICAL, dbPos.id, { quantity: bp.quantity }, { quantity: dbPos.quantity });
                        issuesFoundCount++;
                    }
                    const priceDiff = Math.abs(bp.avgPrice - Number(dbPos.avgPrice));
                    const maxPrice = Math.max(bp.avgPrice, Number(dbPos.avgPrice));
                    if (maxPrice > 0 && priceDiff / maxPrice > reconPriceTolerance) {
                        await this.registerIssue(runId, userId, brokerId, client_1.ReconciliationIssueType.POSITION_PNL_MISMATCH, client_1.Severity.WARNING, dbPos.id, { avgPrice: bp.avgPrice }, { avgPrice: dbPos.avgPrice });
                        issuesFoundCount++;
                    }
                }
            }
            for (const dbPos of dbPositions) {
                if (!matchedSymbols.has(dbPos.symbol)) {
                    await this.registerIssue(runId, userId, brokerId, client_1.ReconciliationIssueType.POSITION_QUANTITY_MISMATCH, client_1.Severity.CRITICAL, dbPos.id, { quantity: 0 }, { quantity: dbPos.quantity });
                    issuesFoundCount++;
                }
            }
            await this.prisma.reconciliationShard.update({
                where: { runId_userId: { runId, userId } },
                data: {
                    status: client_1.ReconciliationStatus.COMPLETED,
                    completedAt: new Date(),
                    issuesFound: issuesFoundCount,
                },
            });
        }
        catch (error) {
            this.logger.error(`Reconciliation shard failed for user ${userId}: ${error.message}`);
            await this.prisma.reconciliationShard.update({
                where: { runId_userId: { runId, userId } },
                data: {
                    status: client_1.ReconciliationStatus.FAILED,
                    completedAt: new Date(),
                },
            });
        }
        finally {
            if (this.redisService.isHealthy()) {
                try {
                    await this.redisService.getClient().del(userLockKey);
                }
                catch (err) {
                    this.logger.warn(`Failed to release user lock ${userLockKey}: ${err.message}`);
                }
            }
            const openIssues = await this.prisma.reconciliationIssue.count({
                where: {
                    userId,
                    brokerId,
                    status: { in: [client_1.ReconciliationIssueStatus.OPEN, client_1.ReconciliationIssueStatus.INVESTIGATING, client_1.ReconciliationIssueStatus.ESCALATED] },
                },
            });
            await this.prisma.reconciliationSnapshot.upsert({
                where: { userId_brokerId: { userId, brokerId } },
                update: {
                    openIssues,
                    lastReconciledAt: new Date(),
                },
                create: {
                    userId,
                    brokerId,
                    openIssues,
                    lastReconciledAt: new Date(),
                },
            });
            this.metrics.setReconciliationIssuesOpen('unknown', client_1.Severity.CRITICAL, brokerCode, openIssues);
            await this.checkRunCompletion(runId);
            this.metrics.observeReconciliationDuration(Date.now() - startTime);
        }
    }
    mapOrderStatus(brokerStatus) {
        const status = brokerStatus.toUpperCase();
        if (status === 'COMPLETE' || status === 'EXECUTED' || status === 'FILLED')
            return client_1.OrderStatus.FILLED;
        if (status === 'REJECTED')
            return client_1.OrderStatus.REJECTED;
        if (status === 'CANCELLED')
            return client_1.OrderStatus.CANCELLED;
        if (status === 'PARTIALLY_FILLED')
            return client_1.OrderStatus.PARTIALLY_FILLED;
        return client_1.OrderStatus.PLACED;
    }
    async applyAutoResolution(orderId, newStatus, userId) {
        const order = await this.prisma.order.update({
            where: { id: orderId },
            data: { status: newStatus },
            include: { trade: true },
        });
        if (newStatus === client_1.OrderStatus.FILLED) {
            await this.prisma.trade.update({
                where: { id: order.tradeId },
                data: { status: client_1.TradeStatus.OPEN },
            });
            await this.prisma.operationsAudit.create({
                data: {
                    operationId: crypto.randomUUID(),
                    operatorId: userId,
                    action: client_1.OperationsAction.REPLAY_SIGNAL,
                    status: client_1.OperationStatus.SUCCESS,
                    resourceType: 'Order',
                    resourceId: orderId,
                    metadata: { autoResolution: true, newStatus },
                },
            });
        }
    }
    async checkRunCompletion(runId) {
        const run = await this.prisma.reconciliationRun.findUnique({
            where: { id: runId },
            include: { shards: true },
        });
        if (!run)
            return;
        const allFinished = run.shards.every((s) => s.status === client_1.ReconciliationStatus.COMPLETED || s.status === client_1.ReconciliationStatus.FAILED);
        if (allFinished) {
            const failedShards = run.shards.some((s) => s.status === client_1.ReconciliationStatus.FAILED);
            const totalIssues = run.shards.reduce((acc, s) => acc + s.issuesFound, 0);
            await this.prisma.reconciliationRun.update({
                where: { id: runId },
                data: {
                    status: failedShards ? client_1.ReconciliationStatus.FAILED : client_1.ReconciliationStatus.COMPLETED,
                    completedAt: new Date(),
                    mismatchesFound: totalIssues,
                },
            });
            if (this.redisService.isHealthy()) {
                try {
                    await this.redisService.getClient().del(`reconciliation:run:${runId}`);
                }
                catch (err) {
                    this.logger.warn(`Failed to release run lock: ${err.message}`);
                }
            }
            this.logger.log(`Reconciliation run ${runId} finished. Mismatches: ${totalIssues}`);
        }
    }
    async registerIssue(runId, userId, brokerId, issueType, severity, resourceId, brokerValue, dbValue, initialStatus = client_1.ReconciliationIssueStatus.OPEN) {
        const fingerprintRaw = `${userId}:${brokerId}:${issueType}:${resourceId}`;
        const fingerprint = crypto.createHash('sha256').update(fingerprintRaw).digest('hex');
        const existingIssue = await this.prisma.reconciliationIssue.findUnique({
            where: { fingerprint },
        });
        if (existingIssue && existingIssue.status !== client_1.ReconciliationIssueStatus.RESOLVED) {
            await this.prisma.reconciliationIssue.update({
                where: { id: existingIssue.id },
                data: {
                    runId,
                    lastSeenAt: new Date(),
                    occurrenceCount: existingIssue.occurrenceCount + 1,
                    brokerValue,
                    dbValue,
                },
            });
        }
        else {
            await this.prisma.reconciliationIssue.create({
                data: {
                    runId,
                    userId,
                    brokerId,
                    issueType,
                    severity,
                    resourceId,
                    brokerValue,
                    dbValue,
                    status: initialStatus,
                    fingerprint,
                    occurrenceCount: 1,
                },
            });
            const ub = await this.prisma.userBroker.findFirst({
                where: { userId },
                include: { broker: true },
            });
            const brokerCode = ub?.broker.code || 'unknown';
            this.metrics.incrementReconciliationIssuesTotal(issueType, severity, brokerCode);
            await this.outboxService.createEvent('RECONCILIATION_ISSUE', {
                userId,
                brokerId,
                issueType,
                severity,
                resourceId,
                brokerValue,
                dbValue,
            });
        }
    }
};
exports.ReconciliationService = ReconciliationService;
exports.ReconciliationService = ReconciliationService = ReconciliationService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        redis_service_1.RedisService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService,
        broker_registry_1.BrokerRegistry,
        outbox_service_1.OutboxService])
], ReconciliationService);
//# sourceMappingURL=reconciliation.service.js.map