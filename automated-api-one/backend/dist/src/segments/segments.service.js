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
exports.SegmentsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const client_1 = require("@prisma/client");
const seed_constants_1 = require("../common/constants/seed.constants");
const audit_service_1 = require("../audit/audit.service");
const audit_event_enum_1 = require("../audit/enums/audit-event.enum");
let SegmentsService = class SegmentsService {
    prisma;
    auditService;
    constructor(prisma, auditService) {
        this.prisma = prisma;
        this.auditService = auditService;
    }
    async onModuleInit() {
        await this.seedDefaultSegments();
    }
    async seedDefaultSegments() {
        console.log('Seeding default master segments into database...');
        const segmentsToSeed = Object.values(seed_constants_1.SEED_SEGMENTS).map((seg) => ({
            id: seg.id,
            name: seg.name,
            description: seg.description,
            segment: seg.segment,
            status: client_1.UserSegmentStatus.ACTIVE,
        }));
        for (const data of segmentsToSeed) {
            await this.prisma.segmentMaster.upsert({
                where: { id: data.id },
                update: {
                    name: data.name,
                    description: data.description,
                    segment: data.segment,
                    status: data.status,
                },
                create: data,
            });
        }
    }
    async listSegments() {
        const segments = await this.prisma.segmentMaster.findMany({
            where: {
                deletedAt: null,
            },
        });
        return segments.map((seg) => ({
            ...seg,
            sizingType: seg.name?.toUpperCase() === 'EQUITY CASH' ? 'AMOUNT' : 'LOT',
        }));
    }
    async activateSegment(userId, data) {
        const segment = await this.prisma.segmentMaster.findUnique({
            where: { id: data.segmentId },
        });
        if (!segment) {
            throw new common_1.NotFoundException('Segment not found');
        }
        const existing = await this.prisma.userSegment.findFirst({
            where: {
                userId,
                segmentId: data.segmentId,
            },
        });
        const res = await (existing
            ? this.prisma.userSegment.update({
                where: { id: existing.id },
                data: {
                    capital: data.capital,
                    backupCapital: data.backupCapital,
                    baseLot: data.baseLot,
                    maxMultiplier: data.maxMultiplier,
                    dailyLossLimit: data.dailyLossLimit,
                    status: client_1.UserSegmentStatus.ACTIVE,
                    activatedAt: new Date(),
                },
            })
            : this.prisma.userSegment.create({
                data: {
                    userId,
                    segmentId: data.segmentId,
                    capital: data.capital,
                    backupCapital: data.backupCapital,
                    baseLot: data.baseLot,
                    maxMultiplier: data.maxMultiplier,
                    dailyLossLimit: data.dailyLossLimit,
                    status: client_1.UserSegmentStatus.ACTIVE,
                    activatedAt: new Date(),
                },
            }));
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.SEGMENT_ACTIVATED, 'UserSegment', res.id, {
            segmentId: data.segmentId,
            capital: data.capital,
            backupCapital: data.backupCapital,
            baseLot: data.baseLot,
            maxMultiplier: data.maxMultiplier,
            dailyLossLimit: data.dailyLossLimit,
        });
        return res;
    }
    async pauseSegment(userId, segmentId) {
        const existing = await this.prisma.userSegment.findFirst({
            where: {
                userId,
                segmentId,
            },
        });
        if (!existing) {
            throw new common_1.NotFoundException('You are not subscribed to this segment');
        }
        const res = await this.prisma.userSegment.update({
            where: { id: existing.id },
            data: {
                status: client_1.UserSegmentStatus.PAUSED,
                pausedAt: new Date(),
            },
        });
        await this.auditService.logEvent(userId, audit_event_enum_1.AuditEventType.SEGMENT_PAUSED, 'UserSegment', res.id, {
            segmentId,
        });
        return res;
    }
    async getUserSegments(userId) {
        return this.prisma.userSegment.findMany({
            where: { userId },
            include: {
                segment: true,
            },
        });
    }
};
exports.SegmentsService = SegmentsService;
exports.SegmentsService = SegmentsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        audit_service_1.AuditService])
], SegmentsService);
//# sourceMappingURL=segments.service.js.map