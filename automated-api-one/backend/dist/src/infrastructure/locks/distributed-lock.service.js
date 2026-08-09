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
var DistributedLockService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.DistributedLockService = void 0;
const common_1 = require("@nestjs/common");
const redis_service_1 = require("../redis/redis.service");
const crypto = __importStar(require("crypto"));
let DistributedLockService = DistributedLockService_1 = class DistributedLockService {
    redisService;
    logger = new common_1.Logger(DistributedLockService_1.name);
    activeRenewals = new Map();
    constructor(redisService) {
        this.redisService = redisService;
    }
    onModuleDestroy() {
        for (const timer of this.activeRenewals.values()) {
            clearInterval(timer);
        }
        this.activeRenewals.clear();
    }
    async acquireLock(key, ttlMs, options) {
        this.redisService.assertHealthy();
        const token = crypto.randomUUID();
        try {
            const result = await this.redisService.getClient().set(key, token, 'PX', ttlMs, 'NX');
            if (result === 'OK') {
                if (options?.autoRenew) {
                    this.startHeartbeat(key, token, ttlMs);
                }
                return token;
            }
            return null;
        }
        catch (err) {
            this.logger.error(`Failed to acquire lock for key: ${key}. Error: ${err.message}`);
            throw err;
        }
    }
    async releaseLock(key, token) {
        this.redisService.assertHealthy();
        this.stopHeartbeat(key);
        const script = `
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
      else
        return 0
      end
    `;
        try {
            const result = await this.redisService.getClient().eval(script, 1, key, token);
            return result === 1;
        }
        catch (err) {
            this.logger.error(`Failed to release lock for key: ${key}. Error: ${err.message}`);
            throw err;
        }
    }
    async extendLock(key, token, ttlMs) {
        this.redisService.assertHealthy();
        const script = `
      if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("pexpire", KEYS[1], ARGV[2])
      else
        return 0
      end
    `;
        try {
            const result = await this.redisService.getClient().eval(script, 1, key, token, ttlMs);
            return result === 1;
        }
        catch (err) {
            this.logger.error(`Failed to extend lock for key: ${key}. Error: ${err.message}`);
            return false;
        }
    }
    startHeartbeat(key, token, ttlMs) {
        this.stopHeartbeat(key);
        const intervalMs = Math.max(100, Math.floor(ttlMs / 3));
        const timer = setInterval(async () => {
            try {
                const extended = await this.extendLock(key, token, ttlMs);
                if (!extended) {
                    this.logger.warn(`Failed to renew heartbeat lock for ${key}. Clearing timer.`);
                    this.stopHeartbeat(key);
                }
            }
            catch (err) {
                this.logger.error(`Heartbeat renewal failed for ${key}: ${err.message}`);
                this.stopHeartbeat(key);
            }
        }, intervalMs);
        this.activeRenewals.set(key, timer);
    }
    stopHeartbeat(key) {
        const timer = this.activeRenewals.get(key);
        if (timer) {
            clearInterval(timer);
            this.activeRenewals.delete(key);
        }
    }
};
exports.DistributedLockService = DistributedLockService;
exports.DistributedLockService = DistributedLockService = DistributedLockService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [redis_service_1.RedisService])
], DistributedLockService);
//# sourceMappingURL=distributed-lock.service.js.map