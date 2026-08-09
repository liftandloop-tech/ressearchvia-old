import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { AnalyticsService } from '../analytics.service';
import { Queues } from '../../infrastructure/queues/queue.constants';

@Processor(Queues.ANALYTICS_RECALCULATE)
export class AnalyticsProcessor extends WorkerHost {
  private readonly logger = new Logger(AnalyticsProcessor.name);

  constructor(private readonly analyticsService: AnalyticsService) {
    super();
  }

  async process(
    job: Job<{ userId: string; runId?: string; totalUsers?: number; rebuildHistory?: boolean }>,
  ): Promise<void> {
    const { userId, runId, totalUsers, rebuildHistory } = job.data;
    this.logger.log(
      `Processing analytics job ${job.id} for user: ${userId} (rebuildHistory: ${!!rebuildHistory})`,
    );

    try {
      if (rebuildHistory) {
        await this.analyticsService.rebuildHistoricalSnapshots(userId);
      } else {
        await this.analyticsService.recalculateAnalyticsSnapshot(userId);
      }
      await this.analyticsService.updatePerformanceRollups(userId);

      if (runId && totalUsers) {
        await this.analyticsService.handleJobCompletion(runId, totalUsers, true);
      }
    } catch (err) {
      this.logger.error(`Failed processing analytics job for user ${userId}: ${err.message}`, err.stack);
      if (runId && totalUsers) {
        await this.analyticsService.handleJobCompletion(runId, totalUsers, false);
      }
      throw err;
    }
  }
}
