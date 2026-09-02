"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const app_controller_1 = require("./app.controller");
const app_service_1 = require("./app.service");
const auth_module_1 = require("./auth/auth.module");
const users_module_1 = require("./users/users.module");
const brokers_module_1 = require("./brokers/brokers.module");
const consents_module_1 = require("./consents/consents.module");
const segments_module_1 = require("./segments/segments.module");
const bullmq_1 = require("@nestjs/bullmq");
const signals_module_1 = require("./signals/signals.module");
const trades_module_1 = require("./trades/trades.module");
const positions_module_1 = require("./positions/positions.module");
const notifications_module_1 = require("./notifications/notifications.module");
const risk_module_1 = require("./risk/risk.module");
const health_module_1 = require("./health/health.module");
const subscriptions_module_1 = require("./subscriptions/subscriptions.module");
const trading_module_1 = require("./trading/trading.module");
const audit_module_1 = require("./audit/audit.module");
const websocket_module_1 = require("./websocket/websocket.module");
const reports_module_1 = require("./reports/reports.module");
const admin_module_1 = require("./admin/admin.module");
const reconciliation_module_1 = require("./reconciliation/reconciliation.module");
const analytics_module_1 = require("./analytics/analytics.module");
const audit_interceptor_1 = require("./audit/interceptors/audit.interceptor");
const core_1 = require("@nestjs/core");
const nestjs_pino_1 = require("nestjs-pino");
const env_config_1 = require("./config/env.config");
const logger_config_1 = require("./config/logger.config");
const schedule_1 = require("@nestjs/schedule");
const prisma_module_1 = require("./database/prisma/prisma.module");
const infrastructure_module_1 = require("./infrastructure/infrastructure.module");
const instruments_module_1 = require("./instruments/instruments.module");
const proxy_manager_module_1 = require("./proxy-manager/proxy-manager.module");
const egress_module_1 = require("./egress/egress.module");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            schedule_1.ScheduleModule.forRoot(),
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                validate: env_config_1.validateEnv,
            }),
            nestjs_pino_1.LoggerModule.forRoot(logger_config_1.loggerConfig),
            bullmq_1.BullModule.forRootAsync({
                imports: [config_1.ConfigModule],
                inject: [config_1.ConfigService],
                useFactory: (config) => {
                    const connectionOptions = {
                        host: config.get('REDIS_HOST', 'localhost'),
                        port: config.get('REDIS_PORT', 6379),
                        password: config.get('REDIS_PASSWORD'),
                    };
                    const username = config.get('REDIS_USERNAME');
                    if (username) {
                        connectionOptions.username = username;
                    }
                    return { connection: connectionOptions };
                },
            }),
            prisma_module_1.PrismaModule,
            infrastructure_module_1.InfrastructureModule,
            auth_module_1.AuthModule,
            users_module_1.UsersModule,
            brokers_module_1.BrokersModule,
            consents_module_1.ConsentsModule,
            segments_module_1.SegmentsModule,
            signals_module_1.SignalsModule,
            trades_module_1.TradesModule,
            positions_module_1.PositionsModule,
            notifications_module_1.NotificationsModule,
            risk_module_1.RiskModule,
            health_module_1.HealthModule,
            subscriptions_module_1.SubscriptionsModule,
            trading_module_1.TradingModule,
            audit_module_1.AuditModule,
            websocket_module_1.WebsocketModule,
            reports_module_1.ReportsModule,
            admin_module_1.AdminModule,
            reconciliation_module_1.ReconciliationModule,
            analytics_module_1.AnalyticsModule,
            instruments_module_1.InstrumentsModule,
            proxy_manager_module_1.ProxyManagerModule,
            egress_module_1.EgressModule,
        ],
        controllers: [app_controller_1.AppController],
        providers: [
            app_service_1.AppService,
            {
                provide: core_1.APP_INTERCEPTOR,
                useClass: audit_interceptor_1.AuditInterceptor,
            },
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map