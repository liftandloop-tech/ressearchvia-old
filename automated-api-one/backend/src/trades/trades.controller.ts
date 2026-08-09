import {
  Controller,
  Get,
  Post,
  Query,
  Body,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { TradesService } from './trades.service';
import { IsOptional, IsEnum, IsInt, Min, IsString } from 'class-validator';
import { TradeStatus } from '@prisma/client';
import { Type } from 'class-transformer';

export class GetHistoryDto {
  @IsOptional()
  @IsEnum(TradeStatus)
  status?: TradeStatus;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  offset?: number;
}

export class ExportTradesDto {
  @IsString()
  @IsEnum(['csv', 'pdf'], { message: 'format must be either csv or pdf' })
  format: 'csv' | 'pdf';
}

@Controller('trades')
@UseGuards(JwtAuthGuard)
export class TradesController {
  constructor(private readonly tradesService: TradesService) {}

  @Get('history')
  async getHistory(@Request() req, @Query() query: GetHistoryDto) {
    const userId = req.user.userId;
    const limit = query.limit || 10;
    const offset = query.offset || 0;
    return this.tradesService.getTradeHistory(
      userId,
      query.status,
      limit,
      offset,
    );
  }

  @Get('summary')
  async getSummary(@Request() req) {
    const userId = req.user.userId;
    return this.tradesService.getPnlSummary(userId);
  }

  @Post('export')
  @HttpCode(HttpStatus.OK)
  async exportTrades(@Request() req, @Body() dto: ExportTradesDto) {
    const userId = req.user.userId;
    return this.tradesService.exportTrades(userId, dto.format);
  }
}
