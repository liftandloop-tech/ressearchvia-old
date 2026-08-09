import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { TwilioProvider, Msg91Provider } from '../providers/sms.providers';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { DeliveryStatus, QueueJobStatus } from '@prisma/client';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';

@Processor(Queues.SMS)
export class SmsProcessor extends WorkerHost {
  private readonly logger = new Logger(SmsProcessor.name);

  constructor(
    private readonly twilioProvider: TwilioProvider,
    private readonly msg91Provider: Msg91Provider,
    private readonly circuitBreaker: CircuitBreakerService,
    private readonly prisma: PrismaService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
  ) {
    super();
  }

  async process(job: Job<any>): Promise<void> {
    const { deliveryId, to, message } = job.data;
    const startTime = Date.now();

    this.logger.log(`Processing SMS job ${job.id} for delivery ${deliveryId} to ${to}`);

    let providerUsed = 'twilio';
    let providerId = '';

    try {
      const delivery = await this.prisma.notificationDelivery.findUnique({
        where: { id: deliveryId },
        include: { notification: true },
      });

      const finalMessage = delivery?.notification?.message || message;

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: { attempts: { increment: 1 } },
      });

      if (job.attemptsMade > 0) {
        this.metrics.incrementNotificationRetries('SMS', 'twilio');
      }

      const pStart = Date.now();
      try {
        providerId = await this.circuitBreaker.execute('twilio-notifications', async () => {
          return await this.twilioProvider.sendSms(to, finalMessage);
        });
        this.metrics.observeNotificationProviderLatency('twilio', 'SMS', Date.now() - pStart);
      } catch (twilioErr) {
        this.metrics.incrementNotificationProviderFailures('twilio', 'SMS');
        this.logger.warn(`Twilio failed or circuit open. Failing over to Msg91. Error: ${twilioErr.message}`);
        this.metrics.incrementNotificationFailover('twilio', 'msg91', 'SMS');

        const msgStart = Date.now();
        providerUsed = 'msg91';
        providerId = await this.msg91Provider.sendSms(to, finalMessage);
        this.metrics.observeNotificationProviderLatency('msg91', 'SMS', Date.now() - msgStart);
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

      this.metrics.observeNotificationDeliveryDuration('SMS', providerUsed, Date.now() - startTime);

      await this.queueService.updateJobStatus(Queues.SMS, job.id!, QueueJobStatus.COMPLETED, job.attemptsMade);
    } catch (err) {
      this.logger.error(`SMS delivery ${deliveryId} failed: ${err.message}`, err.stack);

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: {
          status: DeliveryStatus.FAILED,
          error: err.message,
          failedAt: new Date(),
        },
      });

      await this.queueService.updateJobStatus(Queues.SMS, job.id!, QueueJobStatus.FAILED, job.attemptsMade);
      throw err;
    }
  }
}
