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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BrokersController = exports.AuthorizeBrokerDto = exports.LinkBrokerDto = void 0;
const common_1 = require("@nestjs/common");
const crypto = __importStar(require("crypto"));
const consents_service_1 = require("../consents/consents.service");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const broker_factory_1 = require("./factory/broker.factory");
const broker_session_service_1 = require("./services/broker-session.service");
const prisma_service_1 = require("../prisma.service");
const redis_service_1 = require("../infrastructure/redis/redis.service");
const class_validator_1 = require("class-validator");
const client_1 = require("@prisma/client");
class LinkBrokerDto {
    brokerCode;
    brokerClientId;
    apiKey;
    apiSecret;
    vendorCode;
}
exports.LinkBrokerDto = LinkBrokerDto;
__decorate([
    (0, class_validator_1.IsEnum)(client_1.BrokerCode),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], LinkBrokerDto.prototype, "brokerCode", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], LinkBrokerDto.prototype, "brokerClientId", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], LinkBrokerDto.prototype, "apiKey", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], LinkBrokerDto.prototype, "apiSecret", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], LinkBrokerDto.prototype, "vendorCode", void 0);
class AuthorizeBrokerDto {
    brokerCode;
    mpin;
    totpKey;
}
exports.AuthorizeBrokerDto = AuthorizeBrokerDto;
__decorate([
    (0, class_validator_1.IsEnum)(client_1.BrokerCode),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], AuthorizeBrokerDto.prototype, "brokerCode", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], AuthorizeBrokerDto.prototype, "mpin", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], AuthorizeBrokerDto.prototype, "totpKey", void 0);
let BrokersController = class BrokersController {
    prisma;
    brokerFactory;
    brokerSessionService;
    redisService;
    constructor(prisma, brokerFactory, brokerSessionService, redisService) {
        this.prisma = prisma;
        this.brokerFactory = brokerFactory;
        this.brokerSessionService = brokerSessionService;
        this.redisService = redisService;
    }
    async linkBroker(req, dto) {
        const userId = req.user.userId;
        let broker = await this.prisma.broker.findFirst({
            where: { code: dto.brokerCode },
        });
        if (!broker) {
            broker = await this.prisma.broker.create({
                data: {
                    code: dto.brokerCode,
                    name: dto.brokerCode.replace('_', ' '),
                    status: client_1.BrokerStatus.ACTIVE,
                },
            });
        }
        const existing = await this.prisma.userBroker.findFirst({
            where: {
                userId,
                brokerId: broker.id,
                deletedAt: { not: undefined },
            },
        });
        if (existing) {
            const updated = await this.prisma.userBroker.update({
                where: { id: existing.id },
                data: {
                    brokerClientId: dto.brokerClientId,
                    apiKey: dto.apiKey ?? existing.apiKey,
                    apiSecret: dto.apiSecret ?? existing.apiSecret,
                    vendorCode: dto.vendorCode ?? existing.vendorCode,
                    status: client_1.BrokerStatus.ACTIVE,
                    deletedAt: null,
                },
            });
            return updated;
        }
        const created = await this.prisma.userBroker.create({
            data: {
                userId,
                brokerId: broker.id,
                brokerClientId: dto.brokerClientId,
                apiKey: dto.apiKey ?? null,
                apiSecret: dto.apiSecret ?? null,
                vendorCode: dto.vendorCode ?? null,
                status: client_1.BrokerStatus.ACTIVE,
            },
        });
        return created;
    }
    async authorizeBroker(req, dto) {
        const userId = req.user.userId;
        const broker = await this.prisma.broker.findFirst({
            where: { code: dto.brokerCode },
        });
        if (!broker) {
            throw new common_1.BadRequestException('Broker type not registered on platform');
        }
        const userBroker = await this.prisma.userBroker.findFirst({
            where: {
                userId,
                brokerId: broker.id,
            },
        });
        if (!userBroker) {
            throw new common_1.BadRequestException('Please link your broker account details first');
        }
        const brokerType = dto.brokerCode;
        const adapter = this.brokerFactory.getAdapter(brokerType);
        const session = await adapter.generateSession({
            clientCode: userBroker.brokerClientId,
            password: dto.mpin,
            totpKey: dto.totpKey,
            apiKey: userBroker.apiKey ?? undefined,
            vendorCode: userBroker.vendorCode ?? undefined,
        });
        await this.brokerSessionService.storeSession(userId, dto.brokerCode, session, userBroker.id);
        return {
            success: true,
            message: 'Broker daily session authorization completed',
            expiry: session.tokenExpiry,
        };
    }
    async getBrokerStatus(req) {
        const userId = req.user.userId;
        const linkedBrokers = await this.prisma.userBroker.findMany({
            where: { userId },
            include: { broker: true },
        });
        const statusList = await Promise.all(linkedBrokers.map(async (ub) => {
            let isSessionActive = false;
            let availableMargin = 0;
            let profile = null;
            isSessionActive = await this.brokerSessionService.validateSession(userId, ub.broker.code);
            if (isSessionActive && ub.accessToken) {
                const brokerType = ub.broker.code;
                try {
                    const adapter = this.brokerFactory.getAdapter(brokerType);
                    availableMargin = await adapter.getMargin(ub.accessToken, ub.brokerClientId);
                    profile = await adapter.getProfile(ub.accessToken, ub.brokerClientId);
                }
                catch (err) {
                }
            }
            return {
                brokerCode: ub.broker.code,
                brokerClientId: ub.brokerClientId,
                isSessionActive,
                availableMargin,
                profile,
                linkedAt: ub.createdAt,
            };
        }));
        return statusList;
    }
    async listBrokers(req) {
        const userId = req.user.userId;
        const linkedUserBrokers = await this.prisma.userBroker.findMany({
            where: { userId },
            include: { broker: true },
        });
        const results = [];
        const allBrokerCodes = Object.values(client_1.BrokerCode);
        for (const code of allBrokerCodes) {
            const matched = linkedUserBrokers.find((ub) => ub.broker.code === code);
            let isSessionActive = false;
            if (matched) {
                isSessionActive = await this.brokerSessionService.validateSession(userId, code);
            }
            results.push({
                broker: code,
                status: matched
                    ? (isSessionActive ? 'CONNECTED' : 'EXPIRED')
                    : 'NOT_CONNECTED',
            });
        }
        return results;
    }
    async getAuthUrl(req, brokerCodeStr) {
        const userId = req.user.userId;
        const brokerCode = brokerCodeStr.toUpperCase();
        if (!Object.values(client_1.BrokerCode).includes(brokerCode)) {
            throw new common_1.BadRequestException('Invalid broker code');
        }
        const state = crypto.randomUUID();
        const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
        await this.prisma.brokerAuthState.create({
            data: {
                userId,
                broker: brokerCode,
                state,
                expiresAt,
            },
        });
        try {
            const brokerType = brokerCode;
            const adapter = this.brokerFactory.getAdapter(brokerType);
            const authUrl = await adapter.getAuthorizationUrl(state);
            return { authUrl };
        }
        catch (error) {
            await this.prisma.brokerAuthState.deleteMany({
                where: { broker: brokerCode, state },
            });
            throw new common_1.BadRequestException(`Failed to generate authorization URL: ${error.message}`);
        }
    }
    async handleCallback(brokerCodeStr, queryParams, res) {
        const brokerCode = brokerCodeStr.toUpperCase();
        if (!Object.values(client_1.BrokerCode).includes(brokerCode)) {
            return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=Invalid+broker+code`);
        }
        const state = queryParams.state;
        if (!state) {
            return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=Missing+state+parameter`);
        }
        const dbState = await this.prisma.brokerAuthState.findFirst({
            where: { broker: brokerCode, state },
        });
        if (!dbState) {
            return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=Invalid+or+expired+session`);
        }
        await this.prisma.brokerAuthState.delete({
            where: { id: dbState.id },
        });
        if (new Date() > dbState.expiresAt) {
            return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=Session+expired`);
        }
        try {
            const brokerType = brokerCode;
            const adapter = this.brokerFactory.getAdapter(brokerType);
            const session = await adapter.completeAuthorization({ params: queryParams });
            let broker = await this.prisma.broker.findFirst({
                where: { code: brokerCode },
            });
            if (!broker) {
                broker = await this.prisma.broker.create({
                    data: {
                        code: brokerCode,
                        name: brokerCode.replace('_', ' '),
                        status: client_1.BrokerStatus.ACTIVE,
                    },
                });
            }
            let userBroker = await this.prisma.baseClient.userBroker.findFirst({
                where: {
                    userId: dbState.userId,
                    brokerId: broker.id,
                },
            });
            const brokerClientId = session.brokerUserId || 'UNKNOWN';
            if (userBroker) {
                userBroker = await this.prisma.baseClient.userBroker.update({
                    where: { id: userBroker.id },
                    data: {
                        brokerClientId: brokerClientId !== 'UNKNOWN' ? brokerClientId : userBroker.brokerClientId,
                        status: client_1.BrokerStatus.ACTIVE,
                        deletedAt: null,
                    },
                });
            }
            else {
                userBroker = await this.prisma.baseClient.userBroker.create({
                    data: {
                        userId: dbState.userId,
                        brokerId: broker.id,
                        brokerClientId,
                        status: client_1.BrokerStatus.ACTIVE,
                    },
                });
            }
            await this.brokerSessionService.storeSession(dbState.userId, brokerCode, {
                accessToken: session.accessToken,
                refreshToken: session.refreshToken,
                tokenExpiry: session.expiresAt || new Date(Date.now() + 18 * 60 * 60 * 1000),
            }, userBroker.id);
            return res.redirect(`/brokers/${brokerCodeStr}/callback/success`);
        }
        catch (error) {
            return res.redirect(`/brokers/${brokerCodeStr}/callback/failure?error=${encodeURIComponent(error.message)}`);
        }
    }
    async showSuccessPage(brokerCode, res) {
        res.setHeader('Content-Type', 'text/html');
        return res.status(200).send(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Authorization Successful</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&display=swap" rel="stylesheet">
          <style>
            body {
              font-family: 'Poppins', sans-serif;
              background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
              color: #f8fafc;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              margin: 0;
            }
            .card {
              background: rgba(30, 41, 59, 0.7);
              backdrop-filter: blur(16px);
              border: 1px solid rgba(255, 255, 255, 0.08);
              padding: 40px 30px;
              border-radius: 24px;
              text-align: center;
              box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
              max-width: 400px;
              width: 90%;
            }
            .icon {
              font-size: 64px;
              margin-bottom: 20px;
              color: #10b981;
            }
            h1 {
              font-size: 24px;
              font-weight: 700;
              margin: 0 0 10px 0;
            }
            p {
              color: #94a3b8;
              font-size: 15px;
              line-height: 1.5;
              margin: 0;
            }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="icon">✓</div>
            <h1>Connected!</h1>
            <p>${brokerCode.replace('_', ' ')} has been connected successfully. You can close this window now.</p>
          </div>
        </body>
      </html>
    `);
    }
    async showFailurePage(brokerCode, errorMsg, res) {
        res.setHeader('Content-Type', 'text/html');
        return res.status(200).send(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Authorization Failed</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&display=swap" rel="stylesheet">
          <style>
            body {
              font-family: 'Poppins', sans-serif;
              background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
              color: #f8fafc;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              margin: 0;
            }
            .card {
              background: rgba(30, 41, 59, 0.7);
              backdrop-filter: blur(16px);
              border: 1px solid rgba(255, 255, 255, 0.08);
              padding: 40px 30px;
              border-radius: 24px;
              text-align: center;
              box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
              max-width: 400px;
              width: 90%;
            }
            .icon {
              font-size: 64px;
              margin-bottom: 20px;
              color: #ef4444;
            }
            h1 {
              font-size: 24px;
              font-weight: 700;
              margin: 0 0 10px 0;
            }
            p {
              color: #94a3b8;
              font-size: 15px;
              line-height: 1.5;
              margin: 0;
            }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="icon">✗</div>
            <h1>Connection Failed</h1>
            <p>${errorMsg || 'An unknown error occurred during authorization.'}</p>
          </div>
        </body>
      </html>
    `);
    }
    async unlinkBroker(req, brokerCodeStr) {
        const userId = req.user.userId;
        const brokerCode = brokerCodeStr.toUpperCase();
        const broker = await this.prisma.broker.findFirst({
            where: { code: brokerCode },
        });
        if (!broker) {
            throw new common_1.BadRequestException('Broker type not registered on platform');
        }
        const existing = await this.prisma.userBroker.findFirst({
            where: {
                userId,
                brokerId: broker.id,
            },
        });
        if (!existing) {
            throw new common_1.BadRequestException('No broker connection found to unlink');
        }
        await this.prisma.userBroker.delete({
            where: { id: existing.id },
        });
        const todayStr = (0, consents_service_1.getTodayISTString)();
        const todayDate = new Date(`${todayStr}T00:00:00.000Z`);
        await this.prisma.consent.deleteMany({
            where: {
                userId,
                brokerId: broker.id,
                consentDate: todayDate,
            },
        });
        return {
            success: true,
            message: 'Broker details and session disconnected successfully',
        };
    }
    async getActiveBroker(userId) {
        const linkedBrokers = await this.prisma.userBroker.findMany({
            where: { userId },
            include: { broker: true },
        });
        for (const ub of linkedBrokers) {
            const isSessionActive = await this.brokerSessionService.validateSession(userId, ub.broker.code);
            if (isSessionActive && ub.accessToken) {
                return { ub, code: ub.broker.code };
            }
        }
        throw new common_1.BadRequestException('No active broker session found');
    }
    async getLivePositions(req) {
        const userId = req.user.userId;
        const cacheKey = `live:positions:${userId}`;
        try {
            const cached = await this.redisService.getClient().get(cacheKey);
            if (cached)
                return JSON.parse(cached);
        }
        catch (_) { }
        const { ub, code } = await this.getActiveBroker(userId);
        const adapter = this.brokerFactory.getAdapter(code);
        const result = await adapter.getPositions(ub.accessToken, ub.brokerClientId);
        try {
            await this.redisService.getClient().set(cacheKey, JSON.stringify(result), 'EX', 3);
        }
        catch (_) { }
        return result;
    }
    async getLiveHoldings(req) {
        const userId = req.user.userId;
        const cacheKey = `live:holdings:${userId}`;
        try {
            const cached = await this.redisService.getClient().get(cacheKey);
            if (cached)
                return JSON.parse(cached);
        }
        catch (_) { }
        const { ub, code } = await this.getActiveBroker(userId);
        const adapter = this.brokerFactory.getAdapter(code);
        const result = await adapter.getHoldings(ub.accessToken, ub.brokerClientId);
        try {
            await this.redisService.getClient().set(cacheKey, JSON.stringify(result), 'EX', 5);
        }
        catch (_) { }
        return result;
    }
    async getLiveOrders(req) {
        const userId = req.user.userId;
        const cacheKey = `live:orders:${userId}`;
        try {
            const cached = await this.redisService.getClient().get(cacheKey);
            if (cached)
                return JSON.parse(cached);
        }
        catch (_) { }
        const { ub, code } = await this.getActiveBroker(userId);
        const adapter = this.brokerFactory.getAdapter(code);
        const result = await adapter.getOrders(ub.accessToken, ub.brokerClientId);
        try {
            await this.redisService.getClient().set(cacheKey, JSON.stringify(result), 'EX', 3);
        }
        catch (_) { }
        return result;
    }
    async getLiveTrades(req) {
        const userId = req.user.userId;
        const cacheKey = `live:trades:${userId}`;
        try {
            const cached = await this.redisService.getClient().get(cacheKey);
            if (cached)
                return JSON.parse(cached);
        }
        catch (_) { }
        const { ub, code } = await this.getActiveBroker(userId);
        const adapter = this.brokerFactory.getAdapter(code);
        const result = await adapter.getTradeBook(ub.accessToken, ub.brokerClientId);
        try {
            await this.redisService.getClient().set(cacheKey, JSON.stringify(result), 'EX', 3);
        }
        catch (_) { }
        return result;
    }
};
exports.BrokersController = BrokersController;
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('link'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, LinkBrokerDto]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "linkBroker", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Post)('authorize'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, AuthorizeBrokerDto]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "authorizeBroker", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('status'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "getBrokerStatus", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('/'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "listBrokers", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)(':brokerCode/auth-url'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('brokerCode')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "getAuthUrl", null);
__decorate([
    (0, common_1.Get)(':brokerCode/callback'),
    __param(0, (0, common_1.Param)('brokerCode')),
    __param(1, (0, common_1.Query)()),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "handleCallback", null);
__decorate([
    (0, common_1.Get)(':brokerCode/callback/success'),
    __param(0, (0, common_1.Param)('brokerCode')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "showSuccessPage", null);
__decorate([
    (0, common_1.Get)(':brokerCode/callback/failure'),
    __param(0, (0, common_1.Param)('brokerCode')),
    __param(1, (0, common_1.Query)('error')),
    __param(2, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "showFailurePage", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Delete)(':brokerCode/unlink'),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('brokerCode')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "unlinkBroker", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('live/positions'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "getLivePositions", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('live/holdings'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "getLiveHoldings", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('live/orders'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "getLiveOrders", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('live/trades'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], BrokersController.prototype, "getLiveTrades", null);
exports.BrokersController = BrokersController = __decorate([
    (0, common_1.Controller)('brokers'),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        broker_factory_1.BrokerFactory,
        broker_session_service_1.BrokerSessionService,
        redis_service_1.RedisService])
], BrokersController);
//# sourceMappingURL=brokers.controller.js.map