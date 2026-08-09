require('dotenv').config();
const { PrismaClient } = require('@prisma/client');

const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

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
    } else {
      console.log('\nNo users found in database.');
    }
  } catch (error) {
    console.error('Error querying database:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
