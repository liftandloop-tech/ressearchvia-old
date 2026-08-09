import { NestFactory } from '@nestjs/core';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma.service';

async function checkSignal() {
  const app = await NestFactory.createApplicationContext(AppModule, { logger: ['error'] });
  const prisma = app.get(PrismaService);

  try {
    const signalId = '96a64354-d367-470c-9aea-092f1c15a6f4';

    const signal = await prisma.signal.findUnique({
      where: { id: signalId },
    });
    console.log('Signal:', JSON.stringify(signal, null, 2));

    const trades = await prisma.trade.findMany({
      where: { signalId },
      include: { orders: true, user: { select: { id: true, mobile: true } } },
    });

    console.log(`\nTrades for this signal (${trades.length} total):`);
    for (const t of trades) {
      console.log(`  - User: ${t.userId} | Status: ${t.status} | Orders: ${t.orders.length}`);
    }
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await app.close();
  }
}

checkSignal();
