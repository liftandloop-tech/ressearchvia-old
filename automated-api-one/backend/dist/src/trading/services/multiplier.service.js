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
const position_sizing_service_1 = require("./position-sizing.service");
let MultiplierService = MultiplierService_1 = class MultiplierService {
    prisma;
    redisService;
    positionSizingService;
    logger = new common_1.Logger(MultiplierService_1.name);
    constructor(prisma, redisService, positionSizingService) {
        this.prisma = prisma;
        this.redisService = redisService;
        this.positionSizingService = positionSizingService;
    }
    async getState(userId, segmentId) {
        return this.positionSizingService.getState(userId, segmentId);
    }
    async setState(userId, segmentId, state) {
    }
    async advanceOnLoss(userId, segmentId) {
        return this.positionSizingService.advanceOnLoss(userId, segmentId);
    }
    async resetOnWin(userId, segmentId) {
        return this.positionSizingService.resetOnWin(userId, segmentId);
    }
};
exports.MultiplierService = MultiplierService;
exports.MultiplierService = MultiplierService = MultiplierService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        redis_service_1.RedisService,
        position_sizing_service_1.PositionSizingService])
], MultiplierService);
//# sourceMappingURL=multiplier.service.js.map