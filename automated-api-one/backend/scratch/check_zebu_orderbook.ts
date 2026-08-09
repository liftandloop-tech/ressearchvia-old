import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { ZebuService } from '../src/brokers/providers/zebu.service';

async function checkOrderBook() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error'] });
  const zebu = app.get(ZebuService);
  const token = '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113';

  try {
    console.log('=== FETCHING ZEBU LIVE ORDERS ===');
    const orders = await zebu.getOrders(token, 'Z67017');
    console.log('Live Orders from Zebu API:', JSON.stringify(orders, null, 2));
  } catch (err) {
    console.error('Error fetching Zebu orders:', err.message);
  } finally {
    await app.close();
  }
}

checkOrderBook();
