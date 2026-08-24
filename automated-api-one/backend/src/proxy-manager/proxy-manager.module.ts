import { Module } from '@nestjs/common';
import { ProxyManagerService } from './proxy-manager.service';
import { ProxyManagerController } from './proxy-manager.controller';
import { PrismaService } from '../prisma.service';
import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [HttpModule],
  providers: [ProxyManagerService, PrismaService],
  controllers: [ProxyManagerController],
  exports: [ProxyManagerService],
})
export class ProxyManagerModule {}
