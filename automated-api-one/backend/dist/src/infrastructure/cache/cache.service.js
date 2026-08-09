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
var CacheService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.CacheService = void 0;
const common_1 = require("@nestjs/common");
const redis_service_1 = require("../redis/redis.service");
let CacheService = CacheService_1 = class CacheService {
    redisService;
    logger = new common_1.Logger(CacheService_1.name);
    constructor(redisService) {
        this.redisService = redisService;
    }
    async get(key) {
        try {
            if (!this.redisService.isHealthy()) {
                this.logger.warn(`Redis is unhealthy. Cache GET bypassed for key: ${key}`);
                return null;
            }
            const val = await this.redisService.getClient().get(key);
            if (!val)
                return null;
            return JSON.parse(val);
        }
        catch (err) {
            this.logger.warn(`Failed to fetch from cache for key: ${key}. Error: ${err.message}`);
            return null;
        }
    }
    async set(key, value, ttlSeconds) {
        this.redisService.assertHealthy();
        const serialized = JSON.stringify(value);
        if (ttlSeconds) {
            await this.redisService.getClient().set(key, serialized, 'EX', ttlSeconds);
        }
        else {
            await this.redisService.getClient().set(key, serialized);
        }
    }
    async del(key) {
        this.redisService.assertHealthy();
        await this.redisService.getClient().del(key);
    }
};
exports.CacheService = CacheService;
exports.CacheService = CacheService = CacheService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService])
], CacheService);
//# sourceMappingURL=cache.service.js.map