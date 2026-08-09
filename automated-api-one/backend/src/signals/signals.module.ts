import { Module } from '@nestjs/common';
import { SignalsController } from './signals.controller';
import { SignalsService } from './signals.service';
import { BrokersModule } from '../brokers/brokers.module';
import { ConsentsModule } from '../consents/consents.module';
import { PrismaService } from '../prisma.service';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';

@Module({
  imports: [
    BrokersModule,
    ConsentsModule,
    InfrastructureModule,
  ],
  controllers: [SignalsController],
  providers: [SignalsService, PrismaService],
  exports: [SignalsService],
})
export class SignalsModule {}
