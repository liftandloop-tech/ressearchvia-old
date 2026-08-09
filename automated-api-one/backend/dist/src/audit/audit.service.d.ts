import { PrismaService } from '../prisma.service';
import { AuditLog } from '@prisma/client';
import { AuditQueryDto } from './dto/audit-query.dto';
import { AuditEventType } from './enums/audit-event.enum';
export declare class AuditService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    logEvent(userId: string | null, eventType: AuditEventType, entityType: string | null, entityId: string | null, metadata?: any, ipAddress?: string | null): Promise<AuditLog>;
    getAuditLogs(query: AuditQueryDto): Promise<any>;
    getAuditLogById(id: string): Promise<AuditLog>;
}
