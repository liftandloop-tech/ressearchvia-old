# 20-RUNBOOK.md

# Production Operations Runbook

| Field        | Value                                |
| ------------ | ------------------------------------ |
| Project Name | Trading Strategy Automation Platform |
| Version      | 1.0                                  |
| Status       | Production Draft                     |
| Environment  | Production                           |
| Last Updated | June 2026                            |

---

# 1. Purpose

This runbook provides operational procedures for running and maintaining the Trading Strategy Automation Platform in production.

This document is intended for:

* DevOps Engineers
* Operations Team
* On-call Engineers
* Engineering Leads

---

# 2. Production Architecture

```text
Internet
   │

Nginx
   │

 ┌───────┬────────┬────────┐

 ▼       ▼        ▼

App1    App2     App3

   │

Redis
   │

BullMQ
   │

PostgreSQL
```

---

# 3. Daily Operations Checklist

---

## Morning Checklist (Before Market Open)

### Infrastructure

Verify:

```text
✓ VPS Online

✓ CPU < 70%

✓ RAM < 80%

✓ Disk < 80%
```

---

### PostgreSQL

Verify:

```text
✓ Running

✓ Connections Healthy

✓ Replication Healthy (Future)
```

---

### Redis

Verify:

```text
✓ Running

✓ Memory Healthy

✓ Persistence Enabled
```

---

### BullMQ

Verify:

```text
✓ Signal Queue Healthy

✓ Execution Queue Healthy

✓ Notification Queue Healthy
```

---

### Broker Connectivity

Verify:

```text
✓ Angel One Reachable

✓ Authentication Working

✓ Health Checks Passing
```

---

### Monitoring

Verify:

```text
✓ Prometheus Running

✓ Grafana Running

✓ Loki Running
```

---

# 4. Pre-Market Checklist

Run:

```bash
docker ps
```

Verify:

* All containers healthy
* No restart loops

---

Run:

```bash
docker stats
```

Verify:

* CPU Stable
* Memory Stable

---

# 5. Health Check Procedures

---

## API Health

```bash
curl https://api.domain.com/health
```

Expected:

```json
{
 "status":"healthy"
}
```

---

## Database Health

```sql
SELECT 1;
```

---

## Redis Health

```bash
redis-cli ping
```

Expected:

```text
PONG
```

---

# 6. Deployment Procedure

---

## Step 1

Backup Database

```bash
pg_dump
```

---

## Step 2

Pull Latest Images

```bash
docker compose pull
```

---

## Step 3

Deploy

```bash
docker compose up -d
```

---

## Step 4

Verify

```bash
docker ps
```

---

## Step 5

Validate Health

```bash
curl /health
```

---

# 7. Rollback Procedure

---

## Trigger Conditions

* Failed deployment
* Failed health check
* Critical bug

---

## Rollback

```bash
docker compose down

docker compose up -d previous-tag
```

---

Verify:

```bash
docker ps
```

---

# 8. Broker Outage Playbook

---

## Symptoms

* Authentication failures
* Order placement failures
* Timeout increases

---

## Immediate Actions

### Step 1

Verify broker status.

---

### Step 2

Pause execution.

```text
Broker Status

↓

UNHEALTHY
```

---

### Step 3

Notify users.

---

### Step 4

Continue health checks.

---

### Step 5

Resume execution after recovery.

---

# 9. Trading Engine Recovery

---

## Symptoms

* Orders not executing
* Signal backlog
* High latency

---

## Verification

Check:

```text
Signal Queue

Execution Queue

Worker Logs
```

---

## Recovery

Restart workers:

```bash
docker restart worker
```

---

Verify queue processing.

---

# 10. Queue Recovery Procedure

---

## Check Queue Metrics

Verify:

```text
Pending Jobs

Failed Jobs

Queue Latency
```

---

## Retry Failed Jobs

Using BullMQ dashboard.

---

## Restart Workers

```bash
docker restart worker
```

---

## Verify Processing

Observe:

```text
Queue Depth Decreasing
```

---

# 11. PostgreSQL Recovery

---

## Service Failure

Check:

```bash
docker logs postgres
```

---

Restart:

```bash
docker restart postgres
```

---

Verify:

```bash
psql
```

---

## Corruption Recovery

Restore latest backup.

---

# 12. Backup Restore Procedure

---

## Stop Services

```bash
docker compose down
```

---

## Restore Backup

```bash
pg_restore
```

---

## Start Services

```bash
docker compose up -d
```

---

## Verify

* Tables Present
* Application Healthy

---

# 13. Redis Recovery

---

## Service Failure

Check:

```bash
docker logs redis
```

---

Restart:

```bash
docker restart redis
```

---

Verify:

```bash
redis-cli ping
```

---

# 14. High CPU Procedure

---

## Threshold

```text
CPU > 85%
```

for 15 minutes.

---

## Actions

1. Check container usage.
2. Identify heavy queries.
3. Check queue backlog.
4. Scale application containers.

---

# 15. High Memory Procedure

---

## Threshold

```text
RAM > 90%
```

---

## Actions

1. Inspect memory usage.
2. Restart leaking service.
3. Scale infrastructure.

---

# 16. Disk Full Procedure

---

## Threshold

```text
Disk > 90%
```

---

## Actions

* Rotate logs
* Archive reports
* Clean temporary files

---

# 17. Queue Backlog Procedure

---

## Threshold

```text
> 1000 Pending Jobs
```

---

## Actions

1. Add workers.
2. Investigate broker latency.
3. Investigate Redis.

---

# 18. Security Incident Playbook

---

## Examples

* Token leak
* Unauthorized access
* Account takeover

---

## Actions

1. Isolate affected account.
2. Revoke sessions.
3. Rotate secrets.
4. Preserve evidence.
5. Notify Security Lead.

---

# 19. Monitoring Dashboards

---

## Infrastructure Dashboard

Monitor:

* CPU
* RAM
* Disk
* Network

---

## Application Dashboard

Monitor:

* API Latency
* Error Rate
* Request Volume

---

## Trading Dashboard

Monitor:

* Signals Processed
* Orders Executed
* Trade Success Rate

---

## Broker Dashboard

Monitor:

* Authentication Success
* Order Success
* Broker Latency

---

# 20. Alert Response Guide

---

## Alert: API Down

Actions:

```text
Check Containers

Check Nginx

Check Logs
```

---

## Alert: Database Down

Actions:

```text
Check PostgreSQL

Check Disk

Restore If Needed
```

---

## Alert: Queue Backlog

Actions:

```text
Scale Workers

Inspect Broker
```

---

## Alert: Broker Failure

Actions:

```text
Pause Trading

Notify Users
```

---

# 21. On-Call Procedures

---

## Primary On-Call

Responsible for:

* Initial triage
* Escalation

---

## Secondary On-Call

Responsible for:

* Technical investigation

---

## Escalation

```text
On Call
   ↓

Engineering Lead
   ↓

Management
```

---

# 22. Scheduled Maintenance Procedure

---

## Before Maintenance

1. Notify users.
2. Verify backups.
3. Create rollback plan.

---

## During Maintenance

1. Deploy changes.
2. Validate health.
3. Verify trading.

---

## After Maintenance

1. Monitor dashboards.
2. Confirm stability.

---

# 23. Emergency Shutdown Procedure

---

## Trigger

* Critical security event
* Data corruption
* Uncontrolled execution

---

## Actions

### Step 1

Pause signal processing.

---

### Step 2

Disable strategy execution.

---

### Step 3

Stop workers.

```bash
docker stop worker
```

---

### Step 4

Notify stakeholders.

---

# 24. Production Validation Checklist

---

## Infrastructure

```text
✓ VPS Healthy

✓ Containers Healthy
```

---

## Database

```text
✓ PostgreSQL Healthy
```

---

## Cache

```text
✓ Redis Healthy
```

---

## Trading

```text
✓ Signals Working

✓ Orders Working
```

---

## Monitoring

```text
✓ Prometheus

✓ Grafana

✓ Loki
```

---

# 25. Operational KPIs

Monitor:

| KPI                   | Target   |
| --------------------- | -------- |
| Platform Availability | 99.95%   |
| Trading Availability  | 99.99%   |
| API Latency           | <300ms   |
| Trade Success Rate    | >99.9%   |
| Queue Latency         | <30s     |
| MTTR                  | <4 Hours |

---

# 26. Emergency Contacts Matrix

| Role             | Responsibility     |
| ---------------- | ------------------ |
| On-Call Engineer | First Response     |
| DevOps Lead      | Infrastructure     |
| Backend Lead     | Application        |
| Security Lead    | Security Incidents |
| Product Owner    | Business Decisions |

---

# 27. Document Review

Review Frequency:

```text
Quarterly
```

or after major incidents.

---

# 28. Approval

| Role             | Status  |
| ---------------- | ------- |
| Operations Lead  | Pending |
| DevOps Lead      | Pending |
| Engineering Lead | Pending |

---

END OF DOCUMENT
