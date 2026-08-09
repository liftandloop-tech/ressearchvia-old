# 17-SLI.md

# Service Level Indicators (SLI)

| Field         | Value                                 |
| ------------- | ------------------------------------- |
| Project Name  | Trading Strategy Automation Platform  |
| Version       | 1.0                                   |
| Status        | Draft                                 |
| Document Type | Reliability Measurement Specification |
| Last Updated  | June 2026                             |

---

# 1. Purpose

This document defines the Service Level Indicators (SLIs) used to measure system reliability and validate Service Level Objectives (SLOs).

SLIs are the actual measurable metrics collected from production systems.

---

# 2. SLI Framework

Relationship:

```text
SLI → Measurement

SLO → Target

SLA → Customer Commitment
```

Example:

```text
SLI:
Successful API Requests
÷
Total API Requests

=

99.97%

SLO:
99.95%

SLA:
99.90%
```

---

# 3. Availability SLIs

---

# SLI-001 Platform Availability

## Definition

Percentage of time platform is operational.

---

## Formula

```text
Availability %

=

(Total Time - Downtime)

÷

Total Time × 100
```

---

## Data Source

* Prometheus
* Health Checks

---

## Target Mapping

| Target Type | Value  |
| ----------- | ------ |
| SLO         | 99.95% |
| SLA         | 99.90% |

---

# SLI-002 API Availability

---

## Definition

Percentage of successful API requests.

---

## Formula

```text
Successful Requests

÷

Total Requests

× 100
```

---

## Prometheus Metric

```text
http_requests_total

http_requests_success_total
```

---

# SLI-003 Trading Engine Availability

---

## Definition

Trading engine operational during market hours.

---

## Formula

```text
Trading Uptime

÷

Market Hours

× 100
```

---

## Target

```text
99.99%
```

---

# 4. Performance SLIs

---

# SLI-004 API Latency

---

## Definition

Time required to complete API requests.

---

## Formula

```text
95th Percentile

Request Duration
```

---

## Metric

```text
http_request_duration_seconds
```

---

## Targets

| Percentile | Target |
| ---------- | ------ |
| P95        | <300ms |
| P99        | <500ms |

---

# SLI-005 Dashboard Load Time

---

## Formula

```text
Page Load Duration
```

---

## Source

Frontend telemetry.

---

## Target

```text
< 2 Seconds
```

---

# SLI-006 Database Query Latency

---

## Formula

```text
95th Percentile

Database Query Duration
```

---

## Metrics

```text
db_query_duration_ms
```

---

# 5. Trading SLIs

---

# SLI-007 Signal Processing Latency

---

## Definition

Time from signal publication to queue acceptance.

---

## Formula

```text
Queue Accepted Time

-

Signal Published Time
```

---

## Target

```text
< 500 ms
```

---

# SLI-008 Trade Execution Latency

---

## Definition

Time from signal publication to broker order submission.

---

## Formula

```text
Broker Order Time

-

Signal Publish Time
```

---

## Target

```text
< 2 Seconds
```

---

# SLI-009 Trade Execution Success Rate

---

## Formula

```text
Successful Orders

÷

Total Orders

× 100
```

---

## Exclusions

* Broker outages
* Exchange outages

---

## Target

```text
99.90%
```

---

# SLI-010 Duplicate Trade Rate

---

## Formula

```text
Duplicate Trades

÷

Total Trades

× 100
```

---

## Target

```text
0%
```

---

# SLI-011 Risk Validation Accuracy

---

## Formula

```text
Correct Risk Decisions

÷

Total Risk Decisions

× 100
```

---

## Target

```text
100%
```

---

# 6. Queue SLIs

---

# SLI-012 Signal Queue Latency

---

## Formula

```text
Job Start Time

-

Job Enqueue Time
```

---

## Metric

```text
bullmq_signal_queue_latency
```

---

## Target

```text
< 500 ms
```

---

# SLI-013 Order Queue Latency

---

## Formula

```text
Execution Start

-

Queue Entry
```

---

## Target

```text
< 1 Second
```

---

# SLI-014 Notification Queue Latency

---

## Target

```text
< 10 Seconds
```

---

# SLI-015 Queue Backlog

---

## Formula

```text
Pending Jobs
```

---

## Alert Threshold

```text
> 1000
```

jobs

---

# 7. Database SLIs

---

# SLI-016 Database Availability

---

## Formula

```text
Database Uptime

÷

Total Time

× 100
```

---

## Target

```text
99.95%
```

---

# SLI-017 Database Connection Success Rate

---

## Formula

```text
Successful Connections

÷

Connection Attempts

× 100
```

---

## Target

```text
99.99%
```

---

# SLI-018 Transaction Success Rate

---

## Formula

```text
Committed Transactions

÷

Transaction Attempts

× 100
```

---

## Target

```text
99.99%
```

---

# 8. Broker SLIs

---

# SLI-019 Broker API Success Rate

---

## Formula

```text
Successful Broker Calls

÷

Total Broker Calls

× 100
```

---

## Target

```text
99.90%
```

excluding broker outages.

---

# SLI-020 Broker Session Refresh Success

---

## Formula

```text
Successful Refreshes

÷

Refresh Attempts

× 100
```

---

## Target

```text
99.90%
```

---

# SLI-021 Broker Health Status

---

## Formula

```text
Healthy Checks

÷

Total Health Checks

× 100
```

---

## Alert Threshold

```text
< 95%
```

---

# 9. Notification SLIs

---

# SLI-022 Push Delivery Rate

---

## Formula

```text
Delivered Notifications

÷

Sent Notifications

× 100
```

---

## Target

```text
95%
```

---

# SLI-023 SMS Delivery Rate

---

## Formula

```text
Delivered SMS

÷

Sent SMS

× 100
```

---

## Target

```text
95%
```

---

# SLI-024 Notification Latency

---

## Formula

```text
Delivered Time

-

Sent Time
```

---

## Target

```text
< 10 Seconds
```

---

# 10. Security SLIs

---

# SLI-025 Failed Login Detection

---

## Formula

```text
Detection Time

-

Attack Start Time
```

---

## Target

```text
< 1 Minute
```

---

# SLI-026 Security Alert Response

---

## Formula

```text
Response Time

-

Alert Time
```

---

## Target

```text
< 15 Minutes
```

---

# SLI-027 Audit Log Integrity

---

## Formula

```text
Valid Audit Records

÷

Expected Audit Records

× 100
```

---

## Target

```text
100%
```

---

# 11. Backup & Recovery SLIs

---

# SLI-028 Backup Success Rate

---

## Formula

```text
Successful Backups

÷

Scheduled Backups

× 100
```

---

## Target

```text
100%
```

---

# SLI-029 Recovery Point Achievement

---

## Formula

```text
Actual Data Loss

≤

15 Minutes
```

---

# SLI-030 Recovery Time Achievement

---

## Formula

```text
Recovery Duration

≤

2 Hours
```

---

# 12. Error Budget Calculations

---

## Platform Availability

Target:

```text
99.95%
```

---

Monthly Error Budget:

```text
21.9 Minutes
```

---

## Trading Engine

Target:

```text
99.99%
```

---

Monthly Error Budget:

```text
4.3 Minutes
```

---

# 13. Prometheus Metrics Mapping

| SLI                   | Metric                        |
| --------------------- | ----------------------------- |
| API Availability      | http_requests_total           |
| API Latency           | http_request_duration_seconds |
| DB Availability       | postgres_up                   |
| DB Latency            | db_query_duration_ms          |
| Queue Latency         | bullmq_queue_latency          |
| Broker Health         | broker_health_status          |
| Trade Success         | trade_execution_success_total |
| Notification Delivery | notification_delivery_total   |

---

# 14. Grafana Dashboard Mapping

---

## Executive Dashboard

Metrics:

* Availability
* Trade Success Rate
* Active Users
* Broker Health

---

## Engineering Dashboard

Metrics:

* API Latency
* Queue Backlog
* Error Rate
* Database Health

---

## Trading Dashboard

Metrics:

* Trade Execution Latency
* Trade Success Rate
* Signal Processing Time

---

# 15. Alert Thresholds

| Metric               | Threshold |
| -------------------- | --------- |
| API Availability     | <99.95%   |
| Trading Availability | <99.99%   |
| Queue Latency        | >30 sec   |
| Trade Success        | <99.90%   |
| DB Availability      | <99.95%   |
| Broker Health        | <95%      |

---

# 16. Reporting Frequency

| Report       | Frequency |
| ------------ | --------- |
| Availability | Daily     |
| Latency      | Daily     |
| Trading      | Daily     |
| Security     | Weekly    |
| Reliability  | Monthly   |

---

# 17. Review Process

Review Frequency:

```text
Monthly
```

Participants:

* Engineering Lead
* DevOps Lead
* Product Owner

---

# 18. Approval

| Role             | Status  |
| ---------------- | ------- |
| Engineering Lead | Pending |
| DevOps Lead      | Pending |
| Product Owner    | Pending |

---

END OF DOCUMENT
