"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PositionsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const client_1 = require("@prisma/client");
let PositionsService = class PositionsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getActivePositions(userId) {
        const positions = await this.prisma.position.findMany({
            where: {
                status: client_1.PositionStatus.OPEN,
                trade: {
                    userId,
                },
            },
            include: {
                trade: {
                    include: {
                        signal: true,
                    },
                },
            },
        });
        const updatedPositions = [];
        for (const pos of positions) {
            const avgPrice = Number(pos.avgPrice);
            const drift = 1 + (Math.random() * 3 - 1.5) / 100;
            const currentPrice = parseFloat((avgPrice * drift).toFixed(2));
            const isBuy = pos.trade.signal.side === 'BUY';
            const pnlFactor = isBuy
                ? currentPrice - avgPrice
                : avgPrice - currentPrice;
            const unrealizedPnl = parseFloat((pnlFactor * pos.quantity).toFixed(2));
            const updated = await this.prisma.position.update({
                where: { id: pos.id },
                data: {
                    currentPrice,
                    unrealizedPnl,
                },
                include: {
                    trade: {
                        include: {
                            signal: true,
                        },
                    },
                },
            });
            updatedPositions.push(updated);
        }
        return updatedPositions;
    }
    async exitPosition(userId, positionId) {
        const position = await this.prisma.position.findUnique({
            where: { id: positionId },
            include: {
                trade: {
                    include: {
                        signal: true,
                    },
                },
            },
        });
        if (!position || position.trade.userId !== userId) {
            throw new common_1.NotFoundException('Active position not found');
        }
        if (position.status === client_1.PositionStatus.CLOSED) {
            throw new common_1.BadRequestException('Position is already closed');
        }
        const avgPrice = Number(position.avgPrice);
        const currentPrice = Number(position.currentPrice);
        const isBuy = position.trade.signal.side === 'BUY';
        const pnlFactor = isBuy ? currentPrice - avgPrice : avgPrice - currentPrice;
        const realizedPnl = parseFloat((pnlFactor * position.quantity).toFixed(2));
        return this.prisma.$transaction(async (tx) => {
            const closedPos = await tx.position.update({
                where: { id: position.id },
                data: {
                    status: client_1.PositionStatus.CLOSED,
                    unrealizedPnl: 0,
                    realizedPnl,
                    currentPrice,
                },
            });
            await tx.trade.update({
                where: { id: position.tradeId },
                data: {
                    status: client_1.TradeStatus.CLOSED,
                    exitPrice: currentPrice,
                    pnl: realizedPnl,
                },
            });
            await tx.order.create({
                data: {
                    tradeId: position.tradeId,
                    orderType: client_1.OrderType.MARKET,
                    quantity: position.quantity,
                    price: currentPrice,
                    status: client_1.OrderStatus.FILLED,
                    brokerOrderId: `exit_order_${Date.now()}`,
                },
            });
            return closedPos;
        });
    }
};
exports.PositionsService = PositionsService;
exports.PositionsService = PositionsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PositionsService);
//# sourceMappingURL=positions.service.js.map