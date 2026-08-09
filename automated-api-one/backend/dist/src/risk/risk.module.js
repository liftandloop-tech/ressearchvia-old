"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.RiskModule = void 0;
const common_1 = require("@nestjs/common");
const risk_controller_1 = require("./risk.controller");
const risk_service_1 = require("./risk.service");
const prisma_service_1 = require("../prisma.service");
const subscriptions_module_1 = require("../subscriptions/subscriptions.module");
const consents_module_1 = require("../consents/consents.module");
const brokers_module_1 = require("../brokers/brokers.module");
const audit_module_1 = require("../audit/audit.module");
const infrastructure_module_1 = require("../infrastructure/infrastructure.module");
const risk_processor_1 = require("./risk.processor");
let RiskModule = class RiskModule {
};
exports.RiskModule = RiskModule;
exports.RiskModule = RiskModule = __decorate([
    (0, common_1.Module)({
        imports: [
            subscriptions_module_1.SubscriptionsModule,
            consents_module_1.ConsentsModule,
            brokers_module_1.BrokersModule,
            audit_module_1.AuditModule,
            infrastructure_module_1.InfrastructureModule,
        ],
        controllers: [risk_controller_1.RiskController],
        providers: [risk_service_1.RiskService, prisma_service_1.PrismaService, risk_processor_1.RiskProcessor],
        exports: [risk_service_1.RiskService],
    })
], RiskModule);
//# sourceMappingURL=risk.module.js.map