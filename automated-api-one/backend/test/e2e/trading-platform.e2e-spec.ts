import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { createTestApp } from '../helpers/test-app';
import { AuthTestHelper } from '../helpers/auth.helper';
import * as bcrypt from 'bcrypt';
import { BrokerCode, BrokerStatus, UserSegmentStatus } from '@prisma/client';

jest.mock('@nestjs/bullmq', () => {
  const { Inject } = require('@nestjs/common');
  const getQueueToken = (name: string) => `BullQueue_${name}`;
  return {
    BullModule: {
      forRoot: () => ({ module: class {}, providers: [] }),
      forRootAsync: () => ({ module: class {}, providers: [] }),
      registerQueue: (config: any) => ({
        module: class {},
        providers: [
          {
            provide: getQueueToken(config.name),
            useValue: { add: jest.fn().mockResolvedValue({}) },
          },
        ],
        exports: [getQueueToken(config.name)],
      }),
    },
    InjectQueue: (name: string) => Inject(getQueueToken(name)),
    Queue: class {},
    WorkerHost: class {
      process() {}
    },
    Processor: () => () => {},
    QueueEventsHost: class {},
    QueueEventsListener: () => () => {},
    OnQueueEvent: () => () => {},
  };
});

describe('Trading Platform API (e2e)', () => {
  let app: INestApplication<App>;
  let prismaMock: any;
  const authHelper = new AuthTestHelper();
  const testMobile = '9876543210';
  const testUserId = '550e8400-e29b-41d4-a716-446655440000';
  let mockMpinHash: string;

  beforeAll(async () => {
    // Generate valid bcrypt hash for the login test
    const pepperedSecret = '123456default_mpin_pepper_secret';
    mockMpinHash = await bcrypt.hash(pepperedSecret, 10);
  });

  beforeEach(async () => {
    const testEnv = await createTestApp();
    app = testEnv.app;
    prismaMock = testEnv.prismaMock;
  });

  afterEach(async () => {
    if (app) {
      await app.close();
    }
  });

  describe('Authentication Flow', () => {
    it('should successfully send an OTP to a valid mobile number', async () => {
      const response = await request(app.getHttpServer())
        .post('/auth/send-otp')
        .send({ mobile: testMobile })
        .expect(200);

      expect(response.body).toEqual({
        success: true,
        message: 'OTP sent successfully',
      });
    });

    it('should fail sending OTP if mobile format is invalid', async () => {
      await request(app.getHttpServer())
        .post('/auth/send-otp')
        .send({ mobile: 'invalid-phone' })
        .expect(400);
    });

    it('should successfully verify OTP and return a JWT', async () => {
      // Mock createOrUpdateUser
      prismaMock.user.findFirst.mockResolvedValue(null);
      prismaMock.user.create.mockResolvedValue({
        id: testUserId,
        mobile: testMobile,
        mpinHash: '',
        status: 'ACTIVE',
      });

      const response = await request(app.getHttpServer())
        .post('/auth/verify-otp')
        .send({ mobile: testMobile, otp: '123456' }) // Backdoor OTP
        .expect(200);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body.isMpinSet).toBe(false);
      expect(response.body.userId).toBe(testUserId);
    });

    it('should successfully set up MPIN', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: testUserId,
        mobile: testMobile,
        status: 'ACTIVE',
      });
      prismaMock.user.update.mockResolvedValue({
        id: testUserId,
        mobile: testMobile,
        mpinHash: mockMpinHash,
        status: 'ACTIVE',
      });

      const headers = authHelper.getHeadersForUser(testUserId, testMobile);

      const response = await request(app.getHttpServer())
        .post('/auth/setup-mpin')
        .set(headers)
        .send({ mpin: '123456' })
        .expect(200);

      expect(response.body).toEqual({ success: true });
      expect(prismaMock.user.update).toHaveBeenCalled();
    });

    it('should successfully login using MPIN', async () => {
      prismaMock.user.findFirst.mockResolvedValue({
        id: testUserId,
        mobile: testMobile,
        mpinHash: mockMpinHash,
        status: 'ACTIVE',
      });

      // Mock device tracking queries
      prismaMock.userDevice.findFirst.mockResolvedValue(null);
      prismaMock.userDevice.create.mockResolvedValue({
        id: 'device-rec-id',
        userId: testUserId,
      });

      const response = await request(app.getHttpServer())
        .post('/auth/login-mpin')
        .send({
          mobile: testMobile,
          mpin: '123456',
          deviceId: 'my-unique-device-id',
        })
        .expect(200);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body.userId).toBe(testUserId);
    });
  });

  describe('Broker Flow', () => {
    it('should successfully link a broker account', async () => {
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

      prismaMock.userBroker.findFirst.mockResolvedValue(null);
      prismaMock.userBroker.create.mockResolvedValue({
        id: 'ub-1',
        userId: testUserId,
        brokerClientId: 'CLIENT123',
      });

      const headers = authHelper.getHeadersForUser(testUserId, testMobile);

      const response = await request(app.getHttpServer())
        .post('/brokers/link')
        .set(headers)
        .send({
          brokerCode: BrokerCode.ANGEL_ONE,
          brokerClientId: 'CLIENT123',
        })
        .expect(200);

      expect(response.body.brokerClientId).toBe('CLIENT123');
    });

    it('should successfully authorize daily broker session', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: testUserId,
        mobile: testMobile,
        status: 'ACTIVE',
      });

      prismaMock.broker.findFirst.mockResolvedValue({
        id: 'broker-1',
        code: BrokerCode.ANGEL_ONE,
      });

      prismaMock.userBroker.findFirst.mockResolvedValue({
        id: 'ub-1',
        userId: testUserId,
        brokerId: 'broker-1',
        brokerClientId: 'CLIENT123',
      });

      prismaMock.userBroker.update.mockResolvedValue({ id: 'ub-1' });

      const headers = authHelper.getHeadersForUser(testUserId, testMobile);

      const response = await request(app.getHttpServer())
        .post('/brokers/authorize')
        .set(headers)
        .send({
          brokerCode: BrokerCode.ANGEL_ONE,
          mpin: '1234',
          totpKey: 'SECRET',
        })
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('authorization completed');
    });

    it('should successfully retrieve linked brokers status', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: testUserId,
        mobile: testMobile,
        status: 'ACTIVE',
      });

      prismaMock.broker.findFirst.mockResolvedValue({
        id: 'broker-1',
        code: BrokerCode.ANGEL_ONE,
      });

      prismaMock.userBroker.findFirst.mockResolvedValue({
        id: 'ub-1',
        userId: testUserId,
        brokerId: 'broker-1',
        brokerClientId: 'CLIENT123',
        accessToken: 'mock_angel_one_access_token_CLIENT123_12345',
        tokenExpiry: new Date(Date.now() + 1000000),
      });

      prismaMock.userBroker.findMany.mockResolvedValue([
        {
          id: 'ub-1',
          userId: testUserId,
          brokerClientId: 'CLIENT123',
          accessToken: 'mock_angel_one_access_token_CLIENT123_12345',
          tokenExpiry: new Date(Date.now() + 1000000),
          createdAt: new Date(),
          broker: {
            code: BrokerCode.ANGEL_ONE,
          },
        },
      ]);

      const headers = authHelper.getHeadersForUser(testUserId, testMobile);

      const response = await request(app.getHttpServer())
        .get('/brokers/status')
        .set(headers)
        .expect(200);

      expect(response.body).toHaveLength(1);
      expect(response.body[0].brokerClientId).toBe('CLIENT123');
      expect(response.body[0].isSessionActive).toBe(true);
    });
  });

  describe('Segments Flow', () => {
    it('should successfully list available segments', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: testUserId,
        mobile: testMobile,
        status: 'ACTIVE',
      });

      prismaMock.segmentMaster.findMany.mockResolvedValue([
        {
          id: 'strategy-1',
          name: 'NIFTY OPTIONS SCALPING',
          segment: 'FO',
          status: 'ACTIVE',
        },
      ]);

      const headers = authHelper.getHeadersForUser(testUserId, testMobile);

      const response = await request(app.getHttpServer())
        .get('/segments')
        .set(headers)
        .expect(200);

      expect(response.body).toHaveLength(1);
      expect(response.body[0].name).toBe('NIFTY OPTIONS SCALPING');
    });

    it('should successfully activate segment allocation', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: testUserId,
        mobile: testMobile,
        status: 'ACTIVE',
      });

      prismaMock.segmentMaster.findUnique.mockResolvedValue({
        id: 'strategy-1',
        name: 'Nifty Options Scalping',
        segment: 'FO',
      });

      prismaMock.userSegment.findFirst.mockResolvedValue(null);
      prismaMock.userSegment.create.mockResolvedValue({
        id: 'us-1',
        userId: testUserId,
        segmentId: 'strategy-1',
        status: UserSegmentStatus.ACTIVE,
      });

      const headers = authHelper.getHeadersForUser(testUserId, testMobile);

      const response = await request(app.getHttpServer())
        .post('/segments/activate')
        .set(headers)
        .send({
          segmentId: 'strategy-1',
          capital: 10000,
          backupCapital: 2000,
          baseLot: 1,
          maxMultiplier: 4,
          dailyLossLimit: 2000,
        })
        .expect(200);

      expect(response.body.status).toBe(UserSegmentStatus.ACTIVE);
    });

    it('should successfully pause segment allocation', async () => {
      prismaMock.user.findUnique.mockResolvedValue({
        id: testUserId,
        mobile: testMobile,
        status: 'ACTIVE',
      });

      prismaMock.userSegment.findFirst.mockResolvedValue({
        id: 'us-1',
        userId: testUserId,
        segmentId: 'strategy-1',
        status: UserSegmentStatus.ACTIVE,
      });

      prismaMock.userSegment.update.mockResolvedValue({
        id: 'us-1',
        userId: testUserId,
        segmentId: 'strategy-1',
        status: UserSegmentStatus.PAUSED,
      });

      const headers = authHelper.getHeadersForUser(testUserId, testMobile);

      const response = await request(app.getHttpServer())
        .post('/segments/pause')
        .set(headers)
        .send({
          segmentId: 'strategy-1',
        })
        .expect(200);

      expect(response.body.status).toBe(UserSegmentStatus.PAUSED);
    });
  });
});
