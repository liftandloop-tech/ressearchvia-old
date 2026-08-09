import { PrismaClient, BrokerCode, BrokerStatus, Segment, UserStrategyStatus, AdminRole, AdminStatus, AnalystStatus, UserStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { SEED_BROKERS, SEED_SEGMENTS, SEED_USERS } from '../backend/src/common/constants/seed.constants';

let prismaInstance: PrismaClient | null = null;

export async function seed(client?: PrismaClient) {
  const db = client || prismaInstance || (prismaInstance = new PrismaClient());

  // 1. Seed Brokers
  const brokersToSeed = Object.values(SEED_BROKERS);
  for (const broker of brokersToSeed) {
    await db.broker.upsert({
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

  // 2. Seed Default Segments/Strategies
  const segmentsToSeed = [
    {
      id: SEED_SEGMENTS.INTRADAY.id,
      name: SEED_SEGMENTS.INTRADAY.name,
      description: SEED_SEGMENTS.INTRADAY.description,
      segment: Segment.INTRADAY,
      status: UserStrategyStatus.ACTIVE,
    },
    {
      id: SEED_SEGMENTS.DELIVERY.id,
      name: SEED_SEGMENTS.DELIVERY.name,
      description: SEED_SEGMENTS.DELIVERY.description,
      segment: Segment.DELIVERY,
      status: UserStrategyStatus.ACTIVE,
    },
    {
      id: SEED_SEGMENTS.FNO.id,
      name: SEED_SEGMENTS.FNO.name,
      description: SEED_SEGMENTS.FNO.description,
      segment: Segment.OPTIONS,
      status: UserStrategyStatus.ACTIVE,
    },
  ];

  for (const segment of segmentsToSeed) {
    await db.strategy.upsert({
      where: { id: segment.id },
      update: {
        name: segment.name,
        description: segment.description,
        segment: segment.segment,
        status: segment.status,
      },
      create: segment,
    });
  }

  // 3. Seed Default Admin
  const adminData = SEED_USERS.ADMIN;
  const adminPasswordHash = await bcrypt.hash(adminData.password, 10);
  await db.adminUser.upsert({
    where: { id: adminData.id },
    update: {
      email: adminData.email,
      passwordHash: adminPasswordHash,
      role: AdminRole.ADMIN,
      status: AdminStatus.ACTIVE,
    },
    create: {
      id: adminData.id,
      email: adminData.email,
      passwordHash: adminPasswordHash,
      role: AdminRole.ADMIN,
      status: AdminStatus.ACTIVE,
    },
  });

  // 4. Seed Default Analyst
  const analystData = SEED_USERS.ANALYST;
  await db.analyst.upsert({
    where: { id: analystData.id },
    update: {
      name: analystData.name,
      email: analystData.email,
      status: AnalystStatus.ACTIVE,
    },
    create: {
      id: analystData.id,
      name: analystData.name,
      email: analystData.email,
      status: AnalystStatus.ACTIVE,
    },
  });

  // 5. Seed Default Client User (FOR TESTING ONLY)
  const clientData = SEED_USERS.CLIENT;
  const mpinHash = await bcrypt.hash(clientData.mpin, 10);
  await db.user.upsert({
    where: { id: clientData.id },
    update: {
      mobile: clientData.mobile,
      mpinHash,
      firstName: 'Test',
      lastName: 'Client',
      email: clientData.email,
      status: UserStatus.ACTIVE,
    },
    create: {
      id: clientData.id,
      mobile: clientData.mobile,
      mpinHash,
      firstName: 'Test',
      lastName: 'Client',
      email: clientData.email,
      status: UserStatus.ACTIVE,
    },
  });
}

if (require.main === module) {
  seed()
    .then(() => {
      console.log('Database seeded successfully.');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Error during database seeding:', error);
      process.exit(1);
    });
}
