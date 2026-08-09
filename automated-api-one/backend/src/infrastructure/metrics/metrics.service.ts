import { Injectable, OnModuleInit } from '@nestjs/common';
import { Registry, Counter, Gauge, Histogram } from 'prom-client';

@Injectable()
export class MetricsService implements OnModuleInit {
  private readonly registry = new Registry();

  // --- COUNTERS ---
  private signalsReceived!: Counter<string>;
  private signalsProcessed!: Counter<string>;
  private signalsFailed!: Counter<string>;
  private ordersPlaced!: Counter<string>;
  private ordersFilled!: Counter<string>;
  private ordersRejected!: Counter<string>;
  private riskRejected!: Counter<string>;
  private brokerCalls!: Counter<string>;
  private brokerFailures!: Counter<string>;
  private brokerTimeouts!: Counter<string>;
  private brokerCircuitOpen!: Counter<string>;
  private dlqReplayed!: Counter<string>;
  private dlqPurged!: Counter<string>;
  private websocketAuthFailures!: Counter<string>;
  private websocketRateLimited!: Counter<string>;
  private signalFanoutUsers!: Counter<string>;
  private orderPlacementAttempts!: Counter<string>;
  private orderMonitoringAttempts!: Counter<string>;
  private executionSuccess!: Counter<string>;
  private executionFailed!: Counter<string>;
  private multiplierResets!: Counter<string>;
  private multiplierEscalations!: Counter<string>;
  private recoveryJobs!: Counter<string>;
  private recoveryJobsFailed!: Counter<string>;
  private recoveryOrdersRecovered!: Counter<string>;
  private reportsGenerated!: Counter<string>;
  private reportCacheHits!: Counter<string>;
  private reportCacheMisses!: Counter<string>;
  private reportGenerationFailed!: Counter<string>;
  private analyticsSnapshotsCreated!: Counter<string>;
  private outboxEventsCreated!: Counter<string>;
  private outboxEventsProcessed!: Counter<string>;
  private outboxEventsFailed!: Counter<string>;
  private outboxEventsDlq!: Counter<string>;
  private wsConnectionsTotal!: Counter<string>;
  private wsDisconnectsTotal!: Counter<string>;
  private wsMessagesSentTotal!: Counter<string>;
  private wsMessagesFailedTotal!: Counter<string>;
  private wsOrphanedRoomsTotal!: Counter<string>;
  private operationsRequests!: Counter<string>;
  private operationsSuccess!: Counter<string>;
  private operationsFailed!: Counter<string>;
  private operationsRejected!: Counter<string>;
  private queuePausedTotal!: Counter<string>;
  private operationsAuditRecordsTotal!: Counter<string>;
  private operationsAuditFailuresTotal!: Counter<string>;

  // --- RECONCILIATION METRICS ---
  private reconciliationRuns!: Counter<string>;
  private reconciliationIssuesTotal!: Counter<string>;
  private reconciliationIssuesOpen!: Gauge<string>;
  private reconciliationAutoResolved!: Counter<string>;
  private reconciliationFailed!: Counter<string>;
  private reconciliationDuration!: Histogram<string>;

  // --- RISK METRICS ---
  private riskViolationsTotal!: Counter<string>;
  private riskUsersBlockedTotal!: Counter<string>;
  private riskState!: Gauge<string>;
  private riskDailyPnl!: Gauge<string>;

  // --- ANALYTICS METRICS ---
  private analyticsRuns!: Counter<string>;
  private analyticsDuration!: Histogram<string>;
  private analyticsFailures!: Counter<string>;
  private analyticsRetentionDeleted!: Counter<string>;
  private analyticsStaleSnapshots!: Gauge<string>;
  private analyticsUsersProcessed!: Counter<string>;

  // --- NOTIFICATION & SRE ALERT METRICS ---
  private notificationQueueDepth!: Gauge<string>;
  private notificationDeliveryDuration!: Histogram<string>;
  private notificationRetries!: Counter<string>;
  private notificationDeduplicated!: Counter<string>;
  private notificationRateLimited!: Counter<string>;
  private notificationProviderFailures!: Counter<string>;
  private notificationProviderLatency!: Histogram<string>;
  private notificationScheduled!: Counter<string>;
  private notificationQuietHourDeferrals!: Counter<string>;
  private notificationFailover!: Counter<string>;
  private sreAlertOpen!: Gauge<string>;
  private sreAlertAcknowledged!: Gauge<string>;
  private sreAlertResolved!: Gauge<string>;

  // --- GAUGES ---
  private activeSegmentsGauge!: Gauge<string>;
  private subscribersActiveGauge!: Gauge<string>;
  private sparkSubscriptionsGauge!: Gauge<string>;
  private splendidSubscriptionsGauge!: Gauge<string>;
  private consentsActiveTodayGauge!: Gauge<string>;
  private segmentsActiveGauge!: Gauge<string>;
  private segmentsPausedGauge!: Gauge<string>;
  private segmentsRiskLockedGauge!: Gauge<string>;
  private queueDepth!: Gauge<string>;
  private queueProcessing!: Gauge<string>;
  private queueFailed!: Gauge<string>;
  private queueDlqDepth!: Gauge<string>;
  private redisMemoryUsage!: Gauge<string>;
  private redisConnectedClients!: Gauge<string>;
  private distributedLocksActive!: Gauge<string>;
  private idempotencyKeysTotal!: Gauge<string>;
  private outboxEventsPending!: Gauge<string>;
  private outboxEventsProcessingGauge!: Gauge<string>;
  private outboxEventsFailedGauge!: Gauge<string>;
  private outboxEventsDlqGauge!: Gauge<string>;
  private brokerCircuitState!: Gauge<string>;
  private openPositionsGauge!: Gauge<string>;
  private wsActiveConnectionsGauge!: Gauge<string>;
  private wsRoomUsersGauge!: Gauge<string>;
  private wsRoomSegmentsGauge!: Gauge<string>;
  private wsRoomAdminGauge!: Gauge<string>;

  // --- HISTOGRAMS ---
  private brokerLatency!: Histogram<string>;
  private redisLatency!: Histogram<string>;
  private signalProcessingDuration!: Histogram<string>;
  private orderPlacementDuration!: Histogram<string>;
  private analyticsSnapshotDuration!: Histogram<string>;
  private reportGenerationDuration!: Histogram<string>;
  private brokerCircuitOpenDuration!: Histogram<string>;

  onModuleInit() {
    // --- Initialize Counters ---
    this.signalsReceived = new Counter({
      name: 'signals_received_total',
      help: 'Total number of signals received',
      registers: [this.registry],
    });
    this.signalsProcessed = new Counter({
      name: 'signals_processed_total',
      help: 'Total number of signals successfully processed',
      registers: [this.registry],
    });
    this.signalsFailed = new Counter({
      name: 'signals_failed_total',
      help: 'Total number of signals that failed processing',
      registers: [this.registry],
    });
    this.ordersPlaced = new Counter({
      name: 'orders_placed_total',
      help: 'Total number of orders placed to broker',
      registers: [this.registry],
    });
    this.ordersFilled = new Counter({
      name: 'orders_filled_total',
      help: 'Total number of orders filled by broker',
      registers: [this.registry],
    });
    this.ordersRejected = new Counter({
      name: 'orders_rejected_total',
      help: 'Total number of orders rejected by broker',
      registers: [this.registry],
    });
    this.riskRejected = new Counter({
      name: 'risk_rejections_total',
      help: 'Total number of signal executions rejected by Risk Engine',
      registers: [this.registry],
    });
    this.brokerCalls = new Counter({
      name: 'broker_calls_total',
      help: 'Total number of broker API calls',
      labelNames: ['broker', 'operation', 'status'],
      registers: [this.registry],
    });
    this.brokerFailures = new Counter({
      name: 'broker_failures_total',
      help: 'Total number of broker API failures',
      labelNames: ['broker', 'operation'],
      registers: [this.registry],
    });
    this.brokerTimeouts = new Counter({
      name: 'broker_timeouts_total',
      help: 'Total number of broker API timeouts',
      labelNames: ['broker'],
      registers: [this.registry],
    });
    this.brokerCircuitOpen = new Counter({
      name: 'broker_circuit_open_total',
      help: 'Total number of circuit breaker open transitions',
      labelNames: ['broker'],
      registers: [this.registry],
    });
    this.dlqReplayed = new Counter({
      name: 'dlq_replayed_total',
      help: 'Total number of DLQ jobs replayed',
      labelNames: ['queue'],
      registers: [this.registry],
    });
    this.dlqPurged = new Counter({
      name: 'dlq_purged_total',
      help: 'Total number of DLQ jobs purged',
      labelNames: ['queue'],
      registers: [this.registry],
    });
    this.websocketAuthFailures = new Counter({
      name: 'websocket_auth_failures_total',
      help: 'Total number of WebSocket connection authentication failures',
      registers: [this.registry],
    });
    this.websocketRateLimited = new Counter({
      name: 'websocket_rate_limited_total',
      help: 'Total number of WebSocket connection attempts rate limited',
      registers: [this.registry],
    });
    this.signalFanoutUsers = new Counter({
      name: 'signal_fanout_users_total',
      help: 'Total number of target users during signal fanout',
      registers: [this.registry],
    });
    this.orderPlacementAttempts = new Counter({
      name: 'order_placement_attempts_total',
      help: 'Total number of order placement attempts',
      registers: [this.registry],
    });
    this.orderMonitoringAttempts = new Counter({
      name: 'order_monitoring_attempts_total',
      help: 'Total number of order monitoring check attempts',
      registers: [this.registry],
    });
    this.executionSuccess = new Counter({
      name: 'execution_success_total',
      help: 'Total number of successful order executions',
      registers: [this.registry],
    });
    this.executionFailed = new Counter({
      name: 'execution_failed_total',
      help: 'Total number of failed order executions',
      registers: [this.registry],
    });
    this.multiplierResets = new Counter({
      name: 'multiplier_resets_total',
      help: 'Total number of risk engine lot multiplier resets',
      registers: [this.registry],
    });
    this.multiplierEscalations = new Counter({
      name: 'multiplier_escalations_total',
      help: 'Total number of risk engine lot multiplier scale-ups',
      registers: [this.registry],
    });
    this.recoveryJobs = new Counter({
      name: 'recovery_jobs_total',
      help: 'Total number of engine startup recovery cycles executed',
      registers: [this.registry],
    });
    this.recoveryJobsFailed = new Counter({
      name: 'recovery_jobs_failed_total',
      help: 'Total number of engine recovery cycles that failed',
      registers: [this.registry],
    });
    this.recoveryOrdersRecovered = new Counter({
      name: 'recovery_orders_recovered_total',
      help: 'Total number of active/pending broker orders recovered',
      registers: [this.registry],
    });
    this.reportsGenerated = new Counter({
      name: 'reports_generated_total',
      help: 'Total number of reports generated',
      registers: [this.registry],
    });
    this.reportCacheHits = new Counter({
      name: 'report_cache_hits_total',
      help: 'Total number of report cache hits',
      registers: [this.registry],
    });
    this.reportCacheMisses = new Counter({
      name: 'report_cache_misses_total',
      help: 'Total number of report cache misses',
      registers: [this.registry],
    });
    this.reportGenerationFailed = new Counter({
      name: 'report_generation_failed_total',
      help: 'Total number of report generation failures',
      registers: [this.registry],
    });
    this.analyticsSnapshotsCreated = new Counter({
      name: 'analytics_snapshots_created_total',
      help: 'Total number of analytics snapshots created',
      registers: [this.registry],
    });
    this.outboxEventsCreated = new Counter({
      name: 'outbox_events_created_total',
      help: 'Total number of outbox events created',
      registers: [this.registry],
    });
    this.outboxEventsProcessed = new Counter({
      name: 'outbox_events_processed_total',
      help: 'Total number of outbox events successfully processed',
      registers: [this.registry],
    });
    this.outboxEventsFailed = new Counter({
      name: 'outbox_events_failed_total_count',
      help: 'Total number of outbox events that failed processing',
      registers: [this.registry],
    });
    this.outboxEventsDlq = new Counter({
      name: 'outbox_events_dlq_total_count',
      help: 'Total number of outbox events sent to DLQ',
      registers: [this.registry],
    });
    this.wsConnectionsTotal = new Counter({
      name: 'websocket_connections_total',
      help: 'Total number of WebSocket connections initiated',
      registers: [this.registry],
    });
    this.wsDisconnectsTotal = new Counter({
      name: 'websocket_disconnects_total',
      help: 'Total number of WebSocket disconnections',
      registers: [this.registry],
    });
    this.wsMessagesSentTotal = new Counter({
      name: 'websocket_messages_sent_total',
      help: 'Total number of WebSocket messages successfully sent',
      registers: [this.registry],
    });
    this.wsMessagesFailedTotal = new Counter({
      name: 'websocket_messages_failed_total',
      help: 'Total number of WebSocket messages that failed sending',
      registers: [this.registry],
    });
    this.wsOrphanedRoomsTotal = new Counter({
      name: 'orphaned_rooms_total',
      help: 'Total number of orphaned WebSocket rooms cleaned up',
      registers: [this.registry],
    });
    this.operationsRequests = new Counter({
      name: 'operations_requests_total',
      help: 'Total number of SRE/Ops requests received',
      labelNames: ['action'],
      registers: [this.registry],
    });
    this.operationsSuccess = new Counter({
      name: 'operations_success_total',
      help: 'Total number of successful SRE/Ops actions',
      labelNames: ['action'],
      registers: [this.registry],
    });
    this.operationsFailed = new Counter({
      name: 'operations_failed_total',
      help: 'Total number of failed SRE/Ops actions',
      labelNames: ['action'],
      registers: [this.registry],
    });
    this.operationsRejected = new Counter({
      name: 'operations_rejected_total',
      help: 'Total number of rejected/forbidden SRE/Ops actions',
      labelNames: ['action'],
      registers: [this.registry],
    });
    this.queuePausedTotal = new Counter({
      name: 'queue_paused_total',
      help: 'Total number of queue pausing operations',
      labelNames: ['queue'],
      registers: [this.registry],
    });
    this.operationsAuditRecordsTotal = new Counter({
      name: 'operations_audit_records_total',
      help: 'Total number of operations audit records written',
      registers: [this.registry],
    });
    this.operationsAuditFailuresTotal = new Counter({
      name: 'operations_audit_failures_total',
      help: 'Total number of failures to write operations audit records',
      registers: [this.registry],
    });
    this.reconciliationRuns = new Counter({
      name: 'reconciliation_runs_total',
      help: 'Total number of reconciliation runs',
      registers: [this.registry],
    });
    this.reconciliationIssuesTotal = new Counter({
      name: 'reconciliation_issues_total',
      help: 'Total number of reconciliation issues found',
      labelNames: ['issue_type', 'severity', 'broker'],
      registers: [this.registry],
    });
    this.reconciliationAutoResolved = new Counter({
      name: 'reconciliation_auto_resolved_total',
      help: 'Total number of reconciliation auto-resolved issues',
      labelNames: ['broker'],
      registers: [this.registry],
    });
    this.reconciliationFailed = new Counter({
      name: 'reconciliation_failed_total',
      help: 'Total number of failed reconciliation runs',
      registers: [this.registry],
    });

    // --- RISK METRICS ---
    this.riskViolationsTotal = new Counter({
      name: 'risk_violations_total',
      help: 'Total number of risk violations',
      labelNames: ['rule_violated', 'severity'],
      registers: [this.registry],
    });
    this.riskUsersBlockedTotal = new Counter({
      name: 'risk_users_blocked_total',
      help: 'Total number of users blocked by risk engine',
      registers: [this.registry],
    });
    this.riskState = new Gauge({
      name: 'risk_state_total',
      help: 'Total users in each risk state',
      labelNames: ['state'],
      registers: [this.registry],
    });
    this.riskDailyPnl = new Gauge({
      name: 'risk_daily_pnl',
      help: 'Net daily PnL of users used for risk tracking',
      labelNames: ['user'],
      registers: [this.registry],
    });

    // --- ANALYTICS METRICS ---
    this.analyticsRuns = new Counter({
      name: 'analytics_runs_total',
      help: 'Total number of portfolio analytics runs started',
      registers: [this.registry],
    });
    this.analyticsDuration = new Histogram({
      name: 'analytics_duration_ms',
      help: 'Duration of portfolio analytics runs in milliseconds',
      buckets: [100, 500, 1000, 5000, 10000, 30000, 60000, 300000],
      registers: [this.registry],
    });
    this.analyticsFailures = new Counter({
      name: 'analytics_failures_total',
      help: 'Total number of portfolio analytics run failures',
      registers: [this.registry],
    });
    this.analyticsRetentionDeleted = new Counter({
      name: 'analytics_retention_deleted_total',
      help: 'Total number of old equity curve points deleted by retention cleanup',
      labelNames: ['source_type'],
      registers: [this.registry],
    });
    this.analyticsStaleSnapshots = new Gauge({
      name: 'analytics_stale_snapshots_total',
      help: 'Total number of stale daily portfolio snapshots detected',
      registers: [this.registry],
    });
    this.analyticsUsersProcessed = new Counter({
      name: 'analytics_users_processed_total',
      help: 'Total number of users processed in analytics runs',
      registers: [this.registry],
    });

    // --- NOTIFICATION & SRE ALERT METRICS ---
    this.notificationQueueDepth = new Gauge({
      name: 'notification_queue_depth',
      help: 'Depth of notification queues',
      labelNames: ['channel'],
      registers: [this.registry],
    });
    this.notificationDeliveryDuration = new Histogram({
      name: 'notification_delivery_duration_ms',
      help: 'Duration of notification delivery in milliseconds',
      labelNames: ['channel', 'provider'],
      buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000, 10000],
      registers: [this.registry],
    });
    this.notificationRetries = new Counter({
      name: 'notification_retries_total',
      help: 'Total number of notification retries',
      labelNames: ['channel', 'provider'],
      registers: [this.registry],
    });
    this.notificationDeduplicated = new Counter({
      name: 'notification_deduplicated_total',
      help: 'Total number of notification deduplications',
      labelNames: ['event'],
      registers: [this.registry],
    });
    this.notificationRateLimited = new Counter({
      name: 'notification_rate_limited_total',
      help: 'Total number of rate-limited notifications',
      labelNames: ['channel', 'user'],
      registers: [this.registry],
    });
    this.notificationProviderFailures = new Counter({
      name: 'notification_provider_failures_total',
      help: 'Total number of notification provider failures',
      labelNames: ['provider', 'channel'],
      registers: [this.registry],
    });
    this.notificationProviderLatency = new Histogram({
      name: 'notification_provider_latency_ms',
      help: 'Latency of notification provider API calls in milliseconds',
      labelNames: ['provider', 'channel'],
      buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000],
      registers: [this.registry],
    });
    this.notificationScheduled = new Counter({
      name: 'notification_scheduled_total',
      help: 'Total number of scheduled notifications',
      registers: [this.registry],
    });
    this.notificationQuietHourDeferrals = new Counter({
      name: 'notification_quiet_hour_deferrals_total',
      help: 'Total number of notifications deferred due to quiet hours',
      registers: [this.registry],
    });
    this.notificationFailover = new Counter({
      name: 'notification_failover_total',
      help: 'Total number of provider failovers',
      labelNames: ['from', 'to', 'channel'],
      registers: [this.registry],
    });
    this.sreAlertOpen = new Gauge({
      name: 'sre_alert_open_total',
      help: 'Total number of SRE alerts in open state',
      registers: [this.registry],
    });
    this.sreAlertAcknowledged = new Gauge({
      name: 'sre_alert_acknowledged_total',
      help: 'Total number of SRE alerts in acknowledged state',
      registers: [this.registry],
    });
    this.sreAlertResolved = new Gauge({
      name: 'sre_alert_resolved_total',
      help: 'Total number of SRE alerts in resolved state',
      registers: [this.registry],
    });


    // --- Initialize Gauges ---
    this.activeSegmentsGauge = new Gauge({
      name: 'active_segments_total',
      help: 'Current total number of active user segment configurations',
      registers: [this.registry],
    });
    this.subscribersActiveGauge = new Gauge({
      name: 'subscribers_active_total',
      help: 'Total number of active subscribed users',
      registers: [this.registry],
    });
    this.sparkSubscriptionsGauge = new Gauge({
      name: 'spark_subscriptions_total',
      help: 'Total number of active Spark plan subscriptions',
      registers: [this.registry],
    });
    this.splendidSubscriptionsGauge = new Gauge({
      name: 'splendid_subscriptions_total',
      help: 'Total number of active Splendid plan subscriptions',
      registers: [this.registry],
    });
    this.consentsActiveTodayGauge = new Gauge({
      name: 'consents_active_today_total',
      help: 'Total number of active broker API consents today',
      registers: [this.registry],
    });
    this.segmentsActiveGauge = new Gauge({
      name: 'segments_active_total',
      help: 'Total number of segments in ACTIVE state',
      registers: [this.registry],
    });
    this.segmentsPausedGauge = new Gauge({
      name: 'segments_paused_total',
      help: 'Total number of segments in PAUSED state',
      registers: [this.registry],
    });
    this.segmentsRiskLockedGauge = new Gauge({
      name: 'segments_risk_locked_total',
      help: 'Total number of segments temporarily risk-locked',
      registers: [this.registry],
    });
    this.queueDepth = new Gauge({
      name: 'queue_depth',
      help: 'Current depth of waiting jobs in BullMQ queues',
      labelNames: ['queue'],
      registers: [this.registry],
    });
    this.queueProcessing = new Gauge({
      name: 'queue_processing',
      help: 'Current number of active workers processing jobs',
      labelNames: ['queue'],
      registers: [this.registry],
    });
    this.queueFailed = new Gauge({
      name: 'queue_failed',
      help: 'Current number of failed jobs in BullMQ queues',
      labelNames: ['queue'],
      registers: [this.registry],
    });
    this.queueDlqDepth = new Gauge({
      name: 'queue_dlq_depth',
      help: 'Current depth of DLQ queues',
      labelNames: ['queue'],
      registers: [this.registry],
    });
    this.redisMemoryUsage = new Gauge({
      name: 'redis_memory_usage_bytes',
      help: 'Redis database RSS memory consumption in bytes',
      registers: [this.registry],
    });
    this.redisConnectedClients = new Gauge({
      name: 'redis_connected_clients',
      help: 'Number of active connected clients to Redis',
      registers: [this.registry],
    });
    this.distributedLocksActive = new Gauge({
      name: 'distributed_locks_active_total',
      help: 'Current number of active distributed locks in Redis',
      registers: [this.registry],
    });
    this.idempotencyKeysTotal = new Gauge({
      name: 'idempotency_keys_total',
      help: 'Current number of active idempotency keys in Redis',
      registers: [this.registry],
    });
    this.outboxEventsPending = new Gauge({
      name: 'outbox_events_pending_total',
      help: 'Current count of pending events in outbox table',
      registers: [this.registry],
    });
    this.outboxEventsProcessingGauge = new Gauge({
      name: 'outbox_events_processing_total',
      help: 'Current count of outbox events currently being processed',
      registers: [this.registry],
    });
    this.outboxEventsFailedGauge = new Gauge({
      name: 'outbox_events_failed_total',
      help: 'Current count of failed outbox events',
      registers: [this.registry],
    });
    this.outboxEventsDlqGauge = new Gauge({
      name: 'outbox_events_dlq_total',
      help: 'Current count of outbox events marked as DLQ/failed permanently',
      registers: [this.registry],
    });
    this.brokerCircuitState = new Gauge({
      name: 'broker_circuit_state',
      help: 'Current state of broker circuit breakers (0 = CLOSED, 1 = HALF_OPEN, 2 = OPEN)',
      labelNames: ['broker'],
      registers: [this.registry],
    });
    this.openPositionsGauge = new Gauge({
      name: 'open_positions',
      help: 'Current number of open positions in the platform',
      registers: [this.registry],
    });
    this.wsActiveConnectionsGauge = new Gauge({
      name: 'websocket_active_connections',
      help: 'Current number of active WebSocket connections',
      registers: [this.registry],
    });
    this.wsRoomUsersGauge = new Gauge({
      name: 'websocket_room_users',
      help: 'Current number of users in WebSocket rooms',
      registers: [this.registry],
    });
    this.wsRoomSegmentsGauge = new Gauge({
      name: 'websocket_room_segments',
      help: 'Current number of segments in WebSocket rooms',
      registers: [this.registry],
    });
    this.wsRoomAdminGauge = new Gauge({
      name: 'websocket_room_admin',
      help: 'Current number of active connections in the admin WebSocket room',
      registers: [this.registry],
    });
    this.reconciliationIssuesOpen = new Gauge({
      name: 'reconciliation_issues_open',
      help: 'Current count of open reconciliation issues',
      labelNames: ['issue_type', 'severity', 'broker'],
      registers: [this.registry],
    });

    // --- Initialize Histograms ---
    this.brokerLatency = new Histogram({
      name: 'broker_latency_ms',
      help: 'Latency of broker API calls in milliseconds',
      labelNames: ['broker'],
      buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000],
      registers: [this.registry],
    });
    this.redisLatency = new Histogram({
      name: 'redis_latency_ms',
      help: 'Latency of Redis PING command in milliseconds',
      buckets: [0.5, 1, 2, 5, 10, 25, 50],
      registers: [this.registry],
    });
    this.signalProcessingDuration = new Histogram({
      name: 'signal_processing_duration_ms',
      help: 'Duration of signal parsing and user fan-out operations in ms',
      buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000],
      registers: [this.registry],
    });
    this.orderPlacementDuration = new Histogram({
      name: 'order_placement_duration_ms',
      help: 'Duration of broker order placement in milliseconds',
      buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000],
      registers: [this.registry],
    });
    this.analyticsSnapshotDuration = new Histogram({
      name: 'analytics_snapshot_duration_ms',
      help: 'Duration of nightly user segment snapshot aggregation in milliseconds',
      buckets: [50, 200, 500, 1000, 5000, 10000],
      registers: [this.registry],
    });
    this.reportGenerationDuration = new Histogram({
      name: 'report_generation_duration_ms',
      help: 'Duration of report generation in milliseconds',
      buckets: [5, 10, 25, 50, 100, 250, 500, 1000, 2000, 5000],
      registers: [this.registry],
    });
    this.brokerCircuitOpenDuration = new Histogram({
      name: 'broker_circuit_open_duration_ms',
      help: 'Duration of broker circuit breaker open states in milliseconds',
      labelNames: ['broker'],
      buckets: [1000, 5000, 10000, 30000, 60000, 300000],
      registers: [this.registry],
    });
    this.reconciliationDuration = new Histogram({
      name: 'reconciliation_duration_ms',
      help: 'Duration of reconciliation runs in milliseconds',
      buckets: [1000, 5000, 15000, 30000, 60000, 300000, 900000],
      registers: [this.registry],
    });
  }

  // --- Counter Helpers ---
  incrementSignalsReceived() { this.signalsReceived.inc(); }
  incrementSignalsProcessed() { this.signalsProcessed.inc(); }
  incrementSignalsFailed() { this.signalsFailed.inc(); }
  incrementOrdersPlaced() { this.ordersPlaced.inc(); }
  incrementOrdersFilled() { this.ordersFilled.inc(); }
  incrementOrdersRejected() { this.ordersRejected.inc(); }
  incrementRiskRejected() { this.riskRejected.inc(); }
  incrementBrokerCalls(broker: string, operation?: string, status?: string) {
    this.brokerCalls.inc({
      broker,
      operation: operation || 'unknown',
      status: status || 'unknown',
    });
  }
  incrementBrokerFailures(broker: string, operation?: string) {
    this.brokerFailures.inc({
      broker,
      operation: operation || 'unknown',
    });
  }
  incrementBrokerTimeouts(broker: string) { this.brokerTimeouts.inc({ broker }); }
  incrementBrokerCircuitOpen(broker: string) { this.brokerCircuitOpen.inc({ broker }); }
  incrementDlqReplayed(queue: string) { this.dlqReplayed.inc({ queue }); }
  incrementDlqPurged(queue: string) { this.dlqPurged.inc({ queue }); }
  incrementWebsocketAuthFailures() { this.websocketAuthFailures.inc(); }
  incrementWebsocketRateLimited() { this.websocketRateLimited.inc(); }
  incrementSignalFanoutUsers(count: number = 1) { this.signalFanoutUsers.inc(count); }
  incrementOrderPlacementAttempts() { this.orderPlacementAttempts.inc(); }
  incrementOrderMonitoringAttempts() { this.orderMonitoringAttempts.inc(); }
  incrementExecutionSuccess() { this.executionSuccess.inc(); }
  incrementExecutionFailed() { this.executionFailed.inc(); }
  incrementMultiplierResets() { this.multiplierResets.inc(); }
  incrementMultiplierEscalations() { this.multiplierEscalations.inc(); }
  incrementRecoveryJobs() { this.recoveryJobs.inc(); }
  incrementRecoveryJobsFailed() { this.recoveryJobsFailed.inc(); }
  incrementRecoveryOrdersRecovered(count: number = 1) { this.recoveryOrdersRecovered.inc(count); }
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
  incrementOperationsRequests(action: string) { this.operationsRequests.inc({ action }); }
  incrementOperationsSuccess(action: string) { this.operationsSuccess.inc({ action }); }
  incrementOperationsFailed(action: string) { this.operationsFailed.inc({ action }); }
  incrementOperationsRejected(action: string) { this.operationsRejected.inc({ action }); }
  incrementQueuePausedTotal(queue: string) { this.queuePausedTotal.inc({ queue }); }
  incrementOperationsAuditRecords() { this.operationsAuditRecordsTotal.inc(); }
  incrementOperationsAuditFailures() { this.operationsAuditFailuresTotal.inc(); }


  // --- Gauge Helpers ---
  setActiveSegments(count: number) { this.activeSegmentsGauge.set(count); }
  setSubscribersActive(count: number) { this.subscribersActiveGauge.set(count); }
  setSparkSubscriptions(count: number) { this.sparkSubscriptionsGauge.set(count); }
  setSplendidSubscriptions(count: number) { this.splendidSubscriptionsGauge.set(count); }
  setConsentsActiveToday(count: number) { this.consentsActiveTodayGauge.set(count); }
  setSegmentsActive(count: number) { this.segmentsActiveGauge.set(count); }
  setSegmentsPaused(count: number) { this.segmentsPausedGauge.set(count); }
  setSegmentsRiskLocked(count: number) { this.segmentsRiskLockedGauge.set(count); }
  setQueueDepth(queueName: string, depth: number) { this.queueDepth.set({ queue: queueName }, depth); }
  setQueueProcessing(queueName: string, count: number) { this.queueProcessing.set({ queue: queueName }, count); }
  setQueueFailed(queueName: string, count: number) { this.queueFailed.set({ queue: queueName }, count); }
  setQueueDlqDepth(queueName: string, count: number) { this.queueDlqDepth.set({ queue: queueName }, count); }
  setRedisMemoryUsage(bytes: number) { this.redisMemoryUsage.set(bytes); }
  setRedisConnectedClients(count: number) { this.redisConnectedClients.set(count); }
  setDistributedLocksActive(count: number) { this.distributedLocksActive.set(count); }
  setRedisIdempotencyKeysActive(count: number) { this.idempotencyKeysTotal.set(count); }
  setOutboxEventsPending(count: number) { this.outboxEventsPending.set(count); }
  setOutboxEventsProcessing(count: number) { this.outboxEventsProcessingGauge.set(count); }
  setOutboxEventsFailed(count: number) { this.outboxEventsFailedGauge.set(count); }
  setOutboxEventsDlqCount(count: number) { this.outboxEventsDlqGauge.set(count); }
  setBrokerCircuitState(broker: string, state: number) { this.brokerCircuitState.set({ broker }, state); }
  setOpenPositions(count: number) { this.openPositionsGauge.set(count); }
  setWsActiveConnections(count: number) { this.wsActiveConnectionsGauge.set(count); }
  setWsRoomUsers(count: number) { this.wsRoomUsersGauge.set(count); }
  setWsRoomSegments(count: number) { this.wsRoomSegmentsGauge.set(count); }
  setWsRoomAdmin(count: number) { this.wsRoomAdminGauge.set(count); }

  // --- Histogram Helpers ---
  observeBrokerLatency(broker: string, ms: number) { this.brokerLatency.observe({ broker }, ms); }
  observeRedisLatency(ms: number) { this.redisLatency.observe(ms); }
  observeSignalProcessingDuration(ms: number) { this.signalProcessingDuration.observe(ms); }
  observeOrderPlacementDuration(ms: number) { this.orderPlacementDuration.observe(ms); }
  observeAnalyticsSnapshotDuration(ms: number) { this.analyticsSnapshotDuration.observe(ms); }
  observeReportGenerationDuration(ms: number) { this.reportGenerationDuration.observe(ms); }
  observeBrokerCircuitOpenDuration(broker: string, ms: number) { this.brokerCircuitOpenDuration.observe({ broker }, ms); }
  observeReconciliationDuration(ms: number) { this.reconciliationDuration.observe(ms); }

  incrementReconciliationRuns() { this.reconciliationRuns.inc(); }
  incrementReconciliationIssuesTotal(issueType: string, severity: string, broker: string) {
    this.reconciliationIssuesTotal.inc({ issue_type: issueType, severity, broker });
  }
  setReconciliationIssuesOpen(issueType: string, severity: string, broker: string, count: number) {
    this.reconciliationIssuesOpen.set({ issue_type: issueType, severity, broker }, count);
  }
  incrementReconciliationAutoResolved(broker: string) {
    this.reconciliationAutoResolved.inc({ broker });
  }
  incrementReconciliationFailed() {
    this.reconciliationFailed.inc();
  }

  // --- Risk Helper Methods ---
  incrementRiskViolations(rule: string, severity: string) {
    this.riskViolationsTotal.inc({ rule_violated: rule, severity });
  }
  incrementRiskUsersBlocked() {
    this.riskUsersBlockedTotal.inc();
  }
  setRiskState(state: string, val: number) {
    this.riskState.set({ state }, val);
  }
  setRiskDailyPnl(user: string, pnl: number) {
    this.riskDailyPnl.set({ user }, pnl);
  }

  // --- Analytics Helper Methods ---
  incrementAnalyticsRuns() { this.analyticsRuns.inc(); }
  observeAnalyticsDuration(ms: number) { this.analyticsDuration.observe(ms); }
  incrementAnalyticsFailures() { this.analyticsFailures.inc(); }
  incrementAnalyticsRetentionDeleted(sourceType: string, count: number = 1) {
    this.analyticsRetentionDeleted.inc({ source_type: sourceType }, count);
  }
  setAnalyticsStaleSnapshots(count: number) { this.analyticsStaleSnapshots.set(count); }
  incrementAnalyticsUsersProcessed(count: number = 1) { this.analyticsUsersProcessed.inc(count); }

  // --- Notification & SRE Alert Helpers ---
  setNotificationQueueDepth(channel: string, count: number) {
    this.notificationQueueDepth.set({ channel }, count);
  }
  observeNotificationDeliveryDuration(channel: string, provider: string, ms: number) {
    this.notificationDeliveryDuration.observe({ channel, provider }, ms);
  }
  incrementNotificationRetries(channel: string, provider: string) {
    this.notificationRetries.inc({ channel, provider });
  }
  incrementNotificationDeduplicated(event: string) {
    this.notificationDeduplicated.inc({ event });
  }
  incrementNotificationRateLimited(channel: string, user: string) {
    this.notificationRateLimited.inc({ channel, user });
  }
  incrementNotificationProviderFailures(provider: string, channel: string) {
    this.notificationProviderFailures.inc({ provider, channel });
  }
  observeNotificationProviderLatency(provider: string, channel: string, ms: number) {
    this.notificationProviderLatency.observe({ provider, channel }, ms);
  }
  incrementNotificationScheduled() {
    this.notificationScheduled.inc();
  }
  incrementNotificationQuietHourDeferrals() {
    this.notificationQuietHourDeferrals.inc();
  }
  incrementNotificationFailover(from: string, to: string, channel: string) {
    this.notificationFailover.inc({ from, to, channel });
  }
  setSreAlertOpen(count: number) {
    this.sreAlertOpen.set(count);
  }
  setSreAlertAcknowledged(count: number) {
    this.sreAlertAcknowledged.set(count);
  }
  setSreAlertResolved(count: number) {
    this.sreAlertResolved.set(count);
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }
}
