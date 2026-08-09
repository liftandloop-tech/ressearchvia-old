import { OpsService } from './ops.service';
export declare class OpsController {
    private readonly opsService;
    constructor(opsService: OpsService);
    replaySignal(req: any, signalId: string): Promise<{
        operationId: string;
    }>;
    replayOutboxEvent(req: any, eventId: string): Promise<{
        operationId: string;
    }>;
    getDlqMetrics(req: any): Promise<any>;
    getDlqJobs(req: any, queue: string): Promise<any[]>;
    replayDlqJob(req: any, queue: string, jobId: string): Promise<{
        operationId: string;
    }>;
    deleteDlqJob(req: any, queue: string, jobId: string): Promise<{
        operationId: string;
    }>;
    pauseQueue(req: any, queue: string, force?: string, reason?: string): Promise<{
        operationId: string;
    }>;
    resumeQueue(req: any, queue: string, reason?: string): Promise<{
        operationId: string;
    }>;
    drainQueue(req: any, queue: string, reason: string): Promise<{
        operationId: string;
    }>;
    unlockSegment(req: any, segmentId: string): Promise<{
        operationId: string;
    }>;
    forceBrokerRefresh(req: any, userBrokerId: string): Promise<{
        operationId: string;
    }>;
    rebuildAllPositions(req: any): Promise<{
        operationId: string;
    }>;
    rebuildUserPositions(req: any, userId: string): Promise<{
        operationId: string;
    }>;
    enableMaintenance(req: any, type?: string): Promise<{
        operationId: string;
    }>;
    disableMaintenance(req: any, type?: string): Promise<{
        operationId: string;
    }>;
    stopTrading(req: any, permanent?: string, reason?: string): Promise<{
        operationId: string;
    }>;
    startTrading(req: any): Promise<{
        operationId: string;
    }>;
    exportAudit(req: any): Promise<{
        exportId: string;
    }>;
    getAudits(req: any, action?: string, operatorId?: string, status?: string, from?: string, page?: string, limit?: string): Promise<any>;
    getReconciliationRuns(): Promise<any[]>;
    getReconciliationIssues(resolved?: string): Promise<any[]>;
    getReconciliationIssuesSummary(): Promise<any>;
    resolveReconciliationIssue(req: any, issueId: string): Promise<any>;
    escalateReconciliationIssue(req: any, issueId: string): Promise<any>;
    triggerReconciliationRun(req: any): Promise<any>;
    forceRecalculate(req: any, userId: string): Promise<{
        operationId: string;
    }>;
    unblockUserRisk(req: any, userId: string): Promise<{
        operationId: string;
    }>;
    toggleGlobalLock(req: any, blocked: boolean, reason?: string): Promise<{
        operationId: string;
    }>;
    acknowledgeAlert(req: any, alertId: string): Promise<any>;
    resolveAlert(req: any, alertId: string): Promise<any>;
    getUserLiveBrokerData(identifier: string): Promise<{
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
