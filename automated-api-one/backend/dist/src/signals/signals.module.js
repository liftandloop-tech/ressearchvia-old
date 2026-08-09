"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SignalsModule = void 0;
const common_1 = require("@nestjs/common");
const signals_controller_1 = require("./signals.controller");
const signals_service_1 = require("./signals.service");
const brokers_module_1 = require("../brokers/brokers.module");
const consents_module_1 = require("../consents/consents.module");
const prisma_service_1 = require("../prisma.service");
const infrastructure_module_1 = require("../infrastructure/infrastructure.module");
let SignalsModule = class SignalsModule {
};
exports.SignalsModule = SignalsModule;
exports.SignalsModule = SignalsModule = __decorate([
    (0, common_1.Module)({
        imports: [
            brokers_module_1.BrokersModule,
            consents_module_1.ConsentsModule,
            infrastructure_module_1.InfrastructureModule,
        ],
        controllers: [signals_controller_1.SignalsController],
        providers: [signals_service_1.SignalsService, prisma_service_1.PrismaService],
        exports: [signals_service_1.SignalsService],
    })
], SignalsModule);
//# sourceMappingURL=signals.module.js.map