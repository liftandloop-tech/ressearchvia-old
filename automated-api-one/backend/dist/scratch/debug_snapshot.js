"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const prisma_service_1 = require("../src/prisma.service");
async function debugFull() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule, { logger: ['error'] });
    const prisma = app.get(prisma_service_1.PrismaService);
    const userId = '94371dba-36d1-47af-b10a-bf58762677b6';
    const segmentId = 'd8eaa0ee-e793-4b5d-b8d4-5aacb37c5ac4';
    console.log('=== UserSegments for signal segment ===');
    const allUS = await prisma.$queryRaw `
    SELECT id, user_id, segment_id, status, deleted_at
    FROM user_segments 
    WHERE user_id = ${userId}::uuid
  `;
    console.log('All UserSegments (raw):', allUS);
    console.log('\n=== Active subscriptions ===');
    const subs = await prisma.$queryRaw `
    SELECT id, status, start_date, end_date, deleted_at
    FROM subscriptions 
    WHERE user_id = ${userId}::uuid
  `;
    console.log('Subscriptions (raw):', subs);
    console.log('\n=== Consents (today) ===');
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const consents = await prisma.$queryRaw `
    SELECT id, status, consent_date, deleted_at
    FROM consents 
    WHERE user_id = ${userId}::uuid
    ORDER BY consent_date DESC LIMIT 5
  `;
    console.log('Consents (raw):', consents);
    console.log('\n=== Full fetchSubscriberBatch for segment ===');
    const userSegments = await prisma.userSegment.findMany({
        where: {
            segmentId,
            status: 'ACTIVE',
        },
        include: {
            user: {
                include: {
                    userBrokers: {
                        where: { status: 'ACTIVE' },
                        include: { broker: true },
                        take: 1,
                    },
                },
            },
        },
        take: 20,
    });
    console.log(`Found ${userSegments.length} user segments for this segment`);
    for (const us of userSegments) {
        const ub = us.user.userBrokers[0];
        console.log(`User: ${us.userId} | Broker: ${ub?.brokerId || 'NONE'} | BrokerCode: ${ub?.broker?.code || 'NONE'}`);
        console.log(`  UB id: ${ub?.id} | deleted_at: ${ub?.deletedAt}`);
    }
    await app.close();
}
debugFull().catch(console.error);
//# sourceMappingURL=debug_snapshot.js.map