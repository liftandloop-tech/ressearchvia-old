# 05-SAD.md

# Software Architecture Document (SAD)

| Field              | Value                                |
| ------------------ | ------------------------------------ |
| Project Name       | Trading Strategy Automation Platform |
| Version            | 1.0                                  |
| Status             | Draft                                |
| Architecture Style | Modular Monolith                     |
| Last Updated       | June 2026                            |

---

# 1. Introduction

## 1.1 Purpose

This document describes the overall software architecture of the Trading Strategy Automation Platform.

It provides:

* Architectural vision
* Architectural decisions
* Component relationships
* System boundaries
* Technology choices
* Integration architecture
* Scalability strategy

---

## 1.2 Scope

This architecture covers:

* Web Application
* Mobile Application
* Backend APIs
* Trading Engine
* Strategy Engine
* Risk Engine
* Broker Integrations
* Notification Services
* Database Layer
* Infrastructure Layer

---

# 2. Architectural Goals

The platform architecture must:

* Support 10,000 active clients
* Execute trades automatically
* Maintain high reliability
* Support multi-broker integration
* Allow future service extraction
* Minimize operational complexity
* Reduce infrastructure costs

---

# 3. Architecture Principles

---

## AP-001 Modular Design

Business domains shall be isolated into modules.

---

## AP-002 Broker Independence

Trading logic shall not depend on a specific broker.

---

## AP-003 Event Driven Execution

Trade execution shall use asynchronous processing.

---

## AP-004 Scalability

System shall support horizontal scaling.

---

## AP-005 Security First

Security controls shall be embedded throughout the architecture.

---

# 4. Architectural Style

## Selected Style

```text
Modular Monolith
```

---

## Why Not Microservices?

Current scale target:

```text
10,000 Clients
```

Microservices would introduce:

* Increased complexity
* Additional infrastructure
* Higher maintenance overhead
* More operational cost

---

## Migration Path

Future migration supported:

```text
Modular Monolith
       ↓
Hybrid
       ↓
Microservices
```

without major redesign.

---

# 5. High-Level Architecture

```text
┌──────────────────────────────┐
│      Mobile Application      │
│          Flutter             │
└──────────────┬───────────────┘
               │
               ▼

┌──────────────────────────────┐
│        Web Application       │
│          Next.js             │
└──────────────┬───────────────┘
               │
               ▼

┌──────────────────────────────┐
│          API Layer           │
│           NestJS             │
└──────────────┬───────────────┘
               │
               ▼

┌──────────────────────────────┐
│      Business Modules        │
└──────────────┬───────────────┘
               │
               ▼

┌──────────────────────────────┐
│       Trading Engine         │
└──────────────┬───────────────┘
               │
               ▼

┌──────────────────────────────┐
│    Broker Adapter Layer      │
└──────────────┬───────────────┘
               │
       ┌───────┼────────┐
       ▼       ▼        ▼

 Angel    Zerodha   Upstox
  One
```

---

# 6. Logical Architecture

System divided into domains.

---

## User Domain

Responsibilities:

* Registration
* Authentication
* Profile
* MPIN

---

## Broker Domain

Responsibilities:

* Broker linking
* Session management
* Authorization

---

## Strategy Domain

Responsibilities:

* Strategy management
* Activation
* Configuration

---

## Trading Domain

Responsibilities:

* Order placement
* Position tracking
* Execution monitoring

---

## Risk Domain

Responsibilities:

* Daily loss checks
* Capital validation
* Multiplier validation

---

## Notification Domain

Responsibilities:

* Push notifications
* SMS notifications

---

## Reporting Domain

Responsibilities:

* Reports
* Analytics

---

# 7. Backend Module Structure

```text
src/

modules/

├── auth
├── users
├── brokers
├── strategies
├── signals
├── trading
├── positions
├── risk
├── notifications
├── subscriptions
├── reports
├── audit
├── admin

core/

├── database
├── queue
├── cache
├── events
├── logger

shared/

├── dto
├── interfaces
├── enums
├── constants
```

---

# 8. Trading Architecture

## Trading Engine Responsibilities

* Receive signal
* Validate user
* Validate capital
* Validate risk
* Execute order
* Track execution

---

## Execution Flow

```text
Analyst Signal
       ↓

Signal Queue
       ↓

Trading Engine
       ↓

Risk Engine
       ↓

Broker Adapter
       ↓

Broker API
```

---

# 9. Strategy Engine Architecture

Responsibilities:

* Strategy activation
* Lot multiplication
* Daily loss control
* Position sizing

---

## Lot Multiplier Flow

Example:

```text
1 Lot
 ↓ Loss

2 Lots
 ↓ Loss

4 Lots
 ↓ Loss

8 Lots
 ↓ Profit

Reset to 1
```

---

# 10. Risk Engine Architecture

Responsibilities:

* Daily loss validation
* Capital validation
* Margin validation
* Multiplier validation

---

## Validation Sequence

```text
Signal Received
      ↓

Consent Check
      ↓

Subscription Check
      ↓

Capital Check
      ↓

Risk Check
      ↓

Execute
```

---

# 11. Broker Integration Architecture

---

## Broker Adapter Pattern

Purpose:

Prevent broker-specific logic from entering business modules.

---

## Interface

```typescript
interface BrokerAdapter {

connect()

disconnect()

placeOrder()

modifyOrder()

cancelOrder()

getOrders()

getPositions()

getHoldings()

getFunds()

}
```

---

## Broker Implementations

```text
AngelOneAdapter

ZerodhaAdapter

UpstoxAdapter

FyersAdapter

DhanAdapter
```

---

# 12. Queue Architecture

Technology:

```text
Redis + BullMQ
```

---

## Queues

### Signal Queue

Processes analyst signals.

---

### Order Queue

Processes order placements.

---

### Notification Queue

Processes notifications.

---

### Report Queue

Processes report generation.

---

## Queue Flow

```text
Signal
 ↓

Signal Queue
 ↓

Order Queue
 ↓

Broker API
```

---

# 13. Database Architecture

Primary Database:

```text
PostgreSQL
```

---

## Responsibilities

Stores:

* Users
* Brokers
* Orders
* Trades
* Positions
* Signals
* Consents

---

## Database Pattern

```text
Application
      ↓

Prisma ORM
      ↓

PostgreSQL
```

---

# 14. Cache Architecture

Technology:

```text
Redis
```

---

## Cached Data

* Sessions
* OTP
* User Preferences
* Broker Tokens
* Active Positions

---

# 15. WebSocket Architecture

Purpose:

Real-time updates.

---

## Events

### Trade Executed

---

### Position Updated

---

### Consent Expiring

---

### Target Hit

---

### Stop Loss Hit

---

## Flow

```text
Backend
    ↓

WebSocket Gateway
    ↓

Client
```

---

# 16. Notification Architecture

Channels:

* Push Notifications
* SMS
* In-App Notifications

---

## Flow

```text
Event
  ↓

Notification Queue
  ↓

Notification Service
  ↓

User
```

---

# 17. Authentication Architecture

Client Authentication:

```text
Mobile
 ↓

OTP
 ↓

MPIN
```

---

Admin Authentication:

```text
Email
 ↓

Password
 ↓

TOTP
```

---

# 18. Security Architecture

Layers:

```text
Client
 ↓

TLS
 ↓

API Gateway
 ↓

Authentication
 ↓

Authorization
 ↓

Business Logic
```

---

## Security Controls

* JWT
* Refresh Tokens
* Rate Limiting
* IP Logging
* Audit Logs

---

# 19. Audit Architecture

Immutable logging for:

* Login
* Consent
* Strategy Activation
* Order Placement
* Trade Exit

---

## Audit Flow

```text
Event
 ↓

Audit Service
 ↓

Audit Table
```

---

# 20. Deployment Architecture

```text
                Internet
                     │
                     ▼

             Nginx Load Balancer
                     │
        ┌────────────┴────────────┐
        ▼                         ▼

  App Container 1         App Container 2
        │                         │
        └────────────┬────────────┘
                     │

        ┌────────────┼────────────┐
        ▼            ▼            ▼

   PostgreSQL      Redis       BullMQ
```

---

# 21. Scalability Strategy

Phase 1:

```text
2 App Containers
```

---

Phase 2:

```text
4 App Containers
```

---

Phase 3:

```text
8+ App Containers
```

---

Supports:

```text
10,000 Active Clients
```

---

# 22. Failure Handling

---

## Broker Failure

Actions:

* Retry
* Log Failure
* Notify Admin

---

## Queue Failure

Actions:

* Retry Job
* Dead Letter Queue

---

## Database Failure

Actions:

* Failover Recovery
* Backup Restore

---

# 23. Architectural Decisions

| Decision               | Reason                 |
| ---------------------- | ---------------------- |
| Modular Monolith       | Faster Delivery        |
| PostgreSQL             | ACID Compliance        |
| Redis                  | High-Speed Cache       |
| BullMQ                 | Reliable Queue         |
| NestJS                 | Structured Backend     |
| Flutter                | Single Mobile Codebase |
| Broker Adapter Pattern | Multi-Broker Support   |

---

# 24. Risks

| Risk              | Mitigation         |
| ----------------- | ------------------ |
| Broker Downtime   | Retry Logic        |
| Database Overload | Query Optimization |
| Queue Congestion  | Queue Monitoring   |
| High Trade Volume | Horizontal Scaling |

---

# 25. Future Architecture Evolution

Future Extraction Candidates:

* Notification Service
* Reporting Service
* Trading Engine
* Broker Service

These modules can become independent microservices without major redesign.

---

# 26. Approval

| Role               | Status  |
| ------------------ | ------- |
| Solution Architect | Pending |
| Technical Lead     | Pending |
| Product Owner      | Pending |

---

END OF DOCUMENT
