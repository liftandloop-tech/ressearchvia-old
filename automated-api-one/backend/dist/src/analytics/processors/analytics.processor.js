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
var AnalyticsProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnalyticsProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const analytics_service_1 = require("../analytics.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
let AnalyticsProcessor = AnalyticsProcessor_1 = class AnalyticsProcessor extends bullmq_1.WorkerHost {
    analyticsService;
    logger = new common_1.Logger(AnalyticsProcessor_1.name);
    constructor(analyticsService) {
        super();
        this.analyticsService = analyticsService;
    }
    async process(job) {
        const { userId, runId, totalUsers, rebuildHistory } = job.data;
        this.logger.log(`Processing analytics job ${job.id} for user: ${userId} (rebuildHistory: ${!!rebuildHistory})`);
        try {
            if (rebuildHistory) {
                await this.analyticsService.rebuildHistoricalSnapshots(userId);
            }
            else {
                await this.analyticsService.recalculateAnalyticsSnapshot(userId);
            }
            await this.analyticsService.updatePerformanceRollups(userId);
            if (runId && totalUsers) {
                await this.analyticsService.handleJobCompletion(runId, totalUsers, true);
            }
        }
        catch (err) {
            this.logger.error(`Failed processing analytics job for user ${userId}: ${err.message}`, err.stack);
            if (runId && totalUsers) {
                await this.analyticsService.handleJobCompletion(runId, totalUsers, false);
            }
            throw err;
        }
    }
};
exports.AnalyticsProcessor = AnalyticsProcessor;
exports.AnalyticsProcessor = AnalyticsProcessor = AnalyticsProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.ANALYTICS_RECALCULATE),
    __metadata("design:paramtypes", [analytics_service_1.AnalyticsService])
], AnalyticsProcessor);
//# sourceMappingURL=analytics.processor.js.map