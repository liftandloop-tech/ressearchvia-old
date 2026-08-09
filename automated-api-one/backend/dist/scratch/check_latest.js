"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const prisma_service_1 = require("../src/prisma.service");
async function checkLatest() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule, { logger: ['error'] });
    const prisma = app.get(prisma_service_1.PrismaService);
    try {
        const userId = '94371dba-36d1-47af-b10a-bf58762677b6';
        console.log('--- LATEST TRADE ---');
        const trade = await prisma.trade.findFirst({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            include: { orders: true, signal: true },
        });
        if (trade) {
            console.log(`Trade: ${trade.id} | Status: ${trade.status} | Created: ${trade.createdAt}`);
            console.log(`Signal: ${trade.signal?.symbol} (${trade.signal?.side})`);
            console.log(`Orders:`, trade.orders);
        }
        else {
            console.log('No trade found for user');
        }
        console.log('\n--- LATEST AUDIT LOGS (last 5) ---');
        const audits = await prisma.auditLog.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            take: 5,
        });
        for (const a of audits) {
            console.log(`[${a.createdAt.toISOString()}] ${a.eventType}`);
            console.log(`  ${JSON.stringify(a.metadata)}`);
        }
        console.log('\n--- DB UserBroker token check ---');
        const ub = await prisma.$queryRaw `
      SELECT id, broker_client_id, access_token, token_expiry, deleted_at, api_key
      FROM user_brokers 
      WHERE user_id = ${userId}::uuid
    `;
        for (const r of ub) {
            console.log(`ID: ${r.id}`);
            console.log(`  ClientID: ${r.broker_client_id}`);
            console.log(`  ApiKey: ${r.api_key}`);
            console.log(`  Token: ${r.access_token ? r.access_token.substring(0, 15) + '...' : 'NULL'}`);
            console.log(`  Expiry: ${r.token_expiry}`);
            console.log(`  Deleted: ${r.deleted_at}`);
        }
    }
    catch (error) {
        console.error('Error:', error);
    }
    finally {
        await app.close();
    }
}
checkLatest();
//# sourceMappingURL=check_latest.js.map