import { Module } from '@nestjs/common';
import { TerminusModule } from '@nestjs/terminus';
import { HealthController } from './health.controller';
import { RedisHealthIndicator } from './redis.health';
import { BrokerHealthIndicator } from './broker.health';
import { PrismaService } from '../prisma.service';
import { BrokersModule } from '../brokers/brokers.module';

@Module({
  imports: [TerminusModule, BrokersModule],
  controllers: [HealthController],
  providers: [RedisHealthIndicator, BrokerHealthIndicator, PrismaService],
})
export class HealthModule {}
