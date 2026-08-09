# Redis Key Registry

This document records the naming conventions, owner services, TTL parameters, and purposes of all keys managed in the platform Redis instance.

| Prefix / Pattern | TTL | Owner Service | Purpose | Eviction / Cleanup |
| --- | --- | --- | --- | --- |
| `lock:segment:<segmentId>` | 60s | `DistributedLockService` | Mutual exclusion lock to serialize segment executions. | Automated after 60s TTL or SRE Manual unlock. |
| `ops:idempotency:<action>:<resourceId>` | 60s | `OpsService` | Idempotency lock to prevent duplicate operator actions. | Automated after 60s TTL. |
| `outbox:idempotency:<eventId>` | 7 days | `OutboxService` | Deduplication lock to prevent reprocessing dispatched outbox events. | Evicted after 7 days. |
| `report:idempotency:<userId>:<type>:<period>[:segmentId]` | 10 min | `ReportsService` | Prevents redundant overlapping report generation runs. | Evicted after 10 minutes. |
| `report:lock:<reportId>` | 60s | `ReportGenerationProcessor` | Cache stampede lock preventing multiple workers generating same report. | Evicted after 60s. |
| `analytics:snapshot:lock:<userId>:<segmentId>:<date>` | 60s | `ReportsService` | Mutex lock for nightly snapshot calculations. | Evicted after 60s. |
| `system:maintenance:global` | permanent | `OpsService` | Global maintenance flag blocking trading, registrations, reports. | Manual operator deletion. |
| `system:maintenance:signals` | permanent | `OpsService` | Blocks signal publishing and processing during upgrades. | Manual operator deletion. |
| `system:maintenance:subscriptions` | permanent | `OpsService` | Blocks new subscriptions/renewals. | Manual operator deletion. |
| `system:maintenance:reports` | permanent | `OpsService` | Blocks report generation. | Manual operator deletion. |
| `trading:global:disabled` | 15 min / permanent | `OpsService` | Global kill switch payload blocking all trade fan-out executions. | Automated after 15m TTL or SRE manual del. |
| `ws:user:<userId>` | 24h | `WebsocketGateway` | Active socket ID tracking mapping for real-time user pushes. | Evicts on socket disconnect. |
| `ws:event:<eventId>` | 5m | `WebsocketGateway` | Event deduplication tracking for WebSocket clients. | Evicted after 5m. |
| `ops:broker-refresh:<userBrokerId>` | 60s | `OpsService` | Session refresh rate limiting (restricts to once per 60 seconds). | Evicted after 60s. |
