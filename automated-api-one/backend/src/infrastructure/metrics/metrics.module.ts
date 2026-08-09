import { Global, Module } from '@nestjs/common';
import { MetricsService } from './metrics.service';
import { MetricsController } from './metrics.controller';
import { MetricsCollectorService } from './metrics-collector.service';
import { PrismaService } from '../../prisma.service';
import { RedisModule } from '../redis/redis.module';

@Global()
@Module({
  imports: [RedisModule],
  controllers: [MetricsController],
  providers: [MetricsService, MetricsCollectorService, PrismaService],
  exports: [MetricsService],
})
export class MetricsModule {}
