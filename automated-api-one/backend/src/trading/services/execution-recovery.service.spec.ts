import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { ExecutionRecoveryService } from './execution-recovery.service';
import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { RedisService } from '../../infrastructure/redis/redis.service';

import { MetricsService } from '../../infrastructure/metrics/metrics.service';

const mockOrderFindMany = jest.fn();
const mockAddJob = jest.fn();
const mockIsHealthy = jest.fn();
const mockConfigGet = jest.fn();

const mockPrisma = { order: { findMany: mockOrderFindMany } };
const mockQueueService = { addJob: mockAddJob };
const mockRedisService = { isHealthy: mockIsHealthy };
const mockConfigService = { get: mockConfigGet };

async function buildService(overrides?: { batchSize?: number; maxOrders?: number }): Promise<ExecutionRecoveryService> {
  mockConfigGet.mockImplementation((key: string, def: number) => {
    if (key === 'RECOVERY_BATCH_SIZE') return overrides?.batchSize ?? def;
    if (key === 'RECOVERY_MAX_ORDERS') return overrides?.maxOrders ?? def;
    return def;
  });

  const module = await Test.createTestingModule({
    providers: [
      ExecutionRecoveryService,
      { provide: PrismaService, useValue: mockPrisma },
      { provide: QueueService, useValue: mockQueueService },
      { provide: RedisService, useValue: mockRedisService },
      { provide: ConfigService, useValue: mockConfigService },
      {
        provide: MetricsService,
        useValue: {
          incrementRecoveryJobs: jest.fn(),
          incrementRecoveryJobsFailed: jest.fn(),
          incrementRecoveryOrdersRecovered: jest.fn(),
        },
      },
    ],
  }).compile();

  return module.get<ExecutionRecoveryService>(ExecutionRecoveryService);
}

describe('ExecutionRecoveryService', () => {
  beforeEach(() => {
    jest.resetAllMocks();
    mockIsHealthy.mockReturnValue(true);
    mockConfigGet.mockImplementation((key: string, def: any) => def);
    mockOrderFindMany.mockResolvedValue([]);
    mockAddJob.mockResolvedValue(undefined);
  });

  it('should skip recovery when Redis is unhealthy', async () => {
    mockIsHealthy.mockReturnValue(false);
    const service = await buildService();

    await service.onApplicationBootstrap();

    expect(mockOrderFindMany).not.toHaveBeenCalled();
    expect(mockAddJob).not.toHaveBeenCalled();
  });

  it('should log completion when no pending orders found', async () => {
    mockIsHealthy.mockReturnValue(true);
    mockOrderFindMany.mockResolvedValueOnce([]);
    const service = await buildService();

    await service.onApplicationBootstrap();

    expect(mockAddJob).not.toHaveBeenCalled();
  });

  it('should re-enqueue all non-terminal orders', async () => {
    mockIsHealthy.mockReturnValue(true);
    mockOrderFindMany
      .mockResolvedValueOnce([
        { id: 'order-1', tradeId: 'trade-1', correlationId: 'corr-1' },
        { id: 'order-2', tradeId: 'trade-2', correlationId: null },
      ])
      .mockResolvedValueOnce([]); // no more pages
    mockAddJob.mockResolvedValue(undefined);
    const service = await buildService();

    await service.onApplicationBootstrap();

    expect(mockAddJob).toHaveBeenCalledTimes(2);
    expect(mockAddJob).toHaveBeenCalledWith(
      'order-monitoring',
      'recovery:order-1',
      expect.objectContaining({ orderId: 'order-1', isRecovery: true }),
    );
    expect(mockAddJob).toHaveBeenCalledWith(
      'order-monitoring',
      'recovery:order-2',
      expect.objectContaining({ orderId: 'order-2', correlationId: 'recovery-order-2', isRecovery: true }),
    );
  });

  it('should use cursor pagination — second DB call uses lastCursorId', async () => {
    mockIsHealthy.mockReturnValue(true);

    // Use batchSize=2 so we can control pages without 500-item arrays
    const service = await buildService({ batchSize: 2, maxOrders: 1000 });

    mockOrderFindMany
      .mockResolvedValueOnce([
        { id: 'order-A', tradeId: 'trade-A', correlationId: 'cA' },
        { id: 'order-B', tradeId: 'trade-B', correlationId: 'cB' },
      ]) // full page (2 = batchSize) → triggers second fetch
      .mockResolvedValueOnce([]); // empty → loop ends
    mockAddJob.mockResolvedValue(undefined);

    await service.onApplicationBootstrap();

    expect(mockOrderFindMany).toHaveBeenCalledTimes(2);
    const secondCall = mockOrderFindMany.mock.calls[1][0];
    expect(secondCall.cursor).toEqual({ id: 'order-B' });
    expect(secondCall.skip).toBe(1);
  });

  it('should continue recovery even if individual enqueues fail', async () => {
    mockIsHealthy.mockReturnValue(true);
    mockOrderFindMany
      .mockResolvedValueOnce([
        { id: 'order-1', tradeId: 'trade-1', correlationId: 'c1' },
        { id: 'order-2', tradeId: 'trade-2', correlationId: null },
      ])
      .mockResolvedValueOnce([]);
    mockAddJob
      .mockResolvedValueOnce(undefined)                   // order-1 succeeds
      .mockRejectedValueOnce(new Error('Queue error'));   // order-2 fails
    const service = await buildService();

    // Must not throw even when individual enqueues fail
    await expect(service.onApplicationBootstrap()).resolves.not.toThrow();
    expect(mockAddJob).toHaveBeenCalledTimes(2);
  });

  it('should stop at RECOVERY_MAX_ORDERS limit and not exceed it', async () => {
    mockIsHealthy.mockReturnValue(true);
    const service = await buildService({ batchSize: 2, maxOrders: 2 });

    // Each call returns a full page of 2, which would loop forever without the cap
    mockOrderFindMany.mockResolvedValue([
      { id: 'order-X', tradeId: 'trade-X', correlationId: 'cX' },
      { id: 'order-Y', tradeId: 'trade-Y', correlationId: 'cY' },
    ]);
    mockAddJob.mockResolvedValue(undefined);

    await service.onApplicationBootstrap();

    // maxOrders=2 and batchSize=2: first page fills the cap → loop halts
    expect(mockOrderFindMany).toHaveBeenCalledTimes(1);
    expect(mockAddJob).toHaveBeenCalledTimes(2);
  });
});
