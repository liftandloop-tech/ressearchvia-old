import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { AuditLog } from '@prisma/client';
import { AuditQueryDto } from './dto/audit-query.dto';
import { AuditEventType } from './enums/audit-event.enum';

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async logEvent(
    userId: string | null,
    eventType: AuditEventType,
    entityType: string | null,
    entityId: string | null,
    metadata?: any,
    ipAddress?: string | null,
  ): Promise<AuditLog> {
    return this.prisma.auditLog.create({
      data: {
        userId,
        eventType,
        entityType,
        entityId,
        metadata: metadata || null,
        ipAddress: ipAddress || null,
      },
    });
  }

  async getAuditLogs(query: AuditQueryDto) {
    const where: any = {};

    if (query.userId) {
      where.userId = query.userId;
    }
    if (query.eventType) {
      where.eventType = query.eventType;
    }
    if (query.entityType) {
      where.entityType = query.entityType;
    }
    if (query.entityId) {
      where.entityId = query.entityId;
    }
    if (query.startDate || query.endDate) {
      where.createdAt = {};
      if (query.startDate) {
        where.createdAt.gte = new Date(query.startDate);
      }
      if (query.endDate) {
        where.createdAt.lte = new Date(query.endDate);
      }
    }

    return this.prisma.auditLog.paginate({
      page: query.page,
      limit: query.limit,
      where,
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAuditLogById(id: string): Promise<AuditLog> {
    const log = await this.prisma.auditLog.findUnique({
      where: { id },
    });
    if (!log) {
      throw new NotFoundException(`Audit log with ID ${id} not found`);
    }
    return log;
  }
}
