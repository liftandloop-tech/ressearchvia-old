import { Test, TestingModule } from '@nestjs/testing';
import { AlertingService } from './alerting.service';
import { PrismaService } from '../prisma.service';
import { ConfigService } from '@nestjs/config';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { CircuitBreakerService } from '../infrastructure/circuit-breaker/circuit-breaker.service';
import { NotificationEvent, AlertSeverity, AlertStatus } from '@prisma/client';
import { mockPrismaService } from '../../test/mocks/prisma.mock';

describe('AlertingService', () => {
  let service: AlertingService;
  let prismaMock: any;
  let configMock: any;
  let metricsMock: any;
  let circuitBreakerMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();
    configMock = {
      get: jest.fn().mockImplementation((key: string) => {
        if (key === 'SLACK_WEBHOOK_URL') return 'http://slack.webhook';
        if (key === 'PAGERDUTY_ROUTING_KEY') return 'pd-routing-key';
        return null;
      }),
    };
    metricsMock = {
      setSreAlertOpen: jest.fn(),
      setSreAlertAcknowledged: jest.fn(),
      setSreAlertResolved: jest.fn(),
    };
    circuitBreakerMock = {
      execute: jest.fn().mockImplementation((broker: string, op: any) => op()),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AlertingService,
        { provide: PrismaService, useValue: prismaMock },
        { provide: ConfigService, useValue: configMock },
        { provide: MetricsService, useValue: metricsMock },
        { provide: CircuitBreakerService, useValue: circuitBreakerMock },
      ],
    }).compile();

    service = module.get<AlertingService>(AlertingService);
  });

  describe('triggerAlert', () => {
    it('should create a new open alert if none exists with fingerprint', async () => {
      prismaMock.sreAlert.findFirst.mockResolvedValue(null);
      prismaMock.sreAlert.create.mockResolvedValue({
        id: 'alert-1',
        event: NotificationEvent.SYSTEM_ALERT,
        fingerprint: 'sys-alert-1',
        occurrenceCount: 1,
      });
      prismaMock.sreAlert.count.mockResolvedValue(1);

      const result = await service.triggerAlert(
        NotificationEvent.SYSTEM_ALERT,
        'sys-alert-1',
        { msg: 'test' },
        AlertSeverity.CRITICAL,
      );

      expect(result.id).toBe('alert-1');
      expect(prismaMock.sreAlert.create).toHaveBeenCalledWith({
        data: {
          event: NotificationEvent.SYSTEM_ALERT,
          fingerprint: 'sys-alert-1',
          details: { msg: 'test' },
          severity: AlertSeverity.CRITICAL,
          status: AlertStatus.OPEN,
          occurrenceCount: 1,
          escalationLevel: 0,
        },
      });
      expect(metricsMock.setSreAlertOpen).toHaveBeenCalledWith(1);
    });

    it('should increment occurrenceCount if an open alert with fingerprint exists', async () => {
      const existingAlert = {
        id: 'alert-1',
        fingerprint: 'sys-alert-1',
        occurrenceCount: 1,
        status: AlertStatus.OPEN,
      };
      prismaMock.sreAlert.findFirst.mockResolvedValue(existingAlert);
      prismaMock.sreAlert.update.mockResolvedValue({
        ...existingAlert,
        occurrenceCount: 2,
      });

      const result = await service.triggerAlert(
        NotificationEvent.SYSTEM_ALERT,
        'sys-alert-1',
        { msg: 'test-2' },
      );

      expect(result.occurrenceCount).toBe(2);
      expect(prismaMock.sreAlert.update).toHaveBeenCalledWith({
        where: { id: 'alert-1' },
        data: {
          occurrenceCount: { increment: 1 },
          details: { msg: 'test-2' },
          updatedAt: expect.any(Date),
        },
      });
    });
  });

  describe('acknowledgeAlert', () => {
    it('should update status to ACKNOWLEDGED and update metrics', async () => {
      prismaMock.sreAlert.update.mockResolvedValue({
        id: 'alert-1',
        status: AlertStatus.ACKNOWLEDGED,
      });
      prismaMock.sreAlert.count.mockResolvedValue(0);

      const result = await service.acknowledgeAlert('alert-1');
      expect(result.status).toBe(AlertStatus.ACKNOWLEDGED);
      expect(prismaMock.sreAlert.update).toHaveBeenCalledWith({
        where: { id: 'alert-1' },
        data: {
          status: AlertStatus.ACKNOWLEDGED,
          updatedAt: expect.any(Date),
        },
      });
      expect(metricsMock.setSreAlertAcknowledged).toHaveBeenCalled();
    });
  });

  describe('resolveAlert', () => {
    it('should update status to RESOLVED and set resolvedAt date', async () => {
      prismaMock.sreAlert.update.mockResolvedValue({
        id: 'alert-1',
        status: AlertStatus.RESOLVED,
      });
      prismaMock.sreAlert.count.mockResolvedValue(0);

      const result = await service.resolveAlert('alert-1');
      expect(result.status).toBe(AlertStatus.RESOLVED);
      expect(prismaMock.sreAlert.update).toHaveBeenCalledWith({
        where: { id: 'alert-1' },
        data: {
          status: AlertStatus.RESOLVED,
          resolvedAt: expect.any(Date),
          updatedAt: expect.any(Date),
        },
      });
      expect(metricsMock.setSreAlertResolved).toHaveBeenCalled();
    });
  });

  describe('escalateOpenAlerts', () => {
    it('should escalate level 0 open alert after 5 minutes to level 1 (Email)', async () => {
      const sixMinsAgo = new Date(Date.now() - 6 * 60 * 1000);
      const openAlerts = [
        {
          id: 'alert-1',
          status: AlertStatus.OPEN,
          createdAt: sixMinsAgo,
          escalationLevel: 0,
          fingerprint: 'fp-1',
        },
      ];
      prismaMock.sreAlert.findMany.mockResolvedValue(openAlerts);

      await service.escalateOpenAlerts();

      expect(prismaMock.sreAlert.update).toHaveBeenCalledWith({
        where: { id: 'alert-1' },
        data: {
          escalationLevel: 1,
          lastEscalatedAt: expect.any(Date),
        },
      });
    });

    it('should escalate to level 2 (SMS) after 15 minutes', async () => {
      const sixteenMinsAgo = new Date(Date.now() - 16 * 60 * 1000);
      const openAlerts = [
        {
          id: 'alert-2',
          status: AlertStatus.OPEN,
          createdAt: sixteenMinsAgo,
          escalationLevel: 1,
          fingerprint: 'fp-2',
        },
      ];
      prismaMock.sreAlert.findMany.mockResolvedValue(openAlerts);

      await service.escalateOpenAlerts();

      expect(prismaMock.sreAlert.update).toHaveBeenCalledWith({
        where: { id: 'alert-2' },
        data: {
          escalationLevel: 2,
          lastEscalatedAt: expect.any(Date),
        },
      });
    });

    it('should escalate to level 3 (PagerDuty) after 30 minutes', async () => {
      const thirtyOneMinsAgo = new Date(Date.now() - 31 * 60 * 1000);
      const openAlerts = [
        {
          id: 'alert-3',
          status: AlertStatus.OPEN,
          createdAt: thirtyOneMinsAgo,
          escalationLevel: 2,
          fingerprint: 'fp-3',
        },
      ];
      prismaMock.sreAlert.findMany.mockResolvedValue(openAlerts);

      await service.escalateOpenAlerts();

      expect(prismaMock.sreAlert.update).toHaveBeenCalledWith({
        where: { id: 'alert-3' },
        data: {
          escalationLevel: 3,
          lastEscalatedAt: expect.any(Date),
        },
      });
      // PagerDuty should execute through the circuit breaker
      expect(circuitBreakerMock.execute).toHaveBeenCalledWith('pagerduty-alerts', expect.any(Function));
    });
  });
});
