import { Controller, Get } from '@nestjs/common';
import {
  HealthCheckService,
  HealthCheck,
  PrismaHealthIndicator,
} from '@nestjs/terminus';
import { PrismaService } from '../prisma.service';
import { RedisHealthIndicator } from './redis.health';
import { BrokerHealthIndicator } from './broker.health';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { QueueService } from '../infrastructure/queues/queues.service';
import { TradingGateway } from '../websocket/gateway/trading.gateway';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly health: HealthCheckService,
    private readonly prismaHealth: PrismaHealthIndicator,
    private readonly prisma: PrismaService,
    private readonly redisHealth: RedisHealthIndicator,
    private readonly brokerHealth: BrokerHealthIndicator,
    private readonly queueService: QueueService,
    private readonly tradingGateway: TradingGateway,
  ) {}

  @Get()
  @HealthCheck()
  @ApiOperation({ summary: 'Run all health checks' })
  async checkAll() {
    return this.health.check([
      () => this.prismaHealth.pingCheck('database', this.prisma.baseClient),
      () => this.redisHealth.isHealthy('redis'),
      () => this.brokerHealth.isHealthy('broker'),
    ]);
  }

  @Get('db')
  @HealthCheck()
  @ApiOperation({ summary: 'Check database connectivity' })
  async checkDb() {
    return this.health.check([
      () => this.prismaHealth.pingCheck('database', this.prisma.baseClient),
    ]);
  }

  @Get('redis')
  @HealthCheck()
  @ApiOperation({ summary: 'Check Redis connectivity' })
  async checkRedis() {
    return this.health.check([() => this.redisHealth.isHealthy('redis')]);
  }

  @Get('broker')
  @ApiOperation({ summary: 'Check Broker connectivity' })
  async checkBroker() {
    return this.brokerHealth.getCustomHealth();
  }

  @Get('queues')
  @ApiOperation({ summary: 'Get aggregated queue and DLQ metrics' })
  async checkQueues() {
    const metrics = await this.queueService.getAggregatedMetrics();
    
    const signalQueue = this.queueService.getQueue('trade-execution');
    const orderQueue = this.queueService.getQueue('order-placement');
    const reportQueue = this.queueService.getQueue('report-generation');

    const signalProcessingDepth = signalQueue ? await signalQueue.getWaitingCount() : 0;
    const orderPlacementDepth = orderQueue ? await orderQueue.getWaitingCount() : 0;
    const reportDepth = reportQueue ? await reportQueue.getWaitingCount() : 0;

    let status = 'up';
    if (signalProcessingDepth > 5000 || orderPlacementDepth > 5000 || reportDepth > 10000) {
      status = 'degraded';
    }

    return {
      status,
      signalProcessingDepth,
      orderPlacementDepth,
      reportDepth,
      ...metrics,
    };
  }

  @Get('websocket')
  @ApiOperation({ summary: 'Check WebSocket Gateway health' })
  async checkWebsocket() {
    const isInitialized = !!this.tradingGateway.server;
    const activeConnections = this.tradingGateway.server?.engine?.clientsCount || 0;
    return {
      status: isInitialized ? 'up' : 'down',
      gateway: isInitialized ? 'initialized' : 'uninitialized',
      activeConnections,
    };
  }

  @Get('outbox')
  @ApiOperation({ summary: 'Check Outbox service health' })
  async checkOutbox() {
    try {
      const pendingCount = await this.prisma.outboxEvent.count({
        where: { status: 'PENDING' },
      });
      
      const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
      const stuckCount = await this.prisma.outboxEvent.count({
        where: {
          status: 'PROCESSING',
          createdAt: { lt: fiveMinutesAgo },
        },
      });

      const q = this.queueService.getQueue('outbox-dispatcher');
      const queueDepth = q ? await q.getWaitingCount() : 0;
      
      const isDegraded = stuckCount > 10;
      return {
        status: isDegraded ? 'degraded' : 'up',
        pendingEvents: pendingCount,
        stuckEvents: stuckCount,
        queueDepth,
      };
    } catch (err) {
      return {
        status: 'down',
        error: err.message,
      };
    }
  }

  @Get('reports')
  @ApiOperation({ summary: 'Check Reports service health' })
  async checkReports() {
    try {
      const q = this.queueService.getQueue('report-generation');
      const queueDepth = q ? await q.getWaitingCount() : 0;
      // We can do a quick check of database or just report status up
      return {
        status: 'up',
        queueDepth,
      };
    } catch (err) {
      return {
        status: 'down',
        error: err.message,
      };
    }
  }

  @Get('reconciliation')
  @ApiOperation({ summary: 'Check Reconciliation health' })
  async checkReconciliation() {
    try {
      const snapshots = await this.prisma.reconciliationSnapshot.findMany();
      const openIssues = snapshots.reduce((acc, s) => acc + s.openIssues, 0);

      // Find critical open issues
      const criticalCount = await this.prisma.reconciliationIssue.count({
        where: {
          severity: 'CRITICAL',
          status: { not: 'RESOLVED' },
        },
      });

      const lastRun = await this.prisma.reconciliationRun.findFirst({
        orderBy: { startedAt: 'desc' },
      });

      let status = 'healthy';
      if (criticalCount > 0) {
        status = 'critical';
      } else if (openIssues > 0) {
        status = 'degraded';
      }

      return {
        status,
        lastRun: lastRun?.completedAt || lastRun?.startedAt || null,
        openIssues,
        criticalIssues: criticalCount,
      };
    } catch (err) {
      return {
        status: 'down',
        error: err.message,
      };
    }
  }

  @Get('analytics')
  @ApiOperation({ summary: 'Check Analytics health' })
  async checkAnalytics() {
    try {
      const lastRun = await this.prisma.analyticsJobRun.findFirst({
        orderBy: { startedAt: 'desc' },
      });

      const activeUsers = await this.prisma.user.findMany({
        where: { status: 'ACTIVE' },
        select: { id: true },
      });

      let staleSnapshotsCount = 0;
      const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

      for (const u of activeUsers) {
        const lastSnap = await this.prisma.dailyPortfolioSnapshot.findFirst({
          where: { userId: u.id },
          orderBy: { date: 'desc' },
        });
        if (!lastSnap || lastSnap.date < twentyFourHoursAgo) {
          staleSnapshotsCount++;
        }
      }

      let status = 'healthy';
      if (lastRun?.status === 'FAILED') {
        status = 'degraded';
      }
      if (staleSnapshotsCount > 0) {
        status = 'degraded';
      }

      return {
        status,
        lastRun: {
          id: lastRun?.id || null,
          startedAt: lastRun?.startedAt || null,
          completedAt: lastRun?.completedAt || null,
          status: lastRun?.status || null,
          usersProcessed: lastRun?.usersProcessed || 0,
          failures: lastRun?.failures || 0,
          durationMs: lastRun?.durationMs || null,
        },
        staleSnapshotsCount,
      };
    } catch (err) {
      return {
        status: 'down',
        error: err.message,
      };
    }
  }
}
