"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var BrokerRateLimiterService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.BrokerRateLimiterService = exports.BrokerRateLimitException = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const redis_service_1 = require("./redis.service");
const crypto = __importStar(require("crypto"));
class BrokerRateLimitException extends Error {
    constructor(broker, limit) {
        super(`Rate limit of ${limit} requests/min exceeded for broker: ${broker}`);
        this.name = 'BrokerRateLimitException';
    }
}
exports.BrokerRateLimitException = BrokerRateLimitException;
let BrokerRateLimiterService = BrokerRateLimiterService_1 = class BrokerRateLimiterService {
    redisService;
    configService;
    logger = new common_1.Logger(BrokerRateLimiterService_1.name);
    constructor(redisService, configService) {
        this.redisService = redisService;
        this.configService = configService;
    }
    async throttle(broker, operationType = 'trading') {
        if (!this.redisService.isHealthy()) {
            this.logger.warn(`Redis is unhealthy. Bypassing rate limiting for broker: ${broker}:${operationType}`);
            return true;
        }
        const defaultLimit = operationType === 'trading' ? 120 : 60;
        const limit = this.configService.get(operationType === 'trading' ? 'BROKER_RATE_LIMIT_TRADING_PER_MINUTE' : 'BROKER_RATE_LIMIT_MARKET_PER_MINUTE', defaultLimit);
        const key = `broker:ratelimit:${broker}:${operationType}`;
        const now = Date.now();
        const clearBefore = now - 60000;
        try {
            const client = this.redisService.getClient();
            const multi = client.multi();
            multi.zremrangebyscore(key, 0, clearBefore);
            multi.zadd(key, now, `${now}-${crypto.randomUUID()}`);
            multi.zcard(key);
            multi.expire(key, 60);
            const results = await multi.exec();
            if (!results) {
                throw new Error('Redis transaction execution returned null');
            }
            const count = results[2][1];
            if (count > limit) {
                this.logger.warn(`Rate limit tripped for broker ${broker}:${operationType}: ${count}/${limit} reqs/min`);
                throw new BrokerRateLimitException(`${broker}:${operationType}`, limit);
            }
            return true;
        }
        catch (err) {
            if (err instanceof BrokerRateLimitException) {
                throw err;
            }
            this.logger.error(`Error in rate limiter check for ${broker}:${operationType}: ${err.message}`);
            return true;
        }
    }
};
exports.BrokerRateLimiterService = BrokerRateLimiterService;
exports.BrokerRateLimiterService = BrokerRateLimiterService = BrokerRateLimiterService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService,
        config_1.ConfigService])
], BrokerRateLimiterService);
//# sourceMappingURL=broker-rate-limiter.service.js.map