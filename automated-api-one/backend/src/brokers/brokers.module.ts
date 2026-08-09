import { Module, forwardRef } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { BrokersController } from './brokers.controller';
import { AngelOneService } from './providers/angel-one.service';
import { ZebuService } from './providers/zebu.service';
import { BrokerAdapter } from './interfaces/broker-adapter.interface';
import { BrokerRegistry } from './registry/broker.registry';
import { BrokerFactory } from './factory/broker.factory';
import { PrismaService } from '../prisma.service';
import { BrokerSessionService } from './services/broker-session.service';
import { AuditModule } from '../audit/audit.module';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';
import { InstrumentsModule } from '../instruments/instruments.module';

@Module({
  imports: [
    HttpModule,
    AuditModule,
    InfrastructureModule,
    forwardRef(() => InstrumentsModule),
  ],
  controllers: [BrokersController],
  providers: [
    AngelOneService,
    ZebuService,
    PrismaService,
    BrokerRegistry,
    BrokerFactory,
    BrokerSessionService,
    {
      provide: BrokerAdapter,
      useClass: AngelOneService,
    },
  ],
  exports: [BrokerAdapter, BrokerRegistry, BrokerFactory, BrokerSessionService, AngelOneService, ZebuService],
})
export class BrokersModule {}

