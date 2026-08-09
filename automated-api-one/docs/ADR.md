# 08-ADR.md

# Architecture Decision Records (ADR)

| Field        | Value                                |
| ------------ | ------------------------------------ |
| Project Name | Trading Strategy Automation Platform |
| Version      | 1.0                                  |
| Status       | Approved Baseline                    |
| Last Updated | June 2026                            |

---

# 1. Introduction

## Purpose

Architecture Decision Records (ADR) capture significant architectural decisions made during the design and development of the Trading Strategy Automation Platform.

Each ADR includes:

* Context
* Problem Statement
* Decision
* Consequences
* Alternatives Considered

---

# ADR-001

# Use Modular Monolith Architecture

## Status

Accepted

---

## Context

The platform must:

* Support 10,000 active clients
* Deliver quickly
* Minimize infrastructure complexity
* Support future growth

---

## Problem

Should the platform use:

* Monolith
* Modular Monolith
* Microservices

---

## Decision

Adopt:

```text
Modular Monolith
```

using NestJS modules.

---

## Rationale

Benefits:

* Faster development
* Lower operational complexity
* Easier debugging
* Reduced infrastructure cost
* Simpler deployment

---

## Consequences

Positive:

* Faster MVP delivery
* Lower maintenance

Negative:

* Large codebase over time

---

## Future Migration

Modules may later become microservices.

Examples:

* Trading
* Notification
* Reporting

---

# ADR-002

# Use NestJS as Backend Framework

## Status

Accepted

---

## Context

Backend framework required.

Options:

* ExpressJS
* Fastify
* NestJS

---

## Decision

Use:

```text
NestJS
```

---

## Rationale

Provides:

* Dependency Injection
* Modular Architecture
* Validation
* WebSockets
* Testing Support

---

## Consequences

Positive:

* Better maintainability
* Structured code

Negative:

* Slight learning curve

---

# ADR-003

# Use TypeScript

## Status

Accepted

---

## Context

Backend language selection.

Options:

* JavaScript
* TypeScript

---

## Decision

Use:

```text
TypeScript Strict Mode
```

---

## Rationale

Benefits:

* Type Safety
* Better Refactoring
* Fewer Production Errors

---

# ADR-004

# Use PostgreSQL

## Status

Accepted

---

## Context

Primary database required.

Options:

* PostgreSQL
* MySQL
* MongoDB

---

## Decision

Use:

```text
PostgreSQL
```

---

## Rationale

Provides:

* ACID Transactions
* Strong Consistency
* Excellent Indexing
* JSON Support

---

## Consequences

Positive:

* Reliable financial data

Negative:

* More operational complexity than MongoDB

---

# ADR-005

# Use Prisma ORM

## Status

Accepted

---

## Context

ORM required.

Options:

* TypeORM
* Sequelize
* Prisma

---

## Decision

Use:

```text
Prisma
```

---

## Rationale

Benefits:

* Type Safety
* Migration Management
* Better Developer Experience

---

# ADR-006

# Use Redis

## Status

Accepted

---

## Context

Caching and queue infrastructure required.

---

## Decision

Use:

```text
Redis
```

---

## Usage

* Sessions
* OTP Storage
* Broker Sessions
* Caching
* Queue Backend

---

# ADR-007

# Use BullMQ

## Status

Accepted

---

## Context

Background job processing required.

Options:

* RabbitMQ
* Kafka
* BullMQ

---

## Decision

Use:

```text
BullMQ
```

---

## Rationale

Current scale:

```text
10,000 Clients
```

BullMQ is sufficient.

---

## Future Review

Reevaluate at:

```text
50,000+ Clients
```

---

# ADR-008

# Use Broker Adapter Pattern

## Status

Accepted

---

## Context

Platform must support multiple brokers.

---

## Decision

Introduce:

```text
Broker Adapter Layer
```

---

## Architecture

```text
Trading Engine
      │

Broker Adapter
      │

Angel One
Zerodha
Upstox
Fyers
Dhan
```

---

## Benefits

* Broker independence
* Easier expansion
* Reduced coupling

---

# ADR-009

# Angel One as Initial Broker

## Status

Accepted

---

## Context

Phase 1 requires a broker integration.

---

## Decision

Use:

```text
Angel One SmartAPI
```

for initial launch.

---

## Future Expansion

* Zerodha
* Upstox
* Fyers
* Dhan

---

# ADR-010

# Use Flutter for Mobile Applications

## Status

Accepted

---

## Context

Cross-platform mobile framework required.

Options:

* Flutter
* React Native

---

## Decision

Use:

```text
Flutter
```

---

## Rationale

Benefits:

* Single Codebase
* Better Performance
* Consistent UI

---

# ADR-011

# Use Next.js for Web Portal

## Status

Accepted

---

## Decision

Use:

```text
Next.js
```

---

## Rationale

Provides:

* SSR
* Performance
* Scalability

---

# ADR-012

# Use JWT Authentication

## Status

Accepted

---

## Decision

Use:

```text
JWT Access Tokens
+
Refresh Tokens
```

---

## Benefits

* Stateless Authentication
* Horizontal Scalability

---

# ADR-013

# Use OTP + MPIN Authentication

## Status

Accepted

---

## Client Authentication

```text
Mobile Number
 ↓

OTP
 ↓

MPIN
```

---

## Rationale

Improves usability and security.

---

# ADR-014

# Use RBAC Authorization

## Status

Accepted

---

## Roles

* Client
* Analyst
* Admin

---

## Benefits

* Simpler permissions
* Easier auditing

---

# ADR-015

# Daily Trading Consent Required

## Status

Accepted

---

## Context

Automated trading requires user approval.

---

## Decision

Require:

```text
Daily Consent
```

before trade execution.

---

## Rules

* Valid for current trading day
* Mandatory
* Stored in audit logs

---

# ADR-016

# Use WebSocket for Real-Time Updates

## Status

Accepted

---

## Decision

Use:

```text
Socket.IO
```

via NestJS Gateway.

---

## Events

* Orders
* Positions
* Notifications

---

# ADR-017

# VPS + Docker Deployment

## Status

Accepted

---

## Context

Deployment platform required.

Options:

* VPS
* Kubernetes

---

## Decision

Use:

```text
Linux VPS
+
Docker
```

---

## Rationale

Benefits:

* Faster setup
* Lower cost
* Easier maintenance

---

# ADR-018

# Nginx as Reverse Proxy

## Status

Accepted

---

## Decision

Use:

```text
Nginx
```

---

## Responsibilities

* TLS Termination
* Reverse Proxy
* Load Balancing

---

# ADR-019

# Use Prometheus + Grafana + Loki

## Status

Accepted

---

## Monitoring

```text
Prometheus
```

Metrics

---

```text
Grafana
```

Visualization

---

```text
Loki
```

Logs

---

# ADR-020

# Use Audit-First Design

## Status

Accepted

---

## Decision

All critical actions must be auditable.

---

## Audit Events

* Login
* Consent
* Broker Linking
* Strategy Activation
* Signal Execution
* Order Placement

---

# ADR-021

# Use ACID Transactions for Trade Operations

## Status

Accepted

---

## Decision

Trade operations shall execute within database transactions.

---

## Rationale

Prevent:

* Partial Writes
* Inconsistent Data

---

# ADR-022

# Client Configurable Risk Controls

## Status

Accepted

---

## Configurable Settings

* Daily Loss Limit
* Base Lot
* Maximum Multiplier
* Capital Allocation
* Backup Capital

---

# ADR-023

# Full Automation with Daily Consent

## Status

Accepted

---

## Decision

Trades execute automatically after:

```text
Daily Consent
```

No per-trade approval required.

---

# ADR-024

# Event-Driven Trade Execution

## Status

Accepted

---

## Decision

Use queues for:

* Signals
* Orders
* Notifications

---

## Benefits

* Reliability
* Scalability
* Retry Support

---

# ADR-025

# Mobile-First Product Strategy

## Status

Accepted

---

## Decision

Primary UX optimized for mobile devices.

---

## Reason

Majority of retail traders use smartphones.

---

# ADR Summary

| ADR     | Decision                    |
| ------- | --------------------------- |
| ADR-001 | Modular Monolith            |
| ADR-002 | NestJS                      |
| ADR-004 | PostgreSQL                  |
| ADR-006 | Redis                       |
| ADR-007 | BullMQ                      |
| ADR-008 | Broker Adapter              |
| ADR-010 | Flutter                     |
| ADR-011 | Next.js                     |
| ADR-013 | OTP + MPIN                  |
| ADR-015 | Daily Consent               |
| ADR-017 | VPS + Docker                |
| ADR-019 | Prometheus + Grafana + Loki |

---

# Approval

| Role               | Status   |
| ------------------ | -------- |
| Solution Architect | Approved |
| Technical Lead     | Approved |
| Product Owner      | Approved |

---

END OF DOCUMENT
