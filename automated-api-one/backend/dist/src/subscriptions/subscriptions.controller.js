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
exports.SubscriptionsController = exports.HistoryQueryDto = exports.SubscribeDto = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const subscriptions_service_1 = require("./subscriptions.service");
const class_validator_1 = require("class-validator");
const plans_constants_1 = require("./plans.constants");
const class_transformer_1 = require("class-transformer");
class SubscribeDto {
    planId;
}
exports.SubscribeDto = SubscribeDto;
__decorate([
    (0, class_validator_1.IsUUID)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], SubscribeDto.prototype, "planId", void 0);
class HistoryQueryDto {
    page;
    limit;
}
exports.HistoryQueryDto = HistoryQueryDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], HistoryQueryDto.prototype, "page", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], HistoryQueryDto.prototype, "limit", void 0);
let SubscriptionsController = class SubscriptionsController {
    subscriptionsService;
    constructor(subscriptionsService) {
        this.subscriptionsService = subscriptionsService;
    }
    getPlans() {
        return [
            {
                id: plans_constants_1.PLANS.SPARK.id,
                name: plans_constants_1.PLANS.SPARK.name,
                durationDays: plans_constants_1.PLANS.SPARK.durationDays,
            },
            {
                id: plans_constants_1.PLANS.SPLENDID.id,
                name: plans_constants_1.PLANS.SPLENDID.name,
                durationDays: plans_constants_1.PLANS.SPLENDID.durationDays,
            },
        ];
    }
    async getCurrent(req) {
        const userId = req.user.userId;
        return this.subscriptionsService.getCurrentSubscription(userId);
    }
    async getStatus(req) {
        const userId = req.user.userId;
        return this.subscriptionsService.validateSubscription(userId);
    }
    async getHistory(req, query) {
        const userId = req.user.userId;
        return this.subscriptionsService.getSubscriptionHistory(userId, query.page, query.limit);
    }
    async subscribeBase(req, dto) {
        const userId = req.user.userId;
        return this.subscriptionsService.subscribe(userId, dto.planId);
    }
    async subscribeLegacy(req, dto) {
        const userId = req.user.userId;
        return this.subscriptionsService.subscribe(userId, dto.planId);
    }
    async cancel(req, id) {
        const userId = req.user.userId;
        return this.subscriptionsService.cancelSubscription(id, userId);
    }
};
exports.SubscriptionsController = SubscriptionsController;
__decorate([
    (0, common_1.Get)('plans'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], SubscriptionsController.prototype, "getPlans", null);
__decorate([
    (0, common_1.Get)('current'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "getCurrent", null);
__decorate([
    (0, common_1.Get)('status'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "getStatus", null);
__decorate([
    (0, common_1.Get)('history'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, HistoryQueryDto]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "getHistory", null);
__decorate([
    (0, common_1.Post)(),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, SubscribeDto]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "subscribeBase", null);
__decorate([
    (0, common_1.Post)('subscribe'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, SubscribeDto]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "subscribeLegacy", null);
__decorate([
    (0, common_1.Delete)(':id'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "cancel", null);
exports.SubscriptionsController = SubscriptionsController = __decorate([
    (0, common_1.Controller)('subscriptions'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [subscriptions_service_1.SubscriptionsService])
], SubscriptionsController);
//# sourceMappingURL=subscriptions.controller.js.map