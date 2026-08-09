"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    console.log('Connecting to database...');
    try {
        const userCount = await prisma.user.count();
        const tradeCount = await prisma.trade.count();
        const brokerCount = await prisma.broker.count();
        const signalCount = await prisma.signal.count();
        console.log('\n--- DATABASE STATUS & DATA COUNTS ---');
        console.log(`Users:      ${userCount}`);
        console.log(`Trades:     ${tradeCount}`);
        console.log(`Brokers:    ${brokerCount}`);
        console.log(`Signals:    ${signalCount}`);
        if (userCount > 0) {
            const sampleUsers = await prisma.user.findMany({ take: 3 });
            console.log('\nSample Users:');
            sampleUsers.forEach(u => {
                console.log(`- ID: ${u.id} | Mobile: ${u.mobile} | Status: ${u.status}`);
            });
        }
        else {
            console.log('\nNo users found in database.');
        }
    }
    catch (error) {
        console.error('Error querying database:', error);
    }
    finally {
        await prisma.$disconnect();
    }
}
main();
//# sourceMappingURL=check_db_data.js.map