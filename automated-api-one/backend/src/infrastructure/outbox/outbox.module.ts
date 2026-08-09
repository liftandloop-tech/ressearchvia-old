import { Module, Global } from '@nestjs/common';
import { OutboxService } from './outbox.service';
import { OutboxProcessor } from './outbox.processor';
import { QueuesModule } from '../queues/queues.module';
import { RedisModule } from '../redis/redis.module';

@Global()
@Module({
  imports: [QueuesModule, RedisModule],
  providers: [OutboxService, OutboxProcessor],
  exports: [OutboxService],
})
export class OutboxModule {}
