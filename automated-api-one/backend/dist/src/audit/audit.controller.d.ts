import { AuditService } from './audit.service';
import { AuditQueryDto } from './dto/audit-query.dto';
export declare class AuditController {
    private readonly auditService;
    constructor(auditService: AuditService);
    getAuditLogs(query: AuditQueryDto): Promise<any>;
    getAuditLogById(id: string): Promise<{
        id: string;
        createdAt: Date;
        userId: string | null;
        correlationId: string | null;
        eventType: string;
        entityType: string | null;
        entityId: string | null;
        metadata: import("@prisma/client/runtime/client").JsonValue | null;
        ipAddress: string | null;
    }>;
}
