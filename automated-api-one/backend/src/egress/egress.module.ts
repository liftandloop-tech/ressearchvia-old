import { Module, Global } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { EgressService } from './egress.service';
import { EgressController } from './egress.controller';
import { PrismaModule } from '../database/prisma/prisma.module';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';

@Global()
@Module({
  imports: [HttpModule, PrismaModule, InfrastructureModule],
  controllers: [EgressController],
  providers: [EgressService],
  exports: [EgressService],
})
export class EgressModule {}
