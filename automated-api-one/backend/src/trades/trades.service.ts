import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { Trade, TradeStatus, Report } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class TradesService {
  constructor(private readonly prisma: PrismaService) {}

  async getTradeHistory(
    userId: string,
    status?: TradeStatus,
    limit = 10,
    offset = 0,
  ): Promise<{ data: Trade[]; total: number }> {
    const whereClause: any = { userId };
    if (status) {
      whereClause.status = status;
    }

    const [data, total] = await Promise.all([
      this.prisma.trade.findMany({
        where: whereClause,
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
        include: {
          signal: true,
        },
      }),
      this.prisma.trade.count({
        where: whereClause,
      }),
    ]);

    return { data, total };
  }

  async getPnlSummary(userId: string) {
    const closedTrades = await this.prisma.trade.findMany({
      where: {
        userId,
        status: TradeStatus.CLOSED,
      },
    });

    let totalPnl = 0;
    let totalProfit = 0;
    let totalLoss = 0;
    let profitableCount = 0;

    for (const trade of closedTrades) {
      const pnl = Number(trade.pnl || 0);
      totalPnl += pnl;
      if (pnl > 0) {
        totalProfit += pnl;
        profitableCount++;
      } else {
        totalLoss += pnl;
      }
    }

    const totalTrades = closedTrades.length;
    const winRate = totalTrades > 0 ? (profitableCount / totalTrades) * 100 : 0;

    return {
      totalPnl,
      totalTrades,
      profitableTrades: profitableCount,
      winRate: parseFloat(winRate.toFixed(2)),
      totalProfit,
      totalLoss,
    };
  }

  async exportTrades(userId: string, format: 'csv' | 'pdf'): Promise<Report> {
    if (format !== 'csv' && format !== 'pdf') {
      throw new BadRequestException('Unsupported export format');
    }

    const trades = await this.prisma.trade.findMany({
      where: { userId },
      include: { signal: true },
      orderBy: { createdAt: 'desc' },
    });

    // Resolve reports directory in backend
    const reportsDir = path.resolve(__dirname, '..', '..', 'reports');
    if (!fs.existsSync(reportsDir)) {
      fs.mkdirSync(reportsDir, { recursive: true });
    }

    const filename = `trades_report_${userId}_${Date.now()}.${format}`;
    const filePath = path.join(reportsDir, filename);

    if (format === 'csv') {
      // Build mock CSV string
      let csvContent =
        'Trade ID,Signal ID,Symbol,Side,Quantity,Entry Price,Exit Price,PnL,Status,Created At\n';
      for (const t of trades) {
        csvContent += `${t.id},${t.signalId},${t.signal.symbol},${t.signal.side},${t.quantity},${t.entryPrice || ''},${t.exitPrice || ''},${t.pnl || ''},${t.status},${t.createdAt.toISOString()}\n`;
      }
      fs.writeFileSync(filePath, csvContent, 'utf-8');
    } else {
      // Build mock PDF string content
      let pdfContent = `TRADING REPORT - USER ${userId}\n=========================================\n\n`;
      pdfContent += `Generated At: ${new Date().toISOString()}\nTotal Records: ${trades.length}\n\n`;
      for (const t of trades) {
        pdfContent += `ID: ${t.id} | ${t.signal.symbol} | ${t.signal.side} | Qty: ${t.quantity} | Entry: ${t.entryPrice || ''} | Exit: ${t.exitPrice || ''} | PnL: ${t.pnl || ''} | Status: ${t.status}\n`;
      }
      fs.writeFileSync(filePath, pdfContent, 'utf-8');
    }

    const fileUrl = `/reports/${filename}`;

    // Record report in database
    return this.prisma.report.create({
      data: {
        userId,
        reportType: format.toUpperCase(),
        fileUrl,
      },
    });
  }
}
