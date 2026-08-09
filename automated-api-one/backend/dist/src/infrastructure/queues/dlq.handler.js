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
var SignalQueueEventsListener_1, OrderPlacementQueueEventsListener_1, NotificationQueueEventsListener_1, OrderMonitoringQueueEventsListener_1, OutboxQueueEventsListener_1, WebsocketQueueEventsListener_1, ReportGenerationQueueEventsListener_1, ReportExportQueueEventsListener_1, AnalyticsSnapshotQueueEventsListener_1, PositionRebuildQueueEventsListener_1, ReconciliationQueueEventsListener_1, RiskRecalculateQueueEventsListener_1, AnalyticsRecalculateQueueEventsListener_1, EmailQueueEventsListener_1, SmsQueueEventsListener_1, WhatsAppQueueEventsListener_1, PushQueueEventsListener_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PushQueueEventsListener = exports.WhatsAppQueueEventsListener = exports.SmsQueueEventsListener = exports.EmailQueueEventsListener = exports.AnalyticsRecalculateQueueEventsListener = exports.RiskRecalculateQueueEventsListener = exports.ReconciliationQueueEventsListener = exports.PositionRebuildQueueEventsListener = exports.AnalyticsSnapshotQueueEventsListener = exports.ReportExportQueueEventsListener = exports.ReportGenerationQueueEventsListener = exports.WebsocketQueueEventsListener = exports.OutboxQueueEventsListener = exports.OrderMonitoringQueueEventsListener = exports.NotificationQueueEventsListener = exports.OrderPlacementQueueEventsListener = exports.SignalQueueEventsListener = void 0;
const common_1 = require("@nestjs/common");
const bullmq_1 = require("@nestjs/bullmq");
const queues_service_1 = require("./queues.service");
const queue_constants_1 = require("./queue.constants");
const client_1 = require("@prisma/client");
let BaseQueueEventsListener = class BaseQueueEventsListener extends bullmq_1.QueueEventsHost {
    queueService;
    constructor(queueService) {
        super();
        this.queueService = queueService;
    }
    async onJobFailed({ jobId, failedReason }) {
        this.logger.warn(`Job ${jobId} failed in queue ${this.queueName}. Reason: ${failedReason}`);
        try {
            const queue = this.queueService.getQueue(this.queueName);
            const job = await queue.getJob(jobId);
            if (!job) {
                this.logger.error(`Job ${jobId} not found in queue ${this.queueName} to evaluate retry count.`);
                return;
            }
            const attemptsMade = job.attemptsMade;
            const maxAttempts = job.opts.attempts || 1;
            this.logger.log(`Job ${jobId} attempts made: ${attemptsMade}/${maxAttempts}`);
            if (attemptsMade >= maxAttempts) {
                this.logger.error(`Job ${jobId} retries exhausted (${attemptsMade}/${maxAttempts}). Routing to DLQ: ${this.dlqQueueName}`);
                await this.queueService.updateJobStatus(this.queueName, jobId, client_1.QueueJobStatus.DLQ, attemptsMade);
                const dlqQueue = this.queueService.getQueue(this.dlqQueueName);
                await dlqQueue.add(jobId, job.data, { jobId });
            }
            else {
                await this.queueService.updateJobStatus(this.queueName, jobId, client_1.QueueJobStatus.ACTIVE, attemptsMade);
            }
        }
        catch (err) {
            this.logger.error(`Failed to handle failure routing for job ${jobId}: ${err.message}`);
        }
    }
    async onJobCompleted({ jobId }) {
        this.logger.log(`Job ${jobId} successfully completed in queue ${this.queueName}`);
        try {
            await this.queueService.updateJobStatus(this.queueName, jobId, client_1.QueueJobStatus.COMPLETED);
        }
        catch (err) {
            this.logger.error(`Failed to update DB completion for job ${jobId}: ${err.message}`);
        }
    }
};
__decorate([
    (0, bullmq_1.OnQueueEvent)('failed'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BaseQueueEventsListener.prototype, "onJobFailed", null);
__decorate([
    (0, bullmq_1.OnQueueEvent)('completed'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BaseQueueEventsListener.prototype, "onJobCompleted", null);
BaseQueueEventsListener = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], BaseQueueEventsListener);
let SignalQueueEventsListener = SignalQueueEventsListener_1 = class SignalQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(SignalQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.SIGNAL_PROCESSING;
    dlqQueueName = queue_constants_1.Queues.SIGNAL_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.SignalQueueEventsListener = SignalQueueEventsListener;
exports.SignalQueueEventsListener = SignalQueueEventsListener = SignalQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.SIGNAL_PROCESSING),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], SignalQueueEventsListener);
let OrderPlacementQueueEventsListener = OrderPlacementQueueEventsListener_1 = class OrderPlacementQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(OrderPlacementQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.ORDER_PLACEMENT;
    dlqQueueName = queue_constants_1.Queues.ORDER_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.OrderPlacementQueueEventsListener = OrderPlacementQueueEventsListener;
exports.OrderPlacementQueueEventsListener = OrderPlacementQueueEventsListener = OrderPlacementQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.ORDER_PLACEMENT),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], OrderPlacementQueueEventsListener);
let NotificationQueueEventsListener = NotificationQueueEventsListener_1 = class NotificationQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(NotificationQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.NOTIFICATION;
    dlqQueueName = queue_constants_1.Queues.NOTIFICATION_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.NotificationQueueEventsListener = NotificationQueueEventsListener;
exports.NotificationQueueEventsListener = NotificationQueueEventsListener = NotificationQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.NOTIFICATION),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], NotificationQueueEventsListener);
let OrderMonitoringQueueEventsListener = OrderMonitoringQueueEventsListener_1 = class OrderMonitoringQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(OrderMonitoringQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.ORDER_MONITORING;
    dlqQueueName = queue_constants_1.Queues.ORDER_MONITORING_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.OrderMonitoringQueueEventsListener = OrderMonitoringQueueEventsListener;
exports.OrderMonitoringQueueEventsListener = OrderMonitoringQueueEventsListener = OrderMonitoringQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.ORDER_MONITORING),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], OrderMonitoringQueueEventsListener);
let OutboxQueueEventsListener = OutboxQueueEventsListener_1 = class OutboxQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(OutboxQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.OUTBOX_DISPATCHER;
    dlqQueueName = queue_constants_1.Queues.OUTBOX_DISPATCHER_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.OutboxQueueEventsListener = OutboxQueueEventsListener;
exports.OutboxQueueEventsListener = OutboxQueueEventsListener = OutboxQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.OUTBOX_DISPATCHER),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], OutboxQueueEventsListener);
let WebsocketQueueEventsListener = WebsocketQueueEventsListener_1 = class WebsocketQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(WebsocketQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.WEBSOCKET;
    dlqQueueName = queue_constants_1.Queues.WEBSOCKET_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.WebsocketQueueEventsListener = WebsocketQueueEventsListener;
exports.WebsocketQueueEventsListener = WebsocketQueueEventsListener = WebsocketQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.WEBSOCKET),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], WebsocketQueueEventsListener);
let ReportGenerationQueueEventsListener = ReportGenerationQueueEventsListener_1 = class ReportGenerationQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(ReportGenerationQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.REPORT_GENERATION;
    dlqQueueName = queue_constants_1.Queues.REPORT_GENERATION_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.ReportGenerationQueueEventsListener = ReportGenerationQueueEventsListener;
exports.ReportGenerationQueueEventsListener = ReportGenerationQueueEventsListener = ReportGenerationQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.REPORT_GENERATION),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], ReportGenerationQueueEventsListener);
let ReportExportQueueEventsListener = ReportExportQueueEventsListener_1 = class ReportExportQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(ReportExportQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.REPORT_EXPORT;
    dlqQueueName = queue_constants_1.Queues.REPORT_EXPORT_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.ReportExportQueueEventsListener = ReportExportQueueEventsListener;
exports.ReportExportQueueEventsListener = ReportExportQueueEventsListener = ReportExportQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.REPORT_EXPORT),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], ReportExportQueueEventsListener);
let AnalyticsSnapshotQueueEventsListener = AnalyticsSnapshotQueueEventsListener_1 = class AnalyticsSnapshotQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(AnalyticsSnapshotQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.ANALYTICS_SNAPSHOT;
    dlqQueueName = queue_constants_1.Queues.ANALYTICS_SNAPSHOT_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.AnalyticsSnapshotQueueEventsListener = AnalyticsSnapshotQueueEventsListener;
exports.AnalyticsSnapshotQueueEventsListener = AnalyticsSnapshotQueueEventsListener = AnalyticsSnapshotQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.ANALYTICS_SNAPSHOT),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], AnalyticsSnapshotQueueEventsListener);
let PositionRebuildQueueEventsListener = PositionRebuildQueueEventsListener_1 = class PositionRebuildQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(PositionRebuildQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.POSITION_REBUILD;
    dlqQueueName = queue_constants_1.Queues.POSITION_REBUILD_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.PositionRebuildQueueEventsListener = PositionRebuildQueueEventsListener;
exports.PositionRebuildQueueEventsListener = PositionRebuildQueueEventsListener = PositionRebuildQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.POSITION_REBUILD),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], PositionRebuildQueueEventsListener);
let ReconciliationQueueEventsListener = ReconciliationQueueEventsListener_1 = class ReconciliationQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(ReconciliationQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.RECONCILIATION;
    dlqQueueName = queue_constants_1.Queues.RECONCILIATION_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.ReconciliationQueueEventsListener = ReconciliationQueueEventsListener;
exports.ReconciliationQueueEventsListener = ReconciliationQueueEventsListener = ReconciliationQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.RECONCILIATION),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], ReconciliationQueueEventsListener);
let RiskRecalculateQueueEventsListener = RiskRecalculateQueueEventsListener_1 = class RiskRecalculateQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(RiskRecalculateQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.RISK_RECALCULATE;
    dlqQueueName = queue_constants_1.Queues.RISK_RECALCULATE_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.RiskRecalculateQueueEventsListener = RiskRecalculateQueueEventsListener;
exports.RiskRecalculateQueueEventsListener = RiskRecalculateQueueEventsListener = RiskRecalculateQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.RISK_RECALCULATE),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], RiskRecalculateQueueEventsListener);
let AnalyticsRecalculateQueueEventsListener = AnalyticsRecalculateQueueEventsListener_1 = class AnalyticsRecalculateQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(AnalyticsRecalculateQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.ANALYTICS_RECALCULATE;
    dlqQueueName = queue_constants_1.Queues.ANALYTICS_RECALCULATE_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.AnalyticsRecalculateQueueEventsListener = AnalyticsRecalculateQueueEventsListener;
exports.AnalyticsRecalculateQueueEventsListener = AnalyticsRecalculateQueueEventsListener = AnalyticsRecalculateQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.ANALYTICS_RECALCULATE),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], AnalyticsRecalculateQueueEventsListener);
let EmailQueueEventsListener = EmailQueueEventsListener_1 = class EmailQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(EmailQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.EMAIL;
    dlqQueueName = queue_constants_1.Queues.EMAIL_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.EmailQueueEventsListener = EmailQueueEventsListener;
exports.EmailQueueEventsListener = EmailQueueEventsListener = EmailQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.EMAIL),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], EmailQueueEventsListener);
let SmsQueueEventsListener = SmsQueueEventsListener_1 = class SmsQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(SmsQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.SMS;
    dlqQueueName = queue_constants_1.Queues.SMS_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.SmsQueueEventsListener = SmsQueueEventsListener;
exports.SmsQueueEventsListener = SmsQueueEventsListener = SmsQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.SMS),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], SmsQueueEventsListener);
let WhatsAppQueueEventsListener = WhatsAppQueueEventsListener_1 = class WhatsAppQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(WhatsAppQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.WHATSAPP;
    dlqQueueName = queue_constants_1.Queues.WHATSAPP_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.WhatsAppQueueEventsListener = WhatsAppQueueEventsListener;
exports.WhatsAppQueueEventsListener = WhatsAppQueueEventsListener = WhatsAppQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.WHATSAPP),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], WhatsAppQueueEventsListener);
let PushQueueEventsListener = PushQueueEventsListener_1 = class PushQueueEventsListener extends BaseQueueEventsListener {
    logger = new common_1.Logger(PushQueueEventsListener_1.name);
    queueName = queue_constants_1.Queues.PUSH;
    dlqQueueName = queue_constants_1.Queues.PUSH_DLQ;
    constructor(queueService) {
        super(queueService);
    }
};
exports.PushQueueEventsListener = PushQueueEventsListener;
exports.PushQueueEventsListener = PushQueueEventsListener = PushQueueEventsListener_1 = __decorate([
    (0, common_1.Injectable)(),
    (0, bullmq_1.QueueEventsListener)(queue_constants_1.Queues.PUSH),
    __metadata("design:paramtypes", [queues_service_1.QueueService])
], PushQueueEventsListener);
//# sourceMappingURL=dlq.handler.js.map