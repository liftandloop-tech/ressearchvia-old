export const RedisKeys = {
  consent: (userId: string, brokerId: string, date: string) =>
    `consent:${userId}:${brokerId}:${date}`,

  brokerSession: (userId: string, brokerId: string) =>
    `broker:session:${userId}:${brokerId}`,

  riskSegment: (segmentId: string) =>
    `risk:segment:${segmentId}`,

  multiplier: (userId: string, segmentId: string) =>
    `multiplier:${userId}:${segmentId}`,

  idempotency: (signalId: string) =>
    `trade:idempotency:${signalId}`,

  userLock: (userId: string) =>
    `lock:user:${userId}`,

  segmentLock: (segmentId: string) =>
    `lock:segment:${segmentId}`,

  signalLock: (signalId: string) =>
    `lock:signal:${signalId}`,

  reportDaily: (userId: string, date: string) =>
    `report:daily:${userId}:${date}`,

  reportMonthly: (userId: string, month: string) =>
    `report:monthly:${userId}:${month}`,

  circuitBreaker: (broker: string) =>
    `circuit:${broker}`,

  position: (userId: string, segmentId: string) =>
    `position:${userId}:${segmentId}`,
};
