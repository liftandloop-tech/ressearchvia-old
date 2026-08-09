import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { ZebuService } from '../src/brokers/providers/zebu.service';

async function placeSbinTrade() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['log', 'error', 'warn'] });
  const zebu = app.get(ZebuService);
  const token = '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113';
  const clientCode = 'Z67017';

  console.log('=== PLACING SBIN-EQ TRADING CALL ON ZEBU MYNT (go.mynt.in) ===');

  const orderParams = {
    symbol: 'SBIN-EQ',
    exchange: 'NSE',
    quantity: 1,
    price: 810.5,
    side: 'BUY' as const,
    orderType: 'LIMIT' as const,
  };

  try {
    const res = await zebu.placeOrder(token, clientCode, orderParams);
    console.log('=== ORDER PLACEMENT RESULT ===');
    console.log(JSON.stringify(res, null, 2));
  } catch (err: any) {
    console.error('Error placing order:', err.message);
  } finally {
    await app.close();
  }
}

placeSbinTrade();
