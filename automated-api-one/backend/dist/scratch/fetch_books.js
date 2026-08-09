"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const zebu_service_1 = require("../src/brokers/providers/zebu.service");
async function fetchOrderBookAndTradeBook() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule, { logger: ['error'] });
    const zebu = app.get(zebu_service_1.ZebuService);
    const token = '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113';
    const clientCode = 'Z67017';
    try {
        console.log('=== ZEBU LIVE ORDERBOOK ===');
        const orders = await zebu.getOrders(token, clientCode);
        console.log('ORDERS:', JSON.stringify(orders, null, 2));
        console.log('=== ZEBU LIVE TRADEBOOK ===');
        const trades = await zebu.getTradeBook(token, clientCode);
        console.log('TRADES:', JSON.stringify(trades, null, 2));
    }
    catch (err) {
        console.error('Error fetching Zebu books:', err.message);
    }
    finally {
        await app.close();
    }
}
fetchOrderBookAndTradeBook();
//# sourceMappingURL=fetch_books.js.map