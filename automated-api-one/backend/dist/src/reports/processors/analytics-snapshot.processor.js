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
var AnalyticsSnapshotProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnalyticsSnapshotProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const bullmq_2 = require("bullmq");
const prisma_service_1 = require("../../prisma.service");
const reports_service_1 = require("../reports.service");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
let AnalyticsSnapshotProcessor = AnalyticsSnapshotProcessor_1 = class AnalyticsSnapshotProcessor extends bullmq_1.WorkerHost {
    prisma;
    reportsService;
    redisService;
    logger = new common_1.Logger(AnalyticsSnapshotProcessor_1.name);
    workers = [];
    constructor(prisma, reportsService, redisService) {
        super();
        this.prisma = prisma;
        this.reportsService = reportsService;
        this.redisService = redisService;
    }
    onModuleInit() {
        for (let i = 0; i < 10; i++) {
            const qName = `analytics-snapshot-${i}`;
            const worker = new bullmq_2.Worker(qName, async (job) => {
                this.logger.log(`Dynamic worker processing sharded job ${job.id} on queue ${qName}`);
                return this.processJob(job);
            }, {
                connection: this.redisService.getClient(),
            });
            this.workers.push(worker);
        }
        this.logger.log('Started 10 sharded analytics snapshot workers.');
    }
    async onModuleDestroy() {
        await Promise.all(this.workers.map(w => w.close()));
        this.logger.log('Closed 10 sharded analytics snapshot workers.');
    }
    async process(job) {
        return this.processJob(job);
    }
    async processJob(job) {
        const { startDate, endDate, userId, segmentId } = job.data;
        const start = startDate ? new Date(startDate) : new Date();
        if (!startDate) {
            start.setUTCDate(start.getUTCDate() - 1);
        }
        const end = endDate ? new Date(endDate) : new Date(start.getTime());
        const queueName = job.queueName || job.queue?.name || '';
        const shardIndex = queueName.includes('-') && queueName.startsWith('analytics-snapshot-') ? parseInt(queueName.split('analytics-snapshot-')[1], 10) : null;
        this.logger.log(`Processing analytics snapshots rebuild/compilation from ${start.toISOString()} to ${end.toISOString()} on queue ${queueName}`);
        const getShard = (uId) => {
            let hash = 0;
            for (let i = 0; i < uId.length; i++) {
                hash += uId.charCodeAt(i);
            }
            return hash % 10;
        };
        const currentDate = new Date(start.getTime());
        while (currentDate <= end) {
            const utcDate = new Date(Date.UTC(currentDate.getUTCFullYear(), currentDate.getUTCMonth(), currentDate.getUTCDate(), 0, 0, 0, 0));
            if (userId && segmentId) {
                await this.reportsService.calculateAndUpsertSnapshot(userId, segmentId, utcDate);
            }
            else if (userId) {
                const segments = await this.prisma.userSegment.findMany({
                    where: { userId, status: 'ACTIVE' },
                });
                for (const us of segments) {
                    await this.reportsService.calculateAndUpsertSnapshot(userId, us.segmentId, utcDate);
                }
            }
            else {
                let cursor = undefined;
                const batchSize = 500;
                let hasMore = true;
                while (hasMore) {
                    const userSegments = await this.prisma.userSegment.findMany({
                        take: batchSize,
                        skip: cursor ? 1 : 0,
                        cursor: cursor ? { id: cursor.id } : undefined,
                        where: { status: 'ACTIVE' },
                        orderBy: { id: 'asc' },
                    });
                    if (userSegments.length === 0) {
                        break;
                    }
                    for (const us of userSegments) {
                        if (shardIndex !== null && getShard(us.userId) !== shardIndex) {
                            continue;
                        }
                        try {
                            await this.reportsService.calculateAndUpsertSnapshot(us.userId, us.segmentId, utcDate);
                        }
                        catch (err) {
                            this.logger.error(`Failed to calculate snapshot for user ${us.userId} segment ${us.segmentId} on ${utcDate.toISOString()}: ${err.message}`);
                        }
                    }
                    cursor = { id: userSegments[userSegments.length - 1].id };
                    if (userSegments.length < batchSize) {
                        hasMore = false;
                    }
                }
            }
            currentDate.setUTCDate(currentDate.getUTCDate() + 1);
        }
    }
};
exports.AnalyticsSnapshotProcessor = AnalyticsSnapshotProcessor;
exports.AnalyticsSnapshotProcessor = AnalyticsSnapshotProcessor = AnalyticsSnapshotProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.ANALYTICS_SNAPSHOT),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        reports_service_1.ReportsService,
        redis_service_1.RedisService])
], AnalyticsSnapshotProcessor);
//# sourceMappingURL=analytics-snapshot.processor.js.map