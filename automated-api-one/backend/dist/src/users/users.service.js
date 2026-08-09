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
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const client_1 = require("@prisma/client");
let UsersService = class UsersService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findByMobile(mobile) {
        return this.prisma.user.findFirst({
            where: {
                mobile,
                deletedAt: null,
            },
        });
    }
    async findById(id) {
        return this.prisma.user.findUnique({
            where: { id },
        });
    }
    async createOrUpdateUser(mobile) {
        const existing = await this.findByMobile(mobile);
        if (existing) {
            return existing;
        }
        const user = await this.prisma.user.create({
            data: {
                mobile,
                mpinHash: '',
                status: client_1.UserStatus.ACTIVE,
            },
        });
        await this.prisma.subscription.create({
            data: {
                userId: user.id,
                planId: '22222222-e29b-41d4-a716-446655440002',
                startDate: new Date(Date.now() - 24 * 60 * 60 * 1000),
                endDate: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
                status: client_1.SubscriptionStatus.ACTIVE,
            },
        });
        return user;
    }
    async updateMpin(userId, mpinHash) {
        return this.prisma.user.update({
            where: { id: userId },
            data: { mpinHash },
        });
    }
    async findDevice(userId, deviceId) {
        return this.prisma.userDevice.findFirst({
            where: {
                userId,
                deviceId,
            },
        });
    }
    async trackDevice(userId, deviceId, deviceName, platform) {
        const existing = await this.findDevice(userId, deviceId);
        if (existing) {
            return this.prisma.userDevice.update({
                where: { id: existing.id },
                data: {
                    lastLoginAt: new Date(),
                    deviceName,
                    platform,
                },
            });
        }
        return this.prisma.userDevice.create({
            data: {
                userId,
                deviceId,
                deviceName,
                platform,
            },
        });
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], UsersService);
//# sourceMappingURL=users.service.js.map