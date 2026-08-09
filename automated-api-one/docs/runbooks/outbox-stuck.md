# SRE Runbook: Outbox Event Dispatcher Stuck

## Symptoms
- Downstream systems are not receiving updates (e.g. position updates, order updates).
- The `OutboxEvent` table has events remaining in `PENDING` state longer than a few seconds.
- `outbox_dispatcher_stuck` alert or metric triggers.

## Action Steps
1. **Verify Outbox Worker Logs**:
   Inspect the `outbox-worker` logs to check if it's running or looping on a specific event:
   ```bash
   docker logs trading-outbox-worker-prod --tail 100
   ```
2. **Check for DB locks**:
   The outbox dispatcher uses `SELECT FOR UPDATE` or similar row locking. Verify if there is a stuck transaction holding locks:
   ```sql
   SELECT pid, query, state, age(clock_timestamp(), query_start) 
   FROM pg_stat_activity 
   WHERE state != 'idle' AND query LIKE '%outbox%';
   ```
3. **Force Outbox Recovery**:
   If the outbox worker is healthy but missed processing some events, trigger manual outbox recovery via the API:
   ```bash
   curl -X POST -H "Authorization: Bearer <SRE_TOKEN>" http://localhost:3000/ops/outbox/recover
   ```
4. **Restart Worker**:
   If the worker process is deadlocked or unresponsive:
   ```bash
   docker restart trading-outbox-worker-prod
   ```
