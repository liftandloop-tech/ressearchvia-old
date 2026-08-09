import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { ZebuService } from '../src/brokers/providers/zebu.service';

async function fetchOrderBookAndTradeBook() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error'] });
  const zebu = app.get(ZebuService);
  const token = '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113';
  const clientCode = 'Z67017';

  try {
    console.log('=== ZEBU LIVE ORDERBOOK ===');
    const orders = await zebu.getOrders(token, clientCode);
    console.log('ORDERS:', JSON.stringify(orders, null, 2));

    console.log('=== ZEBU LIVE TRADEBOOK ===');
    const trades = await zebu.getTradeBook(token, clientCode);
    console.log('TRADES:', JSON.stringify(trades, null, 2));
  } catch (err) {
    console.error('Error fetching Zebu books:', err.message);
  } finally {
    await app.close();
  }
}

fetchOrderBookAndTradeBook();
