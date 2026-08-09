import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import {
  Position,
  PositionStatus,
  TradeStatus,
  OrderStatus,
  OrderType,
} from '@prisma/client';

@Injectable()
export class PositionsService {
  constructor(private readonly prisma: PrismaService) {}

  async getActivePositions(userId: string): Promise<Position[]> {
    const positions = await this.prisma.position.findMany({
      where: {
        status: PositionStatus.OPEN,
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

    const updatedPositions: Position[] = [];

    // Simulate price fluctuation (LTP) and update unrealized P&L
    for (const pos of positions) {
      const avgPrice = Number(pos.avgPrice);
      // Drift price by -1.5% to +1.5% randomly
      const drift = 1 + (Math.random() * 3 - 1.5) / 100;
      const currentPrice = parseFloat((avgPrice * drift).toFixed(2));

      // Calculate PnL based on trade direction (BUY/SELL)
      const isBuy = pos.trade.signal.side === 'BUY';
      const pnlFactor = isBuy
        ? currentPrice - avgPrice
        : avgPrice - currentPrice;
      const unrealizedPnl = parseFloat((pnlFactor * pos.quantity).toFixed(2));

      // Save updated metrics to DB
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

  async exitPosition(userId: string, positionId: string): Promise<Position> {
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
      throw new NotFoundException('Active position not found');
    }

    if (position.status === PositionStatus.CLOSED) {
      throw new BadRequestException('Position is already closed');
    }

    const avgPrice = Number(position.avgPrice);
    const currentPrice = Number(position.currentPrice);
    const isBuy = position.trade.signal.side === 'BUY';

    // Calculate final realized P&L
    const pnlFactor = isBuy ? currentPrice - avgPrice : avgPrice - currentPrice;
    const realizedPnl = parseFloat((pnlFactor * position.quantity).toFixed(2));

    // Execute database updates inside a safe Prisma Transaction
    return this.prisma.$transaction(async (tx) => {
      // 1. Close Position
      const closedPos = await tx.position.update({
        where: { id: position.id },
        data: {
          status: PositionStatus.CLOSED,
          unrealizedPnl: 0,
          realizedPnl,
          currentPrice,
        },
      });

      // 2. Update Trade record
      await tx.trade.update({
        where: { id: position.tradeId },
        data: {
          status: TradeStatus.CLOSED,
          exitPrice: currentPrice,
          pnl: realizedPnl,
        },
      });

      // 3. Create Exit Order record
      await tx.order.create({
        data: {
          tradeId: position.tradeId,
          orderType: OrderType.MARKET,
          quantity: position.quantity,
          price: currentPrice,
          status: OrderStatus.FILLED,
          brokerOrderId: `exit_order_${Date.now()}`,
        },
      });

      return closedPos;
    });
  }
}
