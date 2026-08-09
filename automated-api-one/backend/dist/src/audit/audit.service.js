"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuditService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
let AuditService = class AuditService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async logEvent(userId, eventType, entityType, entityId, metadata, ipAddress) {
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
    async getAuditLogs(query) {
        const where = {};
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
    async getAuditLogById(id) {
        const log = await this.prisma.auditLog.findUnique({
            where: { id },
        });
        if (!log) {
            throw new common_1.NotFoundException(`Audit log with ID ${id} not found`);
        }
        return log;
    }
};
exports.AuditService = AuditService;
exports.AuditService = AuditService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AuditService);
//# sourceMappingURL=audit.service.js.map