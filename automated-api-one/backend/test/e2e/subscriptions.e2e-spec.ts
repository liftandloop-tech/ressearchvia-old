import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { createTestApp } from '../helpers/test-app';
import { PLANS } from '../../src/subscriptions/plans.constants';
import { SubscriptionStatus } from '@prisma/client';

describe('Subscriptions Module (e2e)', () => {
  let app: INestApplication<App>;
  let prismaMock: any;
  const testMobile = '9876543210';
  const testUserId = '550e8400-e29b-41d4-a716-446655440000';
  const otherUserId = '660e8400-e29b-41d4-a716-446655440000';
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

  it('GET /subscriptions/plans should return all hardcoded plans', async () => {
    const res = await request(app.getHttpServer())
      .get('/subscriptions/plans')
      .set(userHeaders)
      .expect(200);

    expect(res.body).toHaveLength(2);
    expect(res.body[0].id).toBe(PLANS.SPARK.id);
    expect(res.body[1].id).toBe(PLANS.SPLENDID.id);
  });

  it('GET /subscriptions/current should return empty object (NestJS empty response) if no active subscription', async () => {
    prismaMock.subscription.findFirst.mockResolvedValue(null);

    const res = await request(app.getHttpServer())
      .get('/subscriptions/current')
      .set(userHeaders)
      .expect(200);

    expect(res.body).toEqual({});
  });

  it('GET /subscriptions/status should return active: false if no active subscription', async () => {
    prismaMock.subscription.findFirst.mockResolvedValue(null);

    const res = await request(app.getHttpServer())
      .get('/subscriptions/status')
      .set(userHeaders)
      .expect(200);

    expect(res.body).toEqual({
      active: false,
      plan: null,
      expiresAt: null,
    });
  });

  it('POST /subscriptions should allow subscribing to plans', async () => {
    prismaMock.subscription.findFirst.mockResolvedValue(null);
    prismaMock.subscription.create.mockImplementation((args: any) => {
      return Promise.resolve({
        id: 'new-sub-id',
        status: SubscriptionStatus.ACTIVE,
        ...args.data,
      });
    });

    const res = await request(app.getHttpServer())
      .post('/subscriptions')
      .set(userHeaders)
      .send({ planId: PLANS.SPARK.id })
      .expect(200);

    expect(res.body.id).toBe('new-sub-id');
    expect(res.body.planId).toBe(PLANS.SPARK.id);
    expect(res.body.status).toBe(SubscriptionStatus.ACTIVE);
  });

  it('POST /subscriptions/subscribe should support legacy endpoint mapping', async () => {
    prismaMock.subscription.findFirst.mockResolvedValue(null);
    prismaMock.subscription.create.mockImplementation((args: any) => {
      return Promise.resolve({
        id: 'legacy-sub-id',
        status: SubscriptionStatus.ACTIVE,
        ...args.data,
      });
    });

    const res = await request(app.getHttpServer())
      .post('/subscriptions/subscribe')
      .set(userHeaders)
      .send({ planId: PLANS.SPLENDID.id })
      .expect(200);

    expect(res.body.id).toBe('legacy-sub-id');
    expect(res.body.planId).toBe(PLANS.SPLENDID.id);
  });

  it('POST /subscriptions should return 400 for invalid plan ID', async () => {
    await request(app.getHttpServer())
      .post('/subscriptions')
      .set(userHeaders)
      .send({ planId: '00000000-e29b-41d4-a716-446655440000' })
      .expect(400);
  });

  it('GET /subscriptions/history should return paginated list', async () => {
    prismaMock.subscription.paginate.mockResolvedValue({
      data: [
        { id: 'sub-1', planId: PLANS.SPARK.id },
        { id: 'sub-2', planId: PLANS.SPLENDID.id },
      ],
      total: 2,
      page: 1,
      limit: 10,
      totalPages: 1,
    });

    const res = await request(app.getHttpServer())
      .get('/subscriptions/history?page=1&limit=10')
      .set(userHeaders)
      .expect(200);

    expect(res.body.total).toBe(2);
    expect(res.body.data).toHaveLength(2);
  });

  it('DELETE /subscriptions/:id should forbid cancelling another users subscription', async () => {
    prismaMock.subscription.findUnique.mockResolvedValue({
      id: 'other-sub-id',
      userId: otherUserId,
      status: SubscriptionStatus.ACTIVE,
    });

    await request(app.getHttpServer())
      .delete('/subscriptions/other-sub-id')
      .set(userHeaders)
      .expect(403);
  });

  it('DELETE /subscriptions/:id should allow owner to cancel subscription', async () => {
    prismaMock.subscription.findUnique.mockResolvedValue({
      id: 'my-sub-id',
      userId: testUserId,
      planId: PLANS.SPARK.id,
      status: SubscriptionStatus.ACTIVE,
    });

    prismaMock.subscription.update.mockResolvedValue({
      id: 'my-sub-id',
      status: SubscriptionStatus.CANCELLED,
    });

    const res = await request(app.getHttpServer())
      .delete('/subscriptions/my-sub-id')
      .set(userHeaders)
      .expect(200);

    expect(res.body.status).toBe(SubscriptionStatus.CANCELLED);
  });
});
