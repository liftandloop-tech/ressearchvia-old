import { Segment, Side, SignalStatus, Prisma } from '@prisma/client';

export interface MockSignal {
  id: string;
  strategyId: string;
  symbol: string;
  exchange: string;
  segment: Segment;
  side: Side;
  entryPrice: Prisma.Decimal;
  stopLoss: Prisma.Decimal;
  targetPrice: Prisma.Decimal;
  status: SignalStatus;
  publishedAt: Date | null;
}

export const mockSignalFixture = (
  overrides?: Partial<MockSignal>,
): MockSignal => ({
  id: '880e8400-e29b-41d4-a716-446655440000',
  strategyId: '770e8400-e29b-41d4-a716-446655440000',
  symbol: 'NIFTY26JUN22000CE',
  exchange: 'NFO',
  segment: Segment.FO,
  side: Side.BUY,
  entryPrice: new Prisma.Decimal(100.5),
  stopLoss: new Prisma.Decimal(85.0),
  targetPrice: new Prisma.Decimal(130.0),
  status: SignalStatus.PUBLISHED,
  publishedAt: new Date(),
  ...overrides,
});
