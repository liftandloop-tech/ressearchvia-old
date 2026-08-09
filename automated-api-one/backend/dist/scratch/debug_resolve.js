"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const prisma_service_1 = require("../src/prisma.service");
const redis_service_1 = require("../src/infrastructure/redis/redis.service");
const redis_keys_1 = require("../src/infrastructure/redis/redis-keys");
async function debugResolve() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule, { logger: ['error'] });
    const prisma = app.get(prisma_service_1.PrismaService);
    const redis = app.get(redis_service_1.RedisService);
    const userId = '94371dba-36d1-47af-b10a-bf58762677b6';
    const brokerId = '3f6c8d11-5dc2-48df-9f93-4a1ef0c42d3c';
    console.log('=== Redis check ===');
    console.log('isHealthy:', redis.isHealthy());
    const sessionKey = redis_keys_1.RedisKeys.brokerSession(userId, brokerId);
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
    const raw = await prisma.$queryRaw `
    SELECT access_token, status, deleted_at, broker_id 
    FROM user_brokers 
    WHERE user_id = ${userId}::uuid
  `;
    console.log('Raw SQL result:', raw);
    await app.close();
}
debugResolve().catch(console.error);
//# sourceMappingURL=debug_resolve.js.map