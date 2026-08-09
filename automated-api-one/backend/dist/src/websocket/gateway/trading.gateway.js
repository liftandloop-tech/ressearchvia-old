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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var TradingGateway_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.TradingGateway = void 0;
const websockets_1 = require("@nestjs/websockets");
const socket_io_1 = require("socket.io");
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const redis_service_1 = require("../../infrastructure/redis/redis.service");
const prisma_service_1 = require("../../prisma.service");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
const client_1 = require("@prisma/client");
let TradingGateway = TradingGateway_1 = class TradingGateway {
    jwtService;
    redisService;
    prisma;
    metrics;
    logger = new common_1.Logger(TradingGateway_1.name);
    server;
    constructor(jwtService, redisService, prisma, metrics) {
        this.jwtService = jwtService;
        this.redisService = redisService;
        this.prisma = prisma;
        this.metrics = metrics;
    }
    async handleConnection(socket) {
        const ip = socket.handshake.address || socket.conn.remoteAddress || 'unknown';
        const isAllowed = await this.checkConnectionRateLimit(ip);
        if (!isAllowed) {
            this.logger.warn(`Connection rejected due to rate limit: IP=${ip}`);
            socket.disconnect(true);
            return;
        }
        const token = this.extractToken(socket);
        if (!token) {
            this.logger.warn(`Authentication failed: No token provided from IP=${ip}`);
            socket.disconnect(true);
            return;
        }
        try {
            const payload = await this.jwtService.verifyAsync(token);
            socket.data = {
                userId: payload.userId || payload.sub,
                role: payload.role,
                ip,
                appVersion: socket.handshake.query.appVersion || '1.0.0',
                platform: socket.handshake.query.platform || 'web',
            };
            const userId = socket.data.userId;
            await socket.join(`user:${userId}`);
            if (socket.data.role === 'SUPERADMIN' || socket.data.role === 'ADMIN') {
                await socket.join('admin');
            }
            await this.addPresence(userId, socket.id, socket.data.appVersion, socket.data.platform);
            this.metrics.incrementWsConnections();
            this.updateMetricsGauges();
            this.logger.log(`Client connected: Socket=${socket.id} User=${userId} IP=${ip}`);
        }
        catch (err) {
            this.logger.warn(`Authentication failed for IP=${ip}: ${err.message}`);
            socket.disconnect(true);
        }
    }
    async handleDisconnect(socket) {
        const userId = socket.data?.userId;
        if (userId) {
            await this.removePresence(userId, socket.id);
            this.metrics.incrementWsDisconnects();
            this.updateMetricsGauges();
            this.logger.log(`Client disconnected: Socket=${socket.id} User=${userId}`);
        }
    }
    async handleHeartbeat(socket) {
        const userId = socket.data?.userId;
        if (userId) {
            await this.refreshPresenceTTL(userId);
            socket.emit('heartbeat_ack', { timestamp: new Date().toISOString() });
        }
    }
    async handleJoinSegment(socket, data) {
        const userId = socket.data?.userId;
        if (!userId) {
            socket.emit('error', { message: 'Unauthorized' });
            return;
        }
        const { segmentId } = data;
        const userSegment = await this.prisma.userSegment.findUnique({
            where: {
                userId_segmentId: {
                    userId,
                    segmentId,
                },
            },
        });
        if (!userSegment || userSegment.status !== client_1.UserSegmentStatus.ACTIVE) {
            this.logger.warn(`Unauthorized segment join attempt: User=${userId} Segment=${segmentId}`);
            socket.emit('error', { message: 'Unauthorized to join segment room' });
            return;
        }
        const roomName = `segment:${segmentId}`;
        await socket.join(roomName);
        this.logger.log(`User ${userId} joined room ${roomName}`);
        socket.emit('joined_segment', { segmentId });
        this.updateMetricsGauges();
    }
    extractToken(socket) {
        const authHeader = socket.handshake.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            return authHeader.split(' ')[1];
        }
        const tokenQuery = socket.handshake.query.token;
        if (tokenQuery) {
            return Array.isArray(tokenQuery) ? tokenQuery[0] : tokenQuery;
        }
        return null;
    }
    async checkConnectionRateLimit(ip) {
        if (!this.redisService.isHealthy())
            return true;
        const redisKey = `ws:ratelimit:${ip}`;
        try {
            const client = this.redisService.getClient();
            const current = await client.incr(redisKey);
            if (current === 1) {
                await client.expire(redisKey, 60);
            }
            return current <= 20;
        }
        catch (err) {
            this.logger.error(`Failed to execute rate limit check for IP ${ip}: ${err.message}`);
            return true;
        }
    }
    async addPresence(userId, socketId, appVersion, platform) {
        if (!this.redisService.isHealthy())
            return;
        const redisKey = `ws:user:${userId}`;
        try {
            const client = this.redisService.getClient();
            const existing = await client.get(redisKey);
            let presence = {
                connections: 0,
                connectedAt: new Date().toISOString(),
                lastSeen: new Date().toISOString(),
                socketIds: [],
                appVersion,
                platform,
            };
            if (existing) {
                try {
                    presence = JSON.parse(existing);
                }
                catch {
                }
            }
            presence.connections++;
            presence.lastSeen = new Date().toISOString();
            if (!presence.socketIds.includes(socketId)) {
                presence.socketIds.push(socketId);
            }
            await client.set(redisKey, JSON.stringify(presence), 'EX', 120);
        }
        catch (err) {
            this.logger.error(`Presence tracking error for User ${userId}: ${err.message}`);
        }
    }
    async removePresence(userId, socketId) {
        if (!this.redisService.isHealthy())
            return;
        const redisKey = `ws:user:${userId}`;
        try {
            const client = this.redisService.getClient();
            const existing = await client.get(redisKey);
            if (!existing)
                return;
            const presence = JSON.parse(existing);
            presence.connections = Math.max(0, presence.connections - 1);
            presence.socketIds = presence.socketIds.filter((id) => id !== socketId);
            presence.lastSeen = new Date().toISOString();
            if (presence.connections === 0 || presence.socketIds.length === 0) {
                await client.del(redisKey);
            }
            else {
                await client.set(redisKey, JSON.stringify(presence), 'EX', 120);
            }
        }
        catch (err) {
            this.logger.error(`Presence removal error for User ${userId}: ${err.message}`);
        }
    }
    async refreshPresenceTTL(userId) {
        if (!this.redisService.isHealthy())
            return;
        const redisKey = `ws:user:${userId}`;
        try {
            const client = this.redisService.getClient();
            const existing = await client.get(redisKey);
            if (existing) {
                const presence = JSON.parse(existing);
                presence.lastSeen = new Date().toISOString();
                await client.set(redisKey, JSON.stringify(presence), 'EX', 120);
            }
        }
        catch (err) {
            this.logger.error(`Presence refresh error for User ${userId}: ${err.message}`);
        }
    }
    updateMetricsGauges() {
        try {
            const adapter = this.server?.sockets?.adapter;
            if (!adapter)
                return;
            const roomMap = adapter.rooms;
            let userCount = 0;
            let segmentCount = 0;
            let adminCount = 0;
            for (const [roomName, socketsSet] of roomMap.entries()) {
                if (roomName.startsWith('user:')) {
                    userCount++;
                }
                else if (roomName.startsWith('segment:')) {
                    segmentCount++;
                }
                else if (roomName === 'admin') {
                    adminCount = socketsSet.size;
                }
            }
            const activeConns = this.server?.engine?.clientsCount || 0;
            this.metrics.setWsActiveConnections(activeConns);
            this.metrics.setWsRoomUsers(userCount);
            this.metrics.setWsRoomSegments(segmentCount);
            this.metrics.setWsRoomAdmin(adminCount);
        }
        catch (err) {
            this.logger.error(`Failed to update socket room gauges: ${err.message}`);
        }
    }
};
exports.TradingGateway = TradingGateway;
__decorate([
    (0, websockets_1.WebSocketServer)(),
    __metadata("design:type", socket_io_1.Server)
], TradingGateway.prototype, "server", void 0);
__decorate([
    (0, websockets_1.SubscribeMessage)('heartbeat'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket]),
    __metadata("design:returntype", Promise)
], TradingGateway.prototype, "handleHeartbeat", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('join_segment'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], TradingGateway.prototype, "handleJoinSegment", null);
exports.TradingGateway = TradingGateway = TradingGateway_1 = __decorate([
    (0, websockets_1.WebSocketGateway)({
        cors: {
            origin: '*',
        },
    }),
    __metadata("design:paramtypes", [jwt_1.JwtService,
        redis_service_1.RedisService,
        prisma_service_1.PrismaService,
        metrics_service_1.MetricsService])
], TradingGateway);
//# sourceMappingURL=trading.gateway.js.map