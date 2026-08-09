import {
  Controller,
  Get,
  Post,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
  Body,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { AnalyticsService } from './analytics.service';

@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('portfolio')
  @UseGuards(JwtAuthGuard)
  async getPortfolio(@Request() req) {
    const userId = req.user.userId;
    return this.analyticsService.getPortfolioPerformance(userId);
  }

  @Get('segments')
  @UseGuards(JwtAuthGuard)
  async getSegments(@Request() req) {
    const userId = req.user.userId;
    return this.analyticsService.getSegmentPerformance(userId);
  }

  @Get('brokers')
  @UseGuards(JwtAuthGuard)
  async getBrokers(@Request() req) {
    const userId = req.user.userId;
    return this.analyticsService.getBrokerPerformance(userId);
  }

  @Post('recalculate')
  @Roles('SUPERADMIN', 'SRE')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @HttpCode(HttpStatus.OK)
  async forceRecalculate(@Body() dto: { userId?: string; rebuildHistory?: boolean }) {
    if (dto.userId) {
      await this.analyticsService.enqueueRecalculation(dto.userId, dto.rebuildHistory);
      return { message: `Recalculation enqueued for user ${dto.userId}` };
    } else {
      await this.analyticsService.handleNightlyAnalyticsRecalculation();
      return { message: 'Nightly analytics recalculation triggered for all active users' };
    }
  }
}
