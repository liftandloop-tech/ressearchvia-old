# SRE Runbook: High Queue Depth (BullMQ)

## Symptoms
- Delayed executions: signals take several seconds or minutes to be processed.
- Queue depth metric `bullmq_queue_depth` rises above normal thresholds (e.g., > 100).
- Order execution latency spikes.

## Action Steps
1. **Identify the Backed-up Queue**:
   Check Redis queue lengths using `redis-cli`:
   ```bash
   # Check size of BullMQ queues (e.g., bull.signals.wait, bull.orders.wait)
   redis-cli LLEN bull:signals:wait
   redis-cli LLEN bull:orders:wait
   ```
2. **Inspect Worker Container Logs**:
   Verify if the workers are running and actively consuming:
   ```bash
   docker logs trading-signal-worker-prod --tail 100
   docker logs trading-order-worker-prod --tail 100
   ```
3. **Scale Up Workers**:
   If workers are healthy but overwhelmed by volume, scale up the specific worker instances in the compose setup:
   ```bash
   docker compose -f docker-compose.prod.yml up -d --scale signal-worker=3 --scale order-worker=3
   ```
4. **Identify and Clear Toxic/Failing Jobs**:
   If the queue is stuck because of recurring failures or a bug in a specific payload, use the operational endpoint to check and clean the queues or drain them if necessary:
   ```bash
   # Use the queue-drain operational endpoint (requires reason)
   curl -X POST -H "Authorization: Bearer <SRE_TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{"reason": "High queue depth due to poisonous payloads"}' \
     http://localhost:3000/ops/queues/drain
   ```
5. **Monitor Recovery**:
   Check queue sizes again to verify they are dropping back to 0.
