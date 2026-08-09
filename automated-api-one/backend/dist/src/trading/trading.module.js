"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TradingModule = void 0;
const common_1 = require("@nestjs/common");
const bullmq_1 = require("@nestjs/bullmq");
const config_1 = require("@nestjs/config");
const trading_service_1 = require("./trading.service");
const signal_orchestrator_service_1 = require("./services/signal-orchestrator.service");
const order_placement_service_1 = require("./services/order-placement.service");
const order_monitoring_service_1 = require("./services/order-monitoring.service");
const position_cache_service_1 = require("./services/position-cache.service");
const multiplier_service_1 = require("./services/multiplier.service");
const execution_recovery_service_1 = require("./services/execution-recovery.service");
const signal_execution_processor_1 = require("./processors/signal-execution.processor");
const order_placement_processor_1 = require("./processors/order-placement.processor");
const order_monitoring_processor_1 = require("./processors/order-monitoring.processor");
const risk_module_1 = require("../risk/risk.module");
const consents_module_1 = require("../consents/consents.module");
const subscriptions_module_1 = require("../subscriptions/subscriptions.module");
const brokers_module_1 = require("../brokers/brokers.module");
const audit_module_1 = require("../audit/audit.module");
const infrastructure_module_1 = require("../infrastructure/infrastructure.module");
const queue_constants_1 = require("../infrastructure/queues/queue.constants");
let TradingModule = class TradingModule {
};
exports.TradingModule = TradingModule;
exports.TradingModule = TradingModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule,
            bullmq_1.BullModule.registerQueue({ name: queue_constants_1.Queues.SIGNAL_PROCESSING }, { name: queue_constants_1.Queues.ORDER_PLACEMENT }, { name: queue_constants_1.Queues.ORDER_MONITORING }),
            risk_module_1.RiskModule,
            consents_module_1.ConsentsModule,
            subscriptions_module_1.SubscriptionsModule,
            brokers_module_1.BrokersModule,
            audit_module_1.AuditModule,
            infrastructure_module_1.InfrastructureModule,
        ],
        providers: [
            trading_service_1.TradingService,
            signal_orchestrator_service_1.SignalOrchestratorService,
            order_placement_service_1.OrderPlacementService,
            order_monitoring_service_1.OrderMonitoringService,
            position_cache_service_1.PositionCacheService,
            multiplier_service_1.MultiplierService,
            execution_recovery_service_1.ExecutionRecoveryService,
            signal_execution_processor_1.SignalExecutionProcessor,
            order_placement_processor_1.OrderPlacementProcessor,
            order_monitoring_processor_1.OrderMonitoringProcessor,
        ],
        exports: [trading_service_1.TradingService, signal_orchestrator_service_1.SignalOrchestratorService, position_cache_service_1.PositionCacheService],
    })
], TradingModule);
//# sourceMappingURL=trading.module.js.map