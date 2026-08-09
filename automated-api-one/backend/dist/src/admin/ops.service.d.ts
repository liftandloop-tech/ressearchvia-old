import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { QueueService } from '../infrastructure/queues/queues.service';
import { MetricsService } from '../infrastructure/metrics/metrics.service';
import { BrokerSessionService } from '../brokers/services/broker-session.service';
import { BrokerFactory } from '../brokers/factory/broker.factory';
import { ReconciliationService } from '../reconciliation/reconciliation.service';
import { AlertingService } from '../notifications/alerting.service';
export declare class OpsService {
    private readonly prisma;
    private readonly redisService;
    private readonly queueService;
    private readonly metrics;
    private readonly brokerSessionService;
    private readonly reconciliationService;
    private readonly alertingService;
    private readonly brokerFactory;
    private readonly logger;
    constructor(prisma: PrismaService, redisService: RedisService, queueService: QueueService, metrics: MetricsService, brokerSessionService: BrokerSessionService, reconciliationService: ReconciliationService, alertingService: AlertingService, brokerFactory: BrokerFactory);
    private runOperation;
    cleanupOperationsAudit(): Promise<void>;
    replaySignal(operatorId: string, signalId: string): Promise<{
        operationId: string;
    }>;
    replayOutboxEvent(operatorId: string, eventId: string): Promise<{
        operationId: string;
    }>;
    getDlqMetrics(operatorId: string): Promise<any>;
    getDlqJobs(operatorId: string, queueName: string): Promise<any[]>;
    replayDlqJob(operatorId: string, queueName: string, jobId: string): Promise<{
        operationId: string;
    }>;
    deleteDlqJob(operatorId: string, queueName: string, jobId: string): Promise<{
        operationId: string;
    }>;
    private isMarketHours;
    pauseQueue(operatorId: string, queueName: string, force: boolean, reason?: string): Promise<{
        operationId: string;
    }>;
    resumeQueue(operatorId: string, queueName: string, reason?: string): Promise<{
        operationId: string;
    }>;
    drainQueue(operatorId: string, queueName: string, reason: string): Promise<{
        operationId: string;
    }>;
    unlockSegment(operatorId: string, segmentId: string): Promise<{
        operationId: string;
    }>;
    forceBrokerSessionRefresh(operatorId: string, userBrokerId: string): Promise<{
        operationId: string;
    }>;
    rebuildPositions(operatorId: string, userId?: string): Promise<{
        operationId: string;
    }>;
    enableMaintenance(operatorId: string, type: string): Promise<{
        operationId: string;
    }>;
    disableMaintenance(operatorId: string, type: string): Promise<{
        operationId: string;
    }>;
    stopTrading(operatorId: string, permanent?: boolean, reason?: string): Promise<{
        operationId: string;
    }>;
    startTrading(operatorId: string): Promise<{
        operationId: string;
    }>;
    exportAuditLogs(operatorId: string): Promise<{
        exportId: string;
    }>;
    getAudits(operatorId: string, query: {
        action?: string;
        operatorId?: string;
        status?: string;
        from?: string;
        page?: number;
        limit?: number;
    }): Promise<any>;
    getReconciliationRuns(): Promise<any[]>;
    getReconciliationIssues(resolved?: boolean): Promise<any[]>;
    getReconciliationIssuesSummary(): Promise<any>;
    resolveReconciliationIssue(operatorId: string, issueId: string): Promise<any>;
    escalateReconciliationIssue(operatorId: string, issueId: string): Promise<any>;
    triggerReconciliationRun(operatorId: string): Promise<any>;
    recalculateRiskSnapshot(operatorId: string, userId: string): Promise<{
        operationId: string;
    }>;
    unblockUserRisk(operatorId: string, userId: string): Promise<{
        operationId: string;
    }>;
    toggleGlobalEmergencyLock(operatorId: string, blocked: boolean, reason?: string): Promise<{
        operationId: string;
    }>;
    acknowledgeAlert(operatorId: string, alertId: string): Promise<any>;
    resolveAlert(operatorId: string, alertId: string): Promise<any>;
    getUserLiveBrokerData(userIdOrCode: string): Promise<{
        user: {
            id: any;
            name: any;
            email: any;
        };
        brokerCode: any;
        brokerClientId: any;
        isSessionActive: boolean;
        positions: never[] | import("../brokers/interfaces/broker-client.interface").PositionResponse[];
        holdings: never[] | import("../brokers/interfaces/broker-client.interface").HoldingResponse[];
        orders: any[] | never[];
        trades: never[] | import("../brokers/interfaces/broker-client.interface").BrokerTrade[];
    }>;
}
