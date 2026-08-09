import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { ResendProvider, SmtpProvider } from '../providers/email.providers';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { DeliveryStatus, QueueJobStatus } from '@prisma/client';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';

@Processor(Queues.EMAIL)
export class EmailProcessor extends WorkerHost {
  private readonly logger = new Logger(EmailProcessor.name);

  constructor(
    private readonly resendProvider: ResendProvider,
    private readonly smtpProvider: SmtpProvider,
    private readonly circuitBreaker: CircuitBreakerService,
    private readonly prisma: PrismaService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
  ) {
    super();
  }

  async process(job: Job<any>): Promise<void> {
    const { deliveryId, to, subject, body } = job.data;
    const startTime = Date.now();

    this.logger.log(`Processing email job ${job.id} for delivery ${deliveryId} to ${to}`);

    let providerUsed = 'resend';
    let providerId = '';

    try {
      const delivery = await this.prisma.notificationDelivery.findUnique({
        where: { id: deliveryId },
        include: { notification: true },
      });

      const finalBody = delivery?.notification?.message || body;
      const finalSubject = delivery?.notification?.title || subject;

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: { attempts: { increment: 1 } },
      });

      if (job.attemptsMade > 0) {
        this.metrics.incrementNotificationRetries('EMAIL', 'resend');
      }

      const pStart = Date.now();
      try {
        providerId = await this.circuitBreaker.execute('resend-notifications', async () => {
          return await this.resendProvider.sendEmail(to, finalSubject, finalBody);
        });
        this.metrics.observeNotificationProviderLatency('resend', 'EMAIL', Date.now() - pStart);
      } catch (resendErr) {
        this.metrics.incrementNotificationProviderFailures('resend', 'EMAIL');
        this.logger.warn(`Resend failed or circuit open. Failing over to SMTP. Error: ${resendErr.message}`);
        this.metrics.incrementNotificationFailover('resend', 'smtp', 'EMAIL');

        const smtpStart = Date.now();
        providerUsed = 'smtp';
        providerId = await this.smtpProvider.sendEmail(to, finalSubject, finalBody);
        this.metrics.observeNotificationProviderLatency('smtp', 'EMAIL', Date.now() - smtpStart);
      }

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: {
          status: DeliveryStatus.SENT,
          provider: providerUsed,
          providerId,
          sentAt: new Date(),
          deliveredAt: new Date(),
        },
      });

      this.metrics.observeNotificationDeliveryDuration('EMAIL', providerUsed, Date.now() - startTime);

      await this.queueService.updateJobStatus(Queues.EMAIL, job.id!, QueueJobStatus.COMPLETED, job.attemptsMade);
    } catch (err) {
      this.logger.error(`Email delivery ${deliveryId} failed: ${err.message}`, err.stack);

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: {
          status: DeliveryStatus.FAILED,
          error: err.message,
          failedAt: new Date(),
        },
      });

      await this.queueService.updateJobStatus(Queues.EMAIL, job.id!, QueueJobStatus.FAILED, job.attemptsMade);
      throw err;
    }
  }
}
