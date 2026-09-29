"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RedisKeys = void 0;
exports.RedisKeys = {
    consent: function (userId, brokerId, date) {
        return "consent:".concat(userId, ":").concat(brokerId, ":").concat(date);
    },
    brokerSession: function (userId, brokerId) {
        return "broker:session:".concat(userId, ":").concat(brokerId);
    },
    riskSegment: function (segmentId) {
        return "risk:segment:".concat(segmentId);
    },
    multiplier: function (userId, segmentId) {
        return "multiplier:".concat(userId, ":").concat(segmentId);
    },
    idempotency: function (signalId) {
        return "trade:idempotency:".concat(signalId);
    },
    userLock: function (userId) {
        return "lock:user:".concat(userId);
    },
    segmentLock: function (segmentId) {
        return "lock:segment:".concat(segmentId);
    },
    signalLock: function (signalId) {
        return "lock:signal:".concat(signalId);
    },
    reportDaily: function (userId, date) {
        return "report:daily:".concat(userId, ":").concat(date);
    },
    reportMonthly: function (userId, month) {
        return "report:monthly:".concat(userId, ":").concat(month);
    },
    circuitBreaker: function (broker) {
        return "circuit:".concat(broker);
    },
    position: function (userId, segmentId) {
        return "position:".concat(userId, ":").concat(segmentId);
    },
    userEgress: function (userId) {
        return "egress:user:".concat(userId);
    },
    userEgressLock: function (userId) {
        return "lock:egress:".concat(userId);
    },
    strategy: function (userId, segmentId) {
        return segmentId ? "strategy:".concat(userId, ":").concat(segmentId) : "strategy:".concat(userId, ":default");
    },
    systemStrategyConfig: function () {
        return "system:strategy:config";
    },
};
