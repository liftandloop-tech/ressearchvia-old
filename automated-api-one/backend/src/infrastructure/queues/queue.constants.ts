export const Queues = {
  SIGNAL_PROCESSING: 'trade-execution', // Mapped to trade-execution for backwards compatibility
  ORDER_PLACEMENT: 'order-placement',
  ORDER_MONITORING: 'order-monitoring',
  NOTIFICATION: 'notification',
  OUTBOX_DISPATCHER: 'outbox-dispatcher',
  WEBSOCKET: 'websocket',
  REPORT_GENERATION: 'report-generation',
  REPORT_EXPORT: 'report-export',
  ANALYTICS_SNAPSHOT: 'analytics-snapshot',
  POSITION_REBUILD: 'ops-position-rebuild',
  RECONCILIATION: 'broker-reconciliation',
  RISK_RECALCULATE: 'risk-recalculate',
  ANALYTICS_RECALCULATE: 'analytics-recalculate',

  EMAIL: 'email-notification',
  SMS: 'sms-notification',
  WHATSAPP: 'whatsapp-notification',
  PUSH: 'push-notification',

  SIGNAL_DLQ: 'trade-execution-dlq',
  ORDER_DLQ: 'order-placement-dlq',
  ORDER_MONITORING_DLQ: 'order-monitoring-dlq',
  NOTIFICATION_DLQ: 'notification-dlq',
  OUTBOX_DISPATCHER_DLQ: 'outbox-dispatcher-dlq',
  WEBSOCKET_DLQ: 'websocket-dlq',
  REPORT_GENERATION_DLQ: 'report-generation-dlq',
  REPORT_EXPORT_DLQ: 'report-export-dlq',
  ANALYTICS_SNAPSHOT_DLQ: 'analytics-snapshot-dlq',
  POSITION_REBUILD_DLQ: 'ops-position-rebuild-dlq',
  RECONCILIATION_DLQ: 'broker-reconciliation-dlq',
  RISK_RECALCULATE_DLQ: 'risk-recalculate-dlq',
  ANALYTICS_RECALCULATE_DLQ: 'analytics-recalculate-dlq',

  EMAIL_DLQ: 'email-notification-dlq',
  SMS_DLQ: 'sms-notification-dlq',
  WHATSAPP_DLQ: 'whatsapp-notification-dlq',
  PUSH_DLQ: 'push-notification-dlq',
};

export function getSnapshotQueueName(userId: string): string {
  let hash = 0;
  for (let i = 0; i < userId.length; i++) {
    hash += userId.charCodeAt(i);
  }
  return `analytics-snapshot-${hash % 10}`;
}

export function getSnapshotDlqName(userId: string): string {
  let hash = 0;
  for (let i = 0; i < userId.length; i++) {
    hash += userId.charCodeAt(i);
  }
  return `analytics-snapshot-dlq-${hash % 10}`;
}
