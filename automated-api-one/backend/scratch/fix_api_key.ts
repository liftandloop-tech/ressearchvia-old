import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma.service';

async function fixApiKeyAndToken() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error'] });
  const prisma = app.get(PrismaService);

  try {
    const userId = '94371dba-36d1-47af-b10a-bf58762677b6';
    
    // Find all user brokers (including soft-deleted)
    const brokers = await prisma.userBroker.findMany({
      where: { userId, deletedAt: null },
    });
    
    console.log('Found UserBrokers:', brokers.length);
    
    if (brokers.length === 0) {
      // Record is soft-deleted — restore it
      const all = await (prisma as any).$queryRaw`
        SELECT id FROM user_brokers WHERE user_id = ${userId}::uuid LIMIT 1
      `;
      console.log('Soft-deleted records:', all);

      if (all.length > 0) {
        await (prisma as any).$executeRaw`
          UPDATE user_brokers 
          SET 
            api_key = 'ndTaFrT46gDk8nSBX4C4kAe3cc49aF88',
            vendor_code = 'Z67017',
            access_token = '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113',
            token_expiry = '2026-08-03T18:30:00.000Z',
            deleted_at = NULL,
            status = 'ACTIVE'
          WHERE user_id = ${userId}::uuid
        `;
        console.log('Restored and updated soft-deleted record!');
      }
    } else {
      for (const b of brokers) {
        await prisma.userBroker.update({
          where: { id: b.id },
          data: {
            apiKey: 'ndTaFrT46gDk8nSBX4C4kAe3cc49aF88',
            vendorCode: 'Z67017',
            // Also store the fresh working token
            accessToken: '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113',
            tokenExpiry: new Date('2026-08-03T18:30:00.000Z'),
          },
        });
        console.log('Updated broker record:', b.id);
      }
    }

    console.log('Done!');
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await app.close();
  }
}

fixApiKeyAndToken();
