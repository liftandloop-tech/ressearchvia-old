"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const prisma_service_1 = require("../src/prisma.service");
async function fixApiKeyAndToken() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule, { logger: ['error'] });
    const prisma = app.get(prisma_service_1.PrismaService);
    try {
        const userId = '94371dba-36d1-47af-b10a-bf58762677b6';
        const brokers = await prisma.userBroker.findMany({
            where: { userId, deletedAt: null },
        });
        console.log('Found UserBrokers:', brokers.length);
        if (brokers.length === 0) {
            const all = await prisma.$queryRaw `
        SELECT id FROM user_brokers WHERE user_id = ${userId}::uuid LIMIT 1
      `;
            console.log('Soft-deleted records:', all);
            if (all.length > 0) {
                await prisma.$executeRaw `
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
        }
        else {
            for (const b of brokers) {
                await prisma.userBroker.update({
                    where: { id: b.id },
                    data: {
                        apiKey: 'ndTaFrT46gDk8nSBX4C4kAe3cc49aF88',
                        vendorCode: 'Z67017',
                        accessToken: '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113',
                        tokenExpiry: new Date('2026-08-03T18:30:00.000Z'),
                    },
                });
                console.log('Updated broker record:', b.id);
            }
        }
        console.log('Done!');
    }
    catch (error) {
        console.error('Error:', error);
    }
    finally {
        await app.close();
    }
}
fixApiKeyAndToken();
//# sourceMappingURL=fix_api_key.js.map