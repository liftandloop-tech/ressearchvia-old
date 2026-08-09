import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { ConfigService } from '@nestjs/config';
import { AuditService } from '../audit/audit.service';
import { AuditEventType } from '../audit/enums/audit-event.enum';
import * as bcrypt from 'bcrypt';

interface OtpData {
  otp: string;
  expiresAt: Date;
}

@Injectable()
export class AuthService {
  // Simple in-memory cache for OTPs during development
  private otpCache = new Map<string, OtpData>();

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly auditService: AuditService,
  ) {}

  private getPepperedSecret(mpin: string): string {
    const pepper = this.configService.get<string>(
      'MPIN_PEPPER',
      'default_mpin_pepper_secret',
    );
    return mpin + pepper;
  }

  async sendOtp(
    mobile: string,
  ): Promise<{ success: boolean; message: string }> {
    // Basic phone validation check
    if (!/^\+?[1-9]\d{1,14}$/.test(mobile) && !/^\d{10}$/.test(mobile)) {
      throw new BadRequestException('Invalid mobile number format');
    }

    // Generate a 6-digit random OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes validity

    this.otpCache.set(mobile, { otp, expiresAt });

    // Print to console for development verification
    console.log(`\n[SMS GATEWAY MOCK] OTP for mobile ${mobile} is: ${otp}\n`);

    return {
      success: true,
      message: 'OTP sent successfully',
    };
  }

  async verifyOtp(
    mobile: string,
    otp: string,
  ): Promise<{ accessToken: string; isMpinSet: boolean; userId: string }> {
    const cached = this.otpCache.get(mobile);

    // Development backdoor: default to "123456" for convenience
    const isDefaultOtp = otp === '123456';
    const isCachedOtpValid =
      cached && cached.otp === otp && cached.expiresAt > new Date();

    if (!isDefaultOtp && !isCachedOtpValid) {
      throw new UnauthorizedException('Invalid or expired OTP');
    }

    // Clear OTP from cache
    this.otpCache.delete(mobile);

    // Fetch or create user
    const user = await this.usersService.createOrUpdateUser(mobile);
    const payload = { sub: user.id, mobile: user.mobile };
    const accessToken = this.jwtService.sign(payload);

    // Audit logs
    await this.auditService.logEvent(
      user.id,
      AuditEventType.OTP_VERIFIED,
      'User',
      user.id,
      { mobile },
    );
    await this.auditService.logEvent(
      user.id,
      AuditEventType.LOGIN,
      'User',
      user.id,
      { loginType: 'OTP' },
    );

    return {
      accessToken,
      isMpinSet: user.mpinHash !== '',
      userId: user.id,
    };
  }

  async setupMpin(userId: string, mpin: string): Promise<{ success: boolean }> {
    if (!/^\d{4}$/.test(mpin) && !/^\d{6}$/.test(mpin)) {
      throw new BadRequestException(
        'MPIN must be either a 4-digit or 6-digit code',
      );
    }

    const salt = await bcrypt.genSalt(10);
    const pepperedSecret = this.getPepperedSecret(mpin);
    const mpinHash = await bcrypt.hash(pepperedSecret, salt);

    await this.usersService.updateMpin(userId, mpinHash);
    return { success: true };
  }

  async loginMpin(
    mobile: string,
    mpin: string,
    deviceId: string,
    deviceName?: string,
    platform?: string,
  ): Promise<{ accessToken: string; userId: string }> {
    const user = await this.usersService.findByMobile(mobile);
    if (!user || !user.mpinHash) {
      throw new UnauthorizedException(
        'Authentication failed: MPIN is not configured',
      );
    }

    const pepperedSecret = this.getPepperedSecret(mpin);
    const isMpinValid = await bcrypt.compare(pepperedSecret, user.mpinHash);
    if (!isMpinValid) {
      throw new UnauthorizedException('Invalid MPIN');
    }

    // Register/update device audit trail
    await this.usersService.trackDevice(
      user.id,
      deviceId,
      deviceName,
      platform,
    );

    const payload = { sub: user.id, mobile: user.mobile };
    const accessToken = this.jwtService.sign(payload);

    // Audit logs
    await this.auditService.logEvent(
      user.id,
      AuditEventType.MPIN_LOGIN,
      'User',
      user.id,
      { deviceId, platform },
    );
    await this.auditService.logEvent(
      user.id,
      AuditEventType.LOGIN,
      'User',
      user.id,
      { loginType: 'MPIN' },
    );

    return {
      accessToken,
      userId: user.id,
    };
  }
}
