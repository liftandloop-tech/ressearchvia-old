import { Test, TestingModule } from '@nestjs/testing';
import { NotificationTemplateService } from './notification-template.service';
import { NotificationEvent } from '@prisma/client';

describe('NotificationTemplateService', () => {
  let service: NotificationTemplateService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [NotificationTemplateService],
    }).compile();

    service = module.get<NotificationTemplateService>(NotificationTemplateService);
  });

  it('should generate correct template for ORDER_PLACED', () => {
    const result = service.generateTemplate(NotificationEvent.ORDER_PLACED, {
      symbol: 'AAPL',
      quantity: 10,
    });
    expect(result.title).toBe('Order Placed');
    expect(result.body).toContain('AAPL');
    expect(result.body).toContain('10 units');
  });

  it('should generate correct template for ORDER_FILLED', () => {
    const result = service.generateTemplate(NotificationEvent.ORDER_FILLED, {
      symbol: 'MSFT',
      quantity: 5,
    });
    expect(result.title).toBe('Order Filled');
    expect(result.body).toContain('MSFT');
    expect(result.body).toContain('5 units');
  });

  it('should generate correct template for ORDER_REJECTED', () => {
    const result = service.generateTemplate(NotificationEvent.ORDER_REJECTED, {
      symbol: 'TSLA',
      reason: 'Insufficient margins',
    });
    expect(result.title).toBe('Order Rejected');
    expect(result.body).toContain('TSLA');
    expect(result.body).toContain('Insufficient margins');
  });

  it('should generate correct template for RISK_BLOCKED', () => {
    const result = service.generateTemplate(NotificationEvent.RISK_BLOCKED, {
      reason: 'Daily loss limit breached',
    });
    expect(result.title).toBe('Risk Violation Enforced');
    expect(result.body).toContain('Daily loss limit breached');
  });

  it('should generate correct template for SYSTEM_ALERT', () => {
    const result = service.generateTemplate(NotificationEvent.SYSTEM_ALERT, {
      message: 'Database backup failed',
    });
    expect(result.title).toBe('System Operational Alert');
    expect(result.body).toContain('Database backup failed');
  });

  it('should fallback to default for unknown events', () => {
    const result = service.generateTemplate('UNKNOWN_EVENT' as any, {
      message: 'Some message',
    });
    expect(result.title).toBe('Notification');
    expect(result.body).toBe('Some message');
  });
});
