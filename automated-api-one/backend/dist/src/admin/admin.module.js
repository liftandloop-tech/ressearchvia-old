"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AdminModule = void 0;
const common_1 = require("@nestjs/common");
const ops_controller_1 = require("./ops.controller");
const ops_service_1 = require("./ops.service");
const infrastructure_module_1 = require("../infrastructure/infrastructure.module");
const brokers_module_1 = require("../brokers/brokers.module");
const notifications_module_1 = require("../notifications/notifications.module");
const reconciliation_module_1 = require("../reconciliation/reconciliation.module");
let AdminModule = class AdminModule {
};
exports.AdminModule = AdminModule;
exports.AdminModule = AdminModule = __decorate([
    (0, common_1.Module)({
        imports: [infrastructure_module_1.InfrastructureModule, brokers_module_1.BrokersModule, notifications_module_1.NotificationsModule, reconciliation_module_1.ReconciliationModule],
        controllers: [ops_controller_1.OpsController],
        providers: [ops_service_1.OpsService],
        exports: [ops_service_1.OpsService],
    })
], AdminModule);
//# sourceMappingURL=admin.module.js.map