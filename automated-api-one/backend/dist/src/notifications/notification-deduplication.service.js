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
var NotificationDeduplicationService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.NotificationDeduplicationService = void 0;
const common_1 = require("@nestjs/common");
const redis_service_1 = require("../infrastructure/redis/redis.service");
let NotificationDeduplicationService = NotificationDeduplicationService_1 = class NotificationDeduplicationService {
    redisService;
    logger = new common_1.Logger(NotificationDeduplicationService_1.name);
    constructor(redisService) {
        this.redisService = redisService;
    }
    async shouldDeduplicate(fingerprint, ttlSeconds = 60) {
        if (!this.redisService.isHealthy()) {
            this.logger.warn(`Redis is unhealthy. Bypassing deduplication for fingerprint: ${fingerprint}`);
            return false;
        }
        const key = `notifications:dedup:${fingerprint}`;
        try {
            const client = this.redisService.getClient();
            const result = await client.set(key, '1', 'EX', ttlSeconds, 'NX');
            if (result === 'OK') {
                return false;
            }
            this.logger.log(`Deduplicated notification with fingerprint: ${fingerprint}`);
            return true;
        }
        catch (err) {
            this.logger.error(`Error in notification deduplication check for ${fingerprint}: ${err.message}`);
            return false;
        }
    }
};
exports.NotificationDeduplicationService = NotificationDeduplicationService;
exports.NotificationDeduplicationService = NotificationDeduplicationService = NotificationDeduplicationService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService])
], NotificationDeduplicationService);
//# sourceMappingURL=notification-deduplication.service.js.map