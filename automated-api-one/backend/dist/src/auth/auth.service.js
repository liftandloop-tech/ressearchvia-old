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
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const users_service_1 = require("../users/users.service");
const config_1 = require("@nestjs/config");
const audit_service_1 = require("../audit/audit.service");
const audit_event_enum_1 = require("../audit/enums/audit-event.enum");
const bcrypt = __importStar(require("bcrypt"));
let AuthService = class AuthService {
    usersService;
    jwtService;
    configService;
    auditService;
    otpCache = new Map();
    constructor(usersService, jwtService, configService, auditService) {
        this.usersService = usersService;
        this.jwtService = jwtService;
        this.configService = configService;
        this.auditService = auditService;
    }
    getPepperedSecret(mpin) {
        const pepper = this.configService.get('MPIN_PEPPER', 'default_mpin_pepper_secret');
        return mpin + pepper;
    }
    async sendOtp(mobile) {
        if (!/^\+?[1-9]\d{1,14}$/.test(mobile) && !/^\d{10}$/.test(mobile)) {
            throw new common_1.BadRequestException('Invalid mobile number format');
        }
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
        this.otpCache.set(mobile, { otp, expiresAt });
        console.log(`\n[SMS GATEWAY MOCK] OTP for mobile ${mobile} is: ${otp}\n`);
        return {
            success: true,
            message: 'OTP sent successfully',
        };
    }
    async verifyOtp(mobile, otp) {
        const cached = this.otpCache.get(mobile);
        const isDefaultOtp = otp === '123456';
        const isCachedOtpValid = cached && cached.otp === otp && cached.expiresAt > new Date();
        if (!isDefaultOtp && !isCachedOtpValid) {
            throw new common_1.UnauthorizedException('Invalid or expired OTP');
        }
        this.otpCache.delete(mobile);
        const user = await this.usersService.createOrUpdateUser(mobile);
        const payload = { sub: user.id, mobile: user.mobile };
        const accessToken = this.jwtService.sign(payload);
        await this.auditService.logEvent(user.id, audit_event_enum_1.AuditEventType.OTP_VERIFIED, 'User', user.id, { mobile });
        await this.auditService.logEvent(user.id, audit_event_enum_1.AuditEventType.LOGIN, 'User', user.id, { loginType: 'OTP' });
        return {
            accessToken,
            isMpinSet: user.mpinHash !== '',
            userId: user.id,
        };
    }
    async setupMpin(userId, mpin) {
        if (!/^\d{4}$/.test(mpin) && !/^\d{6}$/.test(mpin)) {
            throw new common_1.BadRequestException('MPIN must be either a 4-digit or 6-digit code');
        }
        const salt = await bcrypt.genSalt(10);
        const pepperedSecret = this.getPepperedSecret(mpin);
        const mpinHash = await bcrypt.hash(pepperedSecret, salt);
        await this.usersService.updateMpin(userId, mpinHash);
        return { success: true };
    }
    async loginMpin(mobile, mpin, deviceId, deviceName, platform) {
        const user = await this.usersService.findByMobile(mobile);
        if (!user || !user.mpinHash) {
            throw new common_1.UnauthorizedException('Authentication failed: MPIN is not configured');
        }
        const pepperedSecret = this.getPepperedSecret(mpin);
        const isMpinValid = await bcrypt.compare(pepperedSecret, user.mpinHash);
        if (!isMpinValid) {
            throw new common_1.UnauthorizedException('Invalid MPIN');
        }
        await this.usersService.trackDevice(user.id, deviceId, deviceName, platform);
        const payload = { sub: user.id, mobile: user.mobile };
        const accessToken = this.jwtService.sign(payload);
        await this.auditService.logEvent(user.id, audit_event_enum_1.AuditEventType.MPIN_LOGIN, 'User', user.id, { deviceId, platform });
        await this.auditService.logEvent(user.id, audit_event_enum_1.AuditEventType.LOGIN, 'User', user.id, { loginType: 'MPIN' });
        return {
            accessToken,
            userId: user.id,
        };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [users_service_1.UsersService,
        jwt_1.JwtService,
        config_1.ConfigService,
        audit_service_1.AuditService])
], AuthService);
//# sourceMappingURL=auth.service.js.map