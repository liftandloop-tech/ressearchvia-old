"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("../src/app.module");
const zebu_service_1 = require("../src/brokers/providers/zebu.service");
async function checkQuotes() {
    const app = await core_1.NestFactory.createApplicationContext(app_module_1.AppModule, { logger: ['error'] });
    const zebu = app.get(zebu_service_1.ZebuService);
    const token = '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113';
    try {
        console.log('--- Fetching Quote for IDEA (using token 14366) ---');
        const quote1 = await zebu.getLtp(token, 'NSE', 'IDEA', '14366');
        console.log('Quote with token 14366:', quote1);
    }
    catch (err) {
        console.error('Error fetching quotes:', err.message);
    }
    finally {
        await app.close();
    }
}
checkQuotes();
//# sourceMappingURL=check_quotes.js.map