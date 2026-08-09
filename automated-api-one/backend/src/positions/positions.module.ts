import { Module } from '@nestjs/common';
import { PositionsController } from './positions.controller';
import { PositionsService } from './positions.service';
import { PrismaService } from '../prisma.service';
import { TradingModule } from '../trading/trading.module';
import { PositionRebuildProcessor } from './processors/position-rebuild.processor';

@Module({
  imports: [TradingModule],
  controllers: [PositionsController],
  providers: [PositionsService, PrismaService, PositionRebuildProcessor],
  exports: [PositionsService],
})
export class PositionsModule {}
