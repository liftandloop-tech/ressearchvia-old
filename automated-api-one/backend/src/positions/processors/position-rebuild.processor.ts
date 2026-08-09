import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { PrismaService } from '../../prisma.service';
import { PositionCacheService } from '../../trading/services/position-cache.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { Queues } from '../../infrastructure/queues/queue.constants';
import { QueueJobStatus, TradeStatus } from '@prisma/client';

@Processor(Queues.POSITION_REBUILD, {
  concurrency: 1,
})
export class PositionRebuildProcessor extends WorkerHost {
  private readonly logger = new Logger(PositionRebuildProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly positionCacheService: PositionCacheService,
    private readonly queueService: QueueService,
  ) {
    super();
  }

  async process(
    job: Job<{
      userId?: string;
      segmentId?: string;
    }>,
  ): Promise<void> {
    const { userId, segmentId } = job.data;
    this.logger.log(
      `Starting position rebuild job ${job.id}: userId=${userId || 'ALL'} segmentId=${segmentId || 'ALL'}`,
    );

    try {
      if (userId) {
        // Rebuild positions for a specific user (and optionally segment)
        const userSegments = await this.prisma.userSegment.findMany({
          where: {
            userId,
            ...(segmentId ? { segmentId } : {}),
          },
        });

        for (const userSegment of userSegments) {
          await this.rebuildSegment(userId, userSegment.segmentId);
        }
      } else {
        // Global rebuild: fetch all user segments
        const allSegments = await this.prisma.userSegment.findMany();
        for (const userSegment of allSegments) {
          await this.rebuildSegment(userSegment.userId, userSegment.segmentId);
        }
      }

      await this.queueService.updateJobStatus(
        Queues.POSITION_REBUILD,
        job.id!,
        QueueJobStatus.COMPLETED,
        job.attemptsMade,
      );
      this.logger.log(`Position rebuild job ${job.id} completed successfully.`);
    } catch (err: any) {
      this.logger.error(`Position rebuild job ${job.id} failed: ${err.message}`);
      await this.queueService.updateJobStatus(
        Queues.POSITION_REBUILD,
        job.id!,
        QueueJobStatus.FAILED,
        job.attemptsMade,
      );
      throw err;
    }
  }

  private async rebuildSegment(userId: string, segmentId: string): Promise<void> {
    const openTrade = await this.prisma.trade.findFirst({
      where: {
        userId,
        segmentId,
        status: TradeStatus.OPEN,
      },
      include: {
        signal: true,
      },
    });

    if (openTrade) {
      const cacheObj = {
        userId,
        segmentId,
        tradeId: openTrade.id,
        symbol: openTrade.signal.symbol,
        quantity: openTrade.quantity,
        entryPrice: Number(openTrade.entryPrice || openTrade.signal.entryPrice),
        stopLoss: Number(openTrade.signal.stopLoss),
        targetPrice: Number(openTrade.signal.targetPrice),
        side: openTrade.signal.side,
        cachedAt: new Date().toISOString(),
      };
      await this.positionCacheService.set(cacheObj);
      this.logger.debug(`Rebuilt and cached position for user ${userId} segment ${segmentId}`);
    } else {
      await this.positionCacheService.del(userId, segmentId);
      this.logger.debug(`Cleared cached position for user ${userId} segment ${segmentId} (no open trade found)`);
    }
  }
}
