import pkg from 'bullmq';
const { Queue } = pkg;
import dotenv from 'dotenv';

dotenv.config();

const connection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT || '6379'),
  password: process.env.REDIS_PASSWORD || undefined,
};

async function check() {
  const queue = new Queue('order-placement', { connection });
  const completed = await queue.getJobs(['completed']);
  
  console.log(`Found ${completed.length} completed jobs:`);
  for (const j of completed) {
    console.log(`Job ID: ${j.id}`);
    console.log(`  Data:`, JSON.stringify(j.data, null, 2));
    console.log(`  Return Value:`, JSON.stringify(j.returnvalue, null, 2));
  }
  
  process.exit(0);
}

check().catch(console.error);
