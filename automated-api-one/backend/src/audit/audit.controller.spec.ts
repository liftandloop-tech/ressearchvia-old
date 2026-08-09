import { Test, TestingModule } from '@nestjs/testing';
import { AuditController } from './audit.controller';
import { AuditService } from './audit.service';
import { AuditEventType } from './enums/audit-event.enum';

describe('AuditController', () => {
  let controller: AuditController;
  let service: AuditService;

  const mockAuditLog = {
    id: 'log-123',
    userId: 'user-123',
    eventType: AuditEventType.LOGIN,
    entityType: 'User',
    entityId: 'user-123',
    metadata: { loginType: 'OTP' },
    ipAddress: '127.0.0.1',
    createdAt: new Date(),
  };

  const mockAuditService = {
    getAuditLogs: jest.fn().mockResolvedValue({
      data: [mockAuditLog],
      total: 1,
      page: 1,
      limit: 10,
      totalPages: 1,
    }),
    getAuditLogById: jest.fn().mockResolvedValue(mockAuditLog),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuditController],
      providers: [{ provide: AuditService, useValue: mockAuditService }],
    }).compile();

    controller = module.get<AuditController>(AuditController);
    service = module.get<AuditService>(AuditService);
  });

  describe('getAuditLogs', () => {
    it('should call getAuditLogs on service', async () => {
      const query = { page: 1, limit: 10 };
      const result = await controller.getAuditLogs(query);

      expect(service.getAuditLogs).toHaveBeenCalledWith(query);
      expect(result.data).toEqual([mockAuditLog]);
    });
  });

  describe('getAuditLogById', () => {
    it('should call getAuditLogById on service', async () => {
      const result = await controller.getAuditLogById('log-123');

      expect(service.getAuditLogById).toHaveBeenCalledWith('log-123');
      expect(result).toEqual(mockAuditLog);
    });
  });
});
