# Disaster Recovery Runbook

This runbook defines the action steps to recover the platform from catastrophic system failures.

## 1. Complete Redis State Loss
### Impact
- Active queue states, distributed locks, rate-limits, and session states are wiped.
- Workers fail closed due to Redis healthchecks.

### Recovery Procedure
1. Stop all workers:
   ```bash
   docker-compose -f docker-compose.prod.yml scale signal-worker=0 order-worker=0 outbox-worker=0 websocket-worker=0 report-worker=0 position-worker=0 cron-worker=0
   ```
2. Restore the latest `/data/dump.rdb` hourly backup from S3 to the Redis container `/data` directory.
3. Start Redis service.
4. Rebuild the positions cache globally to reconcile active Postgres position states with Redis:
   ```bash
   curl -X POST -H "Authorization: Bearer <token>" http://api:3000/ops/positions/rebuild
   ```
5. Scale workers back to their original count.

---

## 2. Database Corruption & Restore
### Recovery Procedure
1. Enable global maintenance mode to stop incoming signals and subscriptions:
   ```bash
   curl -X POST http://api:3000/ops/maintenance/enable?type=global
   ```
2. Terminate all active database connections.
3. Restore DB from the latest valid `pg_dump` snapshot:
   ```bash
   pg_restore -h postgres -U postgres -d trading_platform_prod -c /backups/db/daily/db_backup_latest.dump
   ```
4. Replay outbox events that occurred after the backup timestamp to sync external systems.
5. Disable maintenance mode:
   ```bash
   curl -X POST http://api:3000/ops/maintenance/disable?type=global
   ```
