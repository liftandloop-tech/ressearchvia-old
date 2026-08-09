import { PrismaService } from '../../prisma.service';
import { OutboxEvent } from '@prisma/client';
import { QueueService } from '../queues/queues.service';
import { MetricsService } from '../metrics/metrics.service';
export declare class OutboxService {
    private readonly prisma;
    private readonly queueService;
    private readonly metrics;
    private readonly logger;
    constructor(prisma: PrismaService, queueService: QueueService, metrics: MetricsService);
    createEvent(eventType: string, payload: any, tx?: any, options?: {
        eventKey?: string;
        aggregateId?: string;
        version?: number;
        correlationId?: string;
    }): Promise<OutboxEvent>;
    enqueueEvent(eventId: string): Promise<void>;
}
