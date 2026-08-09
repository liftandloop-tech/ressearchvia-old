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
var CircuitBreakerService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.CircuitBreakerService = exports.BrokerUnavailableException = exports.CircuitState = void 0;
const common_1 = require("@nestjs/common");
const redis_service_1 = require("../redis/redis.service");
const redis_keys_1 = require("../redis/redis-keys");
const config_1 = require("@nestjs/config");
const metrics_service_1 = require("../metrics/metrics.service");
var CircuitState;
(function (CircuitState) {
    CircuitState["CLOSED"] = "CLOSED";
    CircuitState["OPEN"] = "OPEN";
    CircuitState["HALF_OPEN"] = "HALF_OPEN";
})(CircuitState || (exports.CircuitState = CircuitState = {}));
class BrokerUnavailableException extends Error {
    constructor(message = 'Broker API is currently unavailable (circuit open)') {
        super(message);
        this.name = 'BrokerUnavailableException';
    }
}
exports.BrokerUnavailableException = BrokerUnavailableException;
let CircuitBreakerService = CircuitBreakerService_1 = class CircuitBreakerService {
    redisService;
    configService;
    metrics;
    logger = new common_1.Logger(CircuitBreakerService_1.name);
    memStates = new Map();
    cooldownMs;
    failureThreshold;
    constructor(redisService, configService, metrics) {
        this.redisService = redisService;
        this.configService = configService;
        this.metrics = metrics;
        this.cooldownMs = this.configService.get('CIRCUIT_BREAKER_RESET_TIMEOUT_MS', 60000);
        this.failureThreshold = this.configService.get('CIRCUIT_BREAKER_FAILURE_THRESHOLD', 3);
    }
    setCircuitStateGauge(broker, state) {
        let val = 0;
        if (state === CircuitState.CLOSED)
            val = 0;
        else if (state === CircuitState.HALF_OPEN)
            val = 1;
        else if (state === CircuitState.OPEN)
            val = 2;
        this.metrics.setBrokerCircuitState(broker, val);
    }
    async getCircuitInfo(broker) {
        const defaultInfo = { state: CircuitState.CLOSED, failures: 0, lastChange: Date.now() };
        if (!this.redisService.isHealthy()) {
            this.logger.warn(`Redis is unhealthy. Using local memory circuit state for broker: ${broker}`);
            if (!this.memStates.has(broker)) {
                this.memStates.set(broker, defaultInfo);
            }
            return this.memStates.get(broker);
        }
        try {
            const redisKey = redis_keys_1.RedisKeys.circuitBreaker(broker);
            const data = await this.redisService.getClient().get(redisKey);
            if (!data) {
                await this.setCircuitInfo(broker, defaultInfo);
                return defaultInfo;
            }
            return JSON.parse(data);
        }
        catch (err) {
            this.logger.error(`Failed to read circuit info from Redis: ${err.message}`);
            return this.memStates.get(broker) || defaultInfo;
        }
    }
    async setCircuitInfo(broker, info) {
        this.memStates.set(broker, info);
        this.setCircuitStateGauge(broker, info.state);
        if (!this.redisService.isHealthy())
            return;
        try {
            const redisKey = redis_keys_1.RedisKeys.circuitBreaker(broker);
            await this.redisService.getClient().set(redisKey, JSON.stringify(info), 'EX', 86400);
        }
        catch (err) {
            this.logger.error(`Failed to save circuit info to Redis: ${err.message}`);
        }
    }
    async execute(broker, operation) {
        const info = await this.getCircuitInfo(broker);
        let state = info.state;
        let lastChange = info.lastChange;
        if (state === CircuitState.OPEN && Date.now() - lastChange >= this.cooldownMs) {
            this.logger.log(`Circuit for broker ${broker} transitioning from OPEN to HALF_OPEN (cooldown expired)`);
            state = CircuitState.HALF_OPEN;
            const duration = Date.now() - lastChange;
            this.metrics.observeBrokerCircuitOpenDuration(broker, duration);
            lastChange = Date.now();
            await this.setCircuitInfo(broker, { ...info, state, lastChange });
        }
        if (state === CircuitState.OPEN) {
            throw new BrokerUnavailableException(`Broker ${broker} API is unavailable (circuit open)`);
        }
        try {
            const result = await operation();
            await this.onSuccess(broker, state, info);
            return result;
        }
        catch (err) {
            await this.onFailure(broker, state, info, err);
            throw err;
        }
    }
    async onSuccess(broker, currentState, info) {
        if (currentState === CircuitState.HALF_OPEN) {
            this.logger.log(`Circuit for broker ${broker} is now CLOSED (pilot request succeeded)`);
            await this.setCircuitInfo(broker, {
                state: CircuitState.CLOSED,
                failures: 0,
                lastChange: Date.now(),
            });
        }
        else if (info.failures > 0) {
            await this.setCircuitInfo(broker, {
                ...info,
                failures: 0,
            });
        }
    }
    async onFailure(broker, currentState, info, error) {
        const failures = info.failures + 1;
        this.logger.warn(`Failure recorded for broker ${broker}. Consecutive failures: ${failures}. Error: ${error.message}`);
        if (currentState === CircuitState.HALF_OPEN || failures >= this.failureThreshold) {
            this.logger.error(`Circuit for broker ${broker} is now OPEN. Requests will be blocked for 60 seconds.`);
            this.metrics.incrementBrokerCircuitOpen(broker);
            await this.setCircuitInfo(broker, {
                state: CircuitState.OPEN,
                failures,
                lastChange: Date.now(),
            });
        }
        else {
            await this.setCircuitInfo(broker, {
                ...info,
                failures,
            });
        }
    }
};
exports.CircuitBreakerService = CircuitBreakerService;
exports.CircuitBreakerService = CircuitBreakerService = CircuitBreakerService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService,
        config_1.ConfigService,
        metrics_service_1.MetricsService])
], CircuitBreakerService);
//# sourceMappingURL=circuit-breaker.service.js.map