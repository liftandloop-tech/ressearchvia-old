import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PositionsService } from './positions.service';
import { IsNotEmpty, IsString } from 'class-validator';

export class ExitPositionDto {
  @IsString()
  @IsNotEmpty()
  positionId: string;
}

@Controller('positions')
@UseGuards(JwtAuthGuard)
export class PositionsController {
  constructor(private readonly positionsService: PositionsService) {}

  @Get('active')
  async getActive(@Request() req) {
    const userId = req.user.userId;
    return this.positionsService.getActivePositions(userId);
  }

  @Post('exit')
  @HttpCode(HttpStatus.OK)
  async exitPosition(@Request() req, @Body() dto: ExitPositionDto) {
    const userId = req.user.userId;
    return this.positionsService.exitPosition(userId, dto.positionId);
  }
}
