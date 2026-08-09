import { Module, Global } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { RedisService } from './redis.service';
import { BrokerRateLimiterService } from './broker-rate-limiter.service';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [RedisService, BrokerRateLimiterService],
  exports: [RedisService, BrokerRateLimiterService],
})
export class RedisModule {}
