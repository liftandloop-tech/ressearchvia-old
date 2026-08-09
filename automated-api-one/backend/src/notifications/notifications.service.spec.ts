import { Test, TestingModule } from '@nestjs/testing';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../prisma.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import {
  NotificationType,
  NotificationEvent,
  NotificationChannel,
  DeliveryStatus,
} from '@prisma/client';
import { NotificationRateLimiterService } from './notification-rate-limiter.service';
import { NotificationDeduplicationService } from './notification-deduplication.service';
import { NotificationTemplateService } from './notification-template.service';
import { WebsocketService } from '../websocket/services/websocket.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let prismaMock: any;
  let rateLimiterMock: any;
  let deduplicationMock: any;
  let templateServiceMock: any;
  let websocketServiceMock: any;
  let queueServiceMock: any;
  let metricsMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    rateLimiterMock = {
      isRateLimited: jest.fn().mockResolvedValue(false),
    };
    deduplicationMock = {
      shouldDeduplicate: jest.fn().mockResolvedValue(false),
    };
    templateServiceMock = {
      generateTemplate: jest.fn().mockReturnValue({ title: 'Test Title', body: 'Test Body' }),
    };
    websocketServiceMock = {
      broadcast: jest.fn().mockResolvedValue(true),
    };
    queueServiceMock = {
      addJob: jest.fn().mockResolvedValue(undefined),
    };
    metricsMock = {
      incrementNotificationDeduplicated: jest.fn(),
      incrementNotificationRateLimited: jest.fn(),
      incrementNotificationQuietHourDeferrals: jest.fn(),
      incrementNotificationScheduled: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: NotificationRateLimiterService, useValue: rateLimiterMock },
        { provide: NotificationDeduplicationService, useValue: deduplicationMock },
        { provide: NotificationTemplateService, useValue: templateServiceMock },
        { provide: WebsocketService, useValue: websocketServiceMock },
        { provide: QueueService, useValue: queueServiceMock },
        { provide: MetricsService, useValue: metricsMock },
      ],
    }).compile();

    service = module.get<NotificationsService>(NotificationsService);
  });

  describe('getHistory', () => {
    it('should query and return notifications list and count', async () => {
      prismaMock.notification.findMany.mockResolvedValue([{ id: 'notif-1' }]);
      prismaMock.notification.count.mockResolvedValue(1);

      const result = await service.getHistory('user-1', 20, 0);
      expect(result.data).toEqual([{ id: 'notif-1' }]);
      expect(result.total).toBe(1);
    });
  });

  describe('markAsRead', () => {
    it('should update notifications delivered flag and return count', async () => {
      prismaMock.notification.updateMany.mockResolvedValue({ count: 2 });

      const result = await service.markAsRead('user-1', ['n1', 'n2']);
      expect(result.count).toBe(2);
      expect(prismaMock.notification.updateMany).toHaveBeenCalledWith({
        where: { userId: 'user-1', id: { in: ['n1', 'n2'] } },
        data: { delivered: true },
      });
    });
  });

  describe('createNotification', () => {
    it('should successfully create and print log', async () => {
      const mockNotif = {
        id: 'notif-1',
        userId: 'user-1',
        type: NotificationType.TRADE_EXECUTED,
        title: 'Title',
        message: 'Message',
        delivered: false,
      };
      prismaMock.notification.create.mockResolvedValue(mockNotif);

      const result = await service.createNotification(
        'user-1',
        NotificationType.TRADE_EXECUTED,
        'Title',
        'Message',
      );
      expect(result).toEqual(mockNotif);
      expect(prismaMock.notification.create).toHaveBeenCalled();
    });
  });

  describe('sendNotification', () => {
    const mockUser = {
      id: 'user-123',
      email: 'user@test.com',
      mobile: '9876543210',
      quietHoursEnabled: false,
      quietStart: null,
      quietEnd: null,
      quietTimezone: null,
      notificationPreferences: [],
    };

    const mockNotif = {
      id: 'notif-555',
      userId: 'user-123',
      type: NotificationType.TRADE_EXECUTED,
      title: 'Test Title',
      message: 'Test Body',
      batchKey: null,
      delivered: false,
    };

    beforeEach(() => {
      prismaMock.user.findUnique.mockResolvedValue(mockUser);
      prismaMock.notification.create.mockResolvedValue(mockNotif);
      prismaMock.notificationDelivery.create.mockResolvedValue({
        id: 'delivery-999',
        status: DeliveryStatus.PENDING,
      });
    });

    it('should deliver notifications immediately when quiet hours are disabled', async () => {
      await service.sendNotification('user-123', NotificationEvent.ORDER_PLACED, { symbol: 'AAPL' });

      expect(prismaMock.notification.create).toHaveBeenCalled();
      expect(prismaMock.notificationDelivery.create).toHaveBeenCalled();
      // websocket and background queues
      expect(websocketServiceMock.broadcast).toHaveBeenCalled();
      expect(queueServiceMock.addJob).toHaveBeenCalled();
    });

    it('should skip rate-limited channels', async () => {
      rateLimiterMock.isRateLimited.mockResolvedValue(true);

      await service.sendNotification('user-123', NotificationEvent.ORDER_PLACED, { symbol: 'AAPL' });

      expect(queueServiceMock.addJob).not.toHaveBeenCalled();
      expect(metricsMock.incrementNotificationRateLimited).toHaveBeenCalled();
    });

    it('should skip deduplicated notifications', async () => {
      deduplicationMock.shouldDeduplicate.mockResolvedValue(true);

      const result = await service.sendNotification('user-123', NotificationEvent.ORDER_PLACED, {
        symbol: 'AAPL',
        fingerprint: 'dup-key',
      });

      expect(result).toEqual({});
      expect(prismaMock.notification.create).not.toHaveBeenCalled();
      expect(metricsMock.incrementNotificationDeduplicated).toHaveBeenCalled();
    });

    it('should defer non-critical notifications during quiet hours', async () => {
      // Enable quiet hours: 22:00 -> 08:00
      const quietUser = {
        ...mockUser,
        quietHoursEnabled: true,
        quietStart: '22:00',
        quietEnd: '08:00',
        quietTimezone: 'Asia/Kolkata',
      };
      prismaMock.user.findUnique.mockResolvedValue(quietUser);

      // Force current time to be 23:00 (within quiet hours)
      const mockDate = new Date('2026-06-13T23:00:00+05:30');
      jest.useFakeTimers().setSystemTime(mockDate);

      // Non-critical alert
      await service.sendNotification('user-123', NotificationEvent.PAYMENT_RECEIVED, { amount: 500 });

      // Delivery should be created with scheduledFor in the future
      expect(prismaMock.notificationDelivery.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            scheduledFor: expect.any(Date),
          }),
        }),
      );

      // Should NOT enqueue to BullMQ queues immediately
      expect(queueServiceMock.addJob).not.toHaveBeenCalled();
      expect(metricsMock.incrementNotificationQuietHourDeferrals).toHaveBeenCalled();

      jest.useRealTimers();
    });

    it('should bypass quiet hours for critical trading events', async () => {
      const quietUser = {
        ...mockUser,
        quietHoursEnabled: true,
        quietStart: '22:00',
        quietEnd: '08:00',
        quietTimezone: 'Asia/Kolkata',
      };
      prismaMock.user.findUnique.mockResolvedValue(quietUser);

      const mockDate = new Date('2026-06-13T23:00:00+05:30');
      jest.useFakeTimers().setSystemTime(mockDate);

      // RISK_BLOCKED is critical and bypasses quiet hours
      await service.sendNotification('user-123', NotificationEvent.RISK_BLOCKED, { reason: 'Violation' });

      // Should enqueue to queues immediately
      expect(queueServiceMock.addJob).toHaveBeenCalled();

      jest.useRealTimers();
    });

    it('should aggregate notifications with the same batchKey', async () => {
      // 1. Create first notification
      prismaMock.notification.findFirst.mockResolvedValue(null);
      await service.sendNotification('user-123', NotificationEvent.TARGET_HIT, { symbol: 'AAPL' }, 'batch-key');

      // 2. Mock existing notification for second trigger
      prismaMock.notification.findFirst.mockResolvedValue({
        id: 'notif-555',
        message: '1 targets hit',
        deliveries: [{ id: 'del-1', status: DeliveryStatus.PENDING, scheduledFor: new Date(Date.now() + 30000) }],
      });
      prismaMock.notification.update.mockResolvedValue({ id: 'notif-555', message: '2 targets hit' });

      await service.sendNotification('user-123', NotificationEvent.TARGET_HIT, { symbol: 'AAPL' }, 'batch-key');

      expect(prismaMock.notification.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            message: '2 targets hit',
          }),
        }),
      );
    });
  });
});
