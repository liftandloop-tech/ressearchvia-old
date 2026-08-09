# SRE Runbook: Redis Outage

## Symptoms
- Workers throw `Redis connection error` / `Redis connection lost`.
- API `/health` endpoint returns `503 Service Unavailable`.
- Signal fan-outs and order placements block and raise errors.

## Action Steps
1. **Check Container Status**:
   Verify if the Redis service container is running:
   ```bash
   docker ps -a --filter name=trading-redis-prod
   ```
2. **Inspect Container Logs**:
   ```bash
   docker logs trading-redis-prod
   ```
3. **Restart Service**:
   If the container stopped or crashed:
   ```bash
   docker start trading-redis-prod
   ```
4. **Outage/Crash Investigation**:
   - Check if Redis exceeded memory limit (`OOM-killer` event). Inspect kernel syslog:
     ```bash
     dmesg -T | grep -i -E 'oom|redis'
     ```
   - Ensure the server maxmemory setting matches system RAM:
     ```bash
     redis-cli CONFIG GET maxmemory
     ```
5. **Rebuild Cache**:
   Once Redis is back online, force rebuild positions cache:
   ```bash
   curl -X POST -H "Authorization: Bearer <SRE_TOKEN>" http://localhost:3000/ops/positions/rebuild
   ```
