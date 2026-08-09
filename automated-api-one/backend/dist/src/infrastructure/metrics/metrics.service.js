"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MetricsService = void 0;
const common_1 = require("@nestjs/common");
const prom_client_1 = require("prom-client");
let MetricsService = class MetricsService {
    registry = new prom_client_1.Registry();
    signalsReceived;
    signalsProcessed;
    signalsFailed;
    ordersPlaced;
    ordersFilled;
    ordersRejected;
    riskRejected;
    brokerCalls;
    brokerFailures;
    brokerTimeouts;
    brokerCircuitOpen;
    dlqReplayed;
    dlqPurged;
    websocketAuthFailures;
    websocketRateLimited;
    signalFanoutUsers;
    orderPlacementAttempts;
    orderMonitoringAttempts;
    executionSuccess;
    executionFailed;
    multiplierResets;
    multiplierEscalations;
    recoveryJobs;
    recoveryJobsFailed;
    recoveryOrdersRecovered;
    reportsGenerated;
    reportCacheHits;
    reportCacheMisses;
    reportGenerationFailed;
    analyticsSnapshotsCreated;
    outboxEventsCreated;
    outboxEventsProcessed;
    outboxEventsFailed;
    outboxEventsDlq;
    wsConnectionsTotal;
    wsDisconnectsTotal;
    wsMessagesSentTotal;
    wsMessagesFailedTotal;
    wsOrphanedRoomsTotal;
    operationsRequests;
    operationsSuccess;
    operationsFailed;
    operationsRejected;
    queuePausedTotal;
    operationsAuditRecordsTotal;
    operationsAuditFailuresTotal;
    reconciliationRuns;
    reconciliationIssuesTotal;
    reconciliationIssuesOpen;
    reconciliationAutoResolved;
    reconciliationFailed;
    reconciliationDuration;
    riskViolationsTotal;
    riskUsersBlockedTotal;
    riskState;
    riskDailyPnl;
    analyticsRuns;
    analyticsDuration;
    analyticsFailures;
    analyticsRetentionDeleted;
    analyticsStaleSnapshots;
    analyticsUsersProcessed;
    notificationQueueDepth;
    notificationDeliveryDuration;
    notificationRetries;
    notificationDeduplicated;
    notificationRateLimited;
    notificationProviderFailures;
    notificationProviderLatency;
    notificationScheduled;
    notificationQuietHourDeferrals;
    notificationFailover;
    sreAlertOpen;
    sreAlertAcknowledged;
    sreAlertResolved;
    activeSegmentsGauge;
    subscribersActiveGauge;
    sparkSubscriptionsGauge;
    splendidSubscriptionsGauge;
    consentsActiveTodayGauge;
    segmentsActiveGauge;
    segmentsPausedGauge;
    segmentsRiskLockedGauge;
    queueDepth;
    queueProcessing;
    queueFailed;
    queueDlqDepth;
    redisMemoryUsage;
    redisConnectedClients;
    distributedLocksActive;
    idempotencyKeysTotal;
    outboxEventsPending;
    outboxEventsProcessingGauge;
    outboxEventsFailedGauge;
    outboxEventsDlqGauge;
    brokerCircuitState;
    openPositionsGauge;
    wsActiveConnectionsGauge;
    wsRoomUsersGauge;
    wsRoomSegmentsGauge;
    wsRoomAdminGauge;
    brokerLatency;
    redisLatency;
    signalProcessingDuration;
    orderPlacementDuration;
    analyticsSnapshotDuration;
    reportGenerationDuration;
    brokerCircuitOpenDuration;
    onModuleInit() {
        this.signalsReceived = new prom_client_1.Counter({
            name: 'signals_received_total',
            help: 'Total number of signals received',
            registers: [this.registry],
        });
        this.signalsProcessed = new prom_client_1.Counter({
            name: 'signals_processed_total',
            help: 'Total number of signals successfully processed',
            registers: [this.registry],
        });
        this.signalsFailed = new prom_client_1.Counter({
            name: 'signals_failed_total',
            help: 'Total number of signals that failed processing',
            registers: [this.registry],
        });
        this.ordersPlaced = new prom_client_1.Counter({
            name: 'orders_placed_total',
            help: 'Total number of orders placed to broker',
            registers: [this.registry],
        });
        this.ordersFilled = new prom_client_1.Counter({
            name: 'orders_filled_total',
            help: 'Total number of orders filled by broker',
            registers: [this.registry],
        });
        this.ordersRejected = new prom_client_1.Counter({
            name: 'orders_rejected_total',
            help: 'Total number of orders rejected by broker',
            registers: [this.registry],
        });
        this.riskRejected = new prom_client_1.Counter({
            name: 'risk_rejections_total',
            help: 'Total number of signal executions rejected by Risk Engine',
            registers: [this.registry],
        });
        this.brokerCalls = new prom_client_1.Counter({
            name: 'broker_calls_total',
            help: 'Total number of broker API calls',
            labelNames: ['broker', 'operation', 'status'],
            registers: [this.registry],
        });
        this.brokerFailures = new prom_client_1.Counter({
            name: 'broker_failures_total',
            help: 'Total number of broker API failures',
            labelNames: ['broker', 'operation'],
            registers: [this.registry],
        });
        this.brokerTimeouts = new prom_client_1.Counter({
            name: 'broker_timeouts_total',
            help: 'Total number of broker API timeouts',
            labelNames: ['broker'],
            registers: [this.registry],
        });
        this.brokerCircuitOpen = new prom_client_1.Counter({
            name: 'broker_circuit_open_total',
            help: 'Total number of circuit breaker open transitions',
            labelNames: ['broker'],
            registers: [this.registry],
        });
        this.dlqReplayed = new prom_client_1.Counter({
            name: 'dlq_replayed_total',
            help: 'Total number of DLQ jobs replayed',
            labelNames: ['queue'],
            registers: [this.registry],
        });
        this.dlqPurged = new prom_client_1.Counter({
            name: 'dlq_purged_total',
            help: 'Total number of DLQ jobs purged',
            labelNames: ['queue'],
            registers: [this.registry],
        });
        this.websocketAuthFailures = new prom_client_1.Counter({
            name: 'websocket_auth_failures_total',
            help: 'Total number of WebSocket connection authentication failures',
            registers: [this.registry],
        });
        this.websocketRateLimited = new prom_client_1.Counter({
            name: 'websocket_rate_limited_total',
            help: 'Total number of WebSocket connection attempts rate limited',
            registers: [this.registry],
        });
        this.signalFanoutUsers = new prom_client_1.Counter({
            name: 'signal_fanout_users_total',
            help: 'Total number of target users during signal fanout',
            registers: [this.registry],
        });
        this.orderPlacementAttempts = new prom_client_1.Counter({
            name: 'order_placement_attempts_total',
            help: 'Total number of order placement attempts',
            registers: [this.registry],
        });
        this.orderMonitoringAttempts = new prom_client_1.Counter({
            name: 'order_monitoring_attempts_total',
            help: 'Total number of order monitoring check attempts',
            registers: [this.registry],
        });
        this.executionSuccess = new prom_client_1.Counter({
            name: 'execution_success_total',
            help: 'Total number of successful order executions',
            registers: [this.registry],
        });
        this.executionFailed = new prom_client_1.Counter({
            name: 'execution_failed_total',
            help: 'Total number of failed order executions',
            registers: [this.registry],
        });
        this.multiplierResets = new prom_client_1.Counter({
            name: 'multiplier_resets_total',
            help: 'Total number of risk engine lot multiplier resets',
            registers: [this.registry],
        });
        this.multiplierEscalations = new prom_client_1.Counter({
            name: 'multiplier_escalations_total',
            help: 'Total number of risk engine lot multiplier scale-ups',
            registers: [this.registry],
        });
        this.recoveryJobs = new prom_client_1.Counter({
            name: 'recovery_jobs_total',
            help: 'Total number of engine startup recovery cycles executed',
            registers: [this.registry],
        });
        this.recoveryJobsFailed = new prom_client_1.Counter({
            name: 'recovery_jobs_failed_total',
            help: 'Total number of engine recovery cycles that failed',
            registers: [this.registry],
        });
        this.recoveryOrdersRecovered = new prom_client_1.Counter({
            name: 'recovery_orders_recovered_total',
            help: 'Total number of active/pending broker orders recovered',
            registers: [this.registry],
        });
        this.reportsGenerated = new prom_client_1.Counter({
            name: 'reports_generated_total',
            help: 'Total number of reports generated',
            registers: [this.registry],
        });
        this.reportCacheHits = new prom_client_1.Counter({
            name: 'report_cache_hits_total',
            help: 'Total number of report cache hits',
            registers: [this.registry],
        });
        this.reportCacheMisses = new prom_client_1.Counter({
            name: 'report_cache_misses_total',
            help: 'Total number of report cache misses',
            registers: [this.registry],
        });
        this.reportGenerationFailed = new prom_client_1.Counter({
            name: 'report_generation_failed_total',
            help: 'Total number of report generation failures',
            registers: [this.registry],
        });
        this.analyticsSnapshotsCreated = new prom_client_1.Counter({
            name: 'analytics_snapshots_created_total',
            help: 'Total number of analytics snapshots created',
            registers: [this.registry],
        });
        this.outboxEventsCreated = new prom_client_1.Counter({
            name: 'outbox_events_created_total',
            help: 'Total number of outbox events created',
            registers: [this.registry],
        });
        this.outboxEventsProcessed = new prom_client_1.Counter({
            name: 'outbox_events_processed_total',
            help: 'Total number of outbox events successfully processed',
            registers: [this.registry],
        });
        this.outboxEventsFailed = new prom_client_1.Counter({
            name: 'outbox_events_failed_total_count',
            help: 'Total number of outbox events that failed processing',
            registers: [this.registry],
        });
        this.outboxEventsDlq = new prom_client_1.Counter({
            name: 'outbox_events_dlq_total_count',
            help: 'Total number of outbox events sent to DLQ',
            registers: [this.registry],
        });
        this.wsConnectionsTotal = new prom_client_1.Counter({
            name: 'websocket_connections_total',
            help: 'Total number of WebSocket connections initiated',
            registers: [this.registry],
        });
        this.wsDisconnectsTotal = new prom_client_1.Counter({
            name: 'websocket_disconnects_total',
            help: 'Total number of WebSocket disconnections',
            registers: [this.registry],
        });
        this.wsMessagesSentTotal = new prom_client_1.Counter({
            name: 'websocket_messages_sent_total',
            help: 'Total number of WebSocket messages successfully sent',
            registers: [this.registry],
        });
        this.wsMessagesFailedTotal = new prom_client_1.Counter({
            name: 'websocket_messages_failed_total',
            help: 'Total number of WebSocket messages that failed sending',
            registers: [this.registry],
        });
        this.wsOrphanedRoomsTotal = new prom_client_1.Counter({
            name: 'orphaned_rooms_total',
            help: 'Total number of orphaned WebSocket rooms cleaned up',
            registers: [this.registry],
        });
        this.operationsRequests = new prom_client_1.Counter({
            name: 'operations_requests_total',
            help: 'Total number of SRE/Ops requests received',
            labelNames: ['action'],
            registers: [this.registry],
        });
        this.operationsSuccess = new prom_client_1.Counter({
            name: 'operations_success_total',
            help: 'Total number of successful SRE/Ops actions',
            labelNames: ['action'],
            registers: [this.registry],
        });
        this.operationsFailed = new prom_client_1.Counter({
            name: 'operations_failed_total',
            help: 'Total number of failed SRE/Ops actions',
            labelNames: ['action'],
            registers: [this.registry],
        });
        this.operationsRejected = new prom_client_1.Counter({
            name: 'operations_rejected_total',
            help: 'Total number of rejected/forbidden SRE/Ops actions',
            labelNames: ['action'],
            registers: [this.registry],
        });
        this.queuePausedTotal = new prom_client_1.Counter({
            name: 'queue_paused_total',
            help: 'Total number of queue pausing operations',
            labelNames: ['queue'],
            registers: [this.registry],
        });
        this.operationsAuditRecordsTotal = new prom_client_1.Counter({
            name: 'operations_audit_records_total',
            help: 'Total number of operations audit records written',
            registers: [this.registry],
        });
        this.operationsAuditFailuresTotal = new prom_client_1.Counter({
            name: 'operations_audit_failures_total',
            help: 'Total number of failures to write operations audit records',
            registers: [this.registry],
        });
        this.reconciliationRuns = new prom_client_1.Counter({
            name: 'reconciliation_runs_total',
            help: 'Total number of reconciliation runs',
            registers: [this.registry],
        });
        this.reconciliationIssuesTotal = new prom_client_1.Counter({
            name: 'reconciliation_issues_total',
            help: 'Total number of reconciliation issues found',
            labelNames: ['issue_type', 'severity', 'broker'],
            registers: [this.registry],
        });
        this.reconciliationAutoResolved = new prom_client_1.Counter({
            name: 'reconciliation_auto_resolved_total',
            help: 'Total number of reconciliation auto-resolved issues',
            labelNames: ['broker'],
            registers: [this.registry],
        });
        this.reconciliationFailed = new prom_client_1.Counter({
            name: 'reconciliation_failed_total',
            help: 'Total number of failed reconciliation runs',
            registers: [this.registry],
        });
        this.riskViolationsTotal = new prom_client_1.Counter({
            name: 'risk_violations_total',
            help: 'Total number of risk violations',
            labelNames: ['rule_violated', 'severity'],
            registers: [this.registry],
        });
        this.riskUsersBlockedTotal = new prom_client_1.Counter({
            name: 'risk_users_blocked_total',
            help: 'Total number of users blocked by risk engine',
            registers: [this.registry],
        });
        this.riskState = new prom_client_1.Gauge({
            name: 'risk_state_total',
            help: 'Total users in each risk state',
            labelNames: ['state'],
            registers: [this.registry],
        });
        this.riskDailyPnl = new prom_client_1.Gauge({
            name: 'risk_daily_pnl',
            help: 'Net daily PnL of users used for risk tracking',
            labelNames: ['user'],
            registers: [this.registry],
        });
        this.analyticsRuns = new prom_client_1.Counter({
            name: 'analytics_runs_total',
            help: 'Total number of portfolio analytics runs started',
            registers: [this.registry],
        });
        this.analyticsDuration = new prom_client_1.Histogram({
            name: 'analytics_duration_ms',
            help: 'Duration of portfolio analytics runs in milliseconds',
            buckets: [100, 500, 1000, 5000, 10000, 30000, 60000, 300000],
            registers: [this.registry],
        });
        this.analyticsFailures = new prom_client_1.Counter({
            name: 'analytics_failures_total',
            help: 'Total number of portfolio analytics run failures',
            registers: [this.registry],
        });
        this.analyticsRetentionDeleted = new prom_client_1.Counter({
            name: 'analytics_retention_deleted_total',
            help: 'Total number of old equity curve points deleted by retention cleanup',
            labelNames: ['source_type'],
            registers: [this.registry],
        });
        this.analyticsStaleSnapshots = new prom_client_1.Gauge({
            name: 'analytics_stale_snapshots_total',
            help: 'Total number of stale daily portfolio snapshots detected',
            registers: [this.registry],
        });
        this.analyticsUsersProcessed = new prom_client_1.Counter({
            name: 'analytics_users_processed_total',
            help: 'Total number of users processed in analytics runs',
            registers: [this.registry],
        });
        this.notificationQueueDepth = new prom_client_1.Gauge({
            name: 'notification_queue_depth',
            help: 'Depth of notification queues',
            labelNames: ['channel'],
            registers: [this.registry],
        });
        this.notificationDeliveryDuration = new prom_client_1.Histogram({
            name: 'notification_delivery_duration_ms',
            help: 'Duration of notification delivery in milliseconds',
            labelNames: ['channel', 'provider'],
            buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000, 10000],
            registers: [this.registry],
        });
        this.notificationRetries = new prom_client_1.Counter({
            name: 'notification_retries_total',
            help: 'Total number of notification retries',
            labelNames: ['channel', 'provider'],
            registers: [this.registry],
        });
        this.notificationDeduplicated = new prom_client_1.Counter({
            name: 'notification_deduplicated_total',
            help: 'Total number of notification deduplications',
            labelNames: ['event'],
            registers: [this.registry],
        });
        this.notificationRateLimited = new prom_client_1.Counter({
            name: 'notification_rate_limited_total',
            help: 'Total number of rate-limited notifications',
            labelNames: ['channel', 'user'],
            registers: [this.registry],
        });
        this.notificationProviderFailures = new prom_client_1.Counter({
            name: 'notification_provider_failures_total',
            help: 'Total number of notification provider failures',
            labelNames: ['provider', 'channel'],
            registers: [this.registry],
        });
        this.notificationProviderLatency = new prom_client_1.Histogram({
            name: 'notification_provider_latency_ms',
            help: 'Latency of notification provider API calls in milliseconds',
            labelNames: ['provider', 'channel'],
            buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000],
            registers: [this.registry],
        });
        this.notificationScheduled = new prom_client_1.Counter({
            name: 'notification_scheduled_total',
            help: 'Total number of scheduled notifications',
            registers: [this.registry],
        });
        this.notificationQuietHourDeferrals = new prom_client_1.Counter({
            name: 'notification_quiet_hour_deferrals_total',
            help: 'Total number of notifications deferred due to quiet hours',
            registers: [this.registry],
        });
        this.notificationFailover = new prom_client_1.Counter({
            name: 'notification_failover_total',
            help: 'Total number of provider failovers',
            labelNames: ['from', 'to', 'channel'],
            registers: [this.registry],
        });
        this.sreAlertOpen = new prom_client_1.Gauge({
            name: 'sre_alert_open_total',
            help: 'Total number of SRE alerts in open state',
            registers: [this.registry],
        });
        this.sreAlertAcknowledged = new prom_client_1.Gauge({
            name: 'sre_alert_acknowledged_total',
            help: 'Total number of SRE alerts in acknowledged state',
            registers: [this.registry],
        });
        this.sreAlertResolved = new prom_client_1.Gauge({
            name: 'sre_alert_resolved_total',
            help: 'Total number of SRE alerts in resolved state',
            registers: [this.registry],
        });
        this.activeSegmentsGauge = new prom_client_1.Gauge({
            name: 'active_segments_total',
            help: 'Current total number of active user segment configurations',
            registers: [this.registry],
        });
        this.subscribersActiveGauge = new prom_client_1.Gauge({
            name: 'subscribers_active_total',
            help: 'Total number of active subscribed users',
            registers: [this.registry],
        });
        this.sparkSubscriptionsGauge = new prom_client_1.Gauge({
            name: 'spark_subscriptions_total',
            help: 'Total number of active Spark plan subscriptions',
            registers: [this.registry],
        });
        this.splendidSubscriptionsGauge = new prom_client_1.Gauge({
            name: 'splendid_subscriptions_total',
            help: 'Total number of active Splendid plan subscriptions',
            registers: [this.registry],
        });
        this.consentsActiveTodayGauge = new prom_client_1.Gauge({
            name: 'consents_active_today_total',
            help: 'Total number of active broker API consents today',
            registers: [this.registry],
        });
        this.segmentsActiveGauge = new prom_client_1.Gauge({
            name: 'segments_active_total',
            help: 'Total number of segments in ACTIVE state',
            registers: [this.registry],
        });
        this.segmentsPausedGauge = new prom_client_1.Gauge({
            name: 'segments_paused_total',
            help: 'Total number of segments in PAUSED state',
            registers: [this.registry],
        });
        this.segmentsRiskLockedGauge = new prom_client_1.Gauge({
            name: 'segments_risk_locked_total',
            help: 'Total number of segments temporarily risk-locked',
            registers: [this.registry],
        });
        this.queueDepth = new prom_client_1.Gauge({
            name: 'queue_depth',
            help: 'Current depth of waiting jobs in BullMQ queues',
            labelNames: ['queue'],
            registers: [this.registry],
        });
        this.queueProcessing = new prom_client_1.Gauge({
            name: 'queue_processing',
            help: 'Current number of active workers processing jobs',
            labelNames: ['queue'],
            registers: [this.registry],
        });
        this.queueFailed = new prom_client_1.Gauge({
            name: 'queue_failed',
            help: 'Current number of failed jobs in BullMQ queues',
            labelNames: ['queue'],
            registers: [this.registry],
        });
        this.queueDlqDepth = new prom_client_1.Gauge({
            name: 'queue_dlq_depth',
            help: 'Current depth of DLQ queues',
            labelNames: ['queue'],
            registers: [this.registry],
        });
        this.redisMemoryUsage = new prom_client_1.Gauge({
            name: 'redis_memory_usage_bytes',
            help: 'Redis database RSS memory consumption in bytes',
            registers: [this.registry],
        });
        this.redisConnectedClients = new prom_client_1.Gauge({
            name: 'redis_connected_clients',
            help: 'Number of active connected clients to Redis',
            registers: [this.registry],
        });
        this.distributedLocksActive = new prom_client_1.Gauge({
            name: 'distributed_locks_active_total',
            help: 'Current number of active distributed locks in Redis',
            registers: [this.registry],
        });
        this.idempotencyKeysTotal = new prom_client_1.Gauge({
            name: 'idempotency_keys_total',
            help: 'Current number of active idempotency keys in Redis',
            registers: [this.registry],
        });
        this.outboxEventsPending = new prom_client_1.Gauge({
            name: 'outbox_events_pending_total',
            help: 'Current count of pending events in outbox table',
            registers: [this.registry],
        });
        this.outboxEventsProcessingGauge = new prom_client_1.Gauge({
            name: 'outbox_events_processing_total',
            help: 'Current count of outbox events currently being processed',
            registers: [this.registry],
        });
        this.outboxEventsFailedGauge = new prom_client_1.Gauge({
            name: 'outbox_events_failed_total',
            help: 'Current count of failed outbox events',
            registers: [this.registry],
        });
        this.outboxEventsDlqGauge = new prom_client_1.Gauge({
            name: 'outbox_events_dlq_total',
            help: 'Current count of outbox events marked as DLQ/failed permanently',
            registers: [this.registry],
        });
        this.brokerCircuitState = new prom_client_1.Gauge({
            name: 'broker_circuit_state',
            help: 'Current state of broker circuit breakers (0 = CLOSED, 1 = HALF_OPEN, 2 = OPEN)',
            labelNames: ['broker'],
            registers: [this.registry],
        });
        this.openPositionsGauge = new prom_client_1.Gauge({
            name: 'open_positions',
            help: 'Current number of open positions in the platform',
            registers: [this.registry],
        });
        this.wsActiveConnectionsGauge = new prom_client_1.Gauge({
            name: 'websocket_active_connections',
            help: 'Current number of active WebSocket connections',
            registers: [this.registry],
        });
        this.wsRoomUsersGauge = new prom_client_1.Gauge({
            name: 'websocket_room_users',
            help: 'Current number of users in WebSocket rooms',
            registers: [this.registry],
        });
        this.wsRoomSegmentsGauge = new prom_client_1.Gauge({
            name: 'websocket_room_segments',
            help: 'Current number of segments in WebSocket rooms',
            registers: [this.registry],
        });
        this.wsRoomAdminGauge = new prom_client_1.Gauge({
            name: 'websocket_room_admin',
            help: 'Current number of active connections in the admin WebSocket room',
            registers: [this.registry],
        });
        this.reconciliationIssuesOpen = new prom_client_1.Gauge({
            name: 'reconciliation_issues_open',
            help: 'Current count of open reconciliation issues',
            labelNames: ['issue_type', 'severity', 'broker'],
            registers: [this.registry],
        });
        this.brokerLatency = new prom_client_1.Histogram({
            name: 'broker_latency_ms',
            help: 'Latency of broker API calls in milliseconds',
            labelNames: ['broker'],
            buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000],
            registers: [this.registry],
        });
        this.redisLatency = new prom_client_1.Histogram({
            name: 'redis_latency_ms',
            help: 'Latency of Redis PING command in milliseconds',
            buckets: [0.5, 1, 2, 5, 10, 25, 50],
            registers: [this.registry],
        });
        this.signalProcessingDuration = new prom_client_1.Histogram({
            name: 'signal_processing_duration_ms',
            help: 'Duration of signal parsing and user fan-out operations in ms',
            buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000],
            registers: [this.registry],
        });
        this.orderPlacementDuration = new prom_client_1.Histogram({
            name: 'order_placement_duration_ms',
            help: 'Duration of broker order placement in milliseconds',
            buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000],
            registers: [this.registry],
        });
        this.analyticsSnapshotDuration = new prom_client_1.Histogram({
            name: 'analytics_snapshot_duration_ms',
            help: 'Duration of nightly user segment snapshot aggregation in milliseconds',
            buckets: [50, 200, 500, 1000, 5000, 10000],
            registers: [this.registry],
        });
        this.reportGenerationDuration = new prom_client_1.Histogram({
            name: 'report_generation_duration_ms',
            help: 'Duration of report generation in milliseconds',
            buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000],
            registers: [this.registry],
        });
        this.brokerCircuitOpenDuration = new prom_client_1.Histogram({
            name: 'broker_circuit_open_duration_ms',
            help: 'Duration of broker circuit breaker open states in milliseconds',
            labelNames: ['broker'],
            buckets: [1000, 5000, 10000, 30000, 60000, 300000],
            registers: [this.registry],
        });
        this.reconciliationDuration = new prom_client_1.Histogram({
            name: 'reconciliation_duration_ms',
            help: 'Duration of reconciliation runs in milliseconds',
            buckets: [1000, 5000, 15000, 30000, 60000, 300000, 900000],
            registers: [this.registry],
        });
    }
    incrementSignalsReceived() { this.signalsReceived.inc(); }
    incrementSignalsProcessed() { this.signalsProcessed.inc(); }
    incrementSignalsFailed() { this.signalsFailed.inc(); }
    incrementOrdersPlaced() { this.ordersPlaced.inc(); }
    incrementOrdersFilled() { this.ordersFilled.inc(); }
    incrementOrdersRejected() { this.ordersRejected.inc(); }
    incrementRiskRejected() { this.riskRejected.inc(); }
    incrementBrokerCalls(broker, operation, status) {
        this.brokerCalls.inc({
            broker,
            operation: operation || 'unknown',
            status: status || 'unknown',
        });
    }
    incrementBrokerFailures(broker, operation) {
        this.brokerFailures.inc({
            broker,
            operation: operation || 'unknown',
        });
    }
    incrementBrokerTimeouts(broker) { this.brokerTimeouts.inc({ broker }); }
    incrementBrokerCircuitOpen(broker) { this.brokerCircuitOpen.inc({ broker }); }
    incrementDlqReplayed(queue) { this.dlqReplayed.inc({ queue }); }
    incrementDlqPurged(queue) { this.dlqPurged.inc({ queue }); }
    incrementWebsocketAuthFailures() { this.websocketAuthFailures.inc(); }
    incrementWebsocketRateLimited() { this.websocketRateLimited.inc(); }
    incrementSignalFanoutUsers(count = 1) { this.signalFanoutUsers.inc(count); }
    incrementOrderPlacementAttempts() { this.orderPlacementAttempts.inc(); }
    incrementOrderMonitoringAttempts() { this.orderMonitoringAttempts.inc(); }
    incrementExecutionSuccess() { this.executionSuccess.inc(); }
    incrementExecutionFailed() { this.executionFailed.inc(); }
    incrementMultiplierResets() { this.multiplierResets.inc(); }
    incrementMultiplierEscalations() { this.multiplierEscalations.inc(); }
    incrementRecoveryJobs() { this.recoveryJobs.inc(); }
    incrementRecoveryJobsFailed() { this.recoveryJobsFailed.inc(); }
    incrementRecoveryOrdersRecovered(count = 1) { this.recoveryOrdersRecovered.inc(count); }
    incrementReportsGenerated() { this.reportsGenerated.inc(); }
    incrementReportCacheHits() { this.reportCacheHits.inc(); }
    incrementReportCacheMisses() { this.reportCacheMisses.inc(); }
    incrementReportGenerationFailed() { this.reportGenerationFailed.inc(); }
    incrementAnalyticsSnapshotsCreated() { this.analyticsSnapshotsCreated.inc(); }
    incrementOutboxEventsCreated() { this.outboxEventsCreated.inc(); }
    incrementOutboxEventsProcessed() { this.outboxEventsProcessed.inc(); }
    incrementOutboxEventsFailed() { this.outboxEventsFailed.inc(); }
    incrementOutboxEventsDlq() { this.outboxEventsDlq.inc(); }
    incrementWsConnections() { this.wsConnectionsTotal.inc(); }
    incrementWsDisconnects() { this.wsDisconnectsTotal.inc(); }
    incrementWsMessagesSent() { this.wsMessagesSentTotal.inc(); }
    incrementWsMessagesFailed() { this.wsMessagesFailedTotal.inc(); }
    incrementWsOrphanedRooms() { this.wsOrphanedRoomsTotal.inc(); }
    incrementOperationsRequests(action) { this.operationsRequests.inc({ action }); }
    incrementOperationsSuccess(action) { this.operationsSuccess.inc({ action }); }
    incrementOperationsFailed(action) { this.operationsFailed.inc({ action }); }
    incrementOperationsRejected(action) { this.operationsRejected.inc({ action }); }
    incrementQueuePausedTotal(queue) { this.queuePausedTotal.inc({ queue }); }
    incrementOperationsAuditRecords() { this.operationsAuditRecordsTotal.inc(); }
    incrementOperationsAuditFailures() { this.operationsAuditFailuresTotal.inc(); }
    setActiveSegments(count) { this.activeSegmentsGauge.set(count); }
    setSubscribersActive(count) { this.subscribersActiveGauge.set(count); }
    setSparkSubscriptions(count) { this.sparkSubscriptionsGauge.set(count); }
    setSplendidSubscriptions(count) { this.splendidSubscriptionsGauge.set(count); }
    setConsentsActiveToday(count) { this.consentsActiveTodayGauge.set(count); }
    setSegmentsActive(count) { this.segmentsActiveGauge.set(count); }
    setSegmentsPaused(count) { this.segmentsPausedGauge.set(count); }
    setSegmentsRiskLocked(count) { this.segmentsRiskLockedGauge.set(count); }
    setQueueDepth(queueName, depth) { this.queueDepth.set({ queue: queueName }, depth); }
    setQueueProcessing(queueName, count) { this.queueProcessing.set({ queue: queueName }, count); }
    setQueueFailed(queueName, count) { this.queueFailed.set({ queue: queueName }, count); }
    setQueueDlqDepth(queueName, count) { this.queueDlqDepth.set({ queue: queueName }, count); }
    setRedisMemoryUsage(bytes) { this.redisMemoryUsage.set(bytes); }
    setRedisConnectedClients(count) { this.redisConnectedClients.set(count); }
    setDistributedLocksActive(count) { this.distributedLocksActive.set(count); }
    setRedisIdempotencyKeysActive(count) { this.idempotencyKeysTotal.set(count); }
    setOutboxEventsPending(count) { this.outboxEventsPending.set(count); }
    setOutboxEventsProcessing(count) { this.outboxEventsProcessingGauge.set(count); }
    setOutboxEventsFailed(count) { this.outboxEventsFailedGauge.set(count); }
    setOutboxEventsDlqCount(count) { this.outboxEventsDlqGauge.set(count); }
    setBrokerCircuitState(broker, state) { this.brokerCircuitState.set({ broker }, state); }
    setOpenPositions(count) { this.openPositionsGauge.set(count); }
    setWsActiveConnections(count) { this.wsActiveConnectionsGauge.set(count); }
    setWsRoomUsers(count) { this.wsRoomUsersGauge.set(count); }
    setWsRoomSegments(count) { this.wsRoomSegmentsGauge.set(count); }
    setWsRoomAdmin(count) { this.wsRoomAdminGauge.set(count); }
    observeBrokerLatency(broker, ms) { this.brokerLatency.observe({ broker }, ms); }
    observeRedisLatency(ms) { this.redisLatency.observe(ms); }
    observeSignalProcessingDuration(ms) { this.signalProcessingDuration.observe(ms); }
    observeOrderPlacementDuration(ms) { this.orderPlacementDuration.observe(ms); }
    observeAnalyticsSnapshotDuration(ms) { this.analyticsSnapshotDuration.observe(ms); }
    observeReportGenerationDuration(ms) { this.reportGenerationDuration.observe(ms); }
    observeBrokerCircuitOpenDuration(broker, ms) { this.brokerCircuitOpenDuration.observe({ broker }, ms); }
    observeReconciliationDuration(ms) { this.reconciliationDuration.observe(ms); }
    incrementReconciliationRuns() { this.reconciliationRuns.inc(); }
    incrementReconciliationIssuesTotal(issueType, severity, broker) {
        this.reconciliationIssuesTotal.inc({ issue_type: issueType, severity, broker });
    }
    setReconciliationIssuesOpen(issueType, severity, broker, count) {
        this.reconciliationIssuesOpen.set({ issue_type: issueType, severity, broker }, count);
    }
    incrementReconciliationAutoResolved(broker) {
        this.reconciliationAutoResolved.inc({ broker });
    }
    incrementReconciliationFailed() {
        this.reconciliationFailed.inc();
    }
    incrementRiskViolations(rule, severity) {
        this.riskViolationsTotal.inc({ rule_violated: rule, severity });
    }
    incrementRiskUsersBlocked() {
        this.riskUsersBlockedTotal.inc();
    }
    setRiskState(state, val) {
        this.riskState.set({ state }, val);
    }
    setRiskDailyPnl(user, pnl) {
        this.riskDailyPnl.set({ user }, pnl);
    }
    incrementAnalyticsRuns() { this.analyticsRuns.inc(); }
    observeAnalyticsDuration(ms) { this.analyticsDuration.observe(ms); }
    incrementAnalyticsFailures() { this.analyticsFailures.inc(); }
    incrementAnalyticsRetentionDeleted(sourceType, count = 1) {
        this.analyticsRetentionDeleted.inc({ source_type: sourceType }, count);
    }
    setAnalyticsStaleSnapshots(count) { this.analyticsStaleSnapshots.set(count); }
    incrementAnalyticsUsersProcessed(count = 1) { this.analyticsUsersProcessed.inc(count); }
    setNotificationQueueDepth(channel, count) {
        this.notificationQueueDepth.set({ channel }, count);
    }
    observeNotificationDeliveryDuration(channel, provider, ms) {
        this.notificationDeliveryDuration.observe({ channel, provider }, ms);
    }
    incrementNotificationRetries(channel, provider) {
        this.notificationRetries.inc({ channel, provider });
    }
    incrementNotificationDeduplicated(event) {
        this.notificationDeduplicated.inc({ event });
    }
    incrementNotificationRateLimited(channel, user) {
        this.notificationRateLimited.inc({ channel, user });
    }
    incrementNotificationProviderFailures(provider, channel) {
        this.notificationProviderFailures.inc({ provider, channel });
    }
    observeNotificationProviderLatency(provider, channel, ms) {
        this.notificationProviderLatency.observe({ provider, channel }, ms);
    }
    incrementNotificationScheduled() {
        this.notificationScheduled.inc();
    }
    incrementNotificationQuietHourDeferrals() {
        this.notificationQuietHourDeferrals.inc();
    }
    incrementNotificationFailover(from, to, channel) {
        this.notificationFailover.inc({ from, to, channel });
    }
    setSreAlertOpen(count) {
        this.sreAlertOpen.set(count);
    }
    setSreAlertAcknowledged(count) {
        this.sreAlertAcknowledged.set(count);
    }
    setSreAlertResolved(count) {
        this.sreAlertResolved.set(count);
    }
    async getMetrics() {
        return this.registry.metrics();
    }
};
exports.MetricsService = MetricsService;
exports.MetricsService = MetricsService = __decorate([
    (0, common_1.Injectable)()
], MetricsService);
//# sourceMappingURL=metrics.service.js.map