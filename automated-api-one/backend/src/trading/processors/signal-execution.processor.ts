import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { SignalOrchestratorService } from '../services/signal-orchestrator.service';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { QueueJobStatus } from '@prisma/client';

import { MetricsService } from '../../infrastructure/metrics/metrics.service';

/**
 * Signal Execution Processor — consumes jobs from the `trade-execution` queue.
 *
 * Each job payload: { signalId: string }
 *
 * This processor is the entry point for the trading engine: it delegates to
 * SignalOrchestratorService which handles idempotency, fan-out, and enqueueing
 * individual user order placement jobs.
 */
@Processor(Queues.SIGNAL_PROCESSING, {
  concurrency: 1, // Signal fan-out is sequential to prevent thundering herd
})
export class SignalExecutionProcessor extends WorkerHost {
  private readonly logger = new Logger(SignalExecutionProcessor.name);

  constructor(
    private readonly orchestrator: SignalOrchestratorService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
  ) {
    super();
  }

  async process(job: Job<{ signalId: string }>): Promise<void> {
    const { signalId } = job.data;
    const jobId = job.id ?? `signal-${signalId}`;

    this.logger.log(`Processing signal execution job: signalId=${signalId} jobId=${jobId}`);

    try {
      const result = await this.orchestrator.processSignal(signalId);

      await this.queueService.updateJobStatus(
        Queues.SIGNAL_PROCESSING,
        jobId,
        QueueJobStatus.COMPLETED,
        job.attemptsMade,
      );

      this.metrics.incrementSignalsProcessed();

      this.logger.log(
        `Signal ${signalId} processed. State=${result.state} ` +
          `Success=${result.successUsers} Rejected=${result.rejectedUsers}`,
      );
    } catch (err) {
      this.metrics.incrementSignalsFailed();

      this.logger.error(
        `Signal execution job ${jobId} failed: ${err.message}`,
        err.stack,
      );

      await this.queueService.updateJobStatus(
        Queues.SIGNAL_PROCESSING,
        jobId,
        QueueJobStatus.FAILED,
        job.attemptsMade,
      );

      // Re-throw so BullMQ applies the configured retry/backoff policy
      throw err;
    }
  }
}
