import { Module } from '@nestjs/common';
import { AnalyticsController } from './analytics.controller';
import { AnalyticsService } from './analytics.service';
import { AnalyticsProcessor } from './processors/analytics.processor';
import { PrismaService } from '../prisma.service';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';

@Module({
  imports: [InfrastructureModule],
  controllers: [AnalyticsController],
  providers: [AnalyticsService, PrismaService, AnalyticsProcessor],
  exports: [AnalyticsService],
})
export class AnalyticsModule {}
