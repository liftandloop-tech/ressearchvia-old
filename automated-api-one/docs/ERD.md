# 09-ERD.md

# Entity Relationship Diagram (ERD) & Data Model

| Field        | Value                                |
| ------------ | ------------------------------------ |
| Project Name | Trading Strategy Automation Platform |
| Version      | 1.0                                  |
| Status       | Draft                                |
| Database     | PostgreSQL 16                        |
| ORM          | Prisma                               |
| Last Updated | June 2026                            |

---

# 1. Introduction

## Purpose

This document defines:

* Database entities
* Relationships
* Constraints
* Indexing strategy
* Multi-broker data model
* Trading data model
* Audit data model

The schema is designed to support:

* 10,000 active clients
* Multi-broker architecture
* Automated trading
* Complete auditability

---

# 2. Database Overview

Database:

```text
PostgreSQL
```

Primary Characteristics:

* ACID compliant
* Transactional consistency
* Horizontal application scaling
* Financial-grade data integrity

---

# 3. High-Level ERD

```text
User
 │
 ├── UserDevice
 │
 ├── UserBroker
 │
 ├── UserConsent
 │
 ├── UserStrategy
 │
 ├── Subscription
 │
 ├── Notification
 │
 └── AuditLog

Strategy
 │
 ├── Signal
 │
 └── UserStrategy

Signal
 │
 ├── Trade
 │
 └── Order

Trade
 │
 ├── Position
 │
 └── Order

Broker
 │
 └── UserBroker
```

---

# 4. Core Tables

---

# users

Stores platform users.

## Columns

| Column     | Type         |
| ---------- | ------------ |
| id         | UUID         |
| mobile     | VARCHAR(15)  |
| mpin_hash  | TEXT         |
| first_name | VARCHAR(100) |
| last_name  | VARCHAR(100) |
| email      | VARCHAR(255) |
| status     | ENUM         |
| created_at | TIMESTAMP    |
| updated_at | TIMESTAMP    |

---

## Indexes

```sql
UNIQUE(mobile)

INDEX(status)
```

---

# user_devices

Stores trusted devices.

## Columns

| Column        | Type      |
| ------------- | --------- |
| id            | UUID      |
| user_id       | UUID      |
| device_id     | VARCHAR   |
| device_name   | VARCHAR   |
| platform      | VARCHAR   |
| last_login_at | TIMESTAMP |

---

# brokers

Master broker registry.

## Columns

| Column | Type    |
| ------ | ------- |
| id     | UUID    |
| code   | VARCHAR |
| name   | VARCHAR |
| status | ENUM    |

---

## Example Records

```text
ANGEL_ONE

ZERODHA

UPSTOX

FYERS

DHAN
```

---

# user_brokers

Broker connections.

## Columns

| Column           | Type      |
| ---------------- | --------- |
| id               | UUID      |
| user_id          | UUID      |
| broker_id        | UUID      |
| broker_client_id | VARCHAR   |
| access_token     | TEXT      |
| refresh_token    | TEXT      |
| token_expiry     | TIMESTAMP |
| status           | ENUM      |
| created_at       | TIMESTAMP |

---

## Relationships

```text
User 1:N UserBroker

Broker 1:N UserBroker
```

---

# subscriptions

Subscription records.

## Columns

| Column     | Type |
| ---------- | ---- |
| id         | UUID |
| user_id    | UUID |
| plan_id    | UUID |
| start_date | DATE |
| end_date   | DATE |
| status     | ENUM |

---

# strategies

Master strategies.

## Columns

| Column      | Type      |
| ----------- | --------- |
| id          | UUID      |
| name        | VARCHAR   |
| description | TEXT      |
| segment     | ENUM      |
| status      | ENUM      |
| created_by  | UUID      |
| created_at  | TIMESTAMP |

---

## Segments

```text
INTRADAY

DELIVERY

FUTURES

OPTIONS
```

---

# user_strategies

User strategy subscriptions.

## Columns

| Column           | Type    |
| ---------------- | ------- |
| id               | UUID    |
| user_id          | UUID    |
| strategy_id      | UUID    |
| capital          | DECIMAL |
| backup_capital   | DECIMAL |
| base_lot         | INTEGER |
| max_multiplier   | INTEGER |
| daily_loss_limit | DECIMAL |
| status           | ENUM    |

---

## Relationships

```text
User 1:N UserStrategy

Strategy 1:N UserStrategy
```

---

# user_consents

Daily trading consent.

## Columns

| Column       | Type      |
| ------------ | --------- |
| id           | UUID      |
| user_id      | UUID      |
| consent_date | DATE      |
| granted_at   | TIMESTAMP |
| expires_at   | TIMESTAMP |
| status       | ENUM      |

---

## Constraint

```sql
UNIQUE(user_id, consent_date)
```

---

# signals

Analyst generated signals.

## Columns

| Column       | Type      |
| ------------ | --------- |
| id           | UUID      |
| strategy_id  | UUID      |
| symbol       | VARCHAR   |
| exchange     | VARCHAR   |
| segment      | ENUM      |
| side         | ENUM      |
| entry_price  | DECIMAL   |
| stop_loss    | DECIMAL   |
| target_price | DECIMAL   |
| status       | ENUM      |
| published_at | TIMESTAMP |

---

## Side

```text
BUY

SELL
```

---

# trades

Client trade instances.

## Columns

| Column      | Type      |
| ----------- | --------- |
| id          | UUID      |
| user_id     | UUID      |
| signal_id   | UUID      |
| strategy_id | UUID      |
| broker_id   | UUID      |
| quantity    | INTEGER   |
| multiplier  | INTEGER   |
| entry_price | DECIMAL   |
| exit_price  | DECIMAL   |
| pnl         | DECIMAL   |
| status      | ENUM      |
| created_at  | TIMESTAMP |

---

## Relationships

```text
User 1:N Trade

Signal 1:N Trade
```

---

# orders

Broker orders.

## Columns

| Column          | Type      |
| --------------- | --------- |
| id              | UUID      |
| trade_id        | UUID      |
| broker_order_id | VARCHAR   |
| order_type      | ENUM      |
| quantity        | INTEGER   |
| price           | DECIMAL   |
| status          | ENUM      |
| created_at      | TIMESTAMP |

---

## Relationships

```text
Trade 1:N Order
```

---

# positions

Open positions.

## Columns

| Column         | Type    |
| -------------- | ------- |
| id             | UUID    |
| trade_id       | UUID    |
| symbol         | VARCHAR |
| quantity       | INTEGER |
| avg_price      | DECIMAL |
| current_price  | DECIMAL |
| unrealized_pnl | DECIMAL |
| realized_pnl   | DECIMAL |
| status         | ENUM    |

---

# strategy_multipliers

Tracks escalation.

## Columns

| Column             | Type      |
| ------------------ | --------- |
| id                 | UUID      |
| user_id            | UUID      |
| strategy_id        | UUID      |
| current_lot        | INTEGER   |
| loss_streak        | INTEGER   |
| current_multiplier | INTEGER   |
| updated_at         | TIMESTAMP |

---

## Example

```text
base_lot = 1

current_lot = 8

loss_streak = 3

current_multiplier = 8
```

---

# risk_events

Risk violations.

## Columns

| Column      | Type      |
| ----------- | --------- |
| id          | UUID      |
| user_id     | UUID      |
| strategy_id | UUID      |
| event_type  | VARCHAR   |
| message     | TEXT      |
| created_at  | TIMESTAMP |

---

## Examples

```text
DAILY_LOSS_LIMIT

INSUFFICIENT_CAPITAL

MULTIPLIER_LIMIT_REACHED
```

---

# notifications

Notification history.

## Columns

| Column     | Type      |
| ---------- | --------- |
| id         | UUID      |
| user_id    | UUID      |
| type       | ENUM      |
| title      | VARCHAR   |
| message    | TEXT      |
| delivered  | BOOLEAN   |
| created_at | TIMESTAMP |

---

# audit_logs

Immutable audit events.

## Columns

| Column      | Type      |
| ----------- | --------- |
| id          | UUID      |
| user_id     | UUID      |
| event_type  | VARCHAR   |
| entity_type | VARCHAR   |
| entity_id   | UUID      |
| metadata    | JSONB     |
| ip_address  | VARCHAR   |
| created_at  | TIMESTAMP |

---

## Events

```text
LOGIN

CONSENT_GRANTED

BROKER_LINKED

STRATEGY_ACTIVATED

SIGNAL_EXECUTED

ORDER_PLACED

POSITION_CLOSED
```

---

# admin_users

Admin accounts.

## Columns

| Column        | Type    |
| ------------- | ------- |
| id            | UUID    |
| email         | VARCHAR |
| password_hash | TEXT    |
| totp_secret   | TEXT    |
| role          | ENUM    |
| status        | ENUM    |

---

# analysts

Analyst accounts.

## Columns

| Column | Type    |
| ------ | ------- |
| id     | UUID    |
| name   | VARCHAR |
| email  | VARCHAR |
| status | ENUM    |

---

# reports

Generated reports.

## Columns

| Column       | Type      |
| ------------ | --------- |
| id           | UUID      |
| user_id      | UUID      |
| report_type  | VARCHAR   |
| file_url     | TEXT      |
| generated_at | TIMESTAMP |

---

# 5. Relationship Summary

| Parent   | Child        | Relationship |
| -------- | ------------ | ------------ |
| User     | UserBroker   | 1:N          |
| User     | UserConsent  | 1:N          |
| User     | UserStrategy | 1:N          |
| User     | Trade        | 1:N          |
| User     | Notification | 1:N          |
| Strategy | Signal       | 1:N          |
| Strategy | UserStrategy | 1:N          |
| Signal   | Trade        | 1:N          |
| Trade    | Order        | 1:N          |
| Trade    | Position     | 1:1          |
| Broker   | UserBroker   | 1:N          |

---

# 6. Index Strategy

## High Frequency Indexes

```sql
users(mobile)

user_consents(user_id, consent_date)

signals(strategy_id)

trades(user_id)

trades(signal_id)

orders(trade_id)

positions(trade_id)

audit_logs(user_id)

notifications(user_id)
```

---

# 7. Partitioning Strategy

Future scale:

```text
50M+ Trades
```

Partition:

### audit_logs

Monthly partitions.

---

### trades

Monthly partitions.

---

### orders

Monthly partitions.

---

# 8. Soft Delete Strategy

Supported tables:

```text
users

strategies

signals

analysts
```

Columns:

```sql
deleted_at TIMESTAMP NULL
```

---

# 9. Data Retention

| Table         | Retention |
| ------------- | --------- |
| Trades        | Permanent |
| Orders        | Permanent |
| Audit Logs    | 7 Years   |
| Notifications | 1 Year    |
| OTP Logs      | 30 Days   |

---

# 10. Future Tables

Planned:

```text
broker_rate_limits

strategy_marketplace

broker_health

portfolio_snapshots

user_watchlists
```

---

# 11. Approval

| Role               | Status  |
| ------------------ | ------- |
| DBA                | Pending |
| Solution Architect | Pending |
| Technical Lead     | Pending |

---

END OF DOCUMENT
