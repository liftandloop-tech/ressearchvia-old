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
var ExecutionRecoveryService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ExecutionRecoveryService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const prisma_service_1 = require("../../prisma.service");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const client_1 = require("@prisma/client");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
const NON_TERMINAL_ORDER_STATUSES = [
    client_1.OrderStatus.PENDING,
    client_1.OrderStatus.PLACED,
    client_1.OrderStatus.PARTIALLY_FILLED,
];
let ExecutionRecoveryService = ExecutionRecoveryService_1 = class ExecutionRecoveryService {
    prisma;
    queueService;
    redisService;
    configService;
    metrics;
    logger = new common_1.Logger(ExecutionRecoveryService_1.name);
    batchSize;
    maxOrders;
    constructor(prisma, queueService, redisService, configService, metrics) {
        this.prisma = prisma;
        this.queueService = queueService;
        this.redisService = redisService;
        this.configService = configService;
        this.metrics = metrics;
        this.batchSize = this.configService.get('RECOVERY_BATCH_SIZE', 500);
        this.maxOrders = this.configService.get('RECOVERY_MAX_ORDERS', 50_000);
    }
    async onApplicationBootstrap() {
        if (!this.redisService.isHealthy()) {
            this.logger.warn('Redis is not available on startup — skipping execution recovery. ' +
                'Orders in non-terminal states will not be re-monitored until Redis recovers.');
            return;
        }
        this.logger.log('Running startup execution recovery scan...');
        try {
            this.metrics.incrementRecoveryJobs();
            await this.recoverPendingOrders();
        }
        catch (err) {
            this.metrics.incrementRecoveryJobsFailed();
            this.logger.error(`Execution recovery scan failed: ${err.message}`);
        }
    }
    async recoverPendingOrders() {
        let recovered = 0;
        let failed = 0;
        let totalScanned = 0;
        let lastCursorId;
        this.logger.log(`Recovery scan config: batchSize=${this.batchSize} maxOrders=${this.maxOrders}`);
        while (true) {
            if (totalScanned >= this.maxOrders) {
                this.logger.warn(`Recovery halted at RECOVERY_MAX_ORDERS limit (${this.maxOrders}). ` +
                    `${totalScanned} orders scanned. Remaining orders will be picked up on the next deployment.`);
                break;
            }
            const batch = await this.prisma.order.findMany({
                where: {
                    status: { in: NON_TERMINAL_ORDER_STATUSES },
                    trade: {
                        status: { in: [client_1.TradeStatus.PENDING, client_1.TradeStatus.OPEN] },
                    },
                },
                select: {
                    id: true,
                    tradeId: true,
                    correlationId: true,
                },
                orderBy: { createdAt: 'asc' },
                take: this.batchSize,
                ...(lastCursorId ? { cursor: { id: lastCursorId }, skip: 1 } : {}),
            });
            if (batch.length === 0)
                break;
            totalScanned += batch.length;
            lastCursorId = batch[batch.length - 1].id;
            for (const order of batch) {
                const jobId = `recovery-${order.id}`;
                try {
                    await this.queueService.addJob(queue_constants_1.Queues.ORDER_MONITORING, jobId, {
                        orderId: order.id,
                        tradeId: order.tradeId,
                        correlationId: order.correlationId ?? `recovery-${order.id}`,
                        isRecovery: true,
                    });
                    recovered++;
                    this.metrics.incrementRecoveryOrdersRecovered(1);
                }
                catch (err) {
                    this.logger.error(`Failed to re-enqueue order ${order.id} during recovery: ${err.message}`);
                    failed++;
                }
            }
            this.logger.debug(`Recovery page processed: ${batch.length} orders. ` +
                `Running — recovered=${recovered} failed=${failed} scanned=${totalScanned}`);
            if (batch.length < this.batchSize)
                break;
        }
        if (totalScanned === 0) {
            this.logger.log('Execution recovery: no pending orders found.');
        }
        else {
            this.logger.log(`Execution recovery complete. ` +
                `Scanned=${totalScanned} Recovered=${recovered} Failed=${failed}`);
        }
    }
};
exports.ExecutionRecoveryService = ExecutionRecoveryService;
exports.ExecutionRecoveryService = ExecutionRecoveryService = ExecutionRecoveryService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        queues_service_1.QueueService,
        redis_service_1.RedisService,
        config_1.ConfigService,
        metrics_service_1.MetricsService])
], ExecutionRecoveryService);
//# sourceMappingURL=execution-recovery.service.js.map