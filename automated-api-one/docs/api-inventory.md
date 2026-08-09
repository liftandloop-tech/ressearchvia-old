# API Inventory

This document catalogues all endpoints exposed by the platform services.

## Auth

* `POST /auth/login` (Public) - Login with mobile & MPIN.
* `POST /auth/refresh` (Public) - Refresh JWT access token.

## Signals

* `POST /signals/publish` (USER / SRE / ADMIN) - Publish and execute a new signal.

## Subscriptions

* `GET /subscriptions/plans` (USER) - List available subscription plans.
* `GET /subscriptions/current` (USER) - Get active subscription for user.
* `GET /subscriptions/status` (USER) - Check subscription validation details.
* `GET /subscriptions/history` (USER) - Paginated subscription history.
* `POST /subscriptions` (USER) - Create/Renew subscription.
* `DELETE /subscriptions/:id` (USER) - Cancel active subscription.

## Positions & Trades

* `GET /positions` (USER) - Get active trading positions.
* `GET /trades` (USER) - Get user trade execution history.

## SRE Operations

* `POST /ops/signals/:signalId/replay` (SUPERADMIN / SRE) - Replay a signal.
* `POST /ops/outbox/:eventId/replay` (SUPERADMIN / SRE) - Replay outbox event.
* `GET /ops/dlq` (SUPERADMIN / SRE) - DLQ overall metrics.
* `GET /ops/dlq/:queue` (SUPERADMIN / SRE) - List jobs in a queue's DLQ.
* `POST /ops/dlq/:queue/:jobId/replay` (SUPERADMIN / SRE) - Replay job from DLQ (Max 3).
* `POST /ops/dlq/:queue/:jobId/delete` (SUPERADMIN / SRE) - Purge job from DLQ.
* `POST /ops/queues/:queue/pause` (SUPERADMIN / SRE) - Pause queue (checks market hours).
* `POST /ops/queues/:queue/resume` (SUPERADMIN / SRE) - Resume queue.
* `POST /ops/queues/:queue/drain` (SUPERADMIN only) - Drain active queue jobs (marks CANCELLED).
* `POST /ops/segments/:segmentId/unlock` (SUPERADMIN / SRE) - Force unlock Redis segment lock.
* `POST /ops/brokers/:userBrokerId/refresh` (SUPERADMIN / SRE) - Rate-limited force session refresh.
* `POST /ops/positions/rebuild` (SUPERADMIN / SRE) - Rebuild all position cache in background.
* `POST /ops/positions/:userId/rebuild` (SUPERADMIN / SRE) - Rebuild user position cache in background.
* `POST /ops/maintenance/enable` (SUPERADMIN / SRE) - Enable granular maintenance (`global`, `signals`, `subscriptions`, `reports`).
* `POST /ops/maintenance/disable` (SUPERADMIN / SRE) - Disable granular maintenance.
* `POST /ops/trading/stop` (SUPERADMIN / SRE) - Trigger emergency global trading stop (kill switch).
* `POST /ops/trading/start` (SUPERADMIN / SRE) - Clear emergency trading stop.
* `POST /ops/audit/export` (SUPERADMIN / SRE) - Export SRE operations audit logs to CSV.
* `GET /ops/audit` (SUPERADMIN / SRE) - Paginated operations audit logs.
