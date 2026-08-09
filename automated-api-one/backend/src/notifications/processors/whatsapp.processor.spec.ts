import { Test, TestingModule } from '@nestjs/testing';
import { WhatsAppProcessor } from './whatsapp.processor';
import { WhatsAppCloudProvider } from '../providers/whatsapp.provider';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';
import { DeliveryStatus, QueueJobStatus } from '@prisma/client';
import { mockPrismaService } from '../../../test/mocks/prisma.mock';

describe('WhatsAppProcessor', () => {
  let processor: WhatsAppProcessor;
  let whatsappMock: any;
  let circuitMock: any;
  let prismaMock: any;
  let queueMock: any;
  let metricsMock: any;

  beforeEach(async () => {
    whatsappMock = { sendWhatsApp: jest.fn().mockResolvedValue('whatsapp-id') };
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
        WhatsAppProcessor,
        { provide: WhatsAppCloudProvider, useValue: whatsappMock },
        { provide: CircuitBreakerService, useValue: circuitMock },
        { provide: PrismaService, useValue: prismaMock },
        { provide: QueueService, useValue: queueMock },
        { provide: MetricsService, useValue: metricsMock },
      ],
    }).compile();

    processor = module.get<WhatsAppProcessor>(WhatsAppProcessor);
  });

  it('should successfully process WhatsApp delivery and update parameters from DB', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue({
      id: 'del-1',
      notification: { message: 'Aggregated Trade Info' },
    });
    prismaMock.notificationDelivery.update.mockResolvedValue({});

    const job = {
      id: 'job-1',
      attemptsMade: 0,
      data: {
        deliveryId: 'del-1',
        to: '+9876543210',
        templateName: 'trade_alert',
        parameters: ['John', 'Old Message'],
      },
    } as any;

    await processor.process(job);

    expect(prismaMock.notificationDelivery.findUnique).toHaveBeenCalledWith({
      where: { id: 'del-1' },
      include: { notification: true },
    });
    expect(whatsappMock.sendWhatsApp).toHaveBeenCalledWith(
      '+9876543210',
      'trade_alert',
      ['John', 'Aggregated Trade Info'],
    );
    expect(circuitMock.execute).toHaveBeenCalledWith('whatsapp-notifications', expect.any(Function));
    expect(queueMock.updateJobStatus).toHaveBeenCalledWith(
      expect.any(String),
      'job-1',
      QueueJobStatus.COMPLETED,
      0,
    );
  });

  it('should fail job and update delivery status to FAILED if WhatsApp provider throws', async () => {
    prismaMock.notificationDelivery.findUnique.mockResolvedValue(null);
    whatsappMock.sendWhatsApp.mockRejectedValue(new Error('WhatsApp service down'));

    const job = {
      id: 'job-2',
      attemptsMade: 0,
      data: {
        deliveryId: 'del-2',
        to: '+9876543210',
        templateName: 'trade_alert',
        parameters: ['John'],
      },
    } as any;

    await expect(processor.process(job)).rejects.toThrow('WhatsApp service down');
    expect(prismaMock.notificationDelivery.update).toHaveBeenLastCalledWith({
      where: { id: 'del-2' },
      data: expect.objectContaining({
        status: DeliveryStatus.FAILED,
        error: 'WhatsApp service down',
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
