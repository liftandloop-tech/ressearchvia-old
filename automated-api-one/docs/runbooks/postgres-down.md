# SRE Runbook: PostgreSQL Database Down

## Symptoms
- API endpoints throw database connection errors: `PrismaClientInitializationError` or `PrismaClientKnownRequestError`.
- API `/health` endpoint returns `503 Service Unavailable` with database status down.
- All write operations (storing signals, trades, orders) and read operations fail.

## Action Steps
1. **Check Container Status**:
   Verify if the PostgreSQL container is running:
   ```bash
   docker ps -a --filter name=trading-db-prod
   ```
2. **Inspect Container Logs**:
   Look for syntax errors, out of disk space, or disk corruption errors:
   ```bash
   docker logs trading-db-prod
   ```
3. **Check Host Disk Space**:
   A common reason for database crashes is out-of-disk-space:
   ```bash
   df -h
   ```
4. **Restart PostgreSQL Service**:
   If the container has stopped:
   ```bash
   docker start trading-db-prod
   ```
5. **Verify Database Health**:
   Connect locally to verify it accepts connections and runs queries:
   ```bash
   docker exec -it trading-db-prod pg_isready -U postgres
   ```
6. **Trigger Outbox Recovery**:
   Database downtime may have caused outbox events to be missed or stuck in `PENDING` states. Once PostgreSQL is healthy, outbox recovery cron will process pending items automatically, or you can force recovery via:
   ```bash
   curl -X POST -H "Authorization: Bearer <SRE_TOKEN>" http://localhost:3000/ops/outbox/recover
   ```
