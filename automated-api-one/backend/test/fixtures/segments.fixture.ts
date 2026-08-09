import { Segment } from '@prisma/client';

export interface MockSegment {
  id: string;
  name: string;
  code: Segment;
  description: string;
  status: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt: Date | null;
}

export const mockSegmentFixture = (
  overrides?: Partial<MockSegment>,
): MockSegment => ({
  id: '770e8400-e29b-41d4-a716-446655440000',
  name: 'Nifty Options Scalping',
  code: Segment.FO,
  description: 'High frequency options trading based on momentum.',
  status: 'ACTIVE',
  createdAt: new Date(),
  updatedAt: new Date(),
  deletedAt: null,
  ...overrides,
});
