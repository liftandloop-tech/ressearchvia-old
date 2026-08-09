import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { createTestApp } from '../helpers/test-app';
import { UserSegmentStatus } from '@prisma/client';

describe('Risk Engine Module (e2e)', () => {
  let app: INestApplication<App>;
  let prismaMock: any;
  const testMobile = '9876543210';
  const testUserId = '550e8400-e29b-41d4-a716-446655440000';
  const otherUserId = '660e8400-e29b-41d4-a716-446655440000';
  const testSegmentId = 'strat-123';
  let userHeaders: { Authorization: string };

  beforeAll(async () => {
    const testEnv = await createTestApp();
    app = testEnv.app;
    prismaMock = testEnv.prismaMock;

    // Standard User Setup
    prismaMock.user.findFirst.mockResolvedValue(null);
    prismaMock.user.create.mockResolvedValue({
      id: testUserId,
      mobile: testMobile,
      mpinHash: '',
      status: 'ACTIVE',
    });
    prismaMock.user.findUnique.mockResolvedValue({
      id: testUserId,
      mobile: testMobile,
      status: 'ACTIVE',
    });

    // Login to get token
    const verifyOtpResponse = await request(app.getHttpServer())
      .post('/auth/verify-otp')
      .send({ mobile: testMobile, otp: '123456' })
      .expect(200);

    const userToken = verifyOtpResponse.body.accessToken;
    userHeaders = { Authorization: `Bearer ${userToken}` };
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('GET /risk/status/:segmentId should return locking and loss status details', async () => {
    prismaMock.userSegment.findFirst.mockResolvedValue({
      id: 'us-123',
      userId: testUserId,
      segmentId: testSegmentId,
      dailyLossLimit: 5000,
      status: UserSegmentStatus.ACTIVE,
      segment: { name: 'FNO OPTIONS' },
    });

    prismaMock.trade.findMany.mockResolvedValue([
      { id: 't-1', pnl: -1500, status: 'CLOSED' },
    ]);

    const res = await request(app.getHttpServer())
      .get(`/risk/status/${testSegmentId}`)
      .set(userHeaders)
      .expect(200);

    expect(res.body).toEqual({
      locked: false,
      dailyLoss: 1500,
      dailyLossLimit: 5000,
    });
  });

  it('GET /risk/events/:segmentId should return paginated risk events', async () => {
    prismaMock.riskEvent.paginate.mockResolvedValue({
      data: [
        {
          id: 're-1',
          eventType: 'INSUFFICIENT_CAPITAL',
          message: 'Low capital',
        },
      ],
      total: 1,
      page: 1,
      limit: 20,
      totalPages: 1,
    });

    const res = await request(app.getHttpServer())
      .get(`/risk/events/${testSegmentId}?page=1&limit=20`)
      .set(userHeaders)
      .expect(200);

    expect(res.body.total).toBe(1);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].eventType).toBe('INSUFFICIENT_CAPITAL');
  });

  it('POST /risk/unlock/:segmentId should allow owner to unlock segment', async () => {
    prismaMock.userSegment.findFirst.mockResolvedValue({
      id: 'us-123',
      userId: testUserId,
      segmentId: testSegmentId,
    });

    const txMock = {
      userSegment: {
        update: jest.fn().mockResolvedValue({
          id: 'us-123',
          status: UserSegmentStatus.ACTIVE,
        }),
      },
      segmentMultiplier: {
        findFirst: jest.fn().mockResolvedValue(null),
      },
      riskEvent: {
        create: jest.fn(),
      },
    };

    prismaMock.$transaction.mockImplementation(async (callback: any) => {
      return callback(txMock);
    });

    // Mock audit service response
    prismaMock.auditLog.create.mockResolvedValue({});

    const res = await request(app.getHttpServer())
      .post(`/risk/unlock/${testSegmentId}`)
      .set(userHeaders)
      .send({})
      .expect(200);

    expect(res.body.status).toBe(UserSegmentStatus.ACTIVE);
  });

  it('POST /risk/unlock/:segmentId should forbid non-owner to unlock segment', async () => {
    prismaMock.userSegment.findFirst.mockResolvedValue({
      id: 'us-123',
      userId: otherUserId, // Different owner
      segmentId: testSegmentId,
    });

    await request(app.getHttpServer())
      .post(`/risk/unlock/${testSegmentId}`)
      .set(userHeaders)
      .send({})
      .expect(403);
  });
});
