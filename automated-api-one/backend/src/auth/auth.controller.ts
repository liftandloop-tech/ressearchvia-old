import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './jwt-auth.guard';
import { IsNotEmpty, IsString, Length, IsOptional } from 'class-validator';

export class SendOtpDto {
  @IsString()
  @IsNotEmpty()
  mobile: string;
}

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  mobile: string;

  @IsString()
  @IsNotEmpty()
  @Length(6, 6, { message: 'OTP must be exactly 6 characters' })
  otp: string;
}

export class SetupMpinDto {
  @IsString()
  @IsNotEmpty()
  @Length(4, 6, { message: 'MPIN must be 4 or 6 digits' })
  mpin: string;
}

export class LoginMpinDto {
  @IsString()
  @IsNotEmpty()
  mobile: string;

  @IsString()
  @IsNotEmpty()
  @Length(4, 6, { message: 'MPIN must be 4 or 6 digits' })
  mpin: string;

  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @IsString()
  @IsOptional()
  deviceName?: string;

  @IsString()
  @IsOptional()
  platform?: string;
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('send-otp')
  @HttpCode(HttpStatus.OK)
  async sendOtp(@Body() dto: SendOtpDto) {
    return this.authService.sendOtp(dto.mobile);
  }

  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto.mobile, dto.otp);
  }

  @Post('setup-mpin')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async setupMpin(@Request() req, @Body() dto: SetupMpinDto) {
    // userId is attached by JwtStrategy validation
    return this.authService.setupMpin(req.user.userId, dto.mpin);
  }

  @Post('login-mpin')
  @HttpCode(HttpStatus.OK)
  async loginMpin(@Body() dto: LoginMpinDto) {
    return this.authService.loginMpin(
      dto.mobile,
      dto.mpin,
      dto.deviceId,
      dto.deviceName,
      dto.platform,
    );
  }
}
