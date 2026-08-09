import { Test, TestingModule } from '@nestjs/testing';
import { CsvCleanupProcessor } from './csv-cleanup.processor';
import { PrismaService } from '../../prisma.service';
import { REPORT_STORAGE_PROVIDER } from '../providers/report-storage.provider';
import { ExportState } from '@prisma/client';
import * as fs from 'fs/promises';

jest.mock('fs/promises');

describe('CsvCleanupProcessor', () => {
  let processor: CsvCleanupProcessor;
  let prisma: PrismaService;

  const mockStorageProvider = {
    upload: jest.fn(),
  };

  const mockPrisma = {
    reportExport: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'exp-1',
          fileUrl: '/uploads/reports/test-1.csv',
          status: ExportState.COMPLETED,
        },
      ]),
      update: jest.fn().mockResolvedValue({}),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CsvCleanupProcessor,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: REPORT_STORAGE_PROVIDER, useValue: mockStorageProvider },
      ],
    }).compile();

    processor = module.get<CsvCleanupProcessor>(CsvCleanupProcessor);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(processor).toBeDefined();
  });

  describe('cleanupExpiredExports', () => {
    it('should delete old files and update database status to EXPIRED', async () => {
      const unlinkMock = jest.spyOn(fs, 'unlink').mockResolvedValue(undefined);

      await processor.cleanupExpiredExports();

      expect(prisma.reportExport.findMany).toHaveBeenCalled();
      expect(unlinkMock).toHaveBeenCalled();
      expect(prisma.reportExport.update).toHaveBeenCalledWith({
        where: { id: 'exp-1' },
        data: { status: ExportState.EXPIRED },
      });
    });
  });
});
