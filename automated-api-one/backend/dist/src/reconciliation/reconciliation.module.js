"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReconciliationModule = void 0;
const common_1 = require("@nestjs/common");
const reconciliation_service_1 = require("./reconciliation.service");
const reconciliation_processor_1 = require("./reconciliation.processor");
const reconciliation_scheduler_1 = require("./reconciliation.scheduler");
const prisma_service_1 = require("../prisma.service");
const infrastructure_module_1 = require("../infrastructure/infrastructure.module");
const brokers_module_1 = require("../brokers/brokers.module");
let ReconciliationModule = class ReconciliationModule {
};
exports.ReconciliationModule = ReconciliationModule;
exports.ReconciliationModule = ReconciliationModule = __decorate([
    (0, common_1.Module)({
        imports: [infrastructure_module_1.InfrastructureModule, brokers_module_1.BrokersModule],
        providers: [
            reconciliation_service_1.ReconciliationService,
            reconciliation_processor_1.ReconciliationProcessor,
            reconciliation_scheduler_1.ReconciliationScheduler,
            prisma_service_1.PrismaService,
        ],
        exports: [reconciliation_service_1.ReconciliationService],
    })
], ReconciliationModule);
//# sourceMappingURL=reconciliation.module.js.map