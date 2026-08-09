import { Module } from '@nestjs/common';
import { OpsController } from './ops.controller';
import { OpsService } from './ops.service';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { BrokersModule } from '../brokers/brokers.module';
import { NotificationsModule } from '../notifications/notifications.module';

import { ReconciliationModule } from '../reconciliation/reconciliation.module';

@Module({
  imports: [InfrastructureModule, BrokersModule, NotificationsModule, ReconciliationModule],
  controllers: [OpsController],
  providers: [OpsService],
  exports: [OpsService],
})
export class AdminModule {}
