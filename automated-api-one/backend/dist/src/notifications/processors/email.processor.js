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
var EmailProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.EmailProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const email_providers_1 = require("../providers/email.providers");
const circuit_breaker_service_1 = require("../../infrastructure/circuit-breaker/circuit-breaker.service");
const prisma_service_1 = require("../../prisma.service");
const client_1 = require("@prisma/client");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
let EmailProcessor = EmailProcessor_1 = class EmailProcessor extends bullmq_1.WorkerHost {
    resendProvider;
    smtpProvider;
    circuitBreaker;
    prisma;
    queueService;
    metrics;
    logger = new common_1.Logger(EmailProcessor_1.name);
    constructor(resendProvider, smtpProvider, circuitBreaker, prisma, queueService, metrics) {
        super();
        this.resendProvider = resendProvider;
        this.smtpProvider = smtpProvider;
        this.circuitBreaker = circuitBreaker;
        this.prisma = prisma;
        this.queueService = queueService;
        this.metrics = metrics;
    }
    async process(job) {
        const { deliveryId, to, subject, body } = job.data;
        const startTime = Date.now();
        this.logger.log(`Processing email job ${job.id} for delivery ${deliveryId} to ${to}`);
        let providerUsed = 'resend';
        let providerId = '';
        try {
            const delivery = await this.prisma.notificationDelivery.findUnique({
                where: { id: deliveryId },
                include: { notification: true },
            });
            const finalBody = delivery?.notification?.message || body;
            const finalSubject = delivery?.notification?.title || subject;
            await this.prisma.notificationDelivery.update({
                where: { id: deliveryId },
                data: { attempts: { increment: 1 } },
            });
            if (job.attemptsMade > 0) {
                this.metrics.incrementNotificationRetries('EMAIL', 'resend');
            }
            const pStart = Date.now();
            try {
                providerId = await this.circuitBreaker.execute('resend-notifications', async () => {
                    return await this.resendProvider.sendEmail(to, finalSubject, finalBody);
                });
                this.metrics.observeNotificationProviderLatency('resend', 'EMAIL', Date.now() - pStart);
            }
            catch (resendErr) {
                this.metrics.incrementNotificationProviderFailures('resend', 'EMAIL');
                this.logger.warn(`Resend failed or circuit open. Failing over to SMTP. Error: ${resendErr.message}`);
                this.metrics.incrementNotificationFailover('resend', 'smtp', 'EMAIL');
                const smtpStart = Date.now();
                providerUsed = 'smtp';
                providerId = await this.smtpProvider.sendEmail(to, finalSubject, finalBody);
                this.metrics.observeNotificationProviderLatency('smtp', 'EMAIL', Date.now() - smtpStart);
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
            this.metrics.observeNotificationDeliveryDuration('EMAIL', providerUsed, Date.now() - startTime);
            await this.queueService.updateJobStatus(queue_constants_1.Queues.EMAIL, job.id, client_1.QueueJobStatus.COMPLETED, job.attemptsMade);
        }
        catch (err) {
            this.logger.error(`Email delivery ${deliveryId} failed: ${err.message}`, err.stack);
            await this.prisma.notificationDelivery.update({
                where: { id: deliveryId },
                data: {
                    status: client_1.DeliveryStatus.FAILED,
                    error: err.message,
                    failedAt: new Date(),
                },
            });
            await this.queueService.updateJobStatus(queue_constants_1.Queues.EMAIL, job.id, client_1.QueueJobStatus.FAILED, job.attemptsMade);
            throw err;
        }
    }
};
exports.EmailProcessor = EmailProcessor;
exports.EmailProcessor = EmailProcessor = EmailProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.EMAIL),
    __metadata("design:paramtypes", [email_providers_1.ResendProvider,
        email_providers_1.SmtpProvider,
        circuit_breaker_service_1.CircuitBreakerService,
        prisma_service_1.PrismaService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService])
], EmailProcessor);
//# sourceMappingURL=email.processor.js.map