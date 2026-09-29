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
import { StrategyType } from '@prisma/client';

@Controller('consents')
@UseGuards(JwtAuthGuard)
export class ConsentsController {
  constructor(private readonly consentsService: ConsentsService) {}

  @Post()
  @HttpCode(HttpStatus.OK)
  async grantConsent(
    @Request() req,
    @Body()
    body: {
      brokerId: string;
      strategy?: StrategyType;
      baseMultiplier?: number;
      consentAccepted?: boolean;
      agreementVersion?: string;
    },
  ) {
    const userId = req.user.userId;
    const ipAddress = (req.headers['x-forwarded-for'] || req.ip || req.socket?.remoteAddress) as string;
    const userAgent = req.headers['user-agent'] as string;

    const consent = await this.consentsService.grantConsentWithStrategy(userId, {
      brokerId: body.brokerId,
      strategy: body.strategy,
      baseMultiplier: body.baseMultiplier ?? 1,
      consentAccepted: body.consentAccepted ?? true,
      agreementVersion: body.agreementVersion ?? 'v1.0',
      ipAddress: Array.isArray(ipAddress) ? ipAddress[0] : ipAddress,
      userAgent,
    });

    return {
      status: consent.status,
      consentDate: getTodayISTString(consent.consentDate),
      strategy: body.strategy ?? 'FIXED_1X',
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

  @Get('strategy')
  async getUserStrategy(@Request() req) {
    const userId = req.user.userId;
    return this.consentsService.getUserStrategyDetails(userId);
  }

  @Post('strategy/change')
  @HttpCode(HttpStatus.OK)
  async changeUserStrategy(
    @Request() req,
    @Body()
    body: {
      strategy: StrategyType;
      agreementVersion?: string;
    },
  ) {
    const userId = req.user.userId;
    const ipAddress = (req.headers['x-forwarded-for'] || req.ip || req.socket?.remoteAddress) as string;
    const userAgent = req.headers['user-agent'] as string;

    const updated = await this.consentsService.changeUserStrategy(
      userId,
      body.strategy,
      body.agreementVersion ?? 'v1.0',
      Array.isArray(ipAddress) ? ipAddress[0] : ipAddress,
      userAgent,
    );

    return {
      success: true,
      message: 'Strategy changed successfully. New cycle active with 1x multiplier.',
      strategy: updated,
    };
  }

  @Get('strategy/history')
  async getStrategyHistory(@Request() req) {
    const userId = req.user.userId;
    const history = await this.consentsService.getStrategyHistory(userId);
    return {
      history,
    };
  }
}
