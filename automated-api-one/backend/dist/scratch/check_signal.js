"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const prisma_service_1 = require("../src/prisma.service");
async function checkSignal() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule, { logger: ['error'] });
    const prisma = app.get(prisma_service_1.PrismaService);
    try {
        const signalId = '96a64354-d367-470c-9aea-092f1c15a6f4';
        const signal = await prisma.signal.findUnique({
            where: { id: signalId },
        });
        console.log('Signal:', JSON.stringify(signal, null, 2));
        const trades = await prisma.trade.findMany({
            where: { signalId },
            include: { orders: true, user: { select: { id: true, mobile: true } } },
        });
        console.log(`\nTrades for this signal (${trades.length} total):`);
        for (const t of trades) {
            console.log(`  - User: ${t.userId} | Status: ${t.status} | Orders: ${t.orders.length}`);
        }
    }
    catch (error) {
        console.error('Error:', error);
    }
    finally {
        await app.close();
    }
}
checkSignal();
//# sourceMappingURL=check_signal.js.map