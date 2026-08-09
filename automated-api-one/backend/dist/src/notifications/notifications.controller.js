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
exports.NotificationsController = exports.UpdatePreferencesDto = exports.UpdatePreferenceItemDto = exports.SimulateNotificationDto = exports.MarkReadDto = exports.GetNotificationsDto = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const notifications_service_1 = require("./notifications.service");
const class_validator_1 = require("class-validator");
const class_transformer_1 = require("class-transformer");
const client_1 = require("@prisma/client");
class GetNotificationsDto {
    limit;
    offset;
}
exports.GetNotificationsDto = GetNotificationsDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    __metadata("design:type", Number)
], GetNotificationsDto.prototype, "limit", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    __metadata("design:type", Number)
], GetNotificationsDto.prototype, "offset", void 0);
class MarkReadDto {
    notificationIds;
}
exports.MarkReadDto = MarkReadDto;
__decorate([
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.IsString)({ each: true }),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", Array)
], MarkReadDto.prototype, "notificationIds", void 0);
class SimulateNotificationDto {
    type;
    title;
    message;
}
exports.SimulateNotificationDto = SimulateNotificationDto;
__decorate([
    (0, class_validator_1.IsEnum)(client_1.NotificationType),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], SimulateNotificationDto.prototype, "type", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], SimulateNotificationDto.prototype, "title", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], SimulateNotificationDto.prototype, "message", void 0);
class UpdatePreferenceItemDto {
    eventType;
    channel;
    enabled;
}
exports.UpdatePreferenceItemDto = UpdatePreferenceItemDto;
__decorate([
    (0, class_validator_1.IsEnum)(client_1.NotificationEvent),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdatePreferenceItemDto.prototype, "eventType", void 0);
__decorate([
    (0, class_validator_1.IsEnum)(client_1.NotificationChannel),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdatePreferenceItemDto.prototype, "channel", void 0);
__decorate([
    (0, class_validator_1.IsBoolean)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", Boolean)
], UpdatePreferenceItemDto.prototype, "enabled", void 0);
class UpdatePreferencesDto {
    preferences;
    quietHoursEnabled;
    quietStart;
    quietEnd;
    quietTimezone;
}
exports.UpdatePreferencesDto = UpdatePreferencesDto;
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsArray)(),
    (0, class_validator_1.ValidateNested)({ each: true }),
    (0, class_transformer_1.Type)(() => UpdatePreferenceItemDto),
    __metadata("design:type", Array)
], UpdatePreferencesDto.prototype, "preferences", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], UpdatePreferencesDto.prototype, "quietHoursEnabled", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdatePreferencesDto.prototype, "quietStart", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdatePreferencesDto.prototype, "quietEnd", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdatePreferencesDto.prototype, "quietTimezone", void 0);
let NotificationsController = class NotificationsController {
    notificationsService;
    constructor(notificationsService) {
        this.notificationsService = notificationsService;
    }
    async getNotifications(req, query) {
        const userId = req.user.userId;
        const limit = query.limit || 20;
        const offset = query.offset || 0;
        return this.notificationsService.getHistory(userId, limit, offset);
    }
    async markRead(req, dto) {
        const userId = req.user.userId;
        return this.notificationsService.markAsRead(userId, dto.notificationIds);
    }
    async simulateNotification(req, dto) {
        const userId = req.user.userId;
        return this.notificationsService.createNotification(userId, dto.type, dto.title, dto.message);
    }
    async getPreferences(req) {
        const userId = req.user.userId;
        return this.notificationsService.getPreferences(userId);
    }
    async updatePreferences(req, dto) {
        const userId = req.user.userId;
        return this.notificationsService.updatePreferences(userId, dto);
    }
};
exports.NotificationsController = NotificationsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, GetNotificationsDto]),
    __metadata("design:returntype", Promise)
], NotificationsController.prototype, "getNotifications", null);
__decorate([
    (0, common_1.Post)('read'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, MarkReadDto]),
    __metadata("design:returntype", Promise)
], NotificationsController.prototype, "markRead", null);
__decorate([
    (0, common_1.Post)('simulate'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, SimulateNotificationDto]),
    __metadata("design:returntype", Promise)
], NotificationsController.prototype, "simulateNotification", null);
__decorate([
    (0, common_1.Get)('preferences'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], NotificationsController.prototype, "getPreferences", null);
__decorate([
    (0, common_1.Post)('preferences'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, UpdatePreferencesDto]),
    __metadata("design:returntype", Promise)
], NotificationsController.prototype, "updatePreferences", null);
exports.NotificationsController = NotificationsController = __decorate([
    (0, common_1.Controller)('notifications'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [notifications_service_1.NotificationsService])
], NotificationsController);
//# sourceMappingURL=notifications.controller.js.map