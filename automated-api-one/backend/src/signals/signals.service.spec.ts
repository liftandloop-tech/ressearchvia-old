import { Test, TestingModule } from '@nestjs/testing';
import { SignalsService } from './signals.service';
import { PrismaService } from '../prisma.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import { Segment, Side } from '@prisma/client';
import { NotFoundException } from '@nestjs/common';
import { QueueService } from '../infrastructure/queues/queues.service';
import { Queues } from '../infrastructure/queues/queue.constants';
import { MetricsService } from '../infrastructure/metrics/metrics.service';

import { RedisService } from '../infrastructure/redis/redis.service';

describe('SignalsService', () => {
  let service: SignalsService;
  let prismaMock: any;
  let queueServiceMock: any;
  let redisServiceMock: any;
  const mockMetrics = {
    incrementSignalsReceived: jest.fn(),
    incrementSignalsProcessed: jest.fn(),
    incrementSignalsFailed: jest.fn(),
    incrementOrdersPlaced: jest.fn(),
    incrementOrdersFilled: jest.fn(),
    incrementOrdersRejected: jest.fn(),
    incrementRiskRejected: jest.fn(),
    incrementBrokerTimeout: jest.fn(),
    incrementCircuitBreakerOpen: jest.fn(),
    incrementRedisLockContention: jest.fn(),
    setQueueDepth: jest.fn(),
    setActiveWorkers: jest.fn(),
    setOpenPositions: jest.fn(),
  };

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    queueServiceMock = {
      addJob: jest.fn().mockResolvedValue(undefined),
    };
    redisServiceMock = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: () => ({
        get: jest.fn().mockResolvedValue(null),
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SignalsService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: QueueService, useValue: queueServiceMock },
        { provide: MetricsService, useValue: mockMetrics },
        { provide: RedisService, useValue: redisServiceMock },
      ],
    }).compile();

    service = module.get<SignalsService>(SignalsService);
  });

  describe('publishAndEnqueue', () => {
    const mockDto = {
      segmentId: 'strategy-1',
      symbol: 'NIFTY',
      exchange: 'NFO',
      segment: Segment.FO,
      side: Side.BUY,
      entryPrice: 100,
      stopLoss: 80,
      targetPrice: 120,
    };

    it('should throw NotFoundException if segment does not exist', async () => {
      prismaMock.segmentMaster.findUnique.mockResolvedValue(null);
      await expect(service.publishAndEnqueue(mockDto)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should successfully save signal and enqueue background job', async () => {
      prismaMock.segmentMaster.findUnique.mockResolvedValue({ id: 'strategy-1' });
      prismaMock.signal.create.mockResolvedValue({
        id: 'signal-1',
        segmentId: 'strategy-1',
        symbol: 'NIFTY',
      });

      const result = await service.publishAndEnqueue(mockDto);
      expect(result).toEqual({ success: true, signalId: 'signal-1' });
      expect(prismaMock.signal.create).toHaveBeenCalled();
      expect(queueServiceMock.addJob).toHaveBeenCalledWith(
        Queues.SIGNAL_PROCESSING,
        'signal:signal-1',
        { signalId: 'signal-1' },
      );
    });
  });
});
