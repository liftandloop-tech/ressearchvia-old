import { AuditEventType } from '../enums/audit-event.enum';
export declare class AuditQueryDto {
    userId?: string;
    eventType?: AuditEventType;
    entityType?: string;
    entityId?: string;
    page?: number;
    limit?: number;
    startDate?: string;
    endDate?: string;
}
