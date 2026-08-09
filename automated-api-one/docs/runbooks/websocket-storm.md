# SRE Runbook: WebSocket Connection Storm / High Memory Usage

## Symptoms
- WebSocket worker container memory usage spikes, leading to OOM restarts.
- High connection latency or dropped connections for clients.
- High `websocket_connections_total` metric.

## Action Steps
1. **Analyze Current Connection Count**:
   Verify the number of active WebSocket connections:
   ```bash
   # Check active connections metric if accessible or check socket usage
   ss -t -a | grep -i 3000 | wc -l
   ```
2. **Inspect Worker Logs**:
   Look for connection reject events, authentication failures, or disconnect loops:
   ```bash
   docker logs trading-websocket-worker-prod --tail 200
   ```
3. **Scale the WebSocket Layer**:
   If resources are exhausted, scale up WebSocket workers behind the load balancer:
   ```bash
   docker compose -f docker-compose.prod.yml up -d --scale websocket-worker=3
   ```
4. **Rate Limit / Shed Load**:
   If clients are reconnecting aggressively, ensure the load balancer uses exponential backoff.
   If needed, trigger the global maintenance mode for websocket/subscriptions to reject new connections:
   ```bash
   # Set maintenance mode for subscriptions to reject / shed load
   redis-cli SET system:maintenance:subscriptions "true"
   ```
5. **Verify Cluster Health**:
   Ensure Redis PubSub channel for WebSockets is not overloaded. Check Redis memory and CPU usage:
   ```bash
   redis-cli INFO stats
   redis-cli INFO cpu
   ```
