import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { ConfigService } from '@nestjs/config';
import { AuditService } from '../audit/audit.service';
export declare class AuthService {
    private readonly usersService;
    private readonly jwtService;
    private readonly configService;
    private readonly auditService;
    private otpCache;
    constructor(usersService: UsersService, jwtService: JwtService, configService: ConfigService, auditService: AuditService);
    private getPepperedSecret;
    sendOtp(mobile: string): Promise<{
        success: boolean;
        message: string;
    }>;
    verifyOtp(mobile: string, otp: string): Promise<{
        accessToken: string;
        isMpinSet: boolean;
        userId: string;
    }>;
    setupMpin(userId: string, mpin: string): Promise<{
        success: boolean;
    }>;
    loginMpin(mobile: string, mpin: string, deviceId: string, deviceName?: string, platform?: string): Promise<{
        accessToken: string;
        userId: string;
    }>;
}
