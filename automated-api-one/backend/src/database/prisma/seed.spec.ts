import { seed } from './../../../prisma/seed';
import { PLANS } from '../../subscriptions/plans.constants';
import {
  SEED_BROKERS,
  SEED_SEGMENTS,
  SEED_USERS,
} from '../../common/constants/seed.constants';
import {
  BrokerCode,
  AdminRole,
  Segment,
  UserStatus,
  UserSegmentStatus,
  BrokerStatus,
  AdminStatus,
  AnalystStatus,
} from '@prisma/client';
import { mockPrismaService } from '../../../test/mocks/prisma.mock';

describe('Seed Validation', () => {
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = mockPrismaService();
  });

  it('should seed default brokers, segments, admin, analyst, and client using upsert with deterministic IDs', async () => {
    await seed(prismaMock);

    // 1. Verify Brokers are upserted with deterministic IDs
    const brokerCodes = Object.keys(SEED_BROKERS) as Array<
      keyof typeof SEED_BROKERS
    >;
    expect(prismaMock.broker.upsert).toHaveBeenCalledTimes(brokerCodes.length);
    for (const key of brokerCodes) {
      const broker = SEED_BROKERS[key];
      expect(prismaMock.broker.upsert).toHaveBeenCalledWith({
        where: { id: broker.id },
        update: {
          code: broker.code as BrokerCode,
          name: broker.name,
          status: BrokerStatus.ACTIVE,
        },
        create: {
          id: broker.id,
          code: broker.code as BrokerCode,
          name: broker.name,
          status: BrokerStatus.ACTIVE,
        },
      });
    }

    // 2. Verify Segments are upserted with deterministic IDs
    expect(prismaMock.segmentMaster.upsert).toHaveBeenCalledTimes(7);
    expect(prismaMock.segmentMaster.upsert).toHaveBeenCalledWith({
      where: { id: SEED_SEGMENTS.EQUITY_CASH.id },
      update: {
        name: SEED_SEGMENTS.EQUITY_CASH.name,
        description: SEED_SEGMENTS.EQUITY_CASH.description,
        segment: Segment.INTRADAY,
        status: UserSegmentStatus.ACTIVE,
      },
      create: {
        id: SEED_SEGMENTS.EQUITY_CASH.id,
        name: SEED_SEGMENTS.EQUITY_CASH.name,
        description: SEED_SEGMENTS.EQUITY_CASH.description,
        segment: Segment.INTRADAY,
        status: UserSegmentStatus.ACTIVE,
      },
    });

    // 3. Verify Admin is upserted with deterministic ID
    expect(prismaMock.adminUser.upsert).toHaveBeenCalledWith({
      where: { id: SEED_USERS.ADMIN.id },
      update: {
        email: SEED_USERS.ADMIN.email,
        passwordHash: expect.any(String),
        role: AdminRole.ADMIN,
        status: AdminStatus.ACTIVE,
      },
      create: {
        id: SEED_USERS.ADMIN.id,
        email: SEED_USERS.ADMIN.email,
        passwordHash: expect.any(String),
        role: AdminRole.ADMIN,
        status: AdminStatus.ACTIVE,
      },
    });

    // 4. Verify Analyst is upserted with deterministic ID
    expect(prismaMock.analyst.upsert).toHaveBeenCalledWith({
      where: { id: SEED_USERS.ANALYST.id },
      update: {
        name: SEED_USERS.ANALYST.name,
        email: SEED_USERS.ANALYST.email,
        status: AnalystStatus.ACTIVE,
      },
      create: {
        id: SEED_USERS.ANALYST.id,
        name: SEED_USERS.ANALYST.name,
        email: SEED_USERS.ANALYST.email,
        status: AnalystStatus.ACTIVE,
      },
    });

    // 5. Verify Client is upserted with deterministic ID
    expect(prismaMock.user.upsert).toHaveBeenCalledWith({
      where: { id: SEED_USERS.CLIENT.id },
      update: {
        mobile: SEED_USERS.CLIENT.mobile,
        mpinHash: expect.any(String),
        firstName: 'Test',
        lastName: 'Client',
        email: SEED_USERS.CLIENT.email,
        status: UserStatus.ACTIVE,
      },
      create: {
        id: SEED_USERS.CLIENT.id,
        mobile: SEED_USERS.CLIENT.mobile,
        mpinHash: expect.any(String),
        firstName: 'Test',
        lastName: 'Client',
        email: SEED_USERS.CLIENT.email,
        status: UserStatus.ACTIVE,
      },
    });
  });

  it('should be completely idempotent when running seed multiple times', async () => {
    // Run seed 3 times consecutively
    await seed(prismaMock);
    await seed(prismaMock);
    await seed(prismaMock);

    // Verify no create or createMany is called (only upserts are used)
    expect(prismaMock.broker.create).not.toHaveBeenCalled();
    expect(prismaMock.segmentMaster.createMany).not.toHaveBeenCalled();
    expect(prismaMock.adminUser.create).not.toHaveBeenCalled();
    expect(prismaMock.analyst.create).not.toHaveBeenCalled();
    expect(prismaMock.user.create).not.toHaveBeenCalled();

    // Verify upsert calls are exactly multiplied by 3
    const brokerCodes = Object.keys(SEED_BROKERS);
    expect(prismaMock.broker.upsert).toHaveBeenCalledTimes(
      brokerCodes.length * 3,
    );
    expect(prismaMock.segmentMaster.upsert).toHaveBeenCalledTimes(7 * 3);
    expect(prismaMock.adminUser.upsert).toHaveBeenCalledTimes(3);
    expect(prismaMock.analyst.upsert).toHaveBeenCalledTimes(3);
    expect(prismaMock.user.upsert).toHaveBeenCalledTimes(3);
  });

  describe('Plans validation', () => {
    it('should have SPARK plan configured correctly', () => {
      expect(PLANS.SPARK).toBeDefined();
      expect(PLANS.SPARK.id).toBe('11111111-e29b-41d4-a716-446655440001');
      expect(PLANS.SPARK.name).toBe('SPARK');
      expect(PLANS.SPARK.durationDays).toBe(30);
    });

    it('should have SPLENDID plan configured correctly', () => {
      expect(PLANS.SPLENDID).toBeDefined();
      expect(PLANS.SPLENDID.id).toBe('22222222-e29b-41d4-a716-446655440002');
      expect(PLANS.SPLENDID.name).toBe('SPLENDID');
      expect(PLANS.SPLENDID.durationDays).toBe(365);
    });
  });
});
