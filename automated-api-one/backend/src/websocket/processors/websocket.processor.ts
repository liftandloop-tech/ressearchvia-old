import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { WebsocketService } from '../services/websocket.service';
import { WebsocketEvent } from '../enums/websocket-event.enum';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { QueueJobStatus } from '@prisma/client';

@Processor(Queues.WEBSOCKET, {
  concurrency: Number(process.env.WS_WORKER_CONCURRENCY || 20),
})
export class WebsocketProcessor extends WorkerHost {
  private readonly logger = new Logger(WebsocketProcessor.name);

  constructor(
    private readonly websocketService: WebsocketService,
    private readonly queueService: QueueService,
  ) {
    super();
  }

  /**
   * BullMQ processor job consumer for WebSocket events.
   * Handles incoming jobs and delegates broadcast execution.
   */
  async process(
    job: Job<{
      eventId?: string;
      event: string;
      room: string;
      payload: any;
    }>,
  ): Promise<void> {
    const { event, room, payload } = job.data;
    const eventId = job.data.eventId || job.id || `ws-${event}-${Date.now()}`;

    this.logger.log(`Processing WebSocket job: event=${event} room=${room} jobId=${job.id}`);

    try {
      await this.websocketService.broadcast(
        eventId,
        event as WebsocketEvent,
        room,
        payload,
      );

      await this.queueService.updateJobStatus(
        Queues.WEBSOCKET,
        job.id ?? eventId,
        QueueJobStatus.COMPLETED,
        job.attemptsMade,
      );
    } catch (err: any) {
      this.logger.error(`WebSocket processor job ${job.id} failed: ${err.message}`);

      await this.queueService.updateJobStatus(
        Queues.WEBSOCKET,
        job.id ?? eventId,
        QueueJobStatus.FAILED,
        job.attemptsMade,
      );

      throw err;
    }
  }
}
