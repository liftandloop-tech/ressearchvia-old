import { Injectable, Logger, Inject } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../prisma.service';
import { REPORT_STORAGE_PROVIDER, ReportStorageProvider } from '../providers/report-storage.provider';
import { ExportState } from '@prisma/client';
import * as fs from 'fs/promises';
import * as path from 'path';

@Injectable()
export class CsvCleanupProcessor {
  private readonly logger = new Logger(CsvCleanupProcessor.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(REPORT_STORAGE_PROVIDER) private readonly storageProvider: any,
  ) {}

  @Cron('0 2 * * *') // Run daily at 2 AM
  async cleanupExpiredExports() {
    if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
      return;
    }
    this.logger.log('Starting daily CSV export cleanup task...');
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 7);

    try {
      const expiredExports = await this.prisma.reportExport.findMany({
        where: {
          createdAt: {
            lt: cutoffDate,
          },
          status: {
            not: ExportState.EXPIRED,
          },
        },
      });

      this.logger.log(`Found ${expiredExports.length} exports older than 7 days for cleanup.`);

      for (const exp of expiredExports) {
        if (exp.fileUrl && exp.fileUrl.startsWith('/uploads/reports/')) {
          const fileName = exp.fileUrl.replace('/uploads/reports/', '');
          const filePath = path.join(process.cwd(), 'uploads', 'reports', fileName);
          try {
            await fs.unlink(filePath);
            this.logger.log(`Deleted file: ${filePath}`);
          } catch (err) {
            this.logger.warn(`Failed to delete local file ${filePath}: ${err.message}`);
          }
        }

        await this.prisma.reportExport.update({
          where: { id: exp.id },
          data: { status: ExportState.EXPIRED },
        });
      }
      this.logger.log('Finished CSV export cleanup task.');
    } catch (err) {
      this.logger.error(`CSV cleanup task failed: ${err.message}`);
    }
  }
}
