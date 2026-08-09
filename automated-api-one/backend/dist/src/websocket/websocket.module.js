"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.WebsocketModule = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const trading_gateway_1 = require("./gateway/trading.gateway");
const websocket_service_1 = require("./services/websocket.service");
const websocket_processor_1 = require("./processors/websocket.processor");
const redis_module_1 = require("../infrastructure/redis/redis.module");
const queues_module_1 = require("../infrastructure/queues/queues.module");
const prisma_service_1 = require("../prisma.service");
let WebsocketModule = class WebsocketModule {
};
exports.WebsocketModule = WebsocketModule;
exports.WebsocketModule = WebsocketModule = __decorate([
    (0, common_1.Global)(),
    (0, common_1.Module)({
        imports: [
            redis_module_1.RedisModule,
            queues_module_1.QueuesModule,
            jwt_1.JwtModule.registerAsync({
                imports: [config_1.ConfigModule],
                inject: [config_1.ConfigService],
                useFactory: (config) => ({
                    secret: config.get('JWT_SECRET', 'super_secret_trading_platform_key'),
                }),
            }),
        ],
        providers: [
            trading_gateway_1.TradingGateway,
            websocket_service_1.WebsocketService,
            websocket_processor_1.WebsocketProcessor,
            prisma_service_1.PrismaService,
        ],
        exports: [websocket_service_1.WebsocketService, trading_gateway_1.TradingGateway],
    })
], WebsocketModule);
//# sourceMappingURL=websocket.module.js.map