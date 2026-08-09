import { Test, TestingModule } from '@nestjs/testing';
import { OpsController } from './ops.controller';
import { OpsService } from './ops.service';

describe('OpsController', () => {
  let controller: OpsController;
  let service: OpsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [OpsController],
      providers: [
        {
          provide: OpsService,
          useValue: {
            replaySignal: jest.fn().mockResolvedValue({ operationId: 'op-sig-123' }),
            replayOutboxEvent: jest.fn().mockResolvedValue({ operationId: 'op-out-123' }),
            getDlqMetrics: jest.fn().mockResolvedValue({ waiting: 0 }),
            getDlqJobs: jest.fn().mockResolvedValue([]),
            replayDlqJob: jest.fn().mockResolvedValue({ operationId: 'op-dlq-123' }),
            deleteDlqJob: jest.fn().mockResolvedValue({ operationId: 'op-del-123' }),
            pauseQueue: jest.fn().mockResolvedValue({ operationId: 'op-pause-123' }),
            resumeQueue: jest.fn().mockResolvedValue({ operationId: 'op-res-123' }),
            unlockSegment: jest.fn().mockResolvedValue({ operationId: 'op-unlock-123' }),
            forceBrokerSessionRefresh: jest.fn().mockResolvedValue({ operationId: 'op-ref-123' }),
            rebuildPositions: jest.fn().mockResolvedValue({ operationId: 'op-reb-123' }),
            getAudits: jest.fn().mockResolvedValue([]),
          },
        },
      ],
    }).compile();

    controller = module.get<OpsController>(OpsController);
    service = module.get<OpsService>(OpsService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('replaySignal', () => {
    it('should delegate to opsService.replaySignal', async () => {
      const req = { user: { userId: 'operator-1' } };
      const res = await controller.replaySignal(req, 'sig-1');
      expect(res).toEqual({ operationId: 'op-sig-123' });
      expect(service.replaySignal).toHaveBeenCalledWith('operator-1', 'sig-1');
    });
  });

  describe('pauseQueue', () => {
    it('should delegate to opsService.pauseQueue with force=true when force is passed as string', async () => {
      const req = { user: { userId: 'operator-1' } };
      const res = await controller.pauseQueue(req, 'order-placement', 'true');
      expect(res).toEqual({ operationId: 'op-pause-123' });
      expect(service.pauseQueue).toHaveBeenCalledWith('operator-1', 'order-placement', true, undefined);
    });
  });
});
