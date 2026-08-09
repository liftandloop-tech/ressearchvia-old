import { PrismaService } from '../prisma.service';
import { Trade, TradeStatus, Report } from '@prisma/client';
export declare class TradesService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getTradeHistory(userId: string, status?: TradeStatus, limit?: number, offset?: number): Promise<{
        data: Trade[];
        total: number;
    }>;
    getPnlSummary(userId: string): Promise<{
        totalPnl: number;
        totalTrades: any;
        profitableTrades: number;
        winRate: number;
        totalProfit: number;
        totalLoss: number;
    }>;
    exportTrades(userId: string, format: 'csv' | 'pdf'): Promise<Report>;
}
