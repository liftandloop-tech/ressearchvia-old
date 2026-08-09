import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { ReconciliationService } from './reconciliation.service';

@Injectable()
export class ReconciliationScheduler {
  private readonly logger = new Logger(ReconciliationScheduler.name);

  constructor(private readonly reconciliationService: ReconciliationService) {}

  @Cron('30 23 * * *', { timeZone: 'Asia/Kolkata' }) // Run nightly at 23:30 IST
  async runScheduledReconciliation() {
    if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
      return;
    }

    this.logger.log('Triggering daily scheduled broker reconciliation run...');
    try {
      const runId = await this.reconciliationService.triggerReconciliation();
      this.logger.log(`Scheduled reconciliation run triggered successfully: ${runId}`);
    } catch (err) {
      this.logger.error(`Failed to trigger scheduled reconciliation: ${err.message}`);
    }
  }
}
