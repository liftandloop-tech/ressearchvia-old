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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var RedisService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.RedisService = exports.RedisDegradedException = exports.PlatformMode = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const ioredis_1 = __importDefault(require("ioredis"));
var PlatformMode;
(function (PlatformMode) {
    PlatformMode["NORMAL"] = "NORMAL";
    PlatformMode["REDIS_DEGRADED"] = "REDIS_DEGRADED";
})(PlatformMode || (exports.PlatformMode = PlatformMode = {}));
class RedisDegradedException extends Error {
    constructor(message = 'Redis is currently down. Write/Trading operations are suspended.') {
        super(message);
        this.name = 'RedisDegradedException';
    }
}
exports.RedisDegradedException = RedisDegradedException;
let RedisService = RedisService_1 = class RedisService {
    configService;
    logger = new common_1.Logger(RedisService_1.name);
    client;
    isConnected = false;
    mode = PlatformMode.NORMAL;
    constructor(configService) {
        this.configService = configService;
    }
    onModuleInit() {
        const host = this.configService.get('REDIS_HOST', 'localhost');
        const port = this.configService.get('REDIS_PORT', 6379);
        const username = this.configService.get('REDIS_USERNAME');
        const password = this.configService.get('REDIS_PASSWORD');
        this.logger.log(`Initializing Redis client on ${host}:${port}`);
        const redisOptions = {
            host,
            port,
            password,
            maxRetriesPerRequest: null,
            enableReadyCheck: true,
            reconnectOnError: () => true,
        };
        if (username) {
            redisOptions.username = username;
        }
        this.client = new ioredis_1.default(redisOptions);
        this.client.on('connect', () => {
            this.logger.log('Redis client connecting...');
        });
        this.client.on('ready', () => {
            this.isConnected = true;
            this.mode = PlatformMode.NORMAL;
            this.logger.log('Redis client ready. Platform mode: NORMAL');
        });
        this.client.on('error', (err) => {
            this.logger.error(`Redis connection error: ${err.message}`);
            if (this.isConnected) {
                this.isConnected = false;
                this.mode = PlatformMode.REDIS_DEGRADED;
                this.logger.error('Redis connection lost. Platform mode: REDIS_DEGRADED');
            }
        });
        this.client.on('close', () => {
            this.isConnected = false;
            this.mode = PlatformMode.REDIS_DEGRADED;
            this.logger.warn('Redis connection closed. Platform mode: REDIS_DEGRADED');
        });
        this.client.on('end', () => {
            this.isConnected = false;
            this.mode = PlatformMode.REDIS_DEGRADED;
            this.logger.warn('Redis connection ended. Platform mode: REDIS_DEGRADED');
        });
        return new Promise((resolve) => {
            const timeout = setTimeout(() => {
                this.logger.warn('Redis connection startup timeout reached (2s). Bootstrapping anyway.');
                resolve();
            }, 2000);
            this.client.once('ready', () => {
                clearTimeout(timeout);
                resolve();
            });
            this.client.once('error', () => {
                clearTimeout(timeout);
                resolve();
            });
        });
    }
    async onModuleDestroy() {
        this.logger.log('Disconnecting from Redis...');
        if (this.client) {
            await this.client.quit().catch(() => { });
        }
    }
    getClient() {
        return this.client;
    }
    isHealthy() {
        return this.isConnected;
    }
    getPlatformMode() {
        return this.mode;
    }
    assertHealthy() {
        if (!this.isHealthy() || this.mode === PlatformMode.REDIS_DEGRADED) {
            throw new RedisDegradedException();
        }
    }
};
exports.RedisService = RedisService;
exports.RedisService = RedisService = RedisService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], RedisService);
//# sourceMappingURL=redis.service.js.map