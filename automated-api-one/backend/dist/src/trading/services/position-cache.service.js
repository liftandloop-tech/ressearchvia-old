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
var PositionCacheService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PositionCacheService = void 0;
const common_1 = require("@nestjs/common");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const redis_keys_1 = require("../../infrastructure/redis/redis-keys");
const POSITION_CACHE_TTL_SECONDS = 8 * 60 * 60;
let PositionCacheService = PositionCacheService_1 = class PositionCacheService {
    redisService;
    logger = new common_1.Logger(PositionCacheService_1.name);
    constructor(redisService) {
        this.redisService = redisService;
    }
    async set(data) {
        if (!this.redisService.isHealthy()) {
            this.logger.warn(`Redis unhealthy — skipping position cache write for user ${data.userId} / segment ${data.segmentId}`);
            return;
        }
        const key = redis_keys_1.RedisKeys.position(data.userId, data.segmentId);
        try {
            await this.redisService
                .getClient()
                .set(key, JSON.stringify(data), 'EX', POSITION_CACHE_TTL_SECONDS);
            this.logger.debug(`Position cached: ${key}`);
        }
        catch (err) {
            this.logger.error(`Failed to cache position [${key}]: ${err.message}`);
        }
    }
    async get(userId, segmentId) {
        if (!this.redisService.isHealthy()) {
            return null;
        }
        const key = redis_keys_1.RedisKeys.position(userId, segmentId);
        try {
            const raw = await this.redisService.getClient().get(key);
            return raw ? JSON.parse(raw) : null;
        }
        catch (err) {
            this.logger.error(`Failed to read position cache [${key}]: ${err.message}`);
            return null;
        }
    }
    async del(userId, segmentId) {
        if (!this.redisService.isHealthy()) {
            return;
        }
        const key = redis_keys_1.RedisKeys.position(userId, segmentId);
        try {
            await this.redisService.getClient().del(key);
            this.logger.debug(`Position cache cleared: ${key}`);
        }
        catch (err) {
            this.logger.error(`Failed to delete position cache [${key}]: ${err.message}`);
        }
    }
};
exports.PositionCacheService = PositionCacheService;
exports.PositionCacheService = PositionCacheService = PositionCacheService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService])
], PositionCacheService);
//# sourceMappingURL=position-cache.service.js.map