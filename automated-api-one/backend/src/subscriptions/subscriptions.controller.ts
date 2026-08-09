import {
  Controller,
  Post,
  Body,
  UseGuards,
  Request,
  Get,
  Query,
  Param,
  Delete,
  HttpStatus,
  HttpCode,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SubscriptionsService } from './subscriptions.service';
import { IsNotEmpty, IsUUID, IsOptional, IsInt, Min } from 'class-validator';
import { PLANS } from './plans.constants';
import { Type } from 'class-transformer';

export class SubscribeDto {
  @IsUUID()
  @IsNotEmpty()
  planId: string;
}

export class HistoryQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;
}

@Controller('subscriptions')
@UseGuards(JwtAuthGuard)
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Get('plans')
  getPlans() {
    return [
      {
        id: PLANS.SPARK.id,
        name: PLANS.SPARK.name,
        durationDays: PLANS.SPARK.durationDays,
      },
      {
        id: PLANS.SPLENDID.id,
        name: PLANS.SPLENDID.name,
        durationDays: PLANS.SPLENDID.durationDays,
      },
    ];
  }

  @Get('current')
  async getCurrent(@Request() req) {
    const userId = req.user.userId;
    return this.subscriptionsService.getCurrentSubscription(userId);
  }

  @Get('status')
  async getStatus(@Request() req) {
    const userId = req.user.userId;
    return this.subscriptionsService.validateSubscription(userId);
  }

  @Get('history')
  async getHistory(@Request() req, @Query() query: HistoryQueryDto) {
    const userId = req.user.userId;
    return this.subscriptionsService.getSubscriptionHistory(
      userId,
      query.page,
      query.limit,
    );
  }

  @Post()
  @HttpCode(HttpStatus.OK)
  async subscribeBase(@Request() req, @Body() dto: SubscribeDto) {
    const userId = req.user.userId;
    return this.subscriptionsService.subscribe(userId, dto.planId);
  }

  @Post('subscribe')
  @HttpCode(HttpStatus.OK)
  async subscribeLegacy(@Request() req, @Body() dto: SubscribeDto) {
    const userId = req.user.userId;
    return this.subscriptionsService.subscribe(userId, dto.planId);
  }

  @Delete(':id')
  async cancel(@Request() req, @Param('id') id: string) {
    const userId = req.user.userId;
    return this.subscriptionsService.cancelSubscription(id, userId);
  }
}
