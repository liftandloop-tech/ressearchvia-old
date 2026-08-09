import { Test, TestingModule } from '@nestjs/testing';
import { SubscriptionsService } from './subscriptions.service';
import { PrismaService } from '../prisma.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import { SubscriptionStatus } from '@prisma/client';
import {
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { AuditService } from '../audit/audit.service';
import { PLANS } from './plans.constants';

import { RedisService } from '../infrastructure/redis/redis.service';

describe('SubscriptionsService', () => {
  let service: SubscriptionsService;
  let prismaMock: any;
  let auditMock: any;
  let redisServiceMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    auditMock = {
      logEvent: jest.fn().mockResolvedValue({}),
    };
    redisServiceMock = {
      isHealthy: jest.fn().mockReturnValue(true),
      getClient: () => ({
        get: jest.fn().mockResolvedValue(null),
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SubscriptionsService,
        {
          provide: PrismaService,
          useValue: prismaMock,
        },
        {
          provide: AuditService,
          useValue: auditMock,
        },
        {
          provide: RedisService,
          useValue: redisServiceMock,
        },
      ],
    }).compile();

    service = module.get<SubscriptionsService>(SubscriptionsService);
  });

  describe('validateSubscription', () => {
    it('should return active details if active subscription exists within date range', async () => {
      const futureDate = new Date(Date.now() + 100000);
      prismaMock.subscription.findFirst.mockResolvedValue({
        id: 'sub-id',
        planId: PLANS.SPARK.id,
        status: SubscriptionStatus.ACTIVE,
        endDate: futureDate,
      });

      const result = await service.validateSubscription('user-id');
      expect(result).toEqual({
        active: true,
        plan: PLANS.SPARK.name,
        expiresAt: futureDate,
      });
      expect(prismaMock.subscription.findFirst).toHaveBeenCalled();
    });

    it('should return inactive if subscription has expired (endDate < now)', async () => {
      prismaMock.subscription.findFirst.mockResolvedValue(null);

      const result = await service.validateSubscription('user-id');
      expect(result).toEqual({
        active: false,
        plan: null,
        expiresAt: null,
      });
    });
  });

  describe('getCurrentSubscription', () => {
    it('should return active subscription', async () => {
      const activeSub = {
        id: 'sub-id',
        status: SubscriptionStatus.ACTIVE,
      };
      prismaMock.subscription.findFirst.mockResolvedValue(activeSub);

      const result = await service.getCurrentSubscription('user-id');
      expect(result).toBe(activeSub);
    });
  });

  describe('getSubscriptionHistory', () => {
    it('should fetch history with pagination', async () => {
      prismaMock.subscription.paginate.mockResolvedValue({
        data: [],
        total: 0,
      });

      await service.getSubscriptionHistory('user-id', 2, 10);
      expect(prismaMock.subscription.paginate).toHaveBeenCalledWith({
        page: 2,
        limit: 10,
        where: { userId: 'user-id' },
        orderBy: { createdAt: 'desc' },
      });
    });
  });

  describe('subscribe', () => {
    it('should throw BadRequestException for invalid plan ID', async () => {
      await expect(
        service.subscribe('user-id', 'invalid-plan-id'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should create new active subscription if no active one exists', async () => {
      prismaMock.subscription.findFirst.mockResolvedValue(null);
      prismaMock.subscription.create.mockResolvedValue({
        id: 'new-sub-id',
        planId: PLANS.SPARK.id,
        status: SubscriptionStatus.ACTIVE,
      });

      const result = await service.subscribe('user-id', PLANS.SPARK.id);
      expect(result.id).toBe('new-sub-id');
      expect(auditMock.logEvent).toHaveBeenCalledWith(
        'user-id',
        'SUBSCRIPTION_ACTIVATED',
        'Subscription',
        'new-sub-id',
        expect.any(Object),
      );
    });

    it('should renew and extend the start date (+1s) if same plan active subscription exists', async () => {
      const activeEndDate = new Date();
      prismaMock.subscription.findFirst.mockResolvedValue({
        id: 'active-sub-id',
        planId: PLANS.SPARK.id,
        endDate: activeEndDate,
        status: SubscriptionStatus.ACTIVE,
      });

      prismaMock.subscription.create.mockResolvedValue({
        id: 'renewed-sub-id',
        planId: PLANS.SPARK.id,
        status: SubscriptionStatus.ACTIVE,
      });

      await service.subscribe('user-id', PLANS.SPARK.id);

      // Expected start date is activeEndDate + 1 second
      const expectedStartDate = new Date(activeEndDate.getTime() + 1000);
      expect(prismaMock.subscription.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          startDate: expectedStartDate,
          planId: PLANS.SPARK.id,
        }),
      });

      expect(auditMock.logEvent).toHaveBeenCalledWith(
        'user-id',
        'SUBSCRIPTION_RENEWED',
        'Subscription',
        'renewed-sub-id',
        expect.any(Object),
      );
    });

    it('should cancel active plan and start new today if user switches plans (Spark to Splendid)', async () => {
      prismaMock.subscription.findFirst.mockResolvedValue({
        id: 'spark-sub-id',
        planId: PLANS.SPARK.id,
        endDate: new Date(Date.now() + 1000000),
        status: SubscriptionStatus.ACTIVE,
      });

      prismaMock.subscription.update.mockResolvedValue({ id: 'spark-sub-id' });
      prismaMock.subscription.create.mockResolvedValue({
        id: 'splendid-sub-id',
        planId: PLANS.SPLENDID.id,
        status: SubscriptionStatus.ACTIVE,
      });

      await service.subscribe('user-id', PLANS.SPLENDID.id);

      expect(prismaMock.subscription.update).toHaveBeenCalledWith({
        where: { id: 'spark-sub-id' },
        data: { status: SubscriptionStatus.CANCELLED },
      });

      expect(auditMock.logEvent).toHaveBeenCalledWith(
        'user-id',
        'SUBSCRIPTION_CANCELLED',
        'Subscription',
        'spark-sub-id',
        expect.any(Object),
      );

      expect(auditMock.logEvent).toHaveBeenCalledWith(
        'user-id',
        'SUBSCRIPTION_ACTIVATED',
        'Subscription',
        'splendid-sub-id',
        expect.any(Object),
      );
    });
  });

  describe('cancelSubscription', () => {
    it('should update status to CANCELLED and log audit event if owned by user', async () => {
      prismaMock.subscription.findUnique.mockResolvedValue({
        id: 'sub-id',
        userId: 'user-id',
        planId: PLANS.SPARK.id,
        status: SubscriptionStatus.ACTIVE,
      });
      prismaMock.subscription.update.mockResolvedValue({
        id: 'sub-id',
        planId: PLANS.SPARK.id,
        status: SubscriptionStatus.CANCELLED,
      });

      const result = await service.cancelSubscription('sub-id', 'user-id');
      expect(result.status).toBe(SubscriptionStatus.CANCELLED);
      expect(auditMock.logEvent).toHaveBeenCalledWith(
        'user-id',
        'SUBSCRIPTION_CANCELLED',
        'Subscription',
        'sub-id',
        expect.any(Object),
      );
    });

    it('should throw ForbiddenException if user does not own the subscription', async () => {
      prismaMock.subscription.findUnique.mockResolvedValue({
        id: 'sub-id',
        userId: 'other-user-id',
        status: SubscriptionStatus.ACTIVE,
      });

      await expect(
        service.cancelSubscription('sub-id', 'user-id'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException if subscription does not exist', async () => {
      prismaMock.subscription.findUnique.mockResolvedValue(null);

      await expect(
        service.cancelSubscription('sub-id', 'user-id'),
      ).rejects.toThrow(NotFoundException);
    });
  });
});
