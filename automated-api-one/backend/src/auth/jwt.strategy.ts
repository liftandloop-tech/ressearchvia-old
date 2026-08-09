import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { PrismaService } from '../prisma.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly usersService: UsersService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>(
        'JWT_SECRET',
        'super_secret_trading_platform_key',
      ),
    });
  }

  async validate(payload: { sub?: string; _id?: string; mobile?: string; phone?: string }) {
    console.log('JWT Strategy Payload:', payload);
    const userId = payload.sub || payload._id;
    let mobile = payload.mobile || payload.phone;

    const userType = (payload as any).userType;
    const isAdminType = userType && ['super_admin', 'admin', 'researcher'].includes(String(userType).toLowerCase());

    if (!mobile && isAdminType) {
      mobile = '0000000000';
    }

    if (!userId && !mobile) {
      throw new UnauthorizedException('Token payload does not contain a valid user ID or mobile number');
    }

    const isUuid = userId && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(userId);

    if (isUuid) {
      // 1. Check if the ID belongs to an AdminUser first
      const admin = await this.prisma.adminUser.findUnique({
        where: { id: userId },
      });

      if (admin) {
        if (admin.status !== 'ACTIVE') {
          throw new UnauthorizedException('Admin account inactive');
        }
        return {
          userId: admin.id,
          email: admin.email,
          role: admin.role,
          isAdmin: true,
        };
      }

      // 2. Validate normal user
      const user = await this.usersService.findById(userId);
      if (user) {
        if (user.status === 'SUSPENDED' || user.status === 'DELETED') {
          throw new UnauthorizedException('User account inactive');
        }
        return {
          userId: user.id,
          mobile: user.mobile,
          role: 'USER',
          isAdmin: false,
        };
      }
    }

    // 3. Fallback: Lookup or sync user by mobile number (e.g. from MongoDB token)
    if (mobile) {
      const mobileStr = typeof mobile === 'string' ? mobile : String(mobile);
      const cleanMobile = mobileStr.replace(/\D/g, '').slice(-10);
      const user = await this.usersService.createOrUpdateUser(cleanMobile);
      if (user.status === 'SUSPENDED' || user.status === 'DELETED') {
        throw new UnauthorizedException('User account inactive');
      }

      return {
        userId: user.id,
        mobile: user.mobile,
        role: isAdminType ? 'SUPERADMIN' : 'USER',
        isAdmin: isAdminType ? true : false,
      };
    }

    throw new UnauthorizedException('Token payload does not contain a valid user ID or mobile number');
  }
}
