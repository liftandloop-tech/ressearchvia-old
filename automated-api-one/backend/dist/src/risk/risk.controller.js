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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RiskController = exports.UpdateRiskProfileDto = exports.CreateRiskProfileDto = exports.UnlockSegmentDto = exports.PaginatedQueryDto = exports.ResetRiskDto = exports.GetRiskEventsDto = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const risk_service_1 = require("./risk.service");
const class_validator_1 = require("class-validator");
const class_transformer_1 = require("class-transformer");
class GetRiskEventsDto {
    limit;
    offset;
}
exports.GetRiskEventsDto = GetRiskEventsDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], GetRiskEventsDto.prototype, "limit", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], GetRiskEventsDto.prototype, "offset", void 0);
class ResetRiskDto {
    segmentId;
}
exports.ResetRiskDto = ResetRiskDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], ResetRiskDto.prototype, "segmentId", void 0);
class PaginatedQueryDto {
    page;
    limit;
}
exports.PaginatedQueryDto = PaginatedQueryDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], PaginatedQueryDto.prototype, "page", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], PaginatedQueryDto.prototype, "limit", void 0);
class UnlockSegmentDto {
    targetUserId;
}
exports.UnlockSegmentDto = UnlockSegmentDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], UnlockSegmentDto.prototype, "targetUserId", void 0);
class CreateRiskProfileDto {
    userId;
    segmentId;
    brokerId;
    priority;
    maxCapitalPerUser;
    maxCapitalPerSegment;
    maxDailyLoss;
    maxOpenPositions;
    maxPositionSize;
    maxExposurePerSymbol;
    maxExposurePerBroker;
    maxConcurrentOrders;
}
exports.CreateRiskProfileDto = CreateRiskProfileDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], CreateRiskProfileDto.prototype, "userId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], CreateRiskProfileDto.prototype, "segmentId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], CreateRiskProfileDto.prototype, "brokerId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], CreateRiskProfileDto.prototype, "priority", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], CreateRiskProfileDto.prototype, "maxCapitalPerUser", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], CreateRiskProfileDto.prototype, "maxCapitalPerSegment", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], CreateRiskProfileDto.prototype, "maxDailyLoss", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], CreateRiskProfileDto.prototype, "maxOpenPositions", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], CreateRiskProfileDto.prototype, "maxPositionSize", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], CreateRiskProfileDto.prototype, "maxExposurePerSymbol", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], CreateRiskProfileDto.prototype, "maxExposurePerBroker", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], CreateRiskProfileDto.prototype, "maxConcurrentOrders", void 0);
class UpdateRiskProfileDto {
    userId;
    segmentId;
    brokerId;
    priority;
    maxCapitalPerUser;
    maxCapitalPerSegment;
    maxDailyLoss;
    maxOpenPositions;
    maxPositionSize;
    maxExposurePerSymbol;
    maxExposurePerBroker;
    maxConcurrentOrders;
}
exports.UpdateRiskProfileDto = UpdateRiskProfileDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], UpdateRiskProfileDto.prototype, "userId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], UpdateRiskProfileDto.prototype, "segmentId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsUUID)(),
    __metadata("design:type", String)
], UpdateRiskProfileDto.prototype, "brokerId", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], UpdateRiskProfileDto.prototype, "priority", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], UpdateRiskProfileDto.prototype, "maxCapitalPerUser", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], UpdateRiskProfileDto.prototype, "maxCapitalPerSegment", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], UpdateRiskProfileDto.prototype, "maxDailyLoss", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], UpdateRiskProfileDto.prototype, "maxOpenPositions", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], UpdateRiskProfileDto.prototype, "maxPositionSize", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], UpdateRiskProfileDto.prototype, "maxExposurePerSymbol", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], UpdateRiskProfileDto.prototype, "maxExposurePerBroker", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    __metadata("design:type", Number)
], UpdateRiskProfileDto.prototype, "maxConcurrentOrders", void 0);
let RiskController = class RiskController {
    riskService;
    constructor(riskService) {
        this.riskService = riskService;
    }
    async getStatusForSegment(req, segmentId) {
        const userId = req.user.userId;
        return this.riskService.getRiskStatusForSegment(userId, segmentId);
    }
    async getEventsForSegment(req, segmentId, query) {
        const userId = req.user.userId;
        const page = query.page || 1;
        const limit = query.limit || 20;
        return this.riskService.getRiskEventsForSegment(userId, segmentId, page, limit);
    }
    async unlockSegment(req, segmentId, dto) {
        const userId = req.user.userId;
        const isAdmin = req.user.role === 'ADMIN' || req.user.role === 'SUPERADMIN';
        return this.riskService.unlockSegment(userId, segmentId, dto.targetUserId, isAdmin);
    }
    async createProfile(dto) {
        return this.riskService.createProfile(dto);
    }
    async updateProfile(id, dto) {
        return this.riskService.updateProfile(id, dto);
    }
    async getViolations(req, queryUserId) {
        const isAdmin = req.user.role === 'ADMIN' || req.user.role === 'SUPERADMIN';
        const targetUserId = isAdmin ? queryUserId : req.user.userId;
        return this.riskService.getViolations(targetUserId);
    }
    async getSnapshots(req, queryUserId) {
        const isAdmin = req.user.role === 'ADMIN' || req.user.role === 'SUPERADMIN';
        const targetUserId = isAdmin ? queryUserId : req.user.userId;
        return this.riskService.getSnapshots(targetUserId);
    }
    async getEvents(req, query) {
        const userId = req.user.userId;
        const limit = query.limit || 20;
        const offset = query.offset || 0;
        return this.riskService.getRiskEvents(userId, limit, offset);
    }
    async getStatus(req) {
        const userId = req.user.userId;
        return this.riskService.getRiskStatus(userId);
    }
    async resetLock(req, dto) {
        const userId = req.user.userId;
        return this.riskService.resetRiskLock(userId, dto.segmentId);
    }
};
exports.RiskController = RiskController;
__decorate([
    (0, common_1.Get)('status/:segmentId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('segmentId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "getStatusForSegment", null);
__decorate([
    (0, common_1.Get)('events/:segmentId'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('segmentId')),
    __param(2, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, PaginatedQueryDto]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "getEventsForSegment", null);
__decorate([
    (0, common_1.Post)('unlock/:segmentId'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('segmentId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, UnlockSegmentDto]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "unlockSegment", null);
__decorate([
    (0, common_1.Post)('profiles'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [CreateRiskProfileDto]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "createProfile", null);
__decorate([
    (0, common_1.Put)('profiles/:id'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, UpdateRiskProfileDto]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "updateProfile", null);
__decorate([
    (0, common_1.Get)('violations'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "getViolations", null);
__decorate([
    (0, common_1.Get)('snapshots'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "getSnapshots", null);
__decorate([
    (0, common_1.Get)('events'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, GetRiskEventsDto]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "getEvents", null);
__decorate([
    (0, common_1.Get)('status'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "getStatus", null);
__decorate([
    (0, common_1.Post)('reset'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, ResetRiskDto]),
    __metadata("design:returntype", Promise)
], RiskController.prototype, "resetLock", null);
exports.RiskController = RiskController = __decorate([
    (0, common_1.Controller)('risk'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [risk_service_1.RiskService])
], RiskController);
//# sourceMappingURL=risk.controller.js.map