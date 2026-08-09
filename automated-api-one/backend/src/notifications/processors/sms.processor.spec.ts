import { Test, TestingModule } from '@nestjs/testing';
import { SmsProcessor } from './sms.processor';
import { TwilioProvider, Msg91Provider } from '../providers/sms.providers';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { DeliveryStatus, QueueJobStatus } from '@prisma/client';
import { mockPrismaService } from '../../../test/mocks/prisma.mock';

describe('SmsProcessor', () => {
  let processor: SmsProcessor;
  let twilioMock: any;
  let msg91Mock: any;
  let circuitMock: any;
  let prismaMock: any;
  let queueMock: any;
  let metricsMock: any;

  beforeEach(async () => {
    twilioMock = { sendSms: jest.fn().mockResolvedValue('twilio-id') };
    msg91Mock = { sendSms: jest.fn().mockResolvedValue('msg91-id') };
    circuitMock = {
      execute: jest.fn().mockImplementation((name, fn) => fn()),
    };
    prismaMock = mockPrismaService();
    queueMock = { updateJobStatus: jest.fn().mockResolvedValue(undefined) };
    metricsMock = {
      incrementNotificationRetries: jest.fn(),
      observeNotificationProviderLatency: jest.fn(),
      incrementNotificationProviderFailures: jest.fn(),
      incrementNotificationFailover: jest.fn(),
      observeNotificationDeliveryDuration: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SmsProcessor,
        { provide: TwilioProvider, useValue: twilioMock },
        { provide: Msg91Provider, useValue: msg91Mock },
        { provide: CircuitBreakerService, useValue: circuitMock },
        { provide: PrismaService, useValue: prismaMock },
        { provide: QueueService, useValue: queueMock },
        { provide: MetricsService, useValue: metricsMock },
      ],
    }).compile();

    processor = module.get<SmsProcessor>(SmsProcessor);
  });

  it('should successfully process SMS delivery via primary Twilio', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue({
      id: 'del-1',
      notification: { message: 'Fresh SMS Message' },
    });
    prismaMock.notificationDelivery.update.mockResolvedValue({});

    const job = {
      id: 'job-1',
      attemptsMade: 0,
      data: {
        deliveryId: 'del-1',
        to: '+123456789',
        message: 'Old SMS Message',
      },
    } as any;

    await processor.process(job);

    expect(prismaMock.notificationDelivery.findUnique).toHaveBeenCalledWith({
      where: { id: 'del-1' },
      include: { notification: true },
    });
    expect(twilioMock.sendSms).toHaveBeenCalledWith('+123456789', 'Fresh SMS Message');
    expect(circuitMock.execute).toHaveBeenCalledWith('twilio-notifications', expect.any(Function));
    expect(queueMock.updateJobStatus).toHaveBeenCalledWith(
      expect.any(String),
      'job-1',
      QueueJobStatus.COMPLETED,
      0,
    );
  });

  it('should fail over to Msg91 when Twilio fails', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue(null);
    circuitMock.execute.mockRejectedValue(new Error('Twilio fail'));

    const job = {
      id: 'job-2',
      attemptsMade: 0,
      data: {
        deliveryId: 'del-2',
        to: '+123456789',
        message: 'Static SMS Message',
      },
    } as any;

    await processor.process(job);

    expect(twilioMock.sendSms).not.toHaveBeenCalled();
    expect(msg91Mock.sendSms).toHaveBeenCalledWith('+123456789', 'Static SMS Message');
    expect(metricsMock.incrementNotificationFailover).toHaveBeenCalledWith('twilio', 'msg91', 'SMS');
  });

  it('should fail job and update delivery status to FAILED if both primary and secondary fail', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue(null);
    circuitMock.execute.mockRejectedValue(new Error('Twilio fail'));
    msg91Mock.sendSms.mockRejectedValue(new Error('Msg91 fail'));

    const job = {
      id: 'job-3',
      attemptsMade: 1,
      data: {
        deliveryId: 'del-3',
        to: '+123456789',
        message: 'Static SMS Message',
      },
    } as any;

    await expect(processor.process(job)).rejects.toThrow('Msg91 fail');
    expect(prismaMock.notificationDelivery.update).toHaveBeenLastCalledWith({
      where: { id: 'del-3' },
      data: expect.objectContaining({
        status: DeliveryStatus.FAILED,
        error: 'Msg91 fail',
      }),
    });
    expect(queueMock.updateJobStatus).toHaveBeenCalledWith(
      expect.any(String),
      'job-3',
      QueueJobStatus.FAILED,
      1,
    );
  });
});
