import { WebsocketEvent } from '../enums/websocket-event.enum';
export interface WebsocketEnvelope<T> {
    version: 1;
    event: WebsocketEvent;
    timestamp: string;
    payload: T;
}
export interface OrderExecutedEvent {
    orderId: string;
    tradeId: string;
    segmentId: string;
    userId: string;
    symbol: string;
    quantity: number;
    price: number;
    executedAt: string;
}
export interface OrderRejectedEvent {
    orderId: string;
    tradeId: string;
    segmentId: string;
    userId: string;
    reason: string;
    timestamp: string;
}
export interface PositionUpdatedEvent {
    userId: string;
    segmentId: string;
    pnl: number;
    quantity: number;
    timestamp: string;
}
export interface TargetHitEvent {
    userId: string;
    tradeId: string;
    symbol: string;
    targetPrice: number;
    timestamp: string;
}
export interface StoplossHitEvent {
    userId: string;
    tradeId: string;
    symbol: string;
    stopLossPrice: number;
    timestamp: string;
}
export interface SignalReceivedEvent {
    signalId: string;
    segmentId: string;
    symbol: string;
    side: string;
    timestamp: string;
}
export interface SignalCompletedEvent {
    signalId: string;
    segmentId: string;
    status: string;
    timestamp: string;
}
export interface RiskLockedEvent {
    userId: string;
    segmentId: string;
    reason: string;
    timestamp: string;
}
export interface RiskUnlockedEvent {
    userId: string;
    segmentId: string;
    timestamp: string;
}
export interface BrokerDisconnectedEvent {
    userId: string;
    brokerCode: string;
    reason: string;
    timestamp: string;
}
export interface ConsentRequiredEvent {
    userId: string;
    brokerCode: string;
    timestamp: string;
}
export interface SubscriptionExpiredEvent {
    userId: string;
    planId: string;
    expiredAt: string;
}
