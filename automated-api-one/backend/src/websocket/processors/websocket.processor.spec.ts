import { Test, TestingModule } from '@nestjs/testing';
import { WebsocketProcessor } from './websocket.processor';
import { WebsocketService } from '../services/websocket.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { QueueJobStatus } from '@prisma/client';
import { Queues } from '../../infrastructure/queues/queue.constants';

describe('WebsocketProcessor', () => {
  let processor: WebsocketProcessor;
  let websocketServiceMock: any;
  let queueServiceMock: any;

  beforeEach(async () => {
    websocketServiceMock = {
      broadcast: jest.fn(),
    };

    queueServiceMock = {
      updateJobStatus: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebsocketProcessor,
        { provide: WebsocketService, useValue: websocketServiceMock },
        { provide: QueueService, useValue: queueServiceMock },
      ],
    }).compile();

    processor = module.get<WebsocketProcessor>(WebsocketProcessor);
  });

  it('should be defined', () => {
    expect(processor).toBeDefined();
  });

  describe('process', () => {
    const mockJob = {
      id: 'job-123',
      data: {
        eventId: 'event-abc',
        event: 'order.executed',
        room: 'user:user-1',
        payload: { orderId: 'ord-1' },
      },
      attemptsMade: 0,
    } as any;

    it('should invoke websocket service and update queue job status', async () => {
      websocketServiceMock.broadcast.mockResolvedValue(true);

      await processor.process(mockJob);

      expect(websocketServiceMock.broadcast).toHaveBeenCalledWith(
        'event-abc',
        'order.executed',
        'user:user-1',
        { orderId: 'ord-1' },
      );
      expect(queueServiceMock.updateJobStatus).toHaveBeenCalledWith(
        Queues.WEBSOCKET,
        'job-123',
        QueueJobStatus.COMPLETED,
        0,
      );
    });

    it('should fail queue job if broadcast throws', async () => {
      websocketServiceMock.broadcast.mockRejectedValue(new Error('Broadcast failed'));

      await expect(processor.process(mockJob)).rejects.toThrow('Broadcast failed');

      expect(queueServiceMock.updateJobStatus).toHaveBeenCalledWith(
        Queues.WEBSOCKET,
        'job-123',
        QueueJobStatus.FAILED,
        0,
      );
    });
  });
});
