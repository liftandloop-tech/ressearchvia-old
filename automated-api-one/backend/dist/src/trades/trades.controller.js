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
exports.TradesController = exports.ExportTradesDto = exports.GetHistoryDto = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const trades_service_1 = require("./trades.service");
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
const class_transformer_1 = require("class-transformer");
class GetHistoryDto {
    status;
    limit;
    offset;
}
exports.GetHistoryDto = GetHistoryDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEnum)(client_1.TradeStatus),
    __metadata("design:type", String)
], GetHistoryDto.prototype, "status", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], GetHistoryDto.prototype, "limit", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], GetHistoryDto.prototype, "offset", void 0);
class ExportTradesDto {
    format;
}
exports.ExportTradesDto = ExportTradesDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsEnum)(['csv', 'pdf'], { message: 'format must be either csv or pdf' }),
    __metadata("design:type", String)
], ExportTradesDto.prototype, "format", void 0);
let TradesController = class TradesController {
    tradesService;
    constructor(tradesService) {
        this.tradesService = tradesService;
    }
    async getHistory(req, query) {
        const userId = req.user.userId;
        const limit = query.limit || 10;
        const offset = query.offset || 0;
        return this.tradesService.getTradeHistory(userId, query.status, limit, offset);
    }
    async getSummary(req) {
        const userId = req.user.userId;
        return this.tradesService.getPnlSummary(userId);
    }
    async exportTrades(req, dto) {
        const userId = req.user.userId;
        return this.tradesService.exportTrades(userId, dto.format);
    }
};
exports.TradesController = TradesController;
__decorate([
    (0, common_1.Get)('history'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, GetHistoryDto]),
    __metadata("design:returntype", Promise)
], TradesController.prototype, "getHistory", null);
__decorate([
    (0, common_1.Get)('summary'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], TradesController.prototype, "getSummary", null);
__decorate([
    (0, common_1.Post)('export'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, ExportTradesDto]),
    __metadata("design:returntype", Promise)
], TradesController.prototype, "exportTrades", null);
exports.TradesController = TradesController = __decorate([
    (0, common_1.Controller)('trades'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [trades_service_1.TradesService])
], TradesController);
//# sourceMappingURL=trades.controller.js.map