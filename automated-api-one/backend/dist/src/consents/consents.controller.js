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
exports.ConsentsController = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const consents_service_1 = require("./consents.service");
let ConsentsController = class ConsentsController {
    consentsService;
    constructor(consentsService) {
        this.consentsService = consentsService;
    }
    async grantConsent(req, body) {
        const userId = req.user.userId;
        const ipAddress = (req.headers['x-forwarded-for'] ||
            req.ip ||
            req.socket?.remoteAddress);
        const userAgent = req.headers['user-agent'];
        const consent = await this.consentsService.grantConsentWithStrategy(userId, {
            brokerId: body.brokerId,
            strategy: body.strategy,
            baseMultiplier: body.baseMultiplier ?? 1,
            consentAccepted: body.consentAccepted ?? true,
            agreementVersion: body.agreementVersion ?? 'v1.0',
            ipAddress: Array.isArray(ipAddress) ? ipAddress[0] : ipAddress,
            userAgent,
        });
        return {
            status: consent.status,
            consentDate: (0, consents_service_1.getTodayISTString)(consent.consentDate),
            strategy: body.strategy ?? 'FIXED_1X',
        };
    }
    async getConsentStatusToday(req) {
        const userId = req.user.userId;
        return this.consentsService.getConsentStatus(userId);
    }
    async getConsentStatusDashboard(req) {
        const userId = req.user.userId;
        return this.consentsService.getConsentStatus(userId);
    }
    async revokeConsent(req) {
        const userId = req.user.userId;
        await this.consentsService.revokeConsent(userId);
        return {
            status: 'REVOKED',
        };
    }
    async getUserStrategy(req) {
        const userId = req.user.userId;
        return this.consentsService.getUserStrategyDetails(userId);
    }
    async changeUserStrategy(req, body) {
        const userId = req.user.userId;
        const ipAddress = (req.headers['x-forwarded-for'] ||
            req.ip ||
            req.socket?.remoteAddress);
        const userAgent = req.headers['user-agent'];
        const updated = await this.consentsService.changeUserStrategy(userId, body.strategy, body.agreementVersion ?? 'v1.0', Array.isArray(ipAddress) ? ipAddress[0] : ipAddress, userAgent);
        return {
            success: true,
            message: 'Strategy changed successfully. New cycle active with 1x multiplier.',
            strategy: updated,
        };
    }
    async getStrategyHistory(req) {
        const userId = req.user.userId;
        const history = await this.consentsService.getStrategyHistory(userId);
        return {
            history,
        };
    }
};
exports.ConsentsController = ConsentsController;
__decorate([
    (0, common_1.Post)(),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ConsentsController.prototype, "grantConsent", null);
__decorate([
    (0, common_1.Get)('today'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ConsentsController.prototype, "getConsentStatusToday", null);
__decorate([
    (0, common_1.Get)('status'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ConsentsController.prototype, "getConsentStatusDashboard", null);
__decorate([
    (0, common_1.Delete)('today'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ConsentsController.prototype, "revokeConsent", null);
__decorate([
    (0, common_1.Get)('strategy'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ConsentsController.prototype, "getUserStrategy", null);
__decorate([
    (0, common_1.Post)('strategy/change'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", Promise)
], ConsentsController.prototype, "changeUserStrategy", null);
__decorate([
    (0, common_1.Get)('strategy/history'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ConsentsController.prototype, "getStrategyHistory", null);
exports.ConsentsController = ConsentsController = __decorate([
    (0, common_1.Controller)('consents'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [consents_service_1.ConsentsService])
], ConsentsController);
//# sourceMappingURL=consents.controller.js.map