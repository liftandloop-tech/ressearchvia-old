import { Subscription, SubscriptionStatus } from '@prisma/client';

export const mockSparkSubscriptionFixture = (
  overrides?: Partial<Subscription>,
): Subscription => ({
  id: '990e8400-e29b-41d4-a716-446655440001',
  userId: '550e8400-e29b-41d4-a716-446655440000',
  planId: '11111111-e29b-41d4-a716-446655440001', // Spark Plan ID
  startDate: new Date(),
  endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // Active for 30 days
  status: SubscriptionStatus.ACTIVE,
  createdAt: new Date(),
  updatedAt: new Date(),
  deletedAt: null,
  ...overrides,
});
