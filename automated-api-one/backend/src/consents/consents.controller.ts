/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-argument */
import {
  Controller,
  Post,
  Get,
  Delete,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
  Body,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ConsentsService, getTodayISTString } from './consents.service';

@Controller('consents')
@UseGuards(JwtAuthGuard)
export class ConsentsController {
  constructor(private readonly consentsService: ConsentsService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  async grantConsent(@Request() req, @Body('brokerId') brokerId: string) {
    const userId = req.user.userId;
    const consent = await this.consentsService.grantConsent(userId, brokerId);
    return {
      status: consent.status,
      consentDate: getTodayISTString(consent.consentDate),
    };
  }

  @Get('today')
  async getConsentStatusToday(@Request() req) {
    const userId = req.user.userId;
    return this.consentsService.getConsentStatus(userId);
  }

  @Get('status')
  async getConsentStatusDashboard(@Request() req) {
    const userId = req.user.userId;
    return this.consentsService.getConsentStatus(userId);
  }

  @Delete('today')
  async revokeConsent(@Request() req) {
    const userId = req.user.userId;
    await this.consentsService.revokeConsent(userId);
    return {
      status: 'REVOKED',
    };
  }
}
