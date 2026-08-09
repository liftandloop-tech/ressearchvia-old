import { Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { PublishSignalDto } from './signals.controller';
import { Signal, SignalStatus } from '@prisma/client';
import { QueueService } from '../infrastructure/queues/queues.service';
import { Queues } from '../infrastructure/queues/queue.constants';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import axios from 'axios';

@Injectable()
export class SignalsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly queueService: QueueService,
    private readonly metrics: MetricsService,
    private readonly redisService: RedisService,
  ) {}

  async publishAndEnqueue(
    dto: PublishSignalDto,
  ): Promise<{ success: boolean; signalId: string }> {
    // Check maintenance mode
    if (this.redisService.isHealthy()) {
      const isGlobalMaint = await this.redisService.getClient().get('system:maintenance:global');
      const isSignalsMaint = await this.redisService.getClient().get('system:maintenance:signals');
      if (isGlobalMaint === 'true' || isSignalsMaint === 'true') {
        throw new ServiceUnavailableException('Signals publishing is currently disabled due to system maintenance');
      }
    }

    // Verify SegmentMaster exists
    const segment = await this.prisma.segmentMaster.findUnique({
      where: { id: dto.segmentId },
    });

    if (!segment) {
      throw new NotFoundException('Segment not found');
    }

    // Save to Database
    const signal = await this.prisma.signal.create({
      data: {
        segmentId: dto.segmentId,
        symbol: dto.symbol,
        exchange: dto.exchange,
        segment: dto.segment,
        side: dto.side,
        orderType: dto.orderType,
        entryPrice: dto.entryPrice,
        stopLoss: dto.stopLoss,
        targetPrice: dto.targetPrice,
        status: SignalStatus.PUBLISHED,
        publishedAt: new Date(),
      },
    });

    // Enqueue job for background processing using resilient QueueService
    await this.queueService.addJob(
      Queues.SIGNAL_PROCESSING,
      `signal-${signal.id}`,
      { signalId: signal.id },
    );

    this.metrics.incrementSignalsReceived();

    // Forward the signal to l-l-backend for reports and manual user tracking
    await this.forwardSignalToLlBackend(signal);

    return {
      success: true,
      signalId: signal.id,
    };
  }

  private async forwardSignalToLlBackend(signal: Signal): Promise<void> {
    const baseUrl = process.env.LL_BACKEND_URL || 'http://localhost:8080';
    const apiKey = process.env.AUTOMATED_API_KEY || 'default_secret_key';

    try {
      await axios.post(
        `${baseUrl}/api/reports/automated-trading-call`,
        {
          symbol: signal.symbol,
          exchange: signal.exchange,
          side: signal.side,
          entryPrice: Number(signal.entryPrice),
          stopLoss: Number(signal.stopLoss),
          targetPrice: Number(signal.targetPrice),
          segment: signal.segment,
          rawSignalId: signal.id,
        },
        {
          headers: {
            'x-api-key': apiKey,
          },
          timeout: 5000,
        },
      );
      console.log(`[Integration] Successfully forwarded signal ${signal.id} to l-l-backend`);
    } catch (error) {
      console.error(
        `[Integration] Failed to forward signal ${signal.id} to l-l-backend: ${error.message}`,
      );
    }
  }
}

