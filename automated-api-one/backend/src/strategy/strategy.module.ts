import { Module } from '@nestjs/common';
import { PositionSizingService } from '../trading/services/position-sizing.service';
import { PrismaService } from '../prisma.service';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';

@Module({
  imports: [InfrastructureModule],
  providers: [PositionSizingService, PrismaService],
  exports: [PositionSizingService],
})
export class StrategyModule {}
