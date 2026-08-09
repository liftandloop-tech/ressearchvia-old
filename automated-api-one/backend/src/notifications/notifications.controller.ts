import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { NotificationsService } from './notifications.service';
import {
  IsNotEmpty,
  IsString,
  IsArray,
  IsOptional,
  IsInt,
  Min,
  IsEnum,
  IsBoolean,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { NotificationType, NotificationEvent, NotificationChannel } from '@prisma/client';

export class GetNotificationsDto {
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

export class MarkReadDto {
  @IsArray()
  @IsString({ each: true })
  @IsNotEmpty()
  notificationIds: string[];
}

export class SimulateNotificationDto {
  @IsEnum(NotificationType)
  @IsNotEmpty()
  type: NotificationType;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  message: string;
}

export class UpdatePreferenceItemDto {
  @IsEnum(NotificationEvent)
  @IsNotEmpty()
  eventType: NotificationEvent;

  @IsEnum(NotificationChannel)
  @IsNotEmpty()
  channel: NotificationChannel;

  @IsBoolean()
  @IsNotEmpty()
  enabled: boolean;
}

export class UpdatePreferencesDto {
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => UpdatePreferenceItemDto)
  preferences?: UpdatePreferenceItemDto[];

  @IsOptional()
  @IsBoolean()
  quietHoursEnabled?: boolean;

  @IsOptional()
  @IsString()
  quietStart?: string;

  @IsOptional()
  @IsString()
  quietEnd?: string;

  @IsOptional()
  @IsString()
  quietTimezone?: string;
}

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  async getNotifications(@Request() req, @Query() query: GetNotificationsDto) {
    const userId = req.user.userId;
    const limit = query.limit || 20;
    const offset = query.offset || 0;
    return this.notificationsService.getHistory(userId, limit, offset);
  }

  @Post('read')
  @HttpCode(HttpStatus.OK)
  async markRead(@Request() req, @Body() dto: MarkReadDto) {
    const userId = req.user.userId;
    return this.notificationsService.markAsRead(userId, dto.notificationIds);
  }

  @Post('simulate')
  @HttpCode(HttpStatus.OK)
  async simulateNotification(
    @Request() req,
    @Body() dto: SimulateNotificationDto,
  ) {
    const userId = req.user.userId;
    return this.notificationsService.createNotification(
      userId,
      dto.type,
      dto.title,
      dto.message,
    );
  }

  @Get('preferences')
  async getPreferences(@Request() req) {
    const userId = req.user.userId;
    return this.notificationsService.getPreferences(userId);
  }

  @Post('preferences')
  @HttpCode(HttpStatus.OK)
  async updatePreferences(@Request() req, @Body() dto: UpdatePreferencesDto) {
    const userId = req.user.userId;
    return this.notificationsService.updatePreferences(userId, dto);
  }
}
