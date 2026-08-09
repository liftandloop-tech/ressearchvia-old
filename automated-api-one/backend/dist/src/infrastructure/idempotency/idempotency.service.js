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
var IdempotencyService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.IdempotencyService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma.service");
const redis_service_1 = require("../redis/redis.service");
const redis_keys_1 = require("../redis/redis-keys");
const client_1 = require("@prisma/client");
let IdempotencyService = IdempotencyService_1 = class IdempotencyService {
    prisma;
    redisService;
    logger = new common_1.Logger(IdempotencyService_1.name);
    constructor(prisma, redisService) {
        this.prisma = prisma;
        this.redisService = redisService;
    }
    async checkAndLock(key, type, ttlSeconds) {
        this.redisService.assertHealthy();
        const redisKey = redis_keys_1.RedisKeys.idempotency(key);
        try {
            const result = await this.redisService.getClient().set(redisKey, '1', 'EX', ttlSeconds, 'NX');
            if (result !== 'OK') {
                this.logger.warn(`Duplicate request detected via Redis for key: ${key}`);
                return false;
            }
            try {
                await this.prisma.idempotencyKey.create({
                    data: {
                        key,
                        type,
                        status: client_1.IdempotencyStatus.PENDING,
                    },
                });
                return true;
            }
            catch (dbErr) {
                if (dbErr.code === 'P2002') {
                    this.logger.warn(`Duplicate request detected via Database for key: ${key}`);
                    await this.redisService.getClient().del(redisKey).catch(() => { });
                    return false;
                }
                throw dbErr;
            }
        }
        catch (err) {
            this.logger.error(`Idempotency check failed for key: ${key}. Error: ${err.message}`);
            throw err;
        }
    }
    async updateStatus(key, status) {
        try {
            await this.prisma.idempotencyKey.update({
                where: { key },
                data: { status },
            });
        }
        catch (err) {
            this.logger.error(`Failed to update idempotency status for key: ${key}. Error: ${err.message}`);
        }
    }
    async tryAcquire(key, type) {
        return this.checkAndLock(key, type, 86400);
    }
    async markFailed(key) {
        return this.updateStatus(key, client_1.IdempotencyStatus.FAILED);
    }
    async markSuccess(key) {
        return this.updateStatus(key, client_1.IdempotencyStatus.SUCCESS);
    }
};
exports.IdempotencyService = IdempotencyService;
exports.IdempotencyService = IdempotencyService = IdempotencyService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        redis_service_1.RedisService])
], IdempotencyService);
//# sourceMappingURL=idempotency.service.js.map