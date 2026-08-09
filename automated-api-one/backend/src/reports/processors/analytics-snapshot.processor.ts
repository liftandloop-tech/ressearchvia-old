import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Job, Worker } from 'bullmq';
import { PrismaService } from '../../prisma.service';
import { ReportsService } from '../reports.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { Queues } from '../../infrastructure/queues/queue.constants';

@Processor(Queues.ANALYTICS_SNAPSHOT)
export class AnalyticsSnapshotProcessor extends WorkerHost implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AnalyticsSnapshotProcessor.name);
  private workers: Worker[] = [];

  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsService: ReportsService,
    private readonly redisService: RedisService,
  ) {
    super();
  }

  onModuleInit() {
    // Start dynamic workers for all 10 shards
    for (let i = 0; i < 10; i++) {
      const qName = `analytics-snapshot-${i}`;
      const worker = new Worker(
        qName,
        async (job) => {
          this.logger.log(`Dynamic worker processing sharded job ${job.id} on queue ${qName}`);
          return this.processJob(job);
        },
        {
          connection: this.redisService.getClient() as any,
        },
      );
      this.workers.push(worker);
    }
    this.logger.log('Started 10 sharded analytics snapshot workers.');
  }

  async onModuleDestroy() {
    await Promise.all(this.workers.map(w => w.close()));
    this.logger.log('Closed 10 sharded analytics snapshot workers.');
  }

  // Handle standard/legacy jobs
  async process(job: Job<any, any, string>): Promise<any> {
    return this.processJob(job);
  }

  async processJob(job: Job<any, any, string>): Promise<any> {
    const { startDate, endDate, userId, segmentId } = job.data;

    // Default to yesterday if no start date provided
    const start = startDate ? new Date(startDate) : new Date();
    if (!startDate) {
      start.setUTCDate(start.getUTCDate() - 1);
    }

    const end = endDate ? new Date(endDate) : new Date(start.getTime());
    const queueName = job.queueName || (job as any).queue?.name || '';
    const shardIndex = queueName.includes('-') && queueName.startsWith('analytics-snapshot-') ? parseInt(queueName.split('analytics-snapshot-')[1], 10) : null;

    this.logger.log(
      `Processing analytics snapshots rebuild/compilation from ${start.toISOString()} to ${end.toISOString()} on queue ${queueName}`,
    );

    // Sharding Helper
    const getShard = (uId: string): number => {
      let hash = 0;
      for (let i = 0; i < uId.length; i++) {
        hash += uId.charCodeAt(i);
      }
      return hash % 10;
    };

    const currentDate = new Date(start.getTime());
    while (currentDate <= end) {
      const utcDate = new Date(
        Date.UTC(currentDate.getUTCFullYear(), currentDate.getUTCMonth(), currentDate.getUTCDate(), 0, 0, 0, 0),
      );

      if (userId && segmentId) {
        // Specific user and segment
        await this.reportsService.calculateAndUpsertSnapshot(userId, segmentId, utcDate);
      } else if (userId) {
        // Specific user, all active segments
        const segments = await this.prisma.userSegment.findMany({
          where: { userId, status: 'ACTIVE' },
        });
        for (const us of segments) {
          await this.reportsService.calculateAndUpsertSnapshot(userId, us.segmentId, utcDate);
        }
      } else {
        // Cursor-paginated batch of active user segments (take: 500)
        let cursor: { id: string } | undefined = undefined;
        const batchSize = 500;
        let hasMore = true;

        while (hasMore) {
          const userSegments = await this.prisma.userSegment.findMany({
            take: batchSize,
            skip: cursor ? 1 : 0,
            cursor: cursor ? { id: cursor.id } : undefined,
            where: { status: 'ACTIVE' },
            orderBy: { id: 'asc' },
          });

          if (userSegments.length === 0) {
            break;
          }

          for (const us of userSegments) {
            // If sharded, verify if this user belongs to this worker's shard
            if (shardIndex !== null && getShard(us.userId) !== shardIndex) {
              continue;
            }

            try {
              await this.reportsService.calculateAndUpsertSnapshot(us.userId, us.segmentId, utcDate);
            } catch (err) {
              this.logger.error(
                `Failed to calculate snapshot for user ${us.userId} segment ${us.segmentId} on ${utcDate.toISOString()}: ${err.message}`,
              );
            }
          }

          cursor = { id: userSegments[userSegments.length - 1].id };
          if (userSegments.length < batchSize) {
            hasMore = false;
          }
        }
      }

      currentDate.setUTCDate(currentDate.getUTCDate() + 1);
    }
  }
}
