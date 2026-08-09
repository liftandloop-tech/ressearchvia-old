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
exports.JwtStrategy = void 0;
const common_1 = require("@nestjs/common");
const passport_1 = require("@nestjs/passport");
const passport_jwt_1 = require("passport-jwt");
const config_1 = require("@nestjs/config");
const users_service_1 = require("../users/users.service");
const prisma_service_1 = require("../prisma.service");
let JwtStrategy = class JwtStrategy extends (0, passport_1.PassportStrategy)(passport_jwt_1.Strategy) {
    configService;
    usersService;
    prisma;
    constructor(configService, usersService, prisma) {
        super({
            jwtFromRequest: passport_jwt_1.ExtractJwt.fromAuthHeaderAsBearerToken(),
            ignoreExpiration: false,
            secretOrKey: configService.get('JWT_SECRET', 'super_secret_trading_platform_key'),
        });
        this.configService = configService;
        this.usersService = usersService;
        this.prisma = prisma;
    }
    async validate(payload) {
        console.log('JWT Strategy Payload:', payload);
        const userId = payload.sub || payload._id;
        let mobile = payload.mobile || payload.phone;
        const userType = payload.userType;
        const isAdminType = userType && ['super_admin', 'admin', 'researcher'].includes(String(userType).toLowerCase());
        if (!mobile && isAdminType) {
            mobile = '0000000000';
        }
        if (!userId && !mobile) {
            throw new common_1.UnauthorizedException('Token payload does not contain a valid user ID or mobile number');
        }
        const isUuid = userId && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);
        if (isUuid) {
            const admin = await this.prisma.adminUser.findUnique({
                where: { id: userId },
            });
            if (admin) {
                if (admin.status !== 'ACTIVE') {
                    throw new common_1.UnauthorizedException('Admin account inactive');
                }
                return {
                    userId: admin.id,
                    email: admin.email,
                    role: admin.role,
                    isAdmin: true,
                };
            }
            const user = await this.usersService.findById(userId);
            if (user) {
                if (user.status === 'SUSPENDED' || user.status === 'DELETED') {
                    throw new common_1.UnauthorizedException('User account inactive');
                }
                return {
                    userId: user.id,
                    mobile: user.mobile,
                    role: 'USER',
                    isAdmin: false,
                };
            }
        }
        if (mobile) {
            const mobileStr = typeof mobile === 'string' ? mobile : String(mobile);
            const cleanMobile = mobileStr.replace(/\D/g, '').slice(-10);
            const user = await this.usersService.createOrUpdateUser(cleanMobile);
            if (user.status === 'SUSPENDED' || user.status === 'DELETED') {
                throw new common_1.UnauthorizedException('User account inactive');
            }
            return {
                userId: user.id,
                mobile: user.mobile,
                role: isAdminType ? 'SUPERADMIN' : 'USER',
                isAdmin: isAdminType ? true : false,
            };
        }
        throw new common_1.UnauthorizedException('Token payload does not contain a valid user ID or mobile number');
    }
};
exports.JwtStrategy = JwtStrategy;
exports.JwtStrategy = JwtStrategy = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService,
        users_service_1.UsersService,
        prisma_service_1.PrismaService])
], JwtStrategy);
//# sourceMappingURL=jwt.strategy.js.map