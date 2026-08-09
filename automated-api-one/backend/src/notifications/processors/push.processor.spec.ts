import { Test, TestingModule } from '@nestjs/testing';
import { PushProcessor } from './push.processor';
import { FcmProvider } from '../providers/push.provider';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { DeliveryStatus, QueueJobStatus } from '@prisma/client';
import { mockPrismaService } from '../../../test/mocks/prisma.mock';

describe('PushProcessor', () => {
  let processor: PushProcessor;
  let fcmMock: any;
  let circuitMock: any;
  let prismaMock: any;
  let queueMock: any;
  let metricsMock: any;

  beforeEach(async () => {
    fcmMock = { sendPush: jest.fn().mockResolvedValue('push-id') };
    circuitMock = {
      execute: jest.fn().mockImplementation((name, fn) => fn()),
    };
    prismaMock = mockPrismaService();
    queueMock = { updateJobStatus: jest.fn().mockResolvedValue(undefined) };
    metricsMock = {
      incrementNotificationRetries: jest.fn(),
      observeNotificationProviderLatency: jest.fn(),
      incrementNotificationProviderFailures: jest.fn(),
      observeNotificationDeliveryDuration: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PushProcessor,
        { provide: FcmProvider, useValue: fcmMock },
        { provide: CircuitBreakerService, useValue: circuitMock },
        { provide: PrismaService, useValue: prismaMock },
        { provide: QueueService, useValue: queueMock },
        { provide: MetricsService, useValue: metricsMock },
      ],
    }).compile();

    processor = module.get<PushProcessor>(PushProcessor);
  });

  it('should successfully process push delivery and use fresh title/message from DB', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue({
      id: 'del-1',
      notification: { title: 'Fresh Push Title', message: 'Fresh Push Msg' },
    });
    prismaMock.notificationDelivery.update.mockResolvedValue({});

    const job = {
      id: 'job-1',
      attemptsMade: 0,
      data: {
        deliveryId: 'del-1',
        token: 'token-123',
        title: 'Old Title',
        body: 'Old Msg',
      },
    } as any;

    await processor.process(job);

    expect(prismaMock.notificationDelivery.findUnique).toHaveBeenCalledWith({
      where: { id: 'del-1' },
      include: { notification: true },
    });
    expect(fcmMock.sendPush).toHaveBeenCalledWith('token-123', 'Fresh Push Title', 'Fresh Push Msg');
    expect(circuitMock.execute).toHaveBeenCalledWith('push-notifications', expect.any(Function));
    expect(queueMock.updateJobStatus).toHaveBeenCalledWith(
      expect.any(String),
      'job-1',
      QueueJobStatus.COMPLETED,
      0,
    );
  });

  it('should fail job and update status to FAILED if FCM provider throws', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue(null);
    fcmMock.sendPush.mockRejectedValue(new Error('FCM error'));

    const job = {
      id: 'job-2',
      attemptsMade: 0,
      data: {
        deliveryId: 'del-2',
        token: 'token-123',
        title: 'Title',
        body: 'Msg',
      },
    } as any;

    await expect(processor.process(job)).rejects.toThrow('FCM error');
    expect(prismaMock.notificationDelivery.update).toHaveBeenLastCalledWith({
      where: { id: 'del-2' },
      data: expect.objectContaining({
        status: DeliveryStatus.FAILED,
        error: 'FCM error',
      }),
    });
    expect(queueMock.updateJobStatus).toHaveBeenCalledWith(
      expect.any(String),
      'job-2',
      QueueJobStatus.FAILED,
      0,
    );
  });
});
