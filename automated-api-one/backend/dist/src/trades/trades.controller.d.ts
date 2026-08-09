import { TradesService } from './trades.service';
import { TradeStatus } from '@prisma/client';
export declare class GetHistoryDto {
    status?: TradeStatus;
    limit?: number;
    offset?: number;
}
export declare class ExportTradesDto {
    format: 'csv' | 'pdf';
}
export declare class TradesController {
    private readonly tradesService;
    constructor(tradesService: TradesService);
    getHistory(req: any, query: GetHistoryDto): Promise<{
        data: import("@prisma/client").Trade[];
        total: number;
    }>;
    getSummary(req: any): Promise<{
        totalPnl: number;
        totalTrades: any;
        profitableTrades: number;
        winRate: number;
        totalProfit: number;
        totalLoss: number;
    }>;
    exportTrades(req: any, dto: ExportTradesDto): Promise<{
        error: string | null;
        id: string;
        status: import("@prisma/client").$Enums.ReportState;
        userId: string;
        fileUrl: string | null;
        reportType: string;
        generatedAt: Date;
    }>;
}
