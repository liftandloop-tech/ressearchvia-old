import { Module } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { LocalStorageProvider, REPORT_STORAGE_PROVIDER } from './providers/report-storage.provider';
import { ReportGenerationProcessor, ReportExportProcessor } from './processors/report-generation.processor';
import { AnalyticsSnapshotProcessor } from './processors/analytics-snapshot.processor';
import { CsvCleanupProcessor } from './processors/csv-cleanup.processor';
import { PrismaModule } from '../database/prisma/prisma.module';
import { InfrastructureModule } from '../infrastructure/infrastructure.module';

@Module({
  imports: [PrismaModule, InfrastructureModule],
  providers: [
    ReportsService,
    {
      provide: REPORT_STORAGE_PROVIDER,
      useClass: LocalStorageProvider,
    },
    ReportGenerationProcessor,
    ReportExportProcessor,
    AnalyticsSnapshotProcessor,
    CsvCleanupProcessor,
  ],
  exports: [ReportsService],
})
export class ReportsModule {}
