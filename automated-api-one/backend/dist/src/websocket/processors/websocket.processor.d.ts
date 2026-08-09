import { WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { WebsocketService } from '../services/websocket.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
export declare class WebsocketProcessor extends WorkerHost {
    private readonly websocketService;
    private readonly queueService;
    private readonly logger;
    constructor(websocketService: WebsocketService, queueService: QueueService);
    process(job: Job<{
        eventId?: string;
        event: string;
        room: string;
        payload: any;
    }>): Promise<void>;
}
