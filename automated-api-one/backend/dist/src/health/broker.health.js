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
Object.defineProperty(exports, "__esModule", { value: true });
exports.BrokerHealthIndicator = void 0;
const common_1 = require("@nestjs/common");
const terminus_1 = require("@nestjs/terminus");
const config_1 = require("@nestjs/config");
const broker_factory_1 = require("../brokers/factory/broker.factory");
const broker_type_enum_1 = require("../brokers/interfaces/broker-type.enum");
let BrokerHealthIndicator = class BrokerHealthIndicator extends terminus_1.HealthIndicator {
    configService;
    brokerFactory;
    constructor(configService, brokerFactory) {
        super();
        this.configService = configService;
        this.brokerFactory = brokerFactory;
    }
    async getCustomHealth() {
        const start = Date.now();
        const mockVal = this.configService.get('MOCK_BROKERS', true);
        const isMock = mockVal === true || mockVal === 'true';
        if (isMock) {
            return {
                status: 'up',
                broker: 'ANGEL_ONE',
                reachable: true,
                authenticationValid: true,
                responseTimeMs: 10,
                message: 'Mock broker mode is active and healthy',
            };
        }
        try {
            const apiKey = this.configService.get('ANGEL_ONE_API_KEY');
            const authenticationValid = !!apiKey;
            const adapter = this.brokerFactory.getAdapter(broker_type_enum_1.BrokerType.ANGEL_ONE);
            const checkResult = await adapter.healthCheck();
            return {
                status: checkResult.reachable && authenticationValid ? 'up' : 'down',
                broker: 'ANGEL_ONE',
                reachable: checkResult.reachable,
                authenticationValid,
                responseTimeMs: checkResult.responseTimeMs,
            };
        }
        catch (error) {
            return {
                status: 'down',
                broker: 'ANGEL_ONE',
                reachable: false,
                authenticationValid: false,
                responseTimeMs: Date.now() - start,
            };
        }
    }
    async isHealthy(key) {
        const custom = await this.getCustomHealth();
        const isHealthy = custom.status === 'up';
        if (isHealthy) {
            return this.getStatus(key, true, custom);
        }
        else {
            throw new terminus_1.HealthCheckError('Broker check failed', this.getStatus(key, false, custom));
        }
    }
};
exports.BrokerHealthIndicator = BrokerHealthIndicator;
exports.BrokerHealthIndicator = BrokerHealthIndicator = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService,
        broker_factory_1.BrokerFactory])
], BrokerHealthIndicator);
//# sourceMappingURL=broker.health.js.map