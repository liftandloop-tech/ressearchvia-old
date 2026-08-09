import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { RiskService } from './risk.service';
import { Queues } from '../infrastructure/queues/queue.constants';

@Processor(Queues.RISK_RECALCULATE)
export class RiskProcessor extends WorkerHost {
  private readonly logger = new Logger(RiskProcessor.name);

  constructor(private readonly riskService: RiskService) {
    super();
  }

  async process(job: Job<{ userId: string }>): Promise<void> {
    const { userId } = job.data;
    this.logger.log(`Processing risk recalculation job ${job.id} for user: ${userId}`);
    try {
      await this.riskService.recalculateRiskSnapshot(userId);
    } catch (err) {
      this.logger.error(`Failed to recalculate risk snapshot for user ${userId}: ${err.message}`, err.stack);
      throw err;
    }
  }
}
