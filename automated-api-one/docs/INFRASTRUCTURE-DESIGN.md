# 13-INFRASTRUCTURE-DESIGN.md

# Infrastructure Design Document

| Field            | Value                                |
| ---------------- | ------------------------------------ |
| Project Name     | Trading Strategy Automation Platform |
| Version          | 1.0                                  |
| Status           | Draft                                |
| Deployment Model | VPS + Docker                         |
| Scale Target     | 10,000 Active Clients                |
| Last Updated     | June 2026                            |

---

# 1. Introduction

## Purpose

This document defines the infrastructure architecture required to deploy, operate, monitor, and scale the Trading Strategy Automation Platform.

This document covers:

* Production Infrastructure
* Staging Infrastructure
* Network Architecture
* Container Architecture
* Database Architecture
* Monitoring Architecture
* Backup Architecture
* Disaster Recovery

---

# 2. Infrastructure Principles

---

## INF-001

Use open-source technologies wherever possible.

---

## INF-002

Support horizontal scaling.

---

## INF-003

Avoid vendor lock-in.

---

## INF-004

Maintain high availability during market hours.

---

## INF-005

Support future Kubernetes migration.

---

# 3. Environment Strategy

---

## Development

Purpose:

* Local Development

Infrastructure:

```text
Docker Compose
```

---

## Staging

Purpose:

* QA Testing
* UAT Testing

Infrastructure:

```text
Single VPS
```

---

## Production

Purpose:

* Live Trading

Infrastructure:

```text
Multi-Container VPS Deployment
```

---

# 4. Production Architecture

```text
                    Internet
                         │
                         ▼

                 Nginx Reverse Proxy
                         │

        ┌────────────────┼────────────────┐

        ▼                ▼                ▼

 App Container 1  App Container 2  App Container 3

        │                │                │

        └────────────────┼────────────────┘

                         ▼

                  PostgreSQL

                         ▼

                      Redis

                         ▼

                     BullMQ

                         ▼

               Monitoring Stack
```

---

# 5. Recommended VPS Sizing

---

## Production VPS

Minimum:

| Resource | Value     |
| -------- | --------- |
| CPU      | 16 vCPU   |
| RAM      | 64 GB     |
| SSD      | 1 TB NVMe |
| Network  | 1 Gbps    |

---

## Recommended

| Resource | Value     |
| -------- | --------- |
| CPU      | 24 vCPU   |
| RAM      | 96 GB     |
| SSD      | 2 TB NVMe |
| Network  | 1 Gbps    |

---

# 6. Container Architecture

---

## Containers

### nginx

Responsibilities:

* Reverse Proxy
* TLS Termination
* Load Balancing

---

### app

Responsibilities:

* NestJS API
* WebSocket Gateway

Replicas:

```text
3
```

---

### redis

Responsibilities:

* Cache
* Queue Backend

---

### postgres

Responsibilities:

* Primary Database

---

### worker

Responsibilities:

* BullMQ Processing

Replicas:

```text
2
```

---

### prometheus

Responsibilities:

* Metrics Collection

---

### grafana

Responsibilities:

* Monitoring Dashboards

---

### loki

Responsibilities:

* Centralized Logs

---

# 7. Docker Architecture

---

## Docker Network

```text
trading-network
```

---

## Network Segments

### Public

Accessible:

```text
nginx
```

---

### Private

Accessible:

```text
app

postgres

redis

worker

monitoring
```

---

# 8. Nginx Design

---

## Responsibilities

* SSL Termination
* Reverse Proxy
* Rate Limiting
* Load Balancing

---

## Ports

| Port | Purpose  |
| ---- | -------- |
| 80   | Redirect |
| 443  | HTTPS    |

---

## Load Balancing

Method:

```text
Round Robin
```

---

# 9. PostgreSQL Architecture

---

## Database Version

```text
PostgreSQL 16
```

---

## Storage

Dedicated volume.

---

## Connection Pool

Technology:

```text
PgBouncer
```

---

## Recommended Limits

```text
max_connections = 500
```

---

# 10. Redis Architecture

---

## Version

```text
Redis 7
```

---

## Responsibilities

* OTP Cache
* Session Cache
* Broker Tokens
* Queue Backend

---

## Persistence

Enabled:

```text
AOF
```

---

# 11. BullMQ Architecture

---

## Queues

### signal-queue

---

### execution-queue

---

### notification-queue

---

### report-queue

---

## Workers

Minimum:

```text
2
```

---

## Scale Target

```text
10 Workers
```

during peak load.

---

# 12. Storage Design

---

## Volumes

### postgres-data

Database Storage

---

### redis-data

Redis Storage

---

### uploads

Reports

Exports

---

### logs

Application Logs

---

# 13. Network Architecture

```text
Internet
   │

Nginx
   │

Private Docker Network
   │

 ┌──────┬──────┬──────┐

 ▼      ▼      ▼      ▼

App   Redis  PGSQL Worker
```

---

# 14. Security Architecture

---

## Public Access

Allowed:

```text
80

443
```

---

## Restricted

```text
5432

6379
```

not publicly exposed.

---

## SSH

```text
22
```

Restricted.

---

## Authentication

SSH Key Based.

---

# 15. SSL Architecture

---

## TLS Version

```text
TLS 1.3
```

---

## Certificates

Provider:

```text
Let's Encrypt
```

---

## Renewal

Automatic.

---

# 16. Monitoring Architecture

---

## Stack

```text
Prometheus

Grafana

Loki
```

---

## Metrics

### Infrastructure

* CPU
* RAM
* Disk
* Network

---

### Application

* Requests
* Errors
* Latency

---

### Trading

* Execution Success
* Queue Length
* Broker Errors

---

# 17. Logging Architecture

---

## Log Types

### Application Logs

---

### Trading Logs

---

### Audit Logs

---

### Security Logs

---

## Storage

Technology:

```text
Loki
```

---

# 18. Backup Architecture

---

## PostgreSQL

Frequency:

```text
Daily
```

---

Retention:

```text
30 Days
```

---

## Redis

Frequency:

```text
Daily
```

---

Retention:

```text
7 Days
```

---

## Configuration

Frequency:

```text
Daily
```

---

# 19. Disaster Recovery

---

## RPO

```text
15 Minutes
```

---

## RTO

```text
2 Hours
```

---

## Recovery Steps

1. Restore Infrastructure
2. Restore PostgreSQL
3. Restore Redis
4. Verify Services
5. Resume Trading

---

# 20. Production Capacity Planning

---

## Users

```text
10,000
```

---

## Concurrent Users

```text
2,000
```

---

## Active Trades

```text
50,000+
```

---

## Peak Order Requests

```text
5,000+
```

---

# 21. Scaling Strategy

---

## Phase 1

```text
1 VPS

2 App Containers
```

---

## Phase 2

```text
1 VPS

4 App Containers

2 Workers
```

---

## Phase 3

```text
Multiple VPS

Load Balancer

8+ Containers
```

---

# 22. Staging Environment

---

## VPS

| Resource | Value  |
| -------- | ------ |
| CPU      | 4 vCPU |
| RAM      | 8 GB   |
| SSD      | 100 GB |

---

## Containers

* Nginx
* App
* PostgreSQL
* Redis

---

# 23. Infrastructure Risks

| Risk             | Mitigation         |
| ---------------- | ------------------ |
| VPS Failure      | Backups            |
| Broker Downtime  | Retry Logic        |
| Database Failure | Restore Procedures |
| Queue Congestion | Worker Scaling     |
| Traffic Spike    | Horizontal Scaling |

---

# 24. Future Infrastructure Evolution

Future:

```text
Docker
      ↓

Docker Swarm
      ↓

Kubernetes
```

Optional migration.

---

# 25. Approval

| Role               | Status  |
| ------------------ | ------- |
| DevOps Lead        | Pending |
| Solution Architect | Pending |
| Product Owner      | Pending |

---

END OF DOCUMENT
