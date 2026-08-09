import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma.service';
import { RedisService } from '../src/infrastructure/redis/redis.service';
import { RedisKeys } from '../src/infrastructure/redis/redis-keys';

async function debugResolve() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error'] });
  const prisma = app.get(PrismaService);
  const redis = app.get(RedisService);

  const userId = '94371dba-36d1-47af-b10a-bf58762677b6';
  const brokerId = '3f6c8d11-5dc2-48df-9f93-4a1ef0c42d3c';

  console.log('=== Redis check ===');
  console.log('isHealthy:', redis.isHealthy());
  const sessionKey = RedisKeys.brokerSession(userId, brokerId);
  console.log('Redis key:', sessionKey);
  const cached = await redis.getClient().get(sessionKey);
  console.log('Redis value:', cached);

  console.log('\n=== DB check (Prisma findFirst with extension) ===');
  const result = await prisma.userBroker.findFirst({
    where: { userId, brokerId },
    select: { accessToken: true, status: true, deletedAt: true },
  });
  console.log('DB findFirst result:', result);

  console.log('\n=== DB check (raw SQL) ===');
  const raw = await prisma.$queryRaw`
    SELECT access_token, status, deleted_at, broker_id 
    FROM user_brokers 
    WHERE user_id = ${userId}::uuid
  `;
  console.log('Raw SQL result:', raw);

  await app.close();
}

debugResolve().catch(console.error);
