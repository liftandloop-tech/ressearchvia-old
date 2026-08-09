import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ConfigModule } from '@nestjs/config';

import { TradingService } from './trading.service';
import { SignalOrchestratorService } from './services/signal-orchestrator.service';
import { OrderPlacementService } from './services/order-placement.service';
import { OrderMonitoringService } from './services/order-monitoring.service';
import { PositionCacheService } from './services/position-cache.service';
import { MultiplierService } from './services/multiplier.service';
import { ExecutionRecoveryService } from './services/execution-recovery.service';

import { SignalExecutionProcessor } from './processors/signal-execution.processor';
import { OrderPlacementProcessor } from './processors/order-placement.processor';
import { OrderMonitoringProcessor } from './processors/order-monitoring.processor';

import { RiskModule } from '../risk/risk.module';
import { ConsentsModule } from '../consents/consents.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { BrokersModule } from '../brokers/brokers.module';
import { AuditModule } from '../audit/audit.module';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { Queues } from '../infrastructure/queues/queue.constants';

@Module({
  imports: [
    ConfigModule,
    BullModule.registerQueue(
      { name: Queues.SIGNAL_PROCESSING },
      { name: Queues.ORDER_PLACEMENT },
      { name: Queues.ORDER_MONITORING },
    ),
    RiskModule,
    ConsentsModule,
    SubscriptionsModule,
    BrokersModule,
    AuditModule,
    InfrastructureModule,
  ],
  providers: [
    TradingService,
    // Core trading services
    SignalOrchestratorService,
    OrderPlacementService,
    OrderMonitoringService,
    PositionCacheService,
    MultiplierService,
    ExecutionRecoveryService,
    // BullMQ workers
    SignalExecutionProcessor,
    OrderPlacementProcessor,
    OrderMonitoringProcessor,
  ],
  exports: [TradingService, SignalOrchestratorService, PositionCacheService],
})
export class TradingModule {}
