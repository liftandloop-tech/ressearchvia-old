import { Logger } from '@nestjs/common';
import { QueueEventsHost } from '@nestjs/bullmq';
import { QueueService } from './queues.service';
declare abstract class BaseQueueEventsListener extends QueueEventsHost {
    protected readonly queueService: QueueService;
    protected abstract readonly logger: Logger;
    protected abstract readonly queueName: string;
    protected abstract readonly dlqQueueName: string;
    constructor(queueService: QueueService);
    onJobFailed({ jobId, failedReason }: {
        jobId: string;
        failedReason: string;
    }): Promise<void>;
    onJobCompleted({ jobId }: {
        jobId: string;
    }): Promise<void>;
}
export declare class SignalQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class OrderPlacementQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class NotificationQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class OrderMonitoringQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class OutboxQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class WebsocketQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class ReportGenerationQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class ReportExportQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class AnalyticsSnapshotQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class PositionRebuildQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class ReconciliationQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class RiskRecalculateQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class AnalyticsRecalculateQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class EmailQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class SmsQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class WhatsAppQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export declare class PushQueueEventsListener extends BaseQueueEventsListener {
    protected readonly logger: Logger;
    protected readonly queueName: string;
    protected readonly dlqQueueName: string;
    constructor(queueService: QueueService);
}
export {};
