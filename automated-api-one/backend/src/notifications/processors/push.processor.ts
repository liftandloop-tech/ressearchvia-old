import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { FcmProvider } from '../providers/push.provider';
import { CircuitBreakerService } from '../../infrastructure/circuit-breaker/circuit-breaker.service';
import { PrismaService } from '../../prisma.service';
import { DeliveryStatus, QueueJobStatus } from '@prisma/client';
import { MetricsService } from '../../infrastructure/metrics/metrics.service';

@Processor(Queues.PUSH)
export class PushProcessor extends WorkerHost {
  private readonly logger = new Logger(PushProcessor.name);

  constructor(
    private readonly fcmProvider: FcmProvider,
    private readonly circuitBreaker: CircuitBreakerService,
    private readonly prisma: PrismaService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
  ) {
    super();
  }

  async process(job: Job<any>): Promise<void> {
    const { deliveryId, token, title, body } = job.data;
    const startTime = Date.now();

    this.logger.log(`Processing push job ${job.id} for delivery ${deliveryId}`);

    try {
      const delivery = await this.prisma.notificationDelivery.findUnique({
        where: { id: deliveryId },
        include: { notification: true },
      });

      const finalBody = delivery?.notification?.message || body;
      const finalTitle = delivery?.notification?.title || title;

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: { attempts: { increment: 1 } },
      });

      if (job.attemptsMade > 0) {
        this.metrics.incrementNotificationRetries('PUSH', 'fcm');
      }

      const pStart = Date.now();
      const providerId = await this.circuitBreaker.execute('push-notifications', async () => {
        return await this.fcmProvider.sendPush(token, finalTitle, finalBody);
      });
      this.metrics.observeNotificationProviderLatency('fcm', 'PUSH', Date.now() - pStart);

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: {
          status: DeliveryStatus.SENT,
          provider: 'fcm',
          providerId,
          sentAt: new Date(),
          deliveredAt: new Date(),
        },
      });

      this.metrics.observeNotificationDeliveryDuration('PUSH', 'fcm', Date.now() - startTime);

      await this.queueService.updateJobStatus(Queues.PUSH, job.id!, QueueJobStatus.COMPLETED, job.attemptsMade);
    } catch (err) {
      this.metrics.incrementNotificationProviderFailures('fcm', 'PUSH');
      this.logger.error(`Push delivery ${deliveryId} failed: ${err.message}`, err.stack);

      await this.prisma.notificationDelivery.update({
        where: { id: deliveryId },
        data: {
          status: DeliveryStatus.FAILED,
          error: err.message,
          failedAt: new Date(),
        },
      });

      await this.queueService.updateJobStatus(Queues.PUSH, job.id!, QueueJobStatus.FAILED, job.attemptsMade);
      throw err;
    }
  }
}
