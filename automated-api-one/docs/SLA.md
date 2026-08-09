# 15-SLA.md

# Service Level Agreement (SLA)

| Field          | Value                                |
| -------------- | ------------------------------------ |
| Project Name   | Trading Strategy Automation Platform |
| Version        | 1.0                                  |
| Status         | Draft                                |
| Effective Date | TBD                                  |
| Document Type  | Customer Facing                      |
| Last Updated   | June 2026                            |

---

# 1. Purpose

This Service Level Agreement (SLA) defines the service commitments provided by the Trading Strategy Automation Platform to its customers.

The SLA establishes:

* Service availability commitments
* Support response times
* Incident management targets
* Customer responsibilities
* Service exclusions

---

# 2. Scope

This SLA applies to:

* Mobile Application
* Web Application
* API Services
* Trading Platform
* User Dashboard
* Subscription Services

---

# 3. Service Availability

## Platform Availability

Monthly uptime commitment:

```text
99.90%
```

---

## Trading Engine Availability

During market hours:

```text
99.95%
```

---

## API Availability

Monthly target:

```text
99.90%
```

---

# 4. Service Hours

## Platform Access

```text
24 × 7 × 365
```

subject to maintenance windows.

---

## Trading Availability

Trading functionality available during:

```text
Broker Supported Market Hours
```

---

## Support Availability

### Standard Support

```text
Monday - Saturday

09:00 AM - 07:00 PM IST
```

---

### Emergency Support

Critical incidents:

```text
24 × 7
```

---

# 5. Incident Priority Levels

---

## P1 — Critical

### Definition

Complete service outage.

Examples:

* Trading engine unavailable
* Order execution unavailable
* System-wide authentication failure

---

### Response Time

```text
15 Minutes
```

---

### Resolution Target

```text
4 Hours
```

---

# P2 — High

### Definition

Major functionality affected.

Examples:

* Broker integration issues
* Delayed trade execution
* Dashboard unavailable

---

### Response Time

```text
1 Hour
```

---

### Resolution Target

```text
8 Hours
```

---

# P3 — Medium

### Definition

Partial degradation.

Examples:

* Notification delays
* Reporting issues
* Non-critical feature failures

---

### Response Time

```text
4 Hours
```

---

### Resolution Target

```text
2 Business Days
```

---

# P4 — Low

### Definition

Minor issues.

Examples:

* UI issues
* Cosmetic defects
* Documentation requests

---

### Response Time

```text
1 Business Day
```

---

### Resolution Target

```text
5 Business Days
```

---

# 6. Support Matrix

| Priority | Response Time  | Resolution Target |
| -------- | -------------- | ----------------- |
| P1       | 15 Minutes     | 4 Hours           |
| P2       | 1 Hour         | 8 Hours           |
| P3       | 4 Hours        | 2 Business Days   |
| P4       | 1 Business Day | 5 Business Days   |

---

# 7. Maintenance Windows

## Scheduled Maintenance

Window:

```text
Saturday

11:00 PM – 03:00 AM IST
```

---

## Notification

Customers shall receive notice at least:

```text
48 Hours
```

before planned maintenance.

---

## SLA Impact

Scheduled maintenance does not count toward uptime calculations.

---

# 8. Uptime Calculation

Formula:

```text
Availability % =
(Total Time - Downtime)
÷ Total Time × 100
```

---

## Exclusions

Excluded downtime:

* Scheduled maintenance
* Broker outages
* Internet provider outages
* Customer device issues
* Force majeure events

---

# 9. Service Credits

---

## Availability Below 99.90%

Credit:

```text
5% Monthly Subscription Credit
```

---

## Availability Below 99.50%

Credit:

```text
10% Monthly Subscription Credit
```

---

## Availability Below 99.00%

Credit:

```text
20% Monthly Subscription Credit
```

---

## Maximum Credit

```text
20%
```

of monthly subscription fees.

---

# 10. Customer Responsibilities

Customers must:

* Maintain active broker accounts
* Maintain sufficient capital
* Provide daily trading consent
* Maintain valid mobile number
* Follow platform terms

---

# 11. Platform Responsibilities

Platform shall:

* Maintain service availability
* Monitor infrastructure
* Respond to incidents
* Maintain backups
* Protect customer data

---

# 12. Trading Disclaimer

The platform:

* Does not guarantee profits
* Does not guarantee market performance
* Cannot control broker outages
* Cannot control market volatility

Trade execution depends on:

* Broker availability
* Market liquidity
* Exchange conditions

---

# 13. Broker Dependency Clause

The platform depends on third-party broker APIs.

The following are excluded from SLA calculations:

* Broker downtime
* Broker API failures
* Broker rate limits
* Exchange outages

---

# 14. Escalation Matrix

## Level 1

Support Team

---

## Level 2

Technical Operations

---

## Level 3

Engineering Team

---

## Level 4

Management Escalation

---

# 15. Backup Commitments

Database backups:

```text
Daily
```

---

Retention:

```text
30 Days
```

---

# 16. Disaster Recovery Targets

## Recovery Point Objective (RPO)

```text
15 Minutes
```

---

## Recovery Time Objective (RTO)

```text
2 Hours
```

---

# 17. Security Commitments

Platform shall provide:

* TLS Encryption
* Role-Based Access Control
* Audit Logging
* Daily Backups
* Security Monitoring

---

# 18. SLA Review

Review Frequency:

```text
Annually
```

or upon major infrastructure changes.

---

# 19. Acceptance

By using the platform, customers acknowledge and accept the terms defined in this SLA.

---

# 20. Approval

| Role            | Status  |
| --------------- | ------- |
| Operations Lead | Pending |
| Product Owner   | Pending |
| Management      | Pending |

---

END OF DOCUMENT
