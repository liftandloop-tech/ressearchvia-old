"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TradesService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const client_1 = require("@prisma/client");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
let TradesService = class TradesService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getTradeHistory(userId, status, limit = 10, offset = 0) {
        const whereClause = { userId };
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
    async getPnlSummary(userId) {
        const closedTrades = await this.prisma.trade.findMany({
            where: {
                userId,
                status: client_1.TradeStatus.CLOSED,
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
            }
            else {
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
    async exportTrades(userId, format) {
        if (format !== 'csv' && format !== 'pdf') {
            throw new common_1.BadRequestException('Unsupported export format');
        }
        const trades = await this.prisma.trade.findMany({
            where: { userId },
            include: { signal: true },
            orderBy: { createdAt: 'desc' },
        });
        const reportsDir = path.resolve(__dirname, '..', '..', 'reports');
        if (!fs.existsSync(reportsDir)) {
            fs.mkdirSync(reportsDir, { recursive: true });
        }
        const filename = `trades_report_${userId}_${Date.now()}.${format}`;
        const filePath = path.join(reportsDir, filename);
        if (format === 'csv') {
            let csvContent = 'Trade ID,Signal ID,Symbol,Side,Quantity,Entry Price,Exit Price,PnL,Status,Created At\n';
            for (const t of trades) {
                csvContent += `${t.id},${t.signalId},${t.signal.symbol},${t.signal.side},${t.quantity},${t.entryPrice || ''},${t.exitPrice || ''},${t.pnl || ''},${t.status},${t.createdAt.toISOString()}\n`;
            }
            fs.writeFileSync(filePath, csvContent, 'utf-8');
        }
        else {
            let pdfContent = `TRADING REPORT - USER ${userId}\n=========================================\n\n`;
            pdfContent += `Generated At: ${new Date().toISOString()}\nTotal Records: ${trades.length}\n\n`;
            for (const t of trades) {
                pdfContent += `ID: ${t.id} | ${t.signal.symbol} | ${t.signal.side} | Qty: ${t.quantity} | Entry: ${t.entryPrice || ''} | Exit: ${t.exitPrice || ''} | PnL: ${t.pnl || ''} | Status: ${t.status}\n`;
            }
            fs.writeFileSync(filePath, pdfContent, 'utf-8');
        }
        const fileUrl = `/reports/${filename}`;
        return this.prisma.report.create({
            data: {
                userId,
                reportType: format.toUpperCase(),
                fileUrl,
            },
        });
    }
};
exports.TradesService = TradesService;
exports.TradesService = TradesService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], TradesService);
//# sourceMappingURL=trades.service.js.map