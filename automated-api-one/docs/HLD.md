# 06-HLD.md

# High Level Design (HLD)

| Field        | Value                                |
| ------------ | ------------------------------------ |
| Project Name | Trading Strategy Automation Platform |
| Version      | 1.0                                  |
| Status       | Draft                                |
| Architecture | Modular Monolith                     |
| Last Updated | June 2026                            |

---

# 1. Introduction

## 1.1 Purpose

This document provides the high-level system design for the Trading Strategy Automation Platform.

The objective is to define:

* System components
* Component interactions
* Data flows
* Integration points
* Infrastructure topology
* Capacity planning

---

# 2. System Context

The platform acts as an orchestration layer between:

* Clients
* Analysts
* Brokers
* Notification Providers
* Billing Platform

---

## Context Diagram

```text
 ┌───────────────┐
 │     Client    │
 └───────┬───────┘
         │

 ┌───────▼────────┐
 │ Trading System │
 └───────┬────────┘
         │

 ┌───────▼────────┐
 │ Broker APIs    │
 └────────────────┘
```

---

# 3. High Level Components

## Presentation Layer

Components:

* Flutter Mobile App
* Next.js Web Portal
* Admin Dashboard
* Analyst Dashboard

---

## API Layer

Components:

* REST APIs
* WebSocket Gateway
* Authentication Middleware

---

## Business Layer

Components:

* User Module
* Broker Module
* Strategy Module
* Trading Module
* Risk Module
* Notification Module
* Reporting Module

---

## Infrastructure Layer

Components:

* PostgreSQL
* Redis
* BullMQ
* Nginx

---

# 4. Component Architecture

```text
 ┌─────────────────────────┐
 │      Mobile App         │
 └─────────────┬───────────┘

 ┌─────────────▼───────────┐
 │      Web Portal         │
 └─────────────┬───────────┘

 ┌─────────────▼───────────┐
 │     API Gateway         │
 └─────────────┬───────────┘

 ┌─────────────▼───────────┐
 │   Business Modules      │
 └─────────────┬───────────┘

 ┌─────────────▼───────────┐
 │    Trading Engine       │
 └─────────────┬───────────┘

 ┌─────────────▼───────────┐
 │ Broker Adapter Layer    │
 └─────────────┬───────────┘

       Angel One
       Zerodha
       Upstox
       Fyers
       Dhan
```

---

# 5. Module Design

---

## User Module

Responsibilities:

* Registration
* Authentication
* MPIN Management
* Profile Management

---

## Broker Module

Responsibilities:

* Broker Linking
* Session Management
* Access Validation

---

## Subscription Module

Responsibilities:

* Plan Validation
* Subscription Status
* Entitlement Checks

---

## Strategy Module

Responsibilities:

* Strategy Activation
* Strategy Configuration
* Strategy Status

---

## Signal Module

Responsibilities:

* Signal Creation
* Signal Publication
* Signal Tracking

---

## Trading Module

Responsibilities:

* Order Placement
* Order Modification
* Order Cancellation
* Position Tracking

---

## Risk Module

Responsibilities:

* Capital Validation
* Daily Loss Validation
* Multiplier Validation

---

## Notification Module

Responsibilities:

* Push Notifications
* SMS
* In-App Notifications

---

## Reporting Module

Responsibilities:

* Trade Reports
* P&L Reports
* Audit Reports

---

# 6. Broker Adapter Design

---

## Objective

Provide a broker-independent execution layer.

---

## Architecture

```text
Trading Module
        │
        ▼

Broker Adapter
        │

 ┌──────┼──────┬──────┬──────┐

 ▼      ▼      ▼      ▼      ▼

Angel  Zerodha Upstox Fyers Dhan
One
```

---

## Broker Interface

```typescript
interface BrokerAdapter {

authenticate()

placeOrder()

modifyOrder()

cancelOrder()

getOrders()

getPositions()

getFunds()

}
```

---

# 7. Trading Engine Design

## Responsibilities

* Receive Signals
* Validate Users
* Validate Capital
* Execute Orders
* Track Status

---

## Execution Flow

```text
Signal Published
        │

        ▼

Signal Queue
        │

        ▼

Trading Engine
        │

        ▼

Risk Engine
        │

        ▼

Broker Adapter
        │

        ▼

Broker API
```

---

# 8. Strategy Engine Design

## Responsibilities

* Lot Management
* Multiplier Logic
* Daily Loss Management
* Position Sizing

---

## Example Flow

```text
Base Lot = 1

Loss
 ↓

2

Loss
 ↓

4

Loss
 ↓

8

Profit
 ↓

Reset to 1
```

---

## Configurable Parameters

* Base Lot
* Maximum Multiplier
* Backup Capital
* Daily Loss Limit

---

# 9. Risk Engine Design

## Validation Sequence

```text
Signal
 ↓

Subscription Check
 ↓

Consent Check
 ↓

Capital Check
 ↓

Loss Limit Check
 ↓

Multiplier Check
 ↓

Execute
```

---

## Risk Controls

### Daily Loss Limit

Client Configurable

---

### Capital Validation

Before every order.

---

### Margin Validation

Before every order.

---

### Multiplier Validation

Before every escalation.

---

# 10. Queue Architecture

Technology:

```text
BullMQ + Redis
```

---

## Signal Queue

Purpose:

Process analyst signals.

---

## Order Queue

Purpose:

Execute orders.

---

## Notification Queue

Purpose:

Send notifications.

---

## Report Queue

Purpose:

Generate reports.

---

# 11. Queue Flow

```text
Signal
 ↓

Signal Queue
 ↓

Order Queue
 ↓

Broker API
 ↓

Order Updates
 ↓

Position Updates
```

---

# 12. WebSocket Design

---

## Purpose

Real-time communication.

---

## Events

### Consent Expiring

---

### Order Executed

---

### Position Updated

---

### Stop Loss Triggered

---

### Target Achieved

---

### Strategy Paused

---

## Architecture

```text
Backend
   │

WebSocket Gateway
   │

Client
```

---

# 13. Database Overview

Database:

```text
PostgreSQL
```

---

## Core Tables

### Users

Stores:

* Profile
* Mobile
* MPIN

---

### Brokers

Stores:

* Broker Details
* Tokens
* Status

---

### Strategies

Stores:

* Strategy Definitions

---

### Signals

Stores:

* Trade Signals

---

### Orders

Stores:

* Order Information

---

### Positions

Stores:

* Position Information

---

### Consents

Stores:

* Daily Consent Records

---

### Audit Logs

Stores:

* User Activity
* Trade Activity

---

# 14. Cache Design

Technology:

```text
Redis
```

---

## Cached Data

* OTPs
* Sessions
* Broker Tokens
* Active Strategies

---

# 15. Notification Architecture

```text
System Event
      │

      ▼

Notification Queue
      │

      ▼

Notification Service
      │

      ▼

User
```

---

## Notification Channels

* Push
* SMS
* In-App

---

# 16. API Design Overview

API Style:

```text
REST + WebSocket
```

---

## Client APIs

* Authentication
* Profile
* Broker
* Strategy
* Trading

---

## Analyst APIs

* Signals
* Strategies

---

## Admin APIs

* Users
* Reports
* Monitoring

---

# 17. Security Design

---

## Authentication

Client:

```text
Mobile + OTP + MPIN
```

---

Admin:

```text
Email + Password + TOTP
```

---

## Authorization

Role-Based Access Control (RBAC)

Roles:

* Client
* Analyst
* Admin

---

## Security Controls

* JWT
* Refresh Tokens
* Rate Limiting
* Audit Logging

---

# 18. Deployment Topology

```text
                    Internet
                         │
                         ▼

                    Nginx LB
                         │

         ┌───────────────┴───────────────┐

         ▼                               ▼

 App Container 1                 App Container 2

         │                               │

         └───────────────┬───────────────┘

                         ▼

                  PostgreSQL

                         ▼

                      Redis

                         ▼

                     BullMQ
```

---

# 19. Capacity Planning

## Active Users

```text
10,000
```

---

## Concurrent Sessions

```text
2,000
```

---

## Peak Order Requests

```text
5,000+
```

---

## Containers

Initial:

```text
2
```

---

Scale:

```text
4–8
```

---

# 20. Logging Design

Centralized logging using:

```text
Loki
```

---

## Log Categories

* Application Logs
* Audit Logs
* Security Logs
* Trading Logs

---

# 21. Monitoring Design

Monitoring:

```text
Prometheus
```

Visualization:

```text
Grafana
```

---

## Metrics

* API Latency
* Error Rate
* Queue Size
* Execution Success Rate
* Broker Failures

---

# 22. Failure Handling

## Broker Failure

Actions:

* Retry
* Log
* Alert

---

## Queue Failure

Actions:

* Retry
* Dead Letter Queue

---

## Database Failure

Actions:

* Restore Backup
* Failover Procedures

---

# 23. High-Level Data Flow

```text
User
 ↓

API
 ↓

Business Logic
 ↓

Trading Engine
 ↓

Broker Adapter
 ↓

Broker
 ↓

Order Updates
 ↓

Database
 ↓

Dashboard
```

---

# 24. Assumptions

* Broker APIs remain operational.
* User capital is available.
* Daily consent obtained.
* Subscription active.

---

# 25. Approval

| Role               | Status  |
| ------------------ | ------- |
| Solution Architect | Pending |
| Product Owner      | Pending |
| Engineering Lead   | Pending |

---

END OF DOCUMENT
