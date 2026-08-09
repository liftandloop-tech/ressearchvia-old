import { JwtService } from '@nestjs/jwt';

export class AuthTestHelper {
  private readonly jwtService = new JwtService({
    secret: process.env.JWT_SECRET || 'super_secret_trading_platform_key',
  });

  getHeadersForUser(userId: string, mobile: string) {
    const payload = { sub: userId, userId, mobile };
    const token = this.jwtService.sign(payload);
    return {
      Authorization: `Bearer ${token}`,
    };
  }
}
