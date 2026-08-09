import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
  Param,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RiskService } from './risk.service';
import {
  IsNotEmpty,
  IsString,
  IsOptional,
  IsInt,
  Min,
  IsUUID,
  IsNumber,
} from 'class-validator';
import { Type } from 'class-transformer';

export class GetRiskEventsDto {
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

export class ResetRiskDto {
  @IsString()
  @IsNotEmpty()
  segmentId: string;
}

export class PaginatedQueryDto {
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

export class UnlockSegmentDto {
  @IsOptional()
  @IsUUID()
  targetUserId?: string;
}

export class CreateRiskProfileDto {
  @IsOptional()
  @IsUUID()
  userId?: string;

  @IsOptional()
  @IsUUID()
  segmentId?: string;

  @IsOptional()
  @IsUUID()
  brokerId?: string;

  @IsOptional()
  @IsInt()
  priority?: number;

  @IsNumber()
  maxCapitalPerUser: number;

  @IsNumber()
  maxCapitalPerSegment: number;

  @IsNumber()
  maxDailyLoss: number;

  @IsInt()
  maxOpenPositions: number;

  @IsInt()
  maxPositionSize: number;

  @IsNumber()
  maxExposurePerSymbol: number;

  @IsNumber()
  maxExposurePerBroker: number;

  @IsInt()
  maxConcurrentOrders: number;
}

export class UpdateRiskProfileDto {
  @IsOptional()
  @IsUUID()
  userId?: string;

  @IsOptional()
  @IsUUID()
  segmentId?: string;

  @IsOptional()
  @IsUUID()
  brokerId?: string;

  @IsOptional()
  @IsInt()
  priority?: number;

  @IsOptional()
  @IsNumber()
  maxCapitalPerUser?: number;

  @IsOptional()
  @IsNumber()
  maxCapitalPerSegment?: number;

  @IsOptional()
  @IsNumber()
  maxDailyLoss?: number;

  @IsOptional()
  @IsInt()
  maxOpenPositions?: number;

  @IsOptional()
  @IsInt()
  maxPositionSize?: number;

  @IsOptional()
  @IsNumber()
  maxExposurePerSymbol?: number;

  @IsOptional()
  @IsNumber()
  maxExposurePerBroker?: number;

  @IsOptional()
  @IsInt()
  maxConcurrentOrders?: number;
}

@Controller('risk')
@UseGuards(JwtAuthGuard)
export class RiskController {
  constructor(private readonly riskService: RiskService) {}

  // 1. GET /risk/status/:segmentId
  @Get('status/:segmentId')
  async getStatusForSegment(
    @Request() req,
    @Param('segmentId') segmentId: string,
  ) {
    const userId = req.user.userId;
    return this.riskService.getRiskStatusForSegment(userId, segmentId);
  }

  // 2. GET /risk/events/:segmentId (Paginated)
  @Get('events/:segmentId')
  async getEventsForSegment(
    @Request() req,
    @Param('segmentId') segmentId: string,
    @Query() query: PaginatedQueryDto,
  ) {
    const userId = req.user.userId;
    const page = query.page || 1;
    const limit = query.limit || 20;
    return this.riskService.getRiskEventsForSegment(
      userId,
      segmentId,
      page,
      limit,
    );
  }

  // 3. POST /risk/unlock/:segmentId
  @Post('unlock/:segmentId')
  @HttpCode(HttpStatus.OK)
  async unlockSegment(
    @Request() req,
    @Param('segmentId') segmentId: string,
    @Body() dto: UnlockSegmentDto,
  ) {
    const userId = req.user.userId;
    const isAdmin = req.user.role === 'ADMIN' || req.user.role === 'SUPERADMIN';
    return this.riskService.unlockSegment(
      userId,
      segmentId,
      dto.targetUserId,
      isAdmin,
    );
  }

  @Post('profiles')
  async createProfile(@Body() dto: CreateRiskProfileDto) {
    return this.riskService.createProfile(dto);
  }

  @Put('profiles/:id')
  async updateProfile(@Param('id') id: string, @Body() dto: UpdateRiskProfileDto) {
    return this.riskService.updateProfile(id, dto);
  }

  @Get('violations')
  async getViolations(@Request() req, @Query('userId') queryUserId?: string) {
    const isAdmin = req.user.role === 'ADMIN' || req.user.role === 'SUPERADMIN';
    const targetUserId = isAdmin ? queryUserId : req.user.userId;
    return this.riskService.getViolations(targetUserId);
  }

  @Get('snapshots')
  async getSnapshots(@Request() req, @Query('userId') queryUserId?: string) {
    const isAdmin = req.user.role === 'ADMIN' || req.user.role === 'SUPERADMIN';
    const targetUserId = isAdmin ? queryUserId : req.user.userId;
    return this.riskService.getSnapshots(targetUserId);
  }

  // ==========================================
  // Legacy / Backwards-Compatibility Endpoints
  // ==========================================


  @Get('events')
  async getEvents(@Request() req, @Query() query: GetRiskEventsDto) {
    const userId = req.user.userId;
    const limit = query.limit || 20;
    const offset = query.offset || 0;
    return this.riskService.getRiskEvents(userId, limit, offset);
  }

  @Get('status')
  async getStatus(@Request() req) {
    const userId = req.user.userId;
    return this.riskService.getRiskStatus(userId);
  }

  @Post('reset')
  @HttpCode(HttpStatus.OK)
  async resetLock(@Request() req, @Body() dto: ResetRiskDto) {
    const userId = req.user.userId;
    return this.riskService.resetRiskLock(userId, dto.segmentId);
  }
}
