export declare const RedisKeys: {
    consent: (userId: string, brokerId: string, date: string) => string;
    brokerSession: (userId: string, brokerId: string) => string;
    riskSegment: (segmentId: string) => string;
    multiplier: (userId: string, segmentId: string) => string;
    idempotency: (signalId: string) => string;
    userLock: (userId: string) => string;
    segmentLock: (segmentId: string) => string;
    signalLock: (signalId: string) => string;
    reportDaily: (userId: string, date: string) => string;
    reportMonthly: (userId: string, month: string) => string;
    circuitBreaker: (broker: string) => string;
    position: (userId: string, segmentId: string) => string;
};
