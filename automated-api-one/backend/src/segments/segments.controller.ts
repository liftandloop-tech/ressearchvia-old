import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { SegmentsService } from './segments.service';
import { IsNotEmpty, IsString, IsNumber, Min, IsInt } from 'class-validator';

export class ActivateSegmentDto {
  @IsString()
  @IsNotEmpty()
  segmentId: string;

  @IsNumber()
  @Min(0)
  capital: number;

  @IsNumber()
  @Min(0)
  backupCapital: number;

  @IsInt()
  @Min(1)
  baseLot: number;

  @IsInt()
  @Min(1)
  maxMultiplier: number;

  @IsNumber()
  @Min(0)
  dailyLossLimit: number;
}

export class PauseSegmentDto {
  @IsString()
  @IsNotEmpty()
  segmentId: string;
}

@Controller('segments')
export class SegmentsController {
  constructor(private readonly segmentsService: SegmentsService) {}

  @Get()
  async listSegments() {
    return this.segmentsService.listSegments();
  }

  @Get('active')
  @UseGuards(JwtAuthGuard)
  async getActiveSegments(@Request() req) {
    const userId = req.user.userId;
    return this.segmentsService.getUserSegments(userId);
  }

  @Post('activate')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async activateSegment(@Request() req, @Body() dto: ActivateSegmentDto) {
    const userId = req.user.userId;
    return this.segmentsService.activateSegment(userId, dto);
  }

  @Post('pause')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async pauseSegment(@Request() req, @Body() dto: PauseSegmentDto) {
    const userId = req.user.userId;
    return this.segmentsService.pauseSegment(userId, dto.segmentId);
  }
}
