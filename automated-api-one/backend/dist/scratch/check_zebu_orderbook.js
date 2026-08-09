"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const zebu_service_1 = require("../src/brokers/providers/zebu.service");
async function checkOrderBook() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule, { logger: ['error'] });
    const zebu = app.get(zebu_service_1.ZebuService);
    const token = '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113';
    try {
        console.log('=== FETCHING ZEBU LIVE ORDERS ===');
        const orders = await zebu.getOrders(token, 'Z67017');
        console.log('Live Orders from Zebu API:', JSON.stringify(orders, null, 2));
    }
    catch (err) {
        console.error('Error fetching Zebu orders:', err.message);
    }
    finally {
        await app.close();
    }
}
checkOrderBook();
//# sourceMappingURL=check_zebu_orderbook.js.map