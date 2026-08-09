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
exports.SignalsController = exports.PublishSignalDto = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const signals_service_1 = require("./signals.service");
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
class PublishSignalDto {
    segmentId;
    symbol;
    exchange;
    segment;
    side;
    orderType;
    entryPrice;
    stopLoss;
    targetPrice;
}
exports.PublishSignalDto = PublishSignalDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], PublishSignalDto.prototype, "segmentId", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], PublishSignalDto.prototype, "symbol", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], PublishSignalDto.prototype, "exchange", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.Segment),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], PublishSignalDto.prototype, "segment", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.Side),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], PublishSignalDto.prototype, "side", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.OrderType),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], PublishSignalDto.prototype, "orderType", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], PublishSignalDto.prototype, "entryPrice", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], PublishSignalDto.prototype, "stopLoss", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], PublishSignalDto.prototype, "targetPrice", void 0);
let SignalsController = class SignalsController {
    signalsService;
    constructor(signalsService) {
        this.signalsService = signalsService;
    }
    async publishSignal(dto) {
        return this.signalsService.publishAndEnqueue(dto);
    }
};
exports.SignalsController = SignalsController;
__decorate([
    (0, common_1.Post)('publish'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [PublishSignalDto]),
    __metadata("design:returntype", Promise)
], SignalsController.prototype, "publishSignal", null);
exports.SignalsController = SignalsController = __decorate([
    (0, common_1.Controller)('signals'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [signals_service_1.SignalsService])
], SignalsController);
//# sourceMappingURL=signals.controller.js.map