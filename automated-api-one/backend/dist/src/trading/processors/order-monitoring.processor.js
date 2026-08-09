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
var OrderMonitoringProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderMonitoringProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const order_monitoring_service_1 = require("../services/order-monitoring.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const client_1 = require("@prisma/client");
let OrderMonitoringProcessor = OrderMonitoringProcessor_1 = class OrderMonitoringProcessor extends bullmq_1.WorkerHost {
    orderMonitoringService;
    queueService;
    redisService;
    configService;
    logger = new common_1.Logger(OrderMonitoringProcessor_1.name);
    concurrency;
    constructor(orderMonitoringService, queueService, redisService, configService) {
        super();
        this.orderMonitoringService = orderMonitoringService;
        this.queueService = queueService;
        this.redisService = redisService;
        this.configService = configService;
        this.concurrency = this.configService.get('ORDER_MONITORING_CONCURRENCY', 50);
    }
    async process(job) {
        const { orderId, tradeId, correlationId, isRecovery } = job.data;
        const jobId = job.id ?? `monitor-${orderId}`;
        this.redisService.assertHealthy();
        this.logger.log(`[${correlationId}] Monitoring order: orderId=${orderId} tradeId=${tradeId}` +
            (isRecovery ? ' [RECOVERY]' : ''));
        try {
            const result = await this.orderMonitoringService.pollOrderStatus(orderId, correlationId);
            if (result.finalStatus === 'PENDING') {
                throw new Error(`Order ${orderId} still pending: ${result.reason ?? 'awaiting broker confirmation'}`);
            }
            await this.queueService.updateJobStatus(queue_constants_1.Queues.ORDER_MONITORING, jobId, client_1.QueueJobStatus.COMPLETED, job.attemptsMade);
            this.logger.log(`[${correlationId}] Order ${orderId} reached terminal state: ${result.finalStatus}`);
        }
        catch (err) {
            if (job.attemptsMade >= (job.opts.attempts ?? 3) - 1) {
                this.logger.error(`[${correlationId}] Order monitoring job ${jobId} exhausted all retries: ${err.message}`);
                await this.queueService.updateJobStatus(queue_constants_1.Queues.ORDER_MONITORING, jobId, client_1.QueueJobStatus.DLQ, job.attemptsMade);
            }
            throw err;
        }
    }
};
exports.OrderMonitoringProcessor = OrderMonitoringProcessor;
exports.OrderMonitoringProcessor = OrderMonitoringProcessor = OrderMonitoringProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.ORDER_MONITORING),
    __metadata("design:paramtypes", [order_monitoring_service_1.OrderMonitoringService,
        queues_service_1.QueueService,
        redis_service_1.RedisService,
        config_1.ConfigService])
], OrderMonitoringProcessor);
//# sourceMappingURL=order-monitoring.processor.js.map