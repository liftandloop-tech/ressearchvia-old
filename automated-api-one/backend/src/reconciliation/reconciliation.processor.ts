import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Injectable, Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { Queues } from '../infrastructure/queues/queue.constants';
import { ReconciliationService } from './reconciliation.service';

@Processor(Queues.RECONCILIATION)
@Injectable()
export class ReconciliationProcessor extends WorkerHost {
  private readonly logger = new Logger(ReconciliationProcessor.name);

  constructor(private readonly reconciliationService: ReconciliationService) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    const { userId, runId } = job.data;
    this.logger.log(`Processing sharded reconciliation job ${job.id} for user ${userId} in run ${runId}`);
    try {
      await this.reconciliationService.reconcileUserBroker(userId, runId);
    } catch (err) {
      this.logger.error(`Failed to execute sharded reconciliation for user ${userId}: ${err.message}`);
      throw err;
    }
  }
}
