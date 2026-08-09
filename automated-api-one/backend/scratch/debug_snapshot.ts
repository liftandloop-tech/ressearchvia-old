import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma.service';

async function debugFull() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error'] });
  const prisma = app.get(PrismaService);

  const userId = '94371dba-36d1-47af-b10a-bf58762677b6';
  const segmentId = 'd8eaa0ee-e793-4b5d-b8d4-5aacb37c5ac4'; // from signal

  // 1. Check user segments for the specific signal's segment
  console.log('=== UserSegments for signal segment ===');
  const allUS = await prisma.$queryRaw`
    SELECT id, user_id, segment_id, status, deleted_at
    FROM user_segments 
    WHERE user_id = ${userId}::uuid
  `;
  console.log('All UserSegments (raw):', allUS);

  // 2. Check subscriptions
  console.log('\n=== Active subscriptions ===');
  const subs = await prisma.$queryRaw`
    SELECT id, status, start_date, end_date, deleted_at
    FROM subscriptions 
    WHERE user_id = ${userId}::uuid
  `;
  console.log('Subscriptions (raw):', subs);

  // 3. Check consents (today)
  console.log('\n=== Consents (today) ===');
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const consents = await prisma.$queryRaw`
    SELECT id, status, consent_date, deleted_at
    FROM consents 
    WHERE user_id = ${userId}::uuid
    ORDER BY consent_date DESC LIMIT 5
  `;
  console.log('Consents (raw):', consents);

  // 4. Check what fetchSubscriberBatch would actually find (full query)
  console.log('\n=== Full fetchSubscriberBatch for segment ===');
  const userSegments = await prisma.userSegment.findMany({
    where: {
      segmentId,
      status: 'ACTIVE' as any,
    },
    include: {
      user: {
        include: {
          userBrokers: {
            where: { status: 'ACTIVE' as any },
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
