/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-assignment */
import { Test, TestingModule } from '@nestjs/testing';
import { ConsentsService, getTodayISTString } from './consents.service';
import { PrismaService } from '../prisma.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import { ConsentStatus, NotificationType } from '@prisma/client';
import { BadRequestException } from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';

describe('ConsentsService', () => {
  let service: ConsentsService;
  let prismaMock: any;
  let auditMock: any;
  let notificationsMock: any;
  let subscriptionsMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    auditMock = {
      logEvent: jest.fn().mockResolvedValue({}),
    };
    notificationsMock = {
      createNotification: jest.fn().mockResolvedValue({}),
    };
    subscriptionsMock = {
      validateSubscription: jest.fn().mockResolvedValue({ active: true }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ConsentsService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: AuditService, useValue: auditMock },
        { provide: NotificationsService, useValue: notificationsMock },
        { provide: SubscriptionsService, useValue: subscriptionsMock },
      ],
    }).compile();

    service = module.get<ConsentsService>(ConsentsService);
  });

  describe('hasTodayConsent', () => {
    it('should return false if user has no active broker', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue(null);
      const result = await service.hasTodayConsent('user-1');
      expect(result).toBe(false);
    });

    it('should return true if active consent exists for today', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: 'broker-1',
      });
      prismaMock.consent.findFirst.mockResolvedValue({
        id: 'consent-1',
        status: ConsentStatus.ACTIVE,
      });

      const result = await service.hasTodayConsent('user-1');
      expect(result).toBe(true);
      expect(prismaMock.consent.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            userId: 'user-1',
            brokerId: 'broker-1',
            status: ConsentStatus.ACTIVE,
          }),
        }),
      );
    });

    it('should return false if consent is revoked or missing', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: 'broker-1',
      });
      prismaMock.consent.findFirst.mockResolvedValue(null);

      const result = await service.hasTodayConsent('user-1');
      expect(result).toBe(false);
    });
  });

  describe('grantConsent', () => {
    const testUserId = 'user-1';
    const testBrokerId = '44444444-e29b-41d4-a716-446655440001';

    beforeEach(() => {
      prismaMock.broker.findUnique.mockResolvedValue({
        id: testBrokerId,
        code: 'ANGEL_ONE',
      });
      prismaMock.userBroker.findFirst.mockResolvedValue({
        id: 'ub-1',
        brokerId: testBrokerId,
      });
    });

    it('should grant consent by creating/upserting a record', async () => {
      prismaMock.consent.upsert.mockResolvedValue({
        id: 'consent-1',
        status: ConsentStatus.ACTIVE,
        consentDate: new Date(),
      });

      const result = await service.grantConsent(testUserId, testBrokerId);
      expect(result.status).toBe(ConsentStatus.ACTIVE);
      expect(prismaMock.consent.upsert).toHaveBeenCalled();
      expect(auditMock.logEvent).toHaveBeenCalledWith(
        testUserId,
        'CONSENT_GRANTED',
        'Consent',
        'consent-1',
        expect.any(Object),
      );
      expect(notificationsMock.createNotification).toHaveBeenCalledWith(
        testUserId,
        NotificationType.CONSENT_GRANTED,
        expect.any(String),
        expect.any(String),
      );
    });

    it('should resolve brokerId using code or prefixed code if UUID unique lookup fails', async () => {
      prismaMock.broker.findUnique.mockResolvedValue(null);
      prismaMock.broker.findFirst.mockResolvedValue({
        id: testBrokerId,
        code: 'ANGEL_ONE',
      });
      prismaMock.consent.upsert.mockResolvedValue({
        id: 'consent-1',
        status: ConsentStatus.ACTIVE,
        consentDate: new Date(),
      });

      const result = await service.grantConsent(testUserId, 'BROKER_ANGEL_ONE');
      expect(result.status).toBe(ConsentStatus.ACTIVE);
      expect(prismaMock.broker.findFirst).toHaveBeenCalledWith({
        where: { code: 'ANGEL_ONE' },
      });
    });

    it('should throw BadRequestException if broker not found', async () => {
      prismaMock.broker.findUnique.mockResolvedValue(null);
      prismaMock.broker.findFirst.mockResolvedValue(null);

      await expect(service.grantConsent(testUserId, 'INVALID')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw BadRequestException if user does not have active broker link', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue(null);

      await expect(
        service.grantConsent(testUserId, testBrokerId),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('getConsentStatus', () => {
    it('should return default state when no broker linked', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue(null);

      const status = await service.getConsentStatus('user-1');
      expect(status).toEqual({ active: false, broker: null, consentDate: null, status: 'NOT_GRANTED' });
    });

    it('should return pending status if broker linked but no consent today', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: 'broker-1',
        broker: { code: 'ZERODHA' },
      });
      prismaMock.consent.findFirst.mockResolvedValue(null);

      const status = await service.getConsentStatus('user-1');
      expect(status).toEqual({
        active: false,
        broker: 'ZERODHA',
        consentDate: expect.any(String),
        status: 'NOT_GRANTED',
      });
    });

    it('should return active status if consent active', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: 'broker-1',
        broker: { code: 'ZERODHA' },
      });
      prismaMock.consent.findFirst.mockResolvedValue({
        status: ConsentStatus.ACTIVE,
      });

      const status = await service.getConsentStatus('user-1');
      expect(status.active).toBe(true);
      expect(status.status).toBe(ConsentStatus.ACTIVE);
    });

    it('should return inactive if consent revoked', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: 'broker-1',
        broker: { code: 'ZERODHA' },
      });
      prismaMock.consent.findFirst.mockResolvedValue({
        status: ConsentStatus.REVOKED,
      });

      const status = await service.getConsentStatus('user-1');
      expect(status.active).toBe(false);
      expect(status.status).toBe(ConsentStatus.REVOKED);
    });
  });

  describe('revokeConsent', () => {
    it('should update status to REVOKED and log events if consent exists', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: 'broker-1',
      });
      prismaMock.consent.findFirst.mockResolvedValue({
        id: 'consent-1',
        status: ConsentStatus.ACTIVE,
      });
      prismaMock.consent.update.mockResolvedValue({
        id: 'consent-1',
        status: ConsentStatus.REVOKED,
      });

      const result = await service.revokeConsent('user-1');
      expect(result.status).toBe(ConsentStatus.REVOKED);
      expect(prismaMock.consent.update).toHaveBeenCalledWith({
        where: { id: 'consent-1' },
        data: { status: ConsentStatus.REVOKED },
      });
      expect(auditMock.logEvent).toHaveBeenCalledWith(
        'user-1',
        'CONSENT_REVOKED',
        'Consent',
        'consent-1',
        expect.any(Object),
      );
      expect(notificationsMock.createNotification).toHaveBeenCalledWith(
        'user-1',
        NotificationType.CONSENT_REVOKED,
        expect.any(String),
        expect.any(String),
      );
    });

    it('should throw BadRequestException if no consent found today', async () => {
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: 'broker-1',
      });
      prismaMock.consent.findFirst.mockResolvedValue(null);

      await expect(service.revokeConsent('user-1')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('sendConsentReminders Cron', () => {
    it('should filter active users and send consent pending notifications if missing', async () => {
      // Setup active allocations
      prismaMock.userSegment.findMany.mockResolvedValue([
        { userId: 'active-user-1' },
        { userId: 'active-user-2' },
      ]);

      // Mock subscription check (user-1 active, user-2 inactive)
      subscriptionsMock.validateSubscription
        .mockResolvedValueOnce({ active: true }) // active-user-1
        .mockResolvedValueOnce({ active: false }); // active-user-2

      // Mock hasTodayConsent (active-user-1 has no consent, active-user-2 doesn't reach this)
      prismaMock.userBroker.findFirst.mockResolvedValue({
        brokerId: 'broker-1',
      });
      prismaMock.consent.findFirst.mockResolvedValue(null); // No consent

      await service.sendConsentReminders();

      // Only active-user-1 should receive a notification
      expect(notificationsMock.createNotification).toHaveBeenCalledTimes(1);
      expect(notificationsMock.createNotification).toHaveBeenCalledWith(
        'active-user-1',
        NotificationType.CONSENT_PENDING,
        'Trading Consent Required',
        expect.stringContaining('consent is pending'),
      );
    });
  });
});
