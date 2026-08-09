import { Test, TestingModule } from '@nestjs/testing';
import { TradingService } from './trading.service';
import { SignalOrchestratorService } from './services/signal-orchestrator.service';
import { SignalState } from '@prisma/client';

const mockOrchestrator = {
  processSignal: jest.fn(),
};

describe('TradingService', () => {
  let service: TradingService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TradingService,
        { provide: SignalOrchestratorService, useValue: mockOrchestrator },
      ],
    }).compile();

    service = module.get<TradingService>(TradingService);
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('executeSignal()', () => {
    it('should delegate to orchestrator and return success=true when COMPLETED', async () => {
      mockOrchestrator.processSignal.mockResolvedValue({
        state: SignalState.COMPLETED,
        correlationId: 'corr-1',
        totalUsers: 10,
        successUsers: 10,
        rejectedUsers: 0,
      });

      const result = await service.executeSignal('signal-1', 'seg-1');

      expect(result.success).toBe(true);
      expect(result.state).toBe(SignalState.COMPLETED);
      expect(result.totalUsers).toBe(10);
      expect(mockOrchestrator.processSignal).toHaveBeenCalledWith('signal-1');
    });

    it('should return success=true when PARTIALLY_COMPLETED', async () => {
      mockOrchestrator.processSignal.mockResolvedValue({
        state: SignalState.PARTIALLY_COMPLETED,
        correlationId: 'corr-2',
        totalUsers: 10,
        successUsers: 7,
        rejectedUsers: 3,
      });

      const result = await service.executeSignal('signal-1', 'seg-1');

      expect(result.success).toBe(true);
      expect(result.state).toBe(SignalState.PARTIALLY_COMPLETED);
    });

    it('should return success=false when FAILED', async () => {
      mockOrchestrator.processSignal.mockResolvedValue({
        state: SignalState.FAILED,
        correlationId: 'corr-3',
        totalUsers: 10,
        successUsers: 0,
        rejectedUsers: 10,
      });

      const result = await service.executeSignal('signal-1', 'seg-1');

      expect(result.success).toBe(false);
    });
  });
});
