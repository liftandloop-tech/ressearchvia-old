# Deployment & Rollback Checklist

This checklist must be executed for every production and staging release.

## 1. Pre-Deployment Operations
- [ ] Take a manual PostgreSQL backup:
  ```bash
  pg_dump -h <host> -U postgres -d trading_platform > backup_pre_deploy.sql
  ```
- [ ] Take a manual Redis snapshot:
  ```redis
  BGSAVE
  ```
- [ ] Review pending migrations:
  ```bash
  npx prisma migrate status
  ```
- [ ] Prepare the rollback script (SQL script to undo migrations and rollback containers).

## 2. During Deployment
- [ ] Apply database migrations:
  ```bash
  npx prisma migrate deploy
  ```
- [ ] Build and roll out the multi-stage Docker images.
- [ ] Scale down/restart containers gracefully (using rolling update strategy).

## 3. Post-Deployment Verification
- [ ] Verify HTTP `/health` is returning `200 OK`.
- [ ] Verify outbox health: `GET /health` contains outbox connection status.
- [ ] Verify reports service is reachable.
- [ ] Verify WebSocket gateway is accepting connection upgrades.
- [ ] Monitor Prometheus `/metrics` for error rate spikes.

## 4. Rollback Runbook (In case of failure)
- [ ] Invalidate currently queued/unprocessed BullMQ jobs if they depend on broken schemas.
- [ ] Roll back Docker container images to the previous stable release tag.
- [ ] Restore database if schema changes corrupted live data:
  ```bash
  psql -h <host> -U postgres -d trading_platform < backup_pre_deploy.sql
  ```
