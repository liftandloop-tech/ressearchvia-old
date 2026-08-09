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
var WebsocketService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.WebsocketService = void 0;
const common_1 = require("@nestjs/common");
const trading_gateway_1 = require("../gateway/trading.gateway");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
const ADMIN_EVENT_WHITELIST = [
    'dlq.job.failed',
    'redis.down',
    'broker.circuit.open',
    'queue.backpressure',
    'segment.risk.locked',
];
let WebsocketService = WebsocketService_1 = class WebsocketService {
    gateway;
    redisService;
    metrics;
    logger = new common_1.Logger(WebsocketService_1.name);
    constructor(gateway, redisService, metrics) {
        this.gateway = gateway;
        this.redisService = redisService;
        this.metrics = metrics;
    }
    async broadcast(eventId, event, room, payload) {
        if (room === 'admin' && !ADMIN_EVENT_WHITELIST.includes(event)) {
            this.logger.error(`Security violation: Rejected non-whitelisted admin room event "${event}"`);
            this.metrics.incrementWsMessagesFailed();
            return false;
        }
        const isUnique = await this.acquireEventLock(eventId);
        if (!isUnique) {
            this.logger.warn(`Websocket event ${eventId} already broadcasted (idempotency skip)`);
            return false;
        }
        try {
            const envelope = {
                version: 1,
                event,
                timestamp: new Date().toISOString(),
                payload,
            };
            this.gateway.server.to(room).emit(event, envelope);
            this.metrics.incrementWsMessagesSent();
            this.logger.debug(`Broadcasted event ${event} to room ${room} (eventId=${eventId})`);
            return true;
        }
        catch (err) {
            this.logger.error(`Failed to broadcast event ${event} to room ${room}: ${err.message}`);
            this.metrics.incrementWsMessagesFailed();
            return false;
        }
    }
    async acquireEventLock(eventId) {
        if (!this.redisService.isHealthy())
            return true;
        const redisKey = `ws:event:${eventId}`;
        try {
            const client = this.redisService.getClient();
            const isNew = await client.set(redisKey, '1', 'EX', 86400, 'NX');
            return isNew === 'OK' || isNew === true || isNew === 1;
        }
        catch (err) {
            this.logger.error(`Idempotency check failed for WebSocket event ${eventId}: ${err.message}`);
            return true;
        }
    }
};
exports.WebsocketService = WebsocketService;
exports.WebsocketService = WebsocketService = WebsocketService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [trading_gateway_1.TradingGateway,
        redis_service_1.RedisService,
        metrics_service_1.MetricsService])
], WebsocketService);
//# sourceMappingURL=websocket.service.js.map