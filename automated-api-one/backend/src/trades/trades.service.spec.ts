import { Test, TestingModule } from '@nestjs/testing';
import { TradesService } from './trades.service';
import { PrismaService } from '../prisma.service';
import { mockPrismaService } from '../../test/mocks/prisma.mock';
import { TradeStatus, Side, Segment } from '@prisma/client';
import { BadRequestException } from '@nestjs/common';
import * as fs from 'fs';

jest.mock('fs', () => ({
  existsSync: jest.fn().mockReturnValue(true),
  mkdirSync: jest.fn(),
  writeFileSync: jest.fn(),
}));

describe('TradesService', () => {
  let service: TradesService;
  let prismaMock: any;

  beforeEach(async () => {
    prismaMock = mockPrismaService();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TradesService,
        { provide: PrismaService, useValue: prismaMock },
      ],
    }).compile();

    service = module.get<TradesService>(TradesService);
  });

  describe('getTradeHistory', () => {
    it('should query and return trade history list and count', async () => {
      prismaMock.trade.findMany.mockResolvedValue([{ id: 'trade-1' }]);
      prismaMock.trade.count.mockResolvedValue(1);

      const result = await service.getTradeHistory(
        'user-1',
        TradeStatus.CLOSED,
        10,
        0,
      );
      expect(result.data).toEqual([{ id: 'trade-1' }]);
      expect(result.total).toBe(1);
      expect(prismaMock.trade.findMany).toHaveBeenCalled();
      expect(prismaMock.trade.count).toHaveBeenCalled();
    });
  });

  describe('getPnlSummary', () => {
    it('should aggregate closed trades metrics correctly', async () => {
      prismaMock.trade.findMany.mockResolvedValue([
        { id: 't-1', pnl: 500 },
        { id: 't-2', pnl: -200 },
      ]);

      const result = await service.getPnlSummary('user-1');
      expect(result.totalPnl).toBe(300);
      expect(result.totalTrades).toBe(2);
      expect(result.profitableTrades).toBe(1);
      expect(result.winRate).toBe(50.0);
      expect(result.totalProfit).toBe(500);
      expect(result.totalLoss).toBe(-200);
    });

    it('should return 0 winRate if there are no trades', async () => {
      prismaMock.trade.findMany.mockResolvedValue([]);
      const result = await service.getPnlSummary('user-1');
      expect(result.winRate).toBe(0);
    });
  });

  describe('exportTrades', () => {
    const mockTrades = [
      {
        id: 'trade-1',
        signalId: 's-1',
        quantity: 10,
        entryPrice: 100,
        exitPrice: 120,
        pnl: 200,
        status: TradeStatus.CLOSED,
        createdAt: new Date(),
        signal: { symbol: 'NIFTY', side: Side.BUY },
      },
    ];

    it('should successfully write CSV report and record in db', async () => {
      prismaMock.trade.findMany.mockResolvedValue(mockTrades);
      prismaMock.report.create.mockResolvedValue({
        id: 'report-1',
        fileUrl: '/reports/filename.csv',
      });

      const result = await service.exportTrades('user-1', 'csv');
      expect(result.id).toBe('report-1');
      expect(fs.writeFileSync).toHaveBeenCalled();
      expect(prismaMock.report.create).toHaveBeenCalled();
    });

    it('should successfully write PDF report and record in db', async () => {
      prismaMock.trade.findMany.mockResolvedValue(mockTrades);
      prismaMock.report.create.mockResolvedValue({
        id: 'report-2',
        fileUrl: '/reports/filename.pdf',
      });

      const result = await service.exportTrades('user-1', 'pdf');
      expect(result.id).toBe('report-2');
      expect(fs.writeFileSync).toHaveBeenCalled();
      expect(prismaMock.report.create).toHaveBeenCalled();
    });

    it('should create directory if it does not exist', async () => {
      (fs.existsSync as jest.Mock).mockReturnValueOnce(false);
      prismaMock.trade.findMany.mockResolvedValue([]);
      prismaMock.report.create.mockResolvedValue({});

      await service.exportTrades('user-1', 'csv');
      expect(fs.mkdirSync).toHaveBeenCalled();
    });

    it('should throw BadRequestException for unsupported format', async () => {
      await expect(
        service.exportTrades('user-1', 'txt' as any),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
