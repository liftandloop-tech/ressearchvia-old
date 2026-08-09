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
var AnalyticsService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnalyticsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const cache_service_1 = require("../infrastructure/cache/cache.service");
const metrics_service_1 = require("../infrastructure/metrics/metrics.service");
const queues_service_1 = require("../infrastructure/queues/queues.service");
const queue_constants_1 = require("../infrastructure/queues/queue.constants");
const client_1 = require("@prisma/client");
const schedule_1 = require("@nestjs/schedule");
let AnalyticsService = AnalyticsService_1 = class AnalyticsService {
    prisma;
    cacheService;
    metrics;
    queueService;
    logger = new common_1.Logger(AnalyticsService_1.name);
    constructor(prisma, cacheService, metrics, queueService) {
        this.prisma = prisma;
        this.cacheService = cacheService;
        this.metrics = metrics;
        this.queueService = queueService;
    }
    async recalculateAnalyticsSnapshot(userId) {
        this.logger.log(`Recalculating daily portfolio snapshot for user: ${userId}`);
        const segments = await this.prisma.userSegment.findMany({
            where: { userId, deletedAt: null },
        });
        let initialCapital = segments.reduce((sum, seg) => sum + Number(seg.capital), 0);
        if (initialCapital <= 0) {
            const firstSnap = await this.prisma.dailyPortfolioSnapshot.findFirst({
                where: { userId },
                orderBy: { date: 'asc' },
            });
            initialCapital = firstSnap ? Number(firstSnap.equity) : 100000;
        }
        const closedTrades = await this.prisma.trade.findMany({
            where: {
                userId,
                status: { in: [client_1.TradeStatus.CLOSED, client_1.TradeStatus.TARGET_HIT, client_1.TradeStatus.STOPLOSS_HIT] },
            },
        });
        const openPositions = await this.prisma.position.findMany({
            where: {
                trade: { userId },
                status: client_1.PositionStatus.OPEN,
            },
        });
        const totalRealizedPnl = closedTrades.reduce((sum, t) => sum + Number(t.pnl || 0), 0);
        const totalUnrealizedPnl = openPositions.reduce((sum, p) => sum + Number(p.unrealizedPnl || 0), 0);
        const currentEquity = initialCapital + totalRealizedPnl + totalUnrealizedPnl;
        const todayDate = new Date();
        todayDate.setHours(0, 0, 0, 0);
        const pastSnapshots = await this.prisma.dailyPortfolioSnapshot.findMany({
            where: { userId, date: { lt: todayDate } },
        });
        const allEquities = [...pastSnapshots.map((s) => Number(s.equity)), currentEquity];
        const peakEquity = Math.max(initialCapital, ...allEquities);
        const drawdown = peakEquity - currentEquity;
        const openPositionsCount = openPositions.length;
        const startOfToday = new Date(todayDate);
        const endOfToday = new Date(todayDate);
        endOfToday.setHours(23, 59, 59, 999);
        const todayTrades = await this.prisma.trade.findMany({
            where: {
                userId,
                createdAt: { gte: startOfToday, lte: endOfToday },
            },
        });
        const volumeTraded = todayTrades.reduce((sum, t) => sum + Number(t.quantity) * Number(t.entryPrice || 0), 0);
        await this.prisma.dailyPortfolioSnapshot.upsert({
            where: { userId_date: { userId, date: todayDate } },
            update: {
                equity: new client_1.Prisma.Decimal(currentEquity),
                realizedPnl: new client_1.Prisma.Decimal(totalRealizedPnl),
                unrealizedPnl: new client_1.Prisma.Decimal(totalUnrealizedPnl),
                drawdown: new client_1.Prisma.Decimal(drawdown),
                openPositionsCount,
                volumeTraded: new client_1.Prisma.Decimal(volumeTraded),
                version: 1,
            },
            create: {
                userId,
                date: todayDate,
                equity: new client_1.Prisma.Decimal(currentEquity),
                realizedPnl: new client_1.Prisma.Decimal(totalRealizedPnl),
                unrealizedPnl: new client_1.Prisma.Decimal(totalUnrealizedPnl),
                drawdown: new client_1.Prisma.Decimal(drawdown),
                openPositionsCount,
                volumeTraded: new client_1.Prisma.Decimal(volumeTraded),
                version: 1,
            },
        });
        await this.prisma.equityCurvePoint.create({
            data: {
                userId,
                equityValue: new client_1.Prisma.Decimal(currentEquity),
                sourceType: client_1.EquityCurveSourceType.DAILY,
                timestamp: new Date(),
            },
        });
        this.metrics.incrementAnalyticsSnapshotsCreated();
        await this.invalidateUserCache(userId);
    }
    async rebuildHistoricalSnapshots(userId) {
        this.logger.log(`Performing full historical rebuild of daily snapshots for user: ${userId}`);
        const segments = await this.prisma.userSegment.findMany({
            where: { userId, deletedAt: null },
        });
        let initialCapital = segments.reduce((sum, seg) => sum + Number(seg.capital), 0);
        if (initialCapital <= 0) {
            initialCapital = 100000;
        }
        const closedTrades = await this.prisma.trade.findMany({
            where: {
                userId,
                status: { in: [client_1.TradeStatus.CLOSED, client_1.TradeStatus.TARGET_HIT, client_1.TradeStatus.STOPLOSS_HIT] },
            },
            orderBy: { createdAt: 'asc' },
        });
        const openPositions = await this.prisma.position.findMany({
            where: {
                trade: { userId },
                status: client_1.PositionStatus.OPEN,
            },
        });
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        let startDate = new Date(today);
        startDate.setDate(startDate.getDate() - 90);
        if (closedTrades.length > 0) {
            const firstTradeDate = new Date(closedTrades[0].createdAt);
            firstTradeDate.setHours(0, 0, 0, 0);
            if (firstTradeDate < startDate) {
                startDate = firstTradeDate;
            }
        }
        let peakEquity = initialCapital;
        const currentDate = new Date(startDate);
        while (currentDate <= today) {
            const endOfDay = new Date(currentDate);
            endOfDay.setHours(23, 59, 59, 999);
            const tradesUpToD = closedTrades.filter((t) => new Date(t.createdAt) <= endOfDay);
            const realizedPnl = tradesUpToD.reduce((sum, t) => sum + Number(t.pnl || 0), 0);
            const isToday = currentDate.getTime() === today.getTime();
            const unrealizedPnl = isToday
                ? openPositions.reduce((sum, p) => sum + Number(p.unrealizedPnl || 0), 0)
                : 0;
            const equity = initialCapital + realizedPnl + unrealizedPnl;
            if (equity > peakEquity) {
                peakEquity = equity;
            }
            const drawdown = peakEquity - equity;
            const openPositionsCount = isToday ? openPositions.length : 0;
            const startOfDay = new Date(currentDate);
            startOfDay.setHours(0, 0, 0, 0);
            const tradesOnD = closedTrades.filter((t) => {
                const d = new Date(t.createdAt);
                return d >= startOfDay && d <= endOfDay;
            });
            const volumeTraded = tradesOnD.reduce((sum, t) => sum + Number(t.quantity) * Number(t.entryPrice || 0), 0);
            await this.prisma.dailyPortfolioSnapshot.upsert({
                where: { userId_date: { userId, date: startOfDay } },
                update: {
                    equity: new client_1.Prisma.Decimal(equity),
                    realizedPnl: new client_1.Prisma.Decimal(realizedPnl),
                    unrealizedPnl: new client_1.Prisma.Decimal(unrealizedPnl),
                    drawdown: new client_1.Prisma.Decimal(drawdown),
                    openPositionsCount,
                    volumeTraded: new client_1.Prisma.Decimal(volumeTraded),
                    version: 1,
                },
                create: {
                    userId,
                    date: startOfDay,
                    equity: new client_1.Prisma.Decimal(equity),
                    realizedPnl: new client_1.Prisma.Decimal(realizedPnl),
                    unrealizedPnl: new client_1.Prisma.Decimal(unrealizedPnl),
                    drawdown: new client_1.Prisma.Decimal(drawdown),
                    openPositionsCount,
                    volumeTraded: new client_1.Prisma.Decimal(volumeTraded),
                    version: 1,
                },
            });
            currentDate.setDate(currentDate.getDate() + 1);
        }
        this.logger.log(`Full historical rebuild of daily snapshots completed for user: ${userId}`);
        await this.invalidateUserCache(userId);
    }
    async updatePerformanceRollups(userId) {
        this.logger.log(`Updating performance rollups for user: ${userId}`);
        const segments = await this.prisma.userSegment.findMany({
            where: { userId, deletedAt: null },
        });
        let initialCapital = segments.reduce((sum, seg) => sum + Number(seg.capital), 0);
        if (initialCapital <= 0) {
            initialCapital = 100000;
        }
        const closedTrades = await this.prisma.trade.findMany({
            where: {
                userId,
                status: { in: [client_1.TradeStatus.CLOSED, client_1.TradeStatus.TARGET_HIT, client_1.TradeStatus.STOPLOSS_HIT] },
            },
        });
        const snapshots = await this.prisma.dailyPortfolioSnapshot.findMany({
            where: { userId },
            orderBy: { date: 'asc' },
        });
        const totalTrades = closedTrades.length;
        const totalPnl = closedTrades.reduce((sum, t) => sum + Number(t.pnl || 0), 0);
        const grossProfit = closedTrades.reduce((sum, t) => sum + (Number(t.pnl || 0) > 0 ? Number(t.pnl || 0) : 0), 0);
        const grossLoss = closedTrades.reduce((sum, t) => sum + (Number(t.pnl || 0) < 0 ? Number(t.pnl || 0) : 0), 0);
        const winningTrades = closedTrades.filter((t) => Number(t.pnl || 0) > 0).length;
        const losingTrades = closedTrades.filter((t) => Number(t.pnl || 0) <= 0).length;
        const maxDrawdown = snapshots.reduce((max, s) => Math.max(max, Number(s.drawdown)), 0);
        const firstTradeAt = closedTrades.length > 0 ? closedTrades[0].createdAt : null;
        const lastTradeAt = closedTrades.length > 0 ? closedTrades[closedTrades.length - 1].createdAt : null;
        await this.prisma.userPerformance.upsert({
            where: { userId },
            update: {
                totalPnl: new client_1.Prisma.Decimal(totalPnl),
                grossProfit: new client_1.Prisma.Decimal(grossProfit),
                grossLoss: new client_1.Prisma.Decimal(grossLoss),
                totalTrades,
                winningTrades,
                losingTrades,
                maxDrawdown: new client_1.Prisma.Decimal(maxDrawdown),
                firstTradeAt,
                lastTradeAt,
                version: 1,
                calculatedAt: new Date(),
            },
            create: {
                userId,
                totalPnl: new client_1.Prisma.Decimal(totalPnl),
                grossProfit: new client_1.Prisma.Decimal(grossProfit),
                grossLoss: new client_1.Prisma.Decimal(grossLoss),
                totalTrades,
                winningTrades,
                losingTrades,
                maxDrawdown: new client_1.Prisma.Decimal(maxDrawdown),
                firstTradeAt,
                lastTradeAt,
                version: 1,
                calculatedAt: new Date(),
            },
        });
        const segmentIds = Array.from(new Set(closedTrades.map((t) => t.segmentId)));
        for (const segmentId of segmentIds) {
            const segTrades = closedTrades.filter((t) => t.segmentId === segmentId);
            const totalTradesForSegment = segTrades.length;
            const netPnL = segTrades.reduce((sum, t) => sum + Number(t.pnl || 0), 0);
            const winningTradesSegment = segTrades.filter((t) => Number(t.pnl || 0) > 0).length;
            const winRate = totalTradesForSegment > 0 ? (winningTradesSegment / totalTradesForSegment) * 100 : 0;
            const userSeg = segments.find((s) => s.segmentId === segmentId);
            const capitalUsed = userSeg ? Number(userSeg.capital) : 0;
            let runningEquity = capitalUsed;
            let peak = capitalUsed;
            let maxDrawdownSegment = 0;
            const sortedSegTrades = [...segTrades].sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime());
            for (const t of sortedSegTrades) {
                runningEquity += Number(t.pnl || 0);
                if (runningEquity > peak)
                    peak = runningEquity;
                const dd = peak - runningEquity;
                if (dd > maxDrawdownSegment)
                    maxDrawdownSegment = dd;
            }
            const contributionPercent = totalPnl !== 0 ? (netPnL / Math.abs(totalPnl)) * 100 : 0;
            await this.prisma.segmentPerformance.upsert({
                where: { userId_segmentId: { userId, segmentId } },
                update: {
                    totalTrades: totalTradesForSegment,
                    winRate: new client_1.Prisma.Decimal(winRate),
                    netPnL: new client_1.Prisma.Decimal(netPnL),
                    maxDrawdown: new client_1.Prisma.Decimal(maxDrawdownSegment),
                    capitalUsed: new client_1.Prisma.Decimal(capitalUsed),
                    contributionPercent: new client_1.Prisma.Decimal(contributionPercent),
                },
                create: {
                    userId,
                    segmentId,
                    totalTrades: totalTradesForSegment,
                    winRate: new client_1.Prisma.Decimal(winRate),
                    netPnL: new client_1.Prisma.Decimal(netPnL),
                    maxDrawdown: new client_1.Prisma.Decimal(maxDrawdownSegment),
                    capitalUsed: new client_1.Prisma.Decimal(capitalUsed),
                    contributionPercent: new client_1.Prisma.Decimal(contributionPercent),
                },
            });
        }
        await this.invalidateUserCache(userId);
    }
    async getPortfolioPerformance(userId) {
        const cacheKey = `analytics:user:${userId}:portfolio`;
        const cached = await this.cacheService.get(cacheKey);
        if (cached)
            return cached;
        const userPerf = await this.prisma.userPerformance.findUnique({
            where: { userId },
        });
        const snapshots = await this.prisma.dailyPortfolioSnapshot.findMany({
            where: { userId },
            orderBy: { date: 'asc' },
        });
        const segments = await this.prisma.userSegment.findMany({
            where: { userId, deletedAt: null },
        });
        let initialCapital = segments.reduce((sum, seg) => sum + Number(seg.capital), 0);
        if (initialCapital <= 0) {
            initialCapital = snapshots.length > 0 ? Number(snapshots[0].equity) : 100000;
        }
        if (!userPerf || snapshots.length === 0) {
            return {
                sharpeRatio: 0,
                sortinoRatio: 0,
                cagr: 0,
                winRate: 0,
                profitFactor: 0,
                alpha: {},
                rawStats: userPerf || null,
                equityCurvePoints: [],
            };
        }
        const R = [];
        let prevEquity = initialCapital;
        for (const snap of snapshots) {
            const eq = Number(snap.equity);
            const ret = prevEquity > 0 ? (eq - prevEquity) / prevEquity : 0;
            R.push(ret);
            prevEquity = eq;
        }
        const annualRf = parseFloat(process.env.RISK_FREE_RATE_ANNUAL || '6.5');
        const dailyRf = annualRf / 100 / 252;
        const meanR = R.reduce((sum, r) => sum + r, 0) / R.length;
        const variance = R.reduce((sum, r) => sum + Math.pow(r - meanR, 2), 0) / R.length;
        const stdDevR = Math.sqrt(variance);
        const sharpeRatio = stdDevR > 0 ? ((meanR - dailyRf) / stdDevR) * Math.sqrt(252) : 0;
        const downsideDiffs = R.map((r) => Math.min(0, r - dailyRf));
        const downsideVariance = downsideDiffs.reduce((sum, d) => sum + Math.pow(d, 2), 0) / R.length;
        const downsideStdDev = Math.sqrt(downsideVariance);
        const sortinoRatio = downsideStdDev > 0 ? ((meanR - dailyRf) / downsideStdDev) * Math.sqrt(252) : 0;
        const firstDate = new Date(snapshots[0].date);
        const latestDate = new Date(snapshots[snapshots.length - 1].date);
        const diffMs = Math.max(1000 * 60 * 60 * 24, latestDate.getTime() - firstDate.getTime());
        const days = diffMs / (1000 * 60 * 60 * 24);
        const years = days / 365.25;
        const endingValue = Number(snapshots[snapshots.length - 1].equity);
        const beginningValue = initialCapital;
        let cagr = 0;
        if (endingValue > 0 && beginningValue > 0 && years > 0) {
            cagr = Math.pow(endingValue / beginningValue, 1 / years) - 1;
        }
        const portfolioReturn = beginningValue > 0 ? (endingValue - beginningValue) / beginningValue : 0;
        const alpha = {};
        const benchmarks = ['NIFTY50', 'BANKNIFTY', 'MIDCAP150'];
        for (const bName of benchmarks) {
            const startB = await this.prisma.benchmarkSnapshot.findFirst({
                where: { benchmarkName: bName, date: { lte: firstDate } },
                orderBy: { date: 'desc' },
            });
            const endB = await this.prisma.benchmarkSnapshot.findFirst({
                where: { benchmarkName: bName, date: { lte: latestDate } },
                orderBy: { date: 'desc' },
            });
            if (startB && endB) {
                const startVal = Number(startB.value);
                const endVal = Number(endB.value);
                const benchmarkReturn = startVal > 0 ? (endVal - startVal) / startVal : 0;
                alpha[bName] = portfolioReturn - benchmarkReturn;
            }
            else {
                alpha[bName] = 0;
            }
        }
        const winRate = Number(userPerf.totalTrades) > 0 ? Number(userPerf.winningTrades) / Number(userPerf.totalTrades) : 0;
        const profitFactor = Math.abs(Number(userPerf.grossLoss)) > 0
            ? Number(userPerf.grossProfit) / Math.abs(Number(userPerf.grossLoss))
            : Number(userPerf.grossProfit);
        const equityCurvePoints = await this.prisma.equityCurvePoint.findMany({
            where: { userId },
            orderBy: { timestamp: 'asc' },
        });
        const result = {
            sharpeRatio,
            sortinoRatio,
            cagr,
            winRate,
            profitFactor,
            alpha,
            rawStats: userPerf,
            equityCurvePoints,
        };
        await this.cacheService.set(cacheKey, result, 600);
        return result;
    }
    async getSegmentPerformance(userId) {
        const cacheKey = `analytics:user:${userId}:segments`;
        const cached = await this.cacheService.get(cacheKey);
        if (cached)
            return cached;
        const performances = await this.prisma.segmentPerformance.findMany({
            where: { userId },
            include: { segment: true },
        });
        await this.cacheService.set(cacheKey, performances, 600);
        return performances;
    }
    async getBrokerPerformance(userId) {
        const cacheKey = `analytics:user:${userId}:broker-stats`;
        const cached = await this.cacheService.get(cacheKey);
        if (cached)
            return cached;
        const trades = await this.prisma.trade.findMany({
            where: { userId },
            include: {
                signal: true,
                orders: true,
            },
        });
        const brokerGroup = {};
        for (const t of trades) {
            const brokerId = t.brokerId;
            if (!brokerGroup[brokerId]) {
                brokerGroup[brokerId] = {
                    brokerId,
                    totalOrders: 0,
                    filledOrders: 0,
                    rejectedOrders: 0,
                    slippages: [],
                };
            }
            const group = brokerGroup[brokerId];
            for (const o of t.orders) {
                group.totalOrders++;
                if (o.status === 'FILLED') {
                    group.filledOrders++;
                }
                else if (o.status === 'REJECTED') {
                    group.rejectedOrders++;
                }
            }
            if (t.entryPrice && t.signal && t.signal.entryPrice) {
                const diff = Number(t.entryPrice) - Number(t.signal.entryPrice);
                group.slippages.push(diff);
            }
        }
        const result = Object.values(brokerGroup).map((g) => {
            const fillRate = g.totalOrders > 0 ? g.filledOrders / g.totalOrders : 0;
            const rejectionRate = g.totalOrders > 0 ? g.rejectedOrders / g.totalOrders : 0;
            const averageSlippage = g.slippages.length > 0
                ? g.slippages.reduce((sum, val) => sum + Math.abs(val), 0) / g.slippages.length
                : 0;
            return {
                brokerId: g.brokerId,
                totalOrders: g.totalOrders,
                filledOrders: g.filledOrders,
                rejectedOrders: g.rejectedOrders,
                fillRate,
                rejectionRate,
                averageSlippage,
            };
        });
        await this.cacheService.set(cacheKey, result, 600);
        return result;
    }
    async invalidateUserCache(userId) {
        const keys = [
            `analytics:user:${userId}:portfolio`,
            `analytics:user:${userId}:segments`,
            `analytics:user:${userId}:broker-stats`,
        ];
        for (const key of keys) {
            try {
                await this.cacheService.del(key);
            }
            catch (err) {
                this.logger.warn(`Failed to invalidate cache key: ${key}. Error: ${err.message}`);
            }
        }
    }
    async handleNightlyAnalyticsRecalculation() {
        this.logger.log('Nightly portfolio analytics cron triggered');
        this.metrics.incrementAnalyticsRuns();
        const activeUsers = await this.prisma.user.findMany({
            where: { status: 'ACTIVE' },
        });
        const totalUsers = activeUsers.length;
        const run = await this.prisma.analyticsJobRun.create({
            data: {
                startedAt: new Date(),
                status: client_1.AnalyticsRunStatus.RUNNING,
                usersProcessed: 0,
                failures: 0,
            },
        });
        this.logger.log(`Nightly analytics job run ${run.id} started. Enqueuing ${totalUsers} sharded recalculation tasks.`);
        for (const user of activeUsers) {
            try {
                await this.queueService.addJob(queue_constants_1.Queues.ANALYTICS_RECALCULATE, `recalculate-${run.id}-${user.id}`, { userId: user.id, runId: run.id, totalUsers });
            }
            catch (err) {
                this.logger.error(`Failed to enqueue recalculate job for user ${user.id}: ${err.message}`);
                await this.handleJobCompletion(run.id, totalUsers, false);
            }
        }
    }
    async handleJobCompletion(runId, totalUsers, success) {
        try {
            const run = await this.prisma.analyticsJobRun.findUnique({ where: { id: runId } });
            if (!run)
                return;
            const usersProcessed = run.usersProcessed + (success ? 1 : 0);
            const failures = run.failures + (success ? 0 : 1);
            const isDone = usersProcessed + failures >= totalUsers;
            const completedAt = isDone ? new Date() : null;
            const status = isDone
                ? (failures === totalUsers ? client_1.AnalyticsRunStatus.FAILED : client_1.AnalyticsRunStatus.SUCCESS)
                : client_1.AnalyticsRunStatus.RUNNING;
            await this.prisma.analyticsJobRun.update({
                where: { id: runId },
                data: {
                    usersProcessed,
                    failures,
                    status,
                    completedAt,
                    durationMs: completedAt ? completedAt.getTime() - run.startedAt.getTime() : null,
                },
            });
            this.metrics.incrementAnalyticsUsersProcessed();
            if (!success) {
                this.metrics.incrementAnalyticsFailures();
            }
            if (isDone && completedAt) {
                const duration = completedAt.getTime() - run.startedAt.getTime();
                this.metrics.observeAnalyticsDuration(duration);
                this.logger.log(`Nightly analytics job run ${runId} finished. Status: ${status}. Processed: ${usersProcessed}, Failures: ${failures}`);
            }
        }
        catch (err) {
            this.logger.error(`Failed to handle job completion update for run ${runId}: ${err.message}`);
        }
    }
    async cleanupEquityCurvePoints() {
        this.logger.log('Starting tiered equity curve points retention cleanup...');
        const now = new Date();
        const intradayCutoff = new Date(now);
        intradayCutoff.setDate(intradayCutoff.getDate() - 90);
        const hourlyCutoff = new Date(now);
        hourlyCutoff.setDate(hourlyCutoff.getDate() - 365);
        try {
            const deletedIntraday = await this.prisma.equityCurvePoint.deleteMany({
                where: {
                    sourceType: client_1.EquityCurveSourceType.INTRADAY,
                    timestamp: { lt: intradayCutoff },
                },
            });
            const deletedHourly = await this.prisma.equityCurvePoint.deleteMany({
                where: {
                    sourceType: client_1.EquityCurveSourceType.HOURLY,
                    timestamp: { lt: hourlyCutoff },
                },
            });
            this.logger.log(`Retention cleanup finished. Deleted ${deletedIntraday.count} intraday points, ${deletedHourly.count} hourly points.`);
            this.metrics.incrementAnalyticsRetentionDeleted('INTRADAY', deletedIntraday.count);
            this.metrics.incrementAnalyticsRetentionDeleted('HOURLY', deletedHourly.count);
        }
        catch (err) {
            this.logger.error(`Failed to execute retention cleanup: ${err.message}`, err.stack);
        }
    }
    async enqueueRecalculation(userId, rebuildHistory) {
        await this.queueService.addJob(queue_constants_1.Queues.ANALYTICS_RECALCULATE, `recalculate-manual-${Date.now()}-${userId}`, { userId, rebuildHistory });
    }
};
exports.AnalyticsService = AnalyticsService;
__decorate([
    (0, schedule_1.Cron)('45 23 * * *', { timeZone: 'Asia/Kolkata' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AnalyticsService.prototype, "handleNightlyAnalyticsRecalculation", null);
__decorate([
    (0, schedule_1.Cron)('0 2 * * *'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], AnalyticsService.prototype, "cleanupEquityCurvePoints", null);
exports.AnalyticsService = AnalyticsService = AnalyticsService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        cache_service_1.CacheService,
        metrics_service_1.MetricsService,
        queues_service_1.QueueService])
], AnalyticsService);
//# sourceMappingURL=analytics.service.js.map