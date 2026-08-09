import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { createTestApp } from '../helpers/test-app';
import { AuthTestHelper } from '../helpers/auth.helper';
import { BrokerCode, BrokerStatus, UserSegmentStatus } from '@prisma/client';
import { AuditEventType } from '../../src/audit/enums/audit-event.enum';

describe('Audit Module Integration Flow (e2e)', () => {
  let app: INestApplication<App>;
  let prismaMock: any;
  const authHelper = new AuthTestHelper();
  const testMobile = '9876543210';
  const testUserId = '550e8400-e29b-41d4-a716-446655440000';
  const testAdminId = '55555555-e29b-41d4-a716-446655440001';

  const createdLogs: any[] = [];

  beforeEach(async () => {
    createdLogs.length = 0; // Clear array

    const testEnv = await createTestApp();
    app = testEnv.app;
    prismaMock = testEnv.prismaMock;

    // Mock audit log persistence locally in test memory
    prismaMock.auditLog.create.mockImplementation((args: any) => {
      const log = {
        id: `log-${createdLogs.length + 1}`,
        createdAt: new Date(),
        ...args.data,
      };
      createdLogs.push(log);
      return Promise.resolve(log);
    });

    prismaMock.auditLog.paginate.mockImplementation((args: any) => {
      let data = [...createdLogs];
      if (args.where?.eventType) {
        data = data.filter((l) => l.eventType === args.where.eventType);
      }
      if (args.where?.userId) {
        data = data.filter((l) => l.userId === args.where.userId);
      }

      // Sort by desc like real service
      data.reverse();

      const page = args.page || 1;
      const limit = args.limit || 10;
      const total = data.length;

      return Promise.resolve({
        data,
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      });
    });
  });

  afterEach(async () => {
    if (app) {
      await app.close();
    }
  });

  it('should execute integration flow: Login -> Connect Broker -> Activate Segment -> Query Audit Logs', async () => {
    // ----------------------------------------------------
    // STEP 1: Verify OTP (Auth Flow)
    // ----------------------------------------------------
    prismaMock.user.findFirst.mockResolvedValue(null);
    prismaMock.user.create.mockResolvedValue({
      id: testUserId,
      mobile: testMobile,
      mpinHash: '',
      status: 'ACTIVE',
    });

    const verifyOtpResponse = await request(app.getHttpServer())
      .post('/auth/verify-otp')
      .send({ mobile: testMobile, otp: '123456' })
      .expect(200);

    const userToken = verifyOtpResponse.body.accessToken;
    const userHeaders = { Authorization: `Bearer ${userToken}` };

    // ----------------------------------------------------
    // STEP 2: Link & Authorize Broker (Broker Flow)
    // ----------------------------------------------------
    prismaMock.user.findUnique.mockResolvedValue({
      id: testUserId,
      mobile: testMobile,
      status: 'ACTIVE',
    });

    prismaMock.broker.findFirst.mockResolvedValue({
      id: 'broker-1',
      code: BrokerCode.ANGEL_ONE,
      name: 'ANGEL ONE',
      status: BrokerStatus.ACTIVE,
    });

    prismaMock.userBroker.findFirst.mockResolvedValue({
      id: 'ub-1',
      userId: testUserId,
      brokerId: 'broker-1',
      brokerClientId: 'CLIENT123',
    });

    prismaMock.userBroker.update.mockResolvedValue({ id: 'ub-1' });

    // Link
    await request(app.getHttpServer())
      .post('/brokers/link')
      .set(userHeaders)
      .send({
        brokerCode: BrokerCode.ANGEL_ONE,
        brokerClientId: 'CLIENT123',
      })
      .expect(200);

    // Authorize (emits BROKER_CONNECTED)
    await request(app.getHttpServer())
      .post('/brokers/authorize')
      .set(userHeaders)
      .send({
        brokerCode: BrokerCode.ANGEL_ONE,
        mpin: '1234',
        totpKey: 'SECRET',
      })
      .expect(200);

    // ----------------------------------------------------
    // STEP 3: Activate Segment (Segment Flow)
    // ----------------------------------------------------
    prismaMock.segmentMaster.findUnique.mockResolvedValue({
      id: 'strategy-1',
      name: 'FNO OPTIONS',
      segment: 'FO',
    });

    prismaMock.userSegment.findFirst.mockResolvedValue(null);
    prismaMock.userSegment.create.mockResolvedValue({
      id: 'us-1',
      userId: testUserId,
      segmentId: 'strategy-1',
      status: UserSegmentStatus.ACTIVE,
    });

    await request(app.getHttpServer())
      .post('/segments/activate')
      .set(userHeaders)
      .send({
        segmentId: 'strategy-1',
        capital: 10000,
        backupCapital: 2000,
        baseLot: 1,
        maxMultiplier: 4,
        dailyLossLimit: 2000,
      })
      .expect(200);

    // ----------------------------------------------------
    // STEP 4: Query Audit Logs as Admin
    // ----------------------------------------------------
    prismaMock.adminUser.findUnique.mockImplementation((args: any) => {
      if (args.where?.id === testAdminId) {
        return Promise.resolve({
          id: testAdminId,
          email: 'admin@platform.local',
          role: 'ADMIN',
          status: 'ACTIVE',
        });
      }
      return Promise.resolve(null);
    });

    const adminToken = authHelper.getHeadersForUser(
      testAdminId,
      'admin@platform.local',
    ).Authorization;
    const adminHeaders = { Authorization: adminToken };

    // Fetch all logs
    const auditResponse = await request(app.getHttpServer())
      .get('/admin/audit')
      .set(adminHeaders)
      .expect(200);

    const logs = auditResponse.body.data;
    expect(logs.length).toBeGreaterThanOrEqual(3);

    // Verify OTP_VERIFIED and LOGIN exist
    const hasOtpVerified = logs.some(
      (l: any) => l.eventType === AuditEventType.OTP_VERIFIED,
    );
    const hasLogin = logs.some(
      (l: any) => l.eventType === AuditEventType.LOGIN,
    );
    const hasBrokerConnected = logs.some(
      (l: any) => l.eventType === AuditEventType.BROKER_CONNECTED,
    );
    const hasSegmentActivated = logs.some(
      (l: any) => l.eventType === AuditEventType.SEGMENT_ACTIVATED,
    );

    expect(hasOtpVerified).toBe(true);
    expect(hasLogin).toBe(true);
    expect(hasBrokerConnected).toBe(true);
    expect(hasSegmentActivated).toBe(true);

    // Verify API request logging (AuditInterceptor working)
    const hasApiRequest = logs.some(
      (l: any) => l.eventType === AuditEventType.API_REQUEST,
    );
    expect(hasApiRequest).toBe(true);

    // Test RolesGuard works: non-admin gets 403 Forbidden
    await request(app.getHttpServer())
      .get('/admin/audit')
      .set(userHeaders)
      .expect(403);
  });
});
