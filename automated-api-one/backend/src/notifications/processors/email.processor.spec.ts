import { Test, TestingModule } from '@nestjs/testing';
import { EmailProcessor } from './email.processor';
import { ResendProvider, SmtpProvider } from '../providers/email.providers';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { DeliveryStatus, QueueJobStatus } from '@prisma/client';
import { mockPrismaService } from '../../../test/mocks/prisma.mock';

describe('EmailProcessor', () => {
  let processor: EmailProcessor;
  let resendMock: any;
  let smtpMock: any;
  let circuitMock: any;
  let prismaMock: any;
  let queueMock: any;
  let metricsMock: any;

  beforeEach(async () => {
    resendMock = { sendEmail: jest.fn().mockResolvedValue('resend-id') };
    smtpMock = { sendEmail: jest.fn().mockResolvedValue('smtp-id') };
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
        EmailProcessor,
        { provide: ResendProvider, useValue: resendMock },
        { provide: SmtpProvider, useValue: smtpMock },
        { provide: CircuitBreakerService, useValue: circuitMock },
        { provide: PrismaService, useValue: prismaMock },
        { provide: QueueService, useValue: queueMock },
        { provide: MetricsService, useValue: metricsMock },
      ],
    }).compile();

    processor = module.get<EmailProcessor>(EmailProcessor);
  });

  it('should successfully process email delivery via primary Resend', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue({
      id: 'del-1',
      notification: { title: 'Fresh Title', message: 'Fresh Message' },
    });
    prismaMock.notificationDelivery.update.mockResolvedValue({});

    const job = {
      id: 'job-1',
      attemptsMade: 0,
      data: {
        deliveryId: 'del-1',
        to: 'user@test.com',
        subject: 'Old Title',
        body: 'Old Message',
      },
    } as any;

    await processor.process(job);

    expect(prismaMock.notificationDelivery.findUnique).toHaveBeenCalledWith({
      where: { id: 'del-1' },
      include: { notification: true },
    });
    expect(resendMock.sendEmail).toHaveBeenCalledWith('user@test.com', 'Fresh Title', 'Fresh Message');
    expect(circuitMock.execute).toHaveBeenCalledWith('resend-notifications', expect.any(Function));
    expect(queueMock.updateJobStatus).toHaveBeenCalledWith(
      expect.any(String),
      'job-1',
      QueueJobStatus.COMPLETED,
      0,
    );
  });

  it('should fail over to SMTP when Resend fails', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue(null); // Fallback to static job data
    circuitMock.execute.mockRejectedValue(new Error('Resend fail'));

    const job = {
      id: 'job-2',
      attemptsMade: 0,
      data: {
        deliveryId: 'del-2',
        to: 'user@test.com',
        subject: 'Static Title',
        body: 'Static Message',
      },
    } as any;

    await processor.process(job);

    expect(resendMock.sendEmail).not.toHaveBeenCalled(); // since execution fails in circuit breaker
    expect(smtpMock.sendEmail).toHaveBeenCalledWith('user@test.com', 'Static Title', 'Static Message');
    expect(metricsMock.incrementNotificationFailover).toHaveBeenCalledWith('resend', 'smtp', 'EMAIL');
  });

  it('should fail job and update delivery status to FAILED if both primary and secondary fail', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue(null);
    circuitMock.execute.mockRejectedValue(new Error('Resend fail'));
    smtpMock.sendEmail.mockRejectedValue(new Error('SMTP fail'));

    const job = {
      id: 'job-3',
      attemptsMade: 1,
      data: {
        deliveryId: 'del-3',
        to: 'user@test.com',
        subject: 'Static Title',
        body: 'Static Message',
      },
    } as any;

    await expect(processor.process(job)).rejects.toThrow('SMTP fail');
    expect(prismaMock.notificationDelivery.update).toHaveBeenLastCalledWith({
      where: { id: 'del-3' },
      data: expect.objectContaining({
        status: DeliveryStatus.FAILED,
        error: 'SMTP fail',
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
