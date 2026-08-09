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
var PositionRebuildProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PositionRebuildProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma.service");
const position_cache_service_1 = require("../../trading/services/position-cache.service");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const client_1 = require("@prisma/client");
let PositionRebuildProcessor = PositionRebuildProcessor_1 = class PositionRebuildProcessor extends bullmq_1.WorkerHost {
    prisma;
    positionCacheService;
    queueService;
    logger = new common_1.Logger(PositionRebuildProcessor_1.name);
    constructor(prisma, positionCacheService, queueService) {
        super();
        this.prisma = prisma;
        this.positionCacheService = positionCacheService;
        this.queueService = queueService;
    }
    async process(job) {
        const { userId, segmentId } = job.data;
        this.logger.log(`Starting position rebuild job ${job.id}: userId=${userId || 'ALL'} segmentId=${segmentId || 'ALL'}`);
        try {
            if (userId) {
                const userSegments = await this.prisma.userSegment.findMany({
                    where: {
                        userId,
                        ...(segmentId ? { segmentId } : {}),
                    },
                });
                for (const userSegment of userSegments) {
                    await this.rebuildSegment(userId, userSegment.segmentId);
                }
            }
            else {
                const allSegments = await this.prisma.userSegment.findMany();
                for (const userSegment of allSegments) {
                    await this.rebuildSegment(userSegment.userId, userSegment.segmentId);
                }
            }
            await this.queueService.updateJobStatus(queue_constants_1.Queues.POSITION_REBUILD, job.id, client_1.QueueJobStatus.COMPLETED, job.attemptsMade);
            this.logger.log(`Position rebuild job ${job.id} completed successfully.`);
        }
        catch (err) {
            this.logger.error(`Position rebuild job ${job.id} failed: ${err.message}`);
            await this.queueService.updateJobStatus(queue_constants_1.Queues.POSITION_REBUILD, job.id, client_1.QueueJobStatus.FAILED, job.attemptsMade);
            throw err;
        }
    }
    async rebuildSegment(userId, segmentId) {
        const openTrade = await this.prisma.trade.findFirst({
            where: {
                userId,
                segmentId,
                status: client_1.TradeStatus.OPEN,
            },
            include: {
                signal: true,
            },
        });
        if (openTrade) {
            const cacheObj = {
                userId,
                segmentId,
                tradeId: openTrade.id,
                symbol: openTrade.signal.symbol,
                quantity: openTrade.quantity,
                entryPrice: Number(openTrade.entryPrice || openTrade.signal.entryPrice),
                stopLoss: Number(openTrade.signal.stopLoss),
                targetPrice: Number(openTrade.signal.targetPrice),
                side: openTrade.signal.side,
                cachedAt: new Date().toISOString(),
            };
            await this.positionCacheService.set(cacheObj);
            this.logger.debug(`Rebuilt and cached position for user ${userId} segment ${segmentId}`);
        }
        else {
            await this.positionCacheService.del(userId, segmentId);
            this.logger.debug(`Cleared cached position for user ${userId} segment ${segmentId} (no open trade found)`);
        }
    }
};
exports.PositionRebuildProcessor = PositionRebuildProcessor;
exports.PositionRebuildProcessor = PositionRebuildProcessor = PositionRebuildProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.POSITION_REBUILD, {
        concurrency: 1,
    }),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        position_cache_service_1.PositionCacheService,
        queues_service_1.QueueService])
], PositionRebuildProcessor);
//# sourceMappingURL=position-rebuild.processor.js.map