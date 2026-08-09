"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BrokersModule = void 0;
const common_1 = require("@nestjs/common");
const axios_1 = require("@nestjs/axios");
const brokers_controller_1 = require("./brokers.controller");
const angel_one_service_1 = require("./providers/angel-one.service");
const zebu_service_1 = require("./providers/zebu.service");
const broker_adapter_interface_1 = require("./interfaces/broker-adapter.interface");
const broker_registry_1 = require("./registry/broker.registry");
const broker_factory_1 = require("./factory/broker.factory");
const prisma_service_1 = require("../prisma.service");
const broker_session_service_1 = require("./services/broker-session.service");
const audit_module_1 = require("../audit/audit.module");
const infrastructure_module_1 = require("../infrastructure/infrastructure.module");
const instruments_module_1 = require("../instruments/instruments.module");
let BrokersModule = class BrokersModule {
};
exports.BrokersModule = BrokersModule;
exports.BrokersModule = BrokersModule = __decorate([
    (0, common_1.Module)({
        imports: [
            axios_1.HttpModule,
            audit_module_1.AuditModule,
            infrastructure_module_1.InfrastructureModule,
            (0, common_1.forwardRef)(() => instruments_module_1.InstrumentsModule),
        ],
        controllers: [brokers_controller_1.BrokersController],
        providers: [
            angel_one_service_1.AngelOneService,
            zebu_service_1.ZebuService,
            prisma_service_1.PrismaService,
            broker_registry_1.BrokerRegistry,
            broker_factory_1.BrokerFactory,
            broker_session_service_1.BrokerSessionService,
            {
                provide: broker_adapter_interface_1.BrokerAdapter,
                useClass: angel_one_service_1.AngelOneService,
            },
        ],
        exports: [broker_adapter_interface_1.BrokerAdapter, broker_registry_1.BrokerRegistry, broker_factory_1.BrokerFactory, broker_session_service_1.BrokerSessionService, angel_one_service_1.AngelOneService, zebu_service_1.ZebuService],
    })
], BrokersModule);
//# sourceMappingURL=brokers.module.js.map