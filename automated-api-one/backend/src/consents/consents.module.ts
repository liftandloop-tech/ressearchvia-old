import { Module } from '@nestjs/common';
import { ConsentsController } from './consents.controller';
import { ConsentsService } from './consents.service';
import { PrismaService } from '../prisma.service';
import { AuditModule } from '../audit/audit.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { StrategyModule } from '../strategy/strategy.module';

@Module({
  imports: [
    AuditModule,
    NotificationsModule,
    SubscriptionsModule,
    StrategyModule,
  ],
  controllers: [ConsentsController],
  providers: [ConsentsService, PrismaService],
  exports: [ConsentsService],
})
export class ConsentsModule {}
