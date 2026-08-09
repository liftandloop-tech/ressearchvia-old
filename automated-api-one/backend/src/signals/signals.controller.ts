import {
  Controller,
  Post,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SignalsService } from './signals.service';
import { IsNotEmpty, IsString, IsEnum, IsNumber, Min } from 'class-validator';
import { Segment, Side, OrderType } from '@prisma/client';

export class PublishSignalDto {
  @IsString()
  @IsNotEmpty()
  segmentId: string;

  @IsString()
  @IsNotEmpty()
  symbol: string;

  @IsString()
  @IsNotEmpty()
  exchange: string;

  @IsEnum(Segment)
  @IsNotEmpty()
  segment: Segment;

  @IsEnum(Side)
  @IsNotEmpty()
  side: Side;

  @IsEnum(OrderType)
  @IsNotEmpty()
  orderType: OrderType;

  @IsNumber()
  @Min(0)
  entryPrice: number;

  @IsNumber()
  @Min(0)
  stopLoss: number;

  @IsNumber()
  @Min(0)
  targetPrice: number;
}

@Controller('signals')
@UseGuards(JwtAuthGuard)
export class SignalsController {
  constructor(private readonly signalsService: SignalsService) {}

  @Post('publish')
  @HttpCode(HttpStatus.OK)
  async publishSignal(@Body() dto: PublishSignalDto) {
    return this.signalsService.publishAndEnqueue(dto);
  }
}
