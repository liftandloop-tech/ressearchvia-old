"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const prisma_service_1 = require("../src/prisma.service");
async function checkTradesAndAudit() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule, { logger: ['error'] });
    const prisma = app.get(prisma_service_1.PrismaService);
    try {
        const userId = '94371dba-36d1-47af-b10a-bf58762677b6';
        console.log('--- LATEST 5 TRADES ---');
        const trades = await prisma.trade.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            take: 5,
            include: {
                orders: true,
                signal: true,
            },
        });
        for (const t of trades) {
            console.log(`Trade ID: ${t.id}`);
            console.log(`- Created At: ${t.createdAt}`);
            console.log(`- Signal: ${t.signal.symbol} (${t.signal.side})`);
            console.log(`- Status: ${t.status}`);
            console.log(`- Orders Count: ${t.orders.length}`);
            for (const o of t.orders) {
                console.log(`  * Order Status: ${o.status}, Price: ${o.price}, Qty: ${o.quantity}, BrokerOrderId: ${o.brokerOrderId}`);
            }
        }
        console.log('\n--- LATEST 10 AUDIT LOGS ---');
        const audits = await prisma.auditLog.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            take: 10,
        });
        for (const a of audits) {
            console.log(`[${a.createdAt.toISOString()}] Event: ${a.eventType}`);
            console.log(`  Metadata: ${JSON.stringify(a.metadata, null, 2)}`);
        }
    }
    catch (error) {
        console.error('Error:', error);
    }
    finally {
        await app.close();
    }
}
checkTradesAndAudit();
//# sourceMappingURL=check_trades_and_audit.js.map