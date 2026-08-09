export enum WebsocketEvent {
  ORDER_EXECUTED = 'order.executed',
  ORDER_REJECTED = 'order.rejected',
  POSITION_UPDATED = 'position.updated',
  TARGET_HIT = 'target.hit',
  STOPLOSS_HIT = 'stoploss.hit',
  SIGNAL_RECEIVED = 'signal.received',
  SIGNAL_COMPLETED = 'signal.completed',
  RISK_LOCKED = 'risk.locked',
  RISK_UNLOCKED = 'risk.unlocked',
  BROKER_DISCONNECTED = 'broker.disconnected',
  CONSENT_REQUIRED = 'consent.required',
  SUBSCRIPTION_EXPIRED = 'subscription.expired',
}
