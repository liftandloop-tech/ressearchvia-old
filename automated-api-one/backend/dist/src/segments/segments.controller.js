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
exports.SegmentsController = exports.PauseSegmentDto = exports.ActivateSegmentDto = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const segments_service_1 = require("./segments.service");
const class_validator_1 = require("class-validator");
class ActivateSegmentDto {
    segmentId;
    capital;
    backupCapital;
    baseLot;
    maxMultiplier;
    dailyLossLimit;
}
exports.ActivateSegmentDto = ActivateSegmentDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], ActivateSegmentDto.prototype, "segmentId", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], ActivateSegmentDto.prototype, "capital", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], ActivateSegmentDto.prototype, "backupCapital", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], ActivateSegmentDto.prototype, "baseLot", void 0);
__decorate([
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], ActivateSegmentDto.prototype, "maxMultiplier", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], ActivateSegmentDto.prototype, "dailyLossLimit", void 0);
class PauseSegmentDto {
    segmentId;
}
exports.PauseSegmentDto = PauseSegmentDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], PauseSegmentDto.prototype, "segmentId", void 0);
let SegmentsController = class SegmentsController {
    segmentsService;
    constructor(segmentsService) {
        this.segmentsService = segmentsService;
    }
    async listSegments() {
        return this.segmentsService.listSegments();
    }
    async getActiveSegments(req) {
        const userId = req.user.userId;
        return this.segmentsService.getUserSegments(userId);
    }
    async activateSegment(req, dto) {
        const userId = req.user.userId;
        return this.segmentsService.activateSegment(userId, dto);
    }
    async pauseSegment(req, dto) {
        const userId = req.user.userId;
        return this.segmentsService.pauseSegment(userId, dto.segmentId);
    }
};
exports.SegmentsController = SegmentsController;
__decorate([
    (0, common_1.Get)(),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], SegmentsController.prototype, "listSegments", null);
__decorate([
    (0, common_1.Get)('active'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SegmentsController.prototype, "getActiveSegments", null);
__decorate([
    (0, common_1.Post)('activate'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, ActivateSegmentDto]),
    __metadata("design:returntype", Promise)
], SegmentsController.prototype, "activateSegment", null);
__decorate([
    (0, common_1.Post)('pause'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, PauseSegmentDto]),
    __metadata("design:returntype", Promise)
], SegmentsController.prototype, "pauseSegment", null);
exports.SegmentsController = SegmentsController = __decorate([
    (0, common_1.Controller)('segments'),
    __metadata("design:paramtypes", [segments_service_1.SegmentsService])
], SegmentsController);
//# sourceMappingURL=segments.controller.js.map