import { PrismaClient } from '@prisma/client';
import { createRequire } from 'module';
import dotenv from 'dotenv';

dotenv.config();
const require = createRequire(import.meta.url);

const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function check() {
  await prisma.$connect();
  
  const trades = await prisma.trade.findMany({
    include: {
      user: true,
      orders: true
    },
    orderBy: { createdAt: 'desc' }
  });
  
  console.log(`Total trades in PG: ${trades.length}`);
  for (const t of trades) {
    console.log(`Trade ID: ${t.id}, Signal ID: ${t.signalId}, User ID: ${t.userId}, User Mobile: ${t.user.mobile}, Status: ${t.status}`);
    for (const o of t.orders) {
      console.log(`  Order ID: ${o.id}, Status: ${o.status}, BrokerOrderId: ${o.brokerOrderId}, Error: ${o.errorMessage}`);
    }
  }

  await prisma.$disconnect();
  await pool.end();
}

check().catch(console.error);
