# 04-NFR.md

# Non-Functional Requirements (NFR)

| Field        | Value                                |
| ------------ | ------------------------------------ |
| Project Name | Trading Strategy Automation Platform |
| Version      | 1.0                                  |
| Status       | Draft                                |
| Standard     | ISO/IEC 25010                        |
| Last Updated | June 2026                            |

---

# 1. Introduction

## 1.1 Purpose

This document defines the non-functional requirements governing system quality, performance, security, reliability, maintainability, scalability, observability, and operational characteristics of the Trading Strategy Automation Platform.

These requirements apply to all platform components including:

* Web Application
* Mobile Application
* Backend Services
* Trading Engine
* Broker Integrations
* Databases
* Infrastructure

---

# 2. System Overview

The platform must support:

* 10,000 active clients
* Automated trade execution
* Real-time position monitoring
* Broker integrations
* High availability trading operations

The system must prioritize:

1. Reliability
2. Security
3. Availability
4. Scalability
5. Performance

---

# 3. Performance Requirements

---

## NFR-PERF-001 API Response Time

### Requirement

95% of API requests shall complete within:

```text
≤ 300 ms
```

---

### Exceptions

Excluded:

* Report generation
* Data exports
* Historical analytics

---

## NFR-PERF-002 Trade Execution Latency

### Requirement

Time between signal publication and order placement:

```text
≤ 2 seconds
```

Target:

```text
≤ 1 second
```

---

## NFR-PERF-003 Dashboard Loading

### Requirement

Dashboard load time:

```text
≤ 2 seconds
```

---

## NFR-PERF-004 Notification Delivery

### Requirement

Push notification delivery:

```text
≤ 10 seconds
```

---

## NFR-PERF-005 Database Queries

### Requirement

95th percentile query execution:

```text
≤ 100 ms
```

---

# 4. Scalability Requirements

---

## NFR-SCALE-001 User Capacity

System shall support:

```text
10,000 Active Clients
```

---

## NFR-SCALE-002 Concurrent Users

System shall support:

```text
2,000 Concurrent Sessions
```

---

## NFR-SCALE-003 Concurrent Trade Executions

System shall support:

```text
5,000 Simultaneous Order Requests
```

during peak market activity.

---

## NFR-SCALE-004 Horizontal Scaling

Application services shall support horizontal scaling through:

* Docker Containers
* Load Balancers

without code changes.

---

# 5. Availability Requirements

---

## NFR-AVAIL-001 Platform Availability

Monthly Availability:

```text
99.90%
```

---

## NFR-AVAIL-002 Trading Engine Availability

Trading Engine Availability:

```text
99.95%
```

during market hours.

---

## NFR-AVAIL-003 Scheduled Maintenance

Maximum planned downtime:

```text
4 Hours / Month
```

Outside market hours.

---

# 6. Reliability Requirements

---

## NFR-REL-001 Order Processing Reliability

Order processing success rate:

```text
99.9%
```

excluding broker-side failures.

---

## NFR-REL-002 Message Queue Reliability

No trade signal shall be lost.

---

Requirements:

* Persistent queues
* Retry mechanism
* Dead-letter queue

---

## NFR-REL-003 Data Integrity

Financial records must maintain:

```text
100% Consistency
```

---

# 7. Security Requirements

---

## NFR-SEC-001 Authentication

Client Authentication:

* Mobile OTP
* MPIN

---

Admin Authentication:

* Email
* Password
* TOTP

---

## NFR-SEC-002 Encryption

All communications:

```text
TLS 1.3
```

minimum.

---

## NFR-SEC-003 Data Encryption

Sensitive data shall be encrypted at rest.

Examples:

* Access Tokens
* Refresh Tokens
* Broker Credentials
* Personal Data

---

## NFR-SEC-004 Password Storage

Passwords shall be stored using:

```text
Argon2
```

---

## NFR-SEC-005 MPIN Storage

MPIN shall never be stored in plaintext.

Storage:

```text
Argon2 Hash
```

---

## NFR-SEC-006 Session Security

Requirements:

* JWT Access Token
* Refresh Token Rotation
* Session Revocation

---

## NFR-SEC-007 API Security

Protection against:

* Brute Force
* Replay Attacks
* Credential Stuffing
* Injection Attacks

---

## NFR-SEC-008 Audit Logging

All sensitive actions shall be logged.

Examples:

* Login
* Consent
* Broker Linking
* Trade Execution
* Subscription Changes

---

# 8. Compliance Requirements

---

## NFR-COMP-001 Consent Tracking

System shall maintain immutable records of:

* Daily Consent
* Strategy Activation
* Disclaimer Acceptance

---

## NFR-COMP-002 Audit Retention

Audit logs retained for:

```text
7 Years
```

---

## NFR-COMP-003 Trade Traceability

Every trade shall be traceable to:

* Strategy
* Analyst Signal
* User Consent
* Broker Order

---

# 9. Maintainability Requirements

---

## NFR-MAIN-001 Code Structure

Backend shall use:

```text
NestJS Modular Architecture
```

---

## NFR-MAIN-002 Coding Standards

Requirements:

* TypeScript Strict Mode
* ESLint
* Prettier

---

## NFR-MAIN-003 Documentation

All public APIs must be documented using:

```text
OpenAPI 3.1
```

---

# 10. Observability Requirements

---

## NFR-OBS-001 Logging

Centralized logging required.

Technology:

```text
Loki
```

---

## NFR-OBS-002 Metrics

System metrics collected using:

```text
Prometheus
```

---

## NFR-OBS-003 Dashboards

Operational dashboards provided through:

```text
Grafana
```

---

## NFR-OBS-004 Distributed Tracing

System shall support request tracing.

Recommended:

```text
OpenTelemetry
```

---

# 11. Monitoring Requirements

---

## NFR-MON-001 Infrastructure Monitoring

Monitor:

* CPU
* Memory
* Disk
* Network

---

## NFR-MON-002 Application Monitoring

Monitor:

* API Latency
* Error Rate
* Request Volume

---

## NFR-MON-003 Trading Monitoring

Monitor:

* Execution Success Rate
* Broker Failures
* Queue Backlog

---

# 12. Backup Requirements

---

## NFR-BACKUP-001 Database Backups

Frequency:

```text
Daily
```

Retention:

```text
30 Days
```

---

## NFR-BACKUP-002 Configuration Backup

Backup:

* Environment Variables
* Deployment Configurations

Frequency:

```text
Daily
```

---

# 13. Disaster Recovery Requirements

---

## NFR-DR-001 Recovery Point Objective

RPO:

```text
≤ 15 Minutes
```

---

## NFR-DR-002 Recovery Time Objective

RTO:

```text
≤ 2 Hours
```

---

## NFR-DR-003 Failover

Database recovery procedures must be documented.

---

# 14. Data Requirements

---

## NFR-DATA-001 Data Consistency

Trading data shall use:

```text
ACID Transactions
```

---

## NFR-DATA-002 Time Synchronization

All timestamps stored in:

```text
UTC
```

---

## NFR-DATA-003 Data Retention

Trade history retained indefinitely.

---

# 15. Usability Requirements

---

## NFR-UX-001 Mobile First

Primary user experience optimized for mobile.

---

## NFR-UX-002 Dashboard Usability

Users shall access:

* Active Trades
* Daily P&L
* Consent Status

within:

```text
3 Clicks
```

---

## NFR-UX-003 Accessibility

Minimum compliance:

```text
WCAG 2.1 AA
```

---

# 16. Portability Requirements

---

## NFR-PORT-001 Deployment

Application shall run using:

```text
Docker Containers
```

---

## NFR-PORT-002 Cloud Independence

Platform shall support deployment on:

* AWS
* Azure
* GCP
* DigitalOcean
* VPS Providers

without code modifications.

---

# 17. Technology Constraints

---

## Backend

```text
NestJS
TypeScript
```

---

## Frontend

```text
Next.js
```

---

## Mobile

```text
Flutter
```

---

## Database

```text
PostgreSQL
```

---

## Cache

```text
Redis
```

---

## Queue

```text
BullMQ
```

---

## Infrastructure

```text
Docker
Nginx
Linux VPS
```

---

# 18. Quality Attributes Summary

| Attribute            | Target  |
| -------------------- | ------- |
| Availability         | 99.90%  |
| Trading Availability | 99.95%  |
| API Latency          | ≤ 300ms |
| Trade Execution      | ≤ 2 sec |
| Concurrent Users     | 2,000   |
| Active Clients       | 10,000  |
| RPO                  | 15 min  |
| RTO                  | 2 hr    |
| Audit Retention      | 7 Years |

---

# 19. Acceptance Criteria

The platform shall satisfy this document when:

* Performance targets achieved.
* Availability targets achieved.
* Security controls implemented.
* Monitoring operational.
* Backup and recovery tested.
* Scalability requirements validated.

---

# 20. Approval

| Role           | Status  |
| -------------- | ------- |
| Product Owner  | Pending |
| Technical Lead | Pending |
| Security Lead  | Pending |
| DevOps Lead    | Pending |

---

END OF DOCUMENT
