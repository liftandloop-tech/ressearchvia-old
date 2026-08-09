import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { ZebuService } from '../src/brokers/providers/zebu.service';

async function checkQuotes() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error'] });
  const zebu = app.get(ZebuService);

  const token = '2ce6ad0f2e6496e76124f9d2913af1401cf17d5b2b52fce3305518c099e97113'; // active token

  try {
    console.log('--- Fetching Quote for IDEA (using token 14366) ---');
    const quote1 = await zebu.getLtp(token, 'NSE', 'IDEA', '14366');
    console.log('Quote with token 14366:', quote1);
  } catch (err) {
    console.error('Error fetching quotes:', err.message);
  } finally {
    await app.close();
  }
}

checkQuotes();
