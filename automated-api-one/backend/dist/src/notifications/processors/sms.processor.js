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
var SmsProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SmsProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const sms_providers_1 = require("../providers/sms.providers");
const circuit_breaker_service_1 = require("../../infrastructure/circuit-breaker/circuit-breaker.service");
const prisma_service_1 = require("../../prisma.service");
const client_1 = require("@prisma/client");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
let SmsProcessor = SmsProcessor_1 = class SmsProcessor extends bullmq_1.WorkerHost {
    twilioProvider;
    msg91Provider;
    circuitBreaker;
    prisma;
    queueService;
    metrics;
    logger = new common_1.Logger(SmsProcessor_1.name);
    constructor(twilioProvider, msg91Provider, circuitBreaker, prisma, queueService, metrics) {
        super();
        this.twilioProvider = twilioProvider;
        this.msg91Provider = msg91Provider;
        this.circuitBreaker = circuitBreaker;
        this.prisma = prisma;
        this.queueService = queueService;
        this.metrics = metrics;
    }
    async process(job) {
        const { deliveryId, to, message } = job.data;
        const startTime = Date.now();
        this.logger.log(`Processing SMS job ${job.id} for delivery ${deliveryId} to ${to}`);
        let providerUsed = 'twilio';
        let providerId = '';
        try {
            const delivery = await this.prisma.notificationDelivery.findUnique({
                where: { id: deliveryId },
                include: { notification: true },
            });
            const finalMessage = delivery?.notification?.message || message;
            await this.prisma.notificationDelivery.update({
                where: { id: deliveryId },
                data: { attempts: { increment: 1 } },
            });
            if (job.attemptsMade > 0) {
                this.metrics.incrementNotificationRetries('SMS', 'twilio');
            }
            const pStart = Date.now();
            try {
                providerId = await this.circuitBreaker.execute('twilio-notifications', async () => {
                    return await this.twilioProvider.sendSms(to, finalMessage);
                });
                this.metrics.observeNotificationProviderLatency('twilio', 'SMS', Date.now() - pStart);
            }
            catch (twilioErr) {
                this.metrics.incrementNotificationProviderFailures('twilio', 'SMS');
                this.logger.warn(`Twilio failed or circuit open. Failing over to Msg91. Error: ${twilioErr.message}`);
                this.metrics.incrementNotificationFailover('twilio', 'msg91', 'SMS');
                const msgStart = Date.now();
                providerUsed = 'msg91';
                providerId = await this.msg91Provider.sendSms(to, finalMessage);
                this.metrics.observeNotificationProviderLatency('msg91', 'SMS', Date.now() - msgStart);
            }
            await this.prisma.notificationDelivery.update({
                where: { id: deliveryId },
                data: {
                    status: client_1.DeliveryStatus.SENT,
                    provider: providerUsed,
                    providerId,
                    sentAt: new Date(),
                    deliveredAt: new Date(),
                },
            });
            this.metrics.observeNotificationDeliveryDuration('SMS', providerUsed, Date.now() - startTime);
            await this.queueService.updateJobStatus(queue_constants_1.Queues.SMS, job.id, client_1.QueueJobStatus.COMPLETED, job.attemptsMade);
        }
        catch (err) {
            this.logger.error(`SMS delivery ${deliveryId} failed: ${err.message}`, err.stack);
            await this.prisma.notificationDelivery.update({
                where: { id: deliveryId },
                data: {
                    status: client_1.DeliveryStatus.FAILED,
                    error: err.message,
                    failedAt: new Date(),
                },
            });
            await this.queueService.updateJobStatus(queue_constants_1.Queues.SMS, job.id, client_1.QueueJobStatus.FAILED, job.attemptsMade);
            throw err;
        }
    }
};
exports.SmsProcessor = SmsProcessor;
exports.SmsProcessor = SmsProcessor = SmsProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.SMS),
    __metadata("design:paramtypes", [sms_providers_1.TwilioProvider,
        sms_providers_1.Msg91Provider,
        circuit_breaker_service_1.CircuitBreakerService,
        prisma_service_1.PrismaService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService])
], SmsProcessor);
//# sourceMappingURL=sms.processor.js.map