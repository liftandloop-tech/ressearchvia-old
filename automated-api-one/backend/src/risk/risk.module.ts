import { Module } from '@nestjs/common';
import { RiskController } from './risk.controller';
import { RiskService } from './risk.service';
import { PrismaService } from '../prisma.service';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { ConsentsModule } from '../consents/consents.module';
import { BrokersModule } from '../brokers/brokers.module';
import { AuditModule } from '../audit/audit.module';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { RiskProcessor } from './risk.processor';

@Module({
  imports: [
    SubscriptionsModule,
    ConsentsModule,
    BrokersModule,
    AuditModule,
    InfrastructureModule,
  ],
  controllers: [RiskController],
  providers: [RiskService, PrismaService, RiskProcessor],
  exports: [RiskService],
})
export class RiskModule {}

