import { Test, TestingModule } from '@nestjs/testing';
import { AuditService } from './audit.service';
import { PrismaService } from '../prisma.service';
import { AuditEventType } from './enums/audit-event.enum';
import { NotFoundException } from '@nestjs/common';

describe('AuditService', () => {
  let service: AuditService;
  let prisma: PrismaService;

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

  const mockPrismaService = {
    auditLog: {
      create: jest.fn().mockResolvedValue(mockAuditLog),
      paginate: jest.fn().mockResolvedValue({
        data: [mockAuditLog],
        total: 1,
        page: 1,
        limit: 10,
        totalPages: 1,
      }),
      findUnique: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuditService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<AuditService>(AuditService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  describe('logEvent', () => {
    it('should create an audit log record', async () => {
      const result = await service.logEvent(
        'user-123',
        AuditEventType.LOGIN,
        'User',
        'user-123',
        { loginType: 'OTP' },
        '127.0.0.1',
      );

      expect(prisma.auditLog.create).toHaveBeenCalledWith({
        data: {
          userId: 'user-123',
          eventType: AuditEventType.LOGIN,
          entityType: 'User',
          entityId: 'user-123',
          metadata: { loginType: 'OTP' },
          ipAddress: '127.0.0.1',
        },
      });
      expect(result).toEqual(mockAuditLog);
    });
  });

  describe('getAuditLogs', () => {
    it('should call paginate with correct query params', async () => {
      const query = {
        userId: 'user-123',
        eventType: AuditEventType.LOGIN,
        page: 1,
        limit: 10,
      };

      const result = await service.getAuditLogs(query);

      expect(prisma.auditLog.paginate).toHaveBeenCalledWith({
        page: 1,
        limit: 10,
        where: {
          userId: 'user-123',
          eventType: AuditEventType.LOGIN,
        },
        orderBy: { createdAt: 'desc' },
      });
      expect(result.data).toEqual([mockAuditLog]);
      expect(result.total).toBe(1);
    });
  });

  describe('getAuditLogById', () => {
    it('should return log if found', async () => {
      mockPrismaService.auditLog.findUnique.mockResolvedValue(mockAuditLog);

      const result = await service.getAuditLogById('log-123');

      expect(prisma.auditLog.findUnique).toHaveBeenCalledWith({
        where: { id: 'log-123' },
      });
      expect(result).toEqual(mockAuditLog);
    });

    it('should throw NotFoundException if log not found', async () => {
      mockPrismaService.auditLog.findUnique.mockResolvedValue(null);

      await expect(service.getAuditLogById('non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
