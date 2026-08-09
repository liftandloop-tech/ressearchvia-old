import { Subscription, SubscriptionStatus } from '@prisma/client';

export const mockSplendidSubscriptionFixture = (
  overrides?: Partial<Subscription>,
): Subscription => ({
  id: '990e8400-e29b-41d4-a716-446655440002',
  userId: '550e8400-e29b-41d4-a716-446655440000',
  planId: '22222222-e29b-41d4-a716-446655440002', // Splendid Plan ID
  startDate: new Date(),
  endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // Active for 365 days
  status: SubscriptionStatus.ACTIVE,
  createdAt: new Date(),
  updatedAt: new Date(),
  deletedAt: null,
  ...overrides,
});
