import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { WhatsAppCloudProvider } from '../providers/whatsapp.provider';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { DeliveryStatus, QueueJobStatus } from '@prisma/client';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';

@Processor(Queues.WHATSAPP)
export class WhatsAppProcessor extends WorkerHost {
  private readonly logger = new Logger(WhatsAppProcessor.name);

  constructor(
    private readonly whatsappProvider: WhatsAppCloudProvider,
    private readonly circuitBreaker: CircuitBreakerService,
    private readonly prisma: PrismaService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
  ) {
    super();
  }

  async process(job: Job<any>): Promise<void> {
    const { deliveryId, to, templateName, parameters } = job.data;
    const startTime = Date.now();

    this.logger.log(`Processing WhatsApp job ${job.id} for delivery ${deliveryId} to ${to}`);

    try {
      const delivery = await this.prisma.notificationDelivery.findUnique({
        where: { id: deliveryId },
        include: { notification: true },
      });

      const finalParameters = (delivery?.notification?.message && parameters && parameters.length >= 2)
        ? [parameters[0], delivery.notification.message]
        : (parameters || []);

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: { attempts: { increment: 1 } },
      });

      if (job.attemptsMade > 0) {
        this.metrics.incrementNotificationRetries('WHATSAPP', 'whatsapp-cloud');
      }

      const pStart = Date.now();
      const providerId = await this.circuitBreaker.execute('whatsapp-notifications', async () => {
        return await this.whatsappProvider.sendWhatsApp(to, templateName, finalParameters);
      });
      this.metrics.observeNotificationProviderLatency('whatsapp-cloud', 'WHATSAPP', Date.now() - pStart);

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: {
          status: DeliveryStatus.SENT,
          provider: 'whatsapp-cloud',
          providerId,
          sentAt: new Date(),
          deliveredAt: new Date(),
        },
      });

      this.metrics.observeNotificationDeliveryDuration('WHATSAPP', 'whatsapp-cloud', Date.now() - startTime);

      await this.queueService.updateJobStatus(Queues.WHATSAPP, job.id!, QueueJobStatus.COMPLETED, job.attemptsMade);
    } catch (err) {
      this.metrics.incrementNotificationProviderFailures('whatsapp-cloud', 'WHATSAPP');
      this.logger.error(`WhatsApp delivery ${deliveryId} failed: ${err.message}`, err.stack);

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: {
          status: DeliveryStatus.FAILED,
          error: err.message,
          failedAt: new Date(),
        },
      });

      await this.queueService.updateJobStatus(Queues.WHATSAPP, job.id!, QueueJobStatus.FAILED, job.attemptsMade);
      throw err;
    }
  }
}
