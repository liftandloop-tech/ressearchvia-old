import { Injectable, Logger } from '@nestjs/common';
import { SignalOrchestratorService } from './services/signal-orchestrator.service';
import { SignalState } from '@prisma/client';

/**
 * TradingService — public facade for the Trading Engine.
 *
 * All heavy lifting is delegated to specialized services:
 * - SignalOrchestratorService: signal fan-out and user eligibility
 * - OrderPlacementService: broker order submission (via BullMQ workers)
 * - OrderMonitoringService: broker order status polling (via BullMQ workers)
 */
@Injectable()
export class TradingService {
  private readonly logger = new Logger(TradingService.name);

  constructor(private readonly orchestrator: SignalOrchestratorService) {}

  /**
   * Triggers the trading engine for an incoming signal.
   * This is the primary entry point called by SignalsService on signal publication.
   */
  async executeSignal(signalId: string, segmentId: string): Promise<{
    success: boolean;
    state: SignalState;
    correlationId: string;
    totalUsers: number;
    successUsers: number;
    rejectedUsers: number;
  }> {
    this.logger.log(`Trading engine triggered: signalId=${signalId} segmentId=${segmentId}`);

    const result = await this.orchestrator.processSignal(signalId);

    return {
      success: result.state !== SignalState.FAILED,
      ...result,
    };
  }
}
