import { Module } from '@nestjs/common';
import { ReconciliationService } from './reconciliation.service';
import { ReconciliationProcessor } from './reconciliation.processor';
import { ReconciliationScheduler } from './reconciliation.scheduler';
import { PrismaService } from '../prisma.service';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { BrokersModule } from '../brokers/brokers.module';

@Module({
  imports: [InfrastructureModule, BrokersModule],
  providers: [
    ReconciliationService,
    ReconciliationProcessor,
    ReconciliationScheduler,
    PrismaService,
  ],
  exports: [ReconciliationService],
})
export class ReconciliationModule {}
