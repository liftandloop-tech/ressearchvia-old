"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RedisKeys = void 0;
exports.RedisKeys = {
    consent: (userId, brokerId, date) => `consent:${userId}:${brokerId}:${date}`,
    brokerSession: (userId, brokerId) => `broker:session:${userId}:${brokerId}`,
    riskSegment: (segmentId) => `risk:segment:${segmentId}`,
    multiplier: (userId, segmentId) => `multiplier:${userId}:${segmentId}`,
    idempotency: (signalId) => `trade:idempotency:${signalId}`,
    userLock: (userId) => `lock:user:${userId}`,
    segmentLock: (segmentId) => `lock:segment:${segmentId}`,
    signalLock: (signalId) => `lock:signal:${signalId}`,
    reportDaily: (userId, date) => `report:daily:${userId}:${date}`,
    reportMonthly: (userId, month) => `report:monthly:${userId}:${month}`,
    circuitBreaker: (broker) => `circuit:${broker}`,
    position: (userId, segmentId) => `position:${userId}:${segmentId}`,
};
//# sourceMappingURL=redis-keys.js.map