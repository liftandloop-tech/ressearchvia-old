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
var PushProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PushProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const push_provider_1 = require("../providers/push.provider");
const circuit_breaker_service_1 = require("../../infrastructure/circuit-breaker/circuit-breaker.service");
const prisma_service_1 = require("../../prisma.service");
const client_1 = require("@prisma/client");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
let PushProcessor = PushProcessor_1 = class PushProcessor extends bullmq_1.WorkerHost {
    fcmProvider;
    circuitBreaker;
    prisma;
    queueService;
    metrics;
    logger = new common_1.Logger(PushProcessor_1.name);
    constructor(fcmProvider, circuitBreaker, prisma, queueService, metrics) {
        super();
        this.fcmProvider = fcmProvider;
        this.circuitBreaker = circuitBreaker;
        this.prisma = prisma;
        this.queueService = queueService;
        this.metrics = metrics;
    }
    async process(job) {
        const { deliveryId, token, title, body } = job.data;
        const startTime = Date.now();
        this.logger.log(`Processing push job ${job.id} for delivery ${deliveryId}`);
        try {
            const delivery = await this.prisma.notificationDelivery.findUnique({
                where: { id: deliveryId },
                include: { notification: true },
            });
            const finalBody = delivery?.notification?.message || body;
            const finalTitle = delivery?.notification?.title || title;
            await this.prisma.notificationDelivery.update({
                where: { id: deliveryId },
                data: { attempts: { increment: 1 } },
            });
            if (job.attemptsMade > 0) {
                this.metrics.incrementNotificationRetries('PUSH', 'fcm');
            }
            const pStart = Date.now();
            const providerId = await this.circuitBreaker.execute('push-notifications', async () => {
                return await this.fcmProvider.sendPush(token, finalTitle, finalBody);
            });
            this.metrics.observeNotificationProviderLatency('fcm', 'PUSH', Date.now() - pStart);
            await this.prisma.notificationDelivery.update({
                where: { id: deliveryId },
                data: {
                    status: client_1.DeliveryStatus.SENT,
                    provider: 'fcm',
                    providerId,
                    sentAt: new Date(),
                    deliveredAt: new Date(),
                },
            });
            this.metrics.observeNotificationDeliveryDuration('PUSH', 'fcm', Date.now() - startTime);
            await this.queueService.updateJobStatus(queue_constants_1.Queues.PUSH, job.id, client_1.QueueJobStatus.COMPLETED, job.attemptsMade);
        }
        catch (err) {
            this.metrics.incrementNotificationProviderFailures('fcm', 'PUSH');
            this.logger.error(`Push delivery ${deliveryId} failed: ${err.message}`, err.stack);
            await this.prisma.notificationDelivery.update({
                where: { id: deliveryId },
                data: {
                    status: client_1.DeliveryStatus.FAILED,
                    error: err.message,
                    failedAt: new Date(),
                },
            });
            await this.queueService.updateJobStatus(queue_constants_1.Queues.PUSH, job.id, client_1.QueueJobStatus.FAILED, job.attemptsMade);
            throw err;
        }
    }
};
exports.PushProcessor = PushProcessor;
exports.PushProcessor = PushProcessor = PushProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.PUSH),
    __metadata("design:paramtypes", [push_provider_1.FcmProvider,
        circuit_breaker_service_1.CircuitBreakerService,
        prisma_service_1.PrismaService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService])
], PushProcessor);
//# sourceMappingURL=push.processor.js.map