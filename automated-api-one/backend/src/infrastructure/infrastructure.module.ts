import { Module } from '@nestjs/common';
import { RedisModule } from './redis/redis.module';
import { CacheModule } from './cache/cache.module';
import { LocksModule } from './locks/locks.module';
import { IdempotencyModule } from './idempotency/idempotency.module';
import { QueuesModule } from './queues/queues.module';
import { OutboxModule } from './outbox/outbox.module';
import { CircuitBreakerModule } from './circuit-breaker/circuit-breaker.module';
import { MetricsModule } from './metrics/metrics.module';

@Module({
  imports: [
    RedisModule,
    CacheModule,
    LocksModule,
    IdempotencyModule,
    QueuesModule,
    OutboxModule,
    CircuitBreakerModule,
    MetricsModule,
  ],
  exports: [
    RedisModule,
    CacheModule,
    LocksModule,
    IdempotencyModule,
    QueuesModule,
    OutboxModule,
    CircuitBreakerModule,
    MetricsModule,
  ],
})
export class InfrastructureModule {}
