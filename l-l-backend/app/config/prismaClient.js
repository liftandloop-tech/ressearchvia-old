import pg from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from "@prisma/client";

// Global connection pool to protect PostgreSQL from connection exhaustion
let pool = null;
let prismaInstance = null;

export function getPrismaClient() {
  if (!prismaInstance) {
    const connectionString = process.env.DATABASE_URL || "postgresql://postgres:postgrespassword@localhost:5432/trading_platform?schema=public";
    pool = new pg.Pool({ 
      connectionString,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
    });
    
    pool.on('error', (err) => {
      console.error('Unexpected PostgreSQL Pool Error:', err);
    });

    const adapter = new PrismaPg(pool);
    prismaInstance = new PrismaClient({ adapter });
  }
  return prismaInstance;
}

export const prisma = getPrismaClient();

/**
 * Safely converts string IDs (like 24-char MongoDB ObjectIds) into valid 36-char UUID format for PostgreSQL.
 * @param {string} id - Input ID string
 * @returns {string|null} Formatted 36-char UUID or null
 */
export function toUuid(id) {
  if (!id) return null;
  const str = id.toString().replace(/-/g, '');
  if (str.length === 32) {
    return `${str.slice(0,8)}-${str.slice(8,12)}-${str.slice(12,16)}-${str.slice(16,20)}-${str.slice(20,32)}`;
  }
  if (str.length === 24) {
    const padded = str + '00000000';
    return `${padded.slice(0,8)}-${padded.slice(8,12)}-${padded.slice(12,16)}-${padded.slice(16,20)}-${padded.slice(20,32)}`;
  }
  return id.toString();
}

/**
 * Calculates and updates PostgreSQL Automated Trading Performance metrics for a given user.
 * Reads closed trades from PostgreSQL 'trades' table and updates 'user_performances', 'segment_performances',
 * and 'daily_portfolio_snapshots' tables.
 */
export async function calculateAutomatedTradingPerformance(userId) {
  const pgUserId = toUuid(userId);
  if (!pgUserId) return null;

  try {
    const userTrades = await prisma.trade.findMany({
      where: {
        userId: pgUserId,
        status: 'CLOSED',
      },
      orderBy: { createdAt: 'asc' },
    });

    let totalPnl = 0;
    let grossProfit = 0;
    let grossLoss = 0;
    let winningTrades = 0;
    let losingTrades = 0;
    let maxDrawdown = 0;
    let peakEquity = 0;

    let currentEquity = 0;

    for (const trade of userTrades) {
      const pnl = parseFloat(trade.pnl || 0);
      totalPnl += pnl;
      currentEquity += pnl;

      if (pnl > 0) {
        grossProfit += pnl;
        winningTrades++;
      } else if (pnl < 0) {
        grossLoss += Math.abs(pnl);
        losingTrades++;
      }

      if (currentEquity > peakEquity) {
        peakEquity = currentEquity;
      }
      const dd = peakEquity > 0 ? (peakEquity - currentEquity) : 0;
      if (dd > maxDrawdown) {
        maxDrawdown = dd;
      }
    }

    const totalTrades = userTrades.length;
    const firstTradeAt = totalTrades > 0 ? userTrades[0].createdAt : null;
    const lastTradeAt = totalTrades > 0 ? userTrades[totalTrades.length - 1].createdAt : null;

    // Upsert User Performance in PostgreSQL
    const performance = await prisma.userPerformance.upsert({
      where: { userId: pgUserId },
      update: {
        totalPnl,
        grossProfit,
        grossLoss,
        totalTrades,
        winningTrades,
        losingTrades,
        maxDrawdown,
        firstTradeAt,
        lastTradeAt,
        calculatedAt: new Date(),
      },
      create: {
        userId: pgUserId,
        totalPnl,
        grossProfit,
        grossLoss,
        totalTrades,
        winningTrades,
        losingTrades,
        maxDrawdown,
        firstTradeAt,
        lastTradeAt,
        calculatedAt: new Date(),
      },
    });

    return performance;
  } catch (error) {
    console.error(`[PostgreSQL] Error calculating automated trading performance for user ${pgUserId}:`, error);
    throw error;
  }
}
