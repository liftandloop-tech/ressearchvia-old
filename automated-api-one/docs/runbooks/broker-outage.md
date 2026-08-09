# SRE Runbook: Broker Outage / API Connection Failures

## Symptoms
- Logs filled with `Broker API error`, `ECONNREFUSED`, or timeout exceptions.
- Order execution transitions to `FAILED` or gets stuck in `PENDING` states.
- High number of failed requests to external broker endpoints.

## Action Steps
1. **Verify Broker Availability**:
   Check if the broker API endpoints are responding outside our platform using curl:
   ```bash
   curl -I https://api.broker.com/health  # Replace with actual broker health endpoint
   ```
2. **Check Credential/Token Validity**:
   Verify if the API key/token has expired or if rate limits have been hit. Inspect the response headers in logs for `429 Too Many Requests` or `401 Unauthorized`.
3. **Engage Trading Kill Switch**:
   If the broker is completely down or returning garbage responses, immediately trigger the trading kill switch to stop signal processing and order placements:
   ```bash
   curl -X POST -H "Authorization: Bearer <SRE_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"enabled": true, "reason": "Broker API outage", "operatorId": "sre-user", "expiresAt": "2026-06-13T14:39:00.000Z"}' \
     http://localhost:3000/ops/trading/kill-switch
   ```
4. **Retry DLQ / Failed Orders**:
   Once the broker is back online, disable the kill switch and replay any failed queue jobs/signals:
   ```bash
   # Replay DLQ or failed jobs
   curl -X POST -H "Authorization: Bearer <SRE_TOKEN>" http://localhost:3000/ops/queues/replay-dlq
   ```
