import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { AuditService } from './audit.service';
import { AuditQueryDto } from './dto/audit-query.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Audit')
@ApiBearerAuth()
@Controller('admin/audit')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
export class AuditController {
  constructor(private readonly auditService: AuditService) {}

  @Get()
  @ApiOperation({ summary: 'Get audit logs (Admin only)' })
  async getAuditLogs(@Query() query: AuditQueryDto) {
    return this.auditService.getAuditLogs(query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get audit log details by ID (Admin only)' })
  async getAuditLogById(@Param('id') id: string) {
    return this.auditService.getAuditLogById(id);
  }
}
