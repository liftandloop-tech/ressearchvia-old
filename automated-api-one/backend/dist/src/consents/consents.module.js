"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ConsentsModule = void 0;
const common_1 = require("@nestjs/common");
const consents_controller_1 = require("./consents.controller");
const consents_service_1 = require("./consents.service");
const prisma_service_1 = require("../prisma.service");
const audit_module_1 = require("../audit/audit.module");
const notifications_module_1 = require("../notifications/notifications.module");
const subscriptions_module_1 = require("../subscriptions/subscriptions.module");
let ConsentsModule = class ConsentsModule {
};
exports.ConsentsModule = ConsentsModule;
exports.ConsentsModule = ConsentsModule = __decorate([
    (0, common_1.Module)({
        imports: [audit_module_1.AuditModule, notifications_module_1.NotificationsModule, subscriptions_module_1.SubscriptionsModule],
        controllers: [consents_controller_1.ConsentsController],
        providers: [consents_service_1.ConsentsService, prisma_service_1.PrismaService],
        exports: [consents_service_1.ConsentsService],
    })
], ConsentsModule);
//# sourceMappingURL=consents.module.js.map