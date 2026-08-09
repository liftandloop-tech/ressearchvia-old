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
var MultiplierService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.MultiplierService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma.service");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const redis_keys_1 = require("../../infrastructure/redis/redis-keys");
const DEFAULT_PROGRESSION = [1, 2, 4, 8];
let MultiplierService = MultiplierService_1 = class MultiplierService {
    prisma;
    redisService;
    logger = new common_1.Logger(MultiplierService_1.name);
    constructor(prisma, redisService) {
        this.prisma = prisma;
        this.redisService = redisService;
    }
    async getState(userId, segmentId) {
        const cacheKey = redis_keys_1.RedisKeys.multiplier(userId, segmentId);
        if (this.redisService.isHealthy()) {
            try {
                const raw = await this.redisService.getClient().get(cacheKey);
                if (raw) {
                    return JSON.parse(raw);
                }
            }
            catch (err) {
                this.logger.warn(`Failed to read multiplier from Redis [${cacheKey}]: ${err.message}`);
            }
        }
        const dbRecord = await this.prisma.segmentMultiplier.findFirst({
            where: { userId, segmentId },
        });
        if (!dbRecord) {
            const state = { index: 0, current: DEFAULT_PROGRESSION[0] };
            await this.setState(userId, segmentId, state);
            return state;
        }
        const state = {
            index: dbRecord.lossStreak,
            current: dbRecord.currentMultiplier,
        };
        await this.setState(userId, segmentId, state);
        return state;
    }
    async setState(userId, segmentId, state) {
        if (this.redisService.isHealthy()) {
            try {
                const cacheKey = redis_keys_1.RedisKeys.multiplier(userId, segmentId);
                await this.redisService
                    .getClient()
                    .set(cacheKey, JSON.stringify(state), 'EX', 86400);
            }
            catch (err) {
                this.logger.warn(`Failed to write multiplier to Redis: ${err.message}`);
            }
        }
        await this.prisma.segmentMultiplier.upsert({
            where: {
                userId_segmentId: { userId, segmentId },
            },
            create: {
                userId,
                segmentId,
                lossStreak: state.index,
                currentMultiplier: state.current,
                currentLot: state.current,
            },
            update: {
                lossStreak: state.index,
                currentMultiplier: state.current,
                currentLot: state.current,
            },
        });
    }
    async advanceOnLoss(userId, segmentId) {
        const userSegment = await this.prisma.userSegment.findFirst({
            where: { userId, segmentId },
        });
        const maxMultiplier = userSegment?.maxMultiplier ?? 8;
        const current = await this.getState(userId, segmentId);
        const progression = DEFAULT_PROGRESSION;
        const nextIndex = Math.min(current.index + 1, progression.length - 1);
        const nextValue = Math.min(progression[nextIndex], maxMultiplier);
        const nextState = { index: nextIndex, current: nextValue };
        await this.setState(userId, segmentId, nextState);
        this.logger.log(`Multiplier advanced on loss: userId=${userId} segmentId=${segmentId} ` +
            `${current.current}x → ${nextState.current}x (index: ${nextState.index})`);
        return nextState;
    }
    async resetOnWin(userId, segmentId) {
        const resetState = { index: 0, current: DEFAULT_PROGRESSION[0] };
        await this.setState(userId, segmentId, resetState);
        this.logger.log(`Multiplier reset on win: userId=${userId} segmentId=${segmentId} → 1x`);
    }
};
exports.MultiplierService = MultiplierService;
exports.MultiplierService = MultiplierService = MultiplierService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        redis_service_1.RedisService])
], MultiplierService);
//# sourceMappingURL=multiplier.service.js.map