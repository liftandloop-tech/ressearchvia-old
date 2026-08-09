import { User, UserStatus } from '@prisma/client';

export const mockUserFixture = (overrides?: Partial<User>): User => ({
  id: '550e8400-e29b-41d4-a716-446655440000',
  mobile: '9876543210',
  mpinHash: '$2b$10$abcdefghijklmnopqrstuvwxy',
  firstName: 'Test',
  lastName: 'User',
  email: 'testuser@example.com',
  status: UserStatus.ACTIVE,
  quietHoursEnabled: false,
  quietStart: null,
  quietEnd: null,
  quietTimezone: null,
  createdAt: new Date(),
  updatedAt: new Date(),
  deletedAt: null,
  ...overrides,
});
