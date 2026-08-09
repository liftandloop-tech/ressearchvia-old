# Capacity Planning

## Queue Capacity Limits
The platform enforces hard limits on queue depths to prevent memory exhaust or worker starvation:
- `order-placement`: 50,000 jobs.
- `order-monitoring`: 100,000 jobs.
- `notification`: 250,000 jobs.

## Redis Memory Sizing & SRE Policies
- **Eviction Policy**: `noeviction` (crucial because BullMQ queues and locks cannot be evicted).
- **Average Key Sizing**:
  - Idempotency key: ~200 bytes, TTL 60s/10m.
  - Active distributed locks: ~150 bytes, TTL 60s.
  - Session tokens: ~1KB, TTL 24h.
- **Eviction Strategy**: Auto-evicted via Redis TTL parameters, manual SRE purges, or automatic connection termination.

## PostgreSQL Storage Capacity
- **Daily Trades**: Assumes up to 100,000 transactions/day (~15MB data/day).
- **Daily Outbox Events**: 150,000 events/day (~40MB/day).
- **Daily Analytics Snapshots**: Up to 10,000 segments/day (~5MB/day).
- **Retention Policies**:
  - `OutboxEvent`: Cleared after dispatch or archived after 7 days.
  - `OperationsAudit`: Automatically pruned after 180 days (via SRE Operations daily cron job).

## Scaling Thresholds
- **Signal Queue Depth > 5,000**: Scale `signal-worker` replicas up.
- **Order Placement Queue Depth > 10,000**: Scale `order-worker` replicas up.
- **Outbox Queue Depth > 1,000**: Scale `outbox-worker` replicas up.
- **Websocket Active Connections > 10,000**: Scale `websocket-worker` nodes up.
