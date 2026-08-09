/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-assignment */
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { createTestApp } from '../helpers/test-app';
import { ConsentStatus } from '@prisma/client';
import { getTodayISTString } from '../../src/consents/consents.service';

describe('Consent Module (e2e)', () => {
  let app: INestApplication<App>;
  let prismaMock: any;
  const testMobile = '9876543210';
  const testUserId = '550e8400-e29b-41d4-a716-446655440000';
  const testBrokerId = '44444444-e29b-41d4-a716-446655440001';
  let userHeaders: { Authorization: string };

  beforeAll(async () => {
    const testEnv = await createTestApp();
    app = testEnv.app;
    prismaMock = testEnv.prismaMock;

    // Mock User query for login
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

  describe('Authentication protection', () => {
    it('POST /consents should return 401 Unauthorized without token', async () => {
      await request(app.getHttpServer())
        .post('/consents')
        .send({ brokerId: testBrokerId })
        .expect(401);
    });

    it('GET /consents/today should return 401 Unauthorized without token', async () => {
      await request(app.getHttpServer()).get('/consents/today').expect(401);
    });

    it('DELETE /consents/today should return 401 Unauthorized without token', async () => {
      await request(app.getHttpServer()).delete('/consents/today').expect(401);
    });
  });

  describe('POST /consents', () => {
    it('should successfully grant consent', async () => {
      prismaMock.broker.findUnique.mockResolvedValue({
        id: testBrokerId,
        code: 'ANGEL_ONE',
      });
      prismaMock.userBroker.findFirst.mockResolvedValue({
        id: 'ub-1',
        brokerId: testBrokerId,
      });
      prismaMock.consent.upsert.mockResolvedValue({
        id: 'consent-1',
        status: ConsentStatus.ACTIVE,
        consentDate: new Date(),
      });
      prismaMock.auditLog.create.mockResolvedValue({});
      prismaMock.notification.create.mockResolvedValue({});

      const res = await request(app.getHttpServer())
        .post('/consents')
        .set(userHeaders)
        .send({ brokerId: testBrokerId })
        .expect(200);

      expect(res.body).toEqual({
        status: 'ACTIVE',
        consentDate: getTodayISTString(),
      });
    });

    it('should fail if user does not have an active user broker link', async () => {
      prismaMock.broker.findUnique.mockResolvedValue({
        id: testBrokerId,
        code: 'ANGEL_ONE',
      });
      prismaMock.userBroker.findFirst.mockResolvedValue(null); // No active link

      await request(app.getHttpServer())
        .post('/consents')
        .set(userHeaders)
        .send({ brokerId: testBrokerId })
        .expect(400);
    });
  });

  describe('GET /consents/today & GET /consents/status', () => {
    it('should return active status when consent exists', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: testBrokerId,
        broker: { code: 'ANGEL_ONE' },
      });
      prismaMock.consent.findFirst.mockResolvedValue({
        status: ConsentStatus.ACTIVE,
      });

      const res = await request(app.getHttpServer())
        .get('/consents/today')
        .set(userHeaders)
        .expect(200);

      expect(res.body).toEqual({
        active: true,
        broker: 'ANGEL_ONE',
        consentDate: getTodayISTString(),
      });

      // Assert status endpoint does the same
      const resStatus = await request(app.getHttpServer())
        .get('/consents/status')
        .set(userHeaders)
        .expect(200);

      expect(resStatus.body).toEqual(res.body);
    });

    it('should return active: false if no consent exists', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: testBrokerId,
        broker: { code: 'ANGEL_ONE' },
      });
      prismaMock.consent.findFirst.mockResolvedValue(null);

      const res = await request(app.getHttpServer())
        .get('/consents/today')
        .set(userHeaders)
        .expect(200);

      expect(res.body).toEqual({
        active: false,
        broker: 'ANGEL_ONE',
        consentDate: getTodayISTString(),
      });
    });
  });

  describe('DELETE /consents/today', () => {
    it('should successfully revoke consent', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: testBrokerId,
      });
      prismaMock.consent.findFirst.mockResolvedValue({
        id: 'consent-1',
        status: ConsentStatus.ACTIVE,
      });
      prismaMock.consent.update.mockResolvedValue({
        id: 'consent-1',
        status: ConsentStatus.REVOKED,
      });
      prismaMock.auditLog.create.mockResolvedValue({});
      prismaMock.notification.create.mockResolvedValue({});

      const res = await request(app.getHttpServer())
        .delete('/consents/today')
        .set(userHeaders)
        .expect(200);

      expect(res.body).toEqual({
        status: 'REVOKED',
      });
    });

    it('should throw BadRequestException if no consent found today', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: testBrokerId,
      });
      prismaMock.consent.findFirst.mockResolvedValue(null);

      await request(app.getHttpServer())
        .delete('/consents/today')
        .set(userHeaders)
        .expect(400);
    });
  });
});
