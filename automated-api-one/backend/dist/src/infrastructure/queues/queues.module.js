"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.QueuesModule = void 0;
const common_1 = require("@nestjs/common");
const bullmq_1 = require("@nestjs/bullmq");
const queue_constants_1 = require("./queue.constants");
const queues_service_1 = require("./queues.service");
const dlq_handler_1 = require("./dlq.handler");
let QueuesModule = class QueuesModule {
};
exports.QueuesModule = QueuesModule;
exports.QueuesModule = QueuesModule = __decorate([
    (0, common_1.Global)(),
    (0, common_1.Module)({
        imports: [
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.SIGNAL_PROCESSING }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.ORDER_PLACEMENT }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.ORDER_MONITORING }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.NOTIFICATION }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.SIGNAL_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.ORDER_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.ORDER_MONITORING_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.NOTIFICATION_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.OUTBOX_DISPATCHER }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.OUTBOX_DISPATCHER_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.WEBSOCKET }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.WEBSOCKET_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.REPORT_GENERATION }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.REPORT_GENERATION_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.REPORT_EXPORT }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.REPORT_EXPORT_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.ANALYTICS_SNAPSHOT }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.ANALYTICS_SNAPSHOT_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.POSITION_REBUILD }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.POSITION_REBUILD_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.RECONCILIATION }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.RECONCILIATION_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.RISK_RECALCULATE }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.RISK_RECALCULATE_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.ANALYTICS_RECALCULATE }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.ANALYTICS_RECALCULATE_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.EMAIL }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.EMAIL_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.SMS }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.SMS_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.WHATSAPP }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.WHATSAPP_DLQ }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.PUSH }),
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.PUSH_DLQ }),
            ...Array.from({ length: 10 }, (_, i) => bullmq_1.BullModule.registerQueue({ name: `analytics-snapshot-${i}` })),
            ...Array.from({ length: 10 }, (_, i) => bullmq_1.BullModule.registerQueue({ name: `analytics-snapshot-dlq-${i}` })),
        ],
        providers: [
            queues_service_1.QueueService,
            dlq_handler_1.SignalQueueEventsListener,
            dlq_handler_1.OrderPlacementQueueEventsListener,
            dlq_handler_1.NotificationQueueEventsListener,
            dlq_handler_1.OrderMonitoringQueueEventsListener,
            dlq_handler_1.OutboxQueueEventsListener,
            dlq_handler_1.WebsocketQueueEventsListener,
            dlq_handler_1.ReportGenerationQueueEventsListener,
            dlq_handler_1.ReportExportQueueEventsListener,
            dlq_handler_1.AnalyticsSnapshotQueueEventsListener,
            dlq_handler_1.PositionRebuildQueueEventsListener,
            dlq_handler_1.ReconciliationQueueEventsListener,
            dlq_handler_1.RiskRecalculateQueueEventsListener,
            dlq_handler_1.AnalyticsRecalculateQueueEventsListener,
            dlq_handler_1.EmailQueueEventsListener,
            dlq_handler_1.SmsQueueEventsListener,
            dlq_handler_1.WhatsAppQueueEventsListener,
            dlq_handler_1.PushQueueEventsListener,
        ],
        exports: [queues_service_1.QueueService],
    })
], QueuesModule);
//# sourceMappingURL=queues.module.js.map