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
var OrderPlacementProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderPlacementProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const order_placement_service_1 = require("../services/order-placement.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const client_1 = require("@prisma/client");
let OrderPlacementProcessor = OrderPlacementProcessor_1 = class OrderPlacementProcessor extends bullmq_1.WorkerHost {
    orderPlacementService;
    queueService;
    redisService;
    configService;
    logger = new common_1.Logger(OrderPlacementProcessor_1.name);
    concurrency;
    constructor(orderPlacementService, queueService, redisService, configService) {
        super();
        this.orderPlacementService = orderPlacementService;
        this.queueService = queueService;
        this.redisService = redisService;
        this.configService = configService;
        this.concurrency = this.configService.get('ORDER_PLACEMENT_CONCURRENCY', 20);
    }
    async process(job) {
        const ctx = job.data;
        const jobId = job.id ?? ctx.jobId;
        const { correlationId, snapshot } = ctx;
        this.redisService.assertHealthy();
        this.logger.log(`[${correlationId}] Processing order placement: jobId=${jobId} user=${snapshot.userId}`);
        try {
            const result = await this.orderPlacementService.placeEntryOrder(ctx);
            if (!result.success) {
                this.logger.warn(`[${correlationId}] Order placement skipped/rejected for user ${snapshot.userId}: ${result.reason}`);
                await this.queueService.updateJobStatus(queue_constants_1.Queues.ORDER_PLACEMENT, jobId, client_1.QueueJobStatus.COMPLETED, job.attemptsMade);
                return;
            }
            await this.queueService.updateJobStatus(queue_constants_1.Queues.ORDER_PLACEMENT, jobId, client_1.QueueJobStatus.COMPLETED, job.attemptsMade);
            this.logger.log(`[${correlationId}] Order placement successful: tradeId=${result.tradeId} brokerOrderId=${result.brokerOrderId}`);
        }
        catch (err) {
            this.logger.error(`[${correlationId}] Order placement job ${jobId} failed: ${err.message}`, err.stack);
            await this.queueService.updateJobStatus(queue_constants_1.Queues.ORDER_PLACEMENT, jobId, client_1.QueueJobStatus.FAILED, job.attemptsMade);
            throw err;
        }
    }
};
exports.OrderPlacementProcessor = OrderPlacementProcessor;
exports.OrderPlacementProcessor = OrderPlacementProcessor = OrderPlacementProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.ORDER_PLACEMENT),
    __metadata("design:paramtypes", [order_placement_service_1.OrderPlacementService,
        queues_service_1.QueueService,
        redis_service_1.RedisService,
        config_1.ConfigService])
], OrderPlacementProcessor);
//# sourceMappingURL=order-placement.processor.js.map