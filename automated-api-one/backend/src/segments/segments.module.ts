import { Module } from '@nestjs/common';
import { SegmentsController } from './segments.controller';
import { SegmentsService } from './segments.service';
import { PrismaService } from '../prisma.service';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [AuditModule],
  controllers: [SegmentsController],
  providers: [SegmentsService, PrismaService],
  exports: [SegmentsService],
})
export class SegmentsModule {}
