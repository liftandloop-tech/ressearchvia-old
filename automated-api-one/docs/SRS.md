# 03-SRS.md

# Software Requirements Specification (SRS)

| Field        | Value                                |
| ------------ | ------------------------------------ |
| Project Name | Trading Strategy Automation Platform |
| Version      | 1.0                                  |
| Status       | Draft                                |
| Standard     | IEEE 830                             |
| Last Updated | June 2026                            |

---

# 1. Introduction

## 1.1 Purpose

This document defines the complete software requirements for the Trading Strategy Automation Platform.

The platform enables automated trade execution in user brokerage accounts based on analyst-generated trading signals while enforcing user-configurable risk controls and regulatory consent requirements.

---

## 1.2 Scope

The system shall provide:

* User onboarding
* Broker account integration
* Daily consent management
* Subscription validation
* Automated trade execution
* Position monitoring
* Risk management
* Analyst signal management
* Administrative management
* Notification services
* Reporting services

---

## 1.3 Intended Audience

* Product Team
* Development Team
* QA Team
* DevOps Team
* Security Team
* Compliance Team
* Stakeholders

---

# 2. System Overview

## 2.1 Product Context

The platform operates as a middleware layer between:

```text
Users
   ↓
Trading Platform
   ↓
Broker APIs
```

Primary Broker:

* Angel One SmartAPI

Future Brokers:

* Zerodha
* Upstox
* Fyers
* Dhan

---

## 2.2 System Objectives

The platform shall:

* Execute analyst signals automatically
* Maintain user ownership of funds
* Enforce risk controls
* Scale to 10,000 active users
* Support multi-broker architecture

---

# 3. User Classes

## UC-01 Client

Capabilities:

* Manage profile
* Link broker
* Provide consent
* Configure risk settings
* Monitor trades

---

## UC-02 Analyst

Capabilities:

* Create signals
* Manage strategies
* Monitor performance

---

## UC-03 Administrator

Capabilities:

* Manage platform
* Manage users
* Manage subscriptions
* Monitor execution

---

# 4. Functional Requirements

---

# FR-001 User Registration

## Description

System shall allow users to register using mobile numbers.

---

## Inputs

* Mobile Number
* OTP

---

## Outputs

* User Account

---

## Acceptance Criteria

* Mobile must be unique.
* OTP must be validated.

---

# FR-002 User Authentication

## Description

System shall authenticate users using:

* Mobile Number
* OTP
* MPIN

---

## Acceptance Criteria

* Invalid MPIN rejected.
* Failed attempts logged.

---

# FR-003 MPIN Management

## Description

System shall allow users to:

* Create MPIN
* Update MPIN
* Reset MPIN

---

# FR-004 Broker Integration

## Description

System shall support broker account linking.

---

## Inputs

* Broker Selection
* Authentication Token

---

## Outputs

* Linked Broker Account

---

## Acceptance Criteria

* Broker credentials validated.
* Broker status stored.

---

# FR-005 Daily Consent

## Description

System shall require users to provide trading consent every trading day.

---

## Business Rules

BR-001

Consent valid only for current trading day.

---

BR-002

No trade execution without valid consent.

---

# FR-006 Subscription Validation

## Description

System shall verify active subscription before execution.

---

## Acceptance Criteria

Inactive subscriptions shall not receive trades.

---

# FR-007 Strategy Activation

## Description

System shall allow users to activate strategies.

---

## Inputs

* Strategy
* Capital Allocation
* Backup Capital
* Risk Settings

---

## Outputs

* Active Strategy

---

# FR-008 Signal Creation

## Description

Analysts shall create trading signals.

---

## Signal Fields

* Symbol
* Exchange
* Segment
* Side
* Entry
* Stop Loss
* Target

---

# FR-009 Signal Publication

## Description

System shall publish signals to eligible users.

---

## Validation

Before publication:

* Strategy Active
* Subscription Active
* Consent Active

---

# FR-010 Order Placement

## Description

System shall place broker orders automatically.

---

## Acceptance Criteria

Order must be acknowledged by broker.

---

# FR-011 Order Modification

## Description

System shall allow modification of active orders.

---

# FR-012 Order Cancellation

## Description

System shall allow cancellation of pending orders.

---

# FR-013 Position Monitoring

## Description

System shall continuously monitor positions.

---

## Data

* Entry Price
* Quantity
* P&L
* Current Price

---

# FR-014 Trade Exit Management

## Description

System shall manage:

* Target exits
* Stop-loss exits
* Manual exits

---

# FR-015 Lot Multiplication Engine

## Description

System shall support configurable lot multiplication.

---

## Example

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
```

---

## Business Rules

BR-010

Multiplier configurable.

---

BR-011

Profit resets multiplier.

---

BR-012

Capital validation required before escalation.

---

# FR-016 Daily Loss Protection

## Description

System shall stop execution when configured loss threshold is reached.

---

## Business Rules

BR-020

Loss limit configurable per strategy.

---

BR-021

Loss limit violation pauses strategy.

---

# FR-017 Capital Validation

## Description

System shall verify funds before execution.

---

## Validation

* Margin Availability
* Capital Allocation
* Backup Capital

---

# FR-018 Notifications

## Description

System shall generate notifications.

---

## Events

* Consent Pending
* Trade Executed
* Trade Closed
* Target Hit
* Stop Loss Hit
* Capital Shortage

---

# FR-019 Reporting

## Description

System shall generate reports.

---

## Reports

* Daily P&L
* Monthly P&L
* Trade Summary

---

# FR-020 Audit Logging

## Description

System shall maintain immutable audit logs.

---

## Events Logged

* Login
* Consent
* Strategy Activation
* Signal Execution
* Trade Exit

---

# FR-021 Analyst Management

## Description

System shall manage analyst accounts.

---

# FR-022 Strategy Management

## Description

Analysts shall create and manage strategies.

---

# FR-023 Admin Management

## Description

Administrators shall manage platform resources.

---

# FR-024 Broker Abstraction Layer

## Description

System shall provide broker-independent execution.

---

## Interface

```typescript
interface BrokerAdapter {

connect()

disconnect()

placeOrder()

modifyOrder()

cancelOrder()

getPositions()

getFunds()

getOrders()

}
```

---

# FR-025 Trade Execution Queue

## Description

System shall process trade execution asynchronously.

---

# FR-026 Real-Time Dashboard

## Description

System shall provide live dashboard updates.

---

# FR-027 Session Management

## Description

System shall manage broker sessions.

---

# FR-028 Device Management

## Description

System shall maintain device associations.

---

# FR-029 Risk Engine

## Description

System shall evaluate risk before execution.

---

# FR-030 Trade History

## Description

System shall store historical trades indefinitely.

---

# 5. External Interfaces

---

## Broker APIs

### Angel One

Used For:

* Authentication
* Orders
* Positions
* Holdings
* Funds

---

## SMS Provider

Used For:

* OTP
* Alerts

---

## Push Notification Service

Used For:

* Mobile notifications

---

# 6. Business Rules

---

## BR-001

Daily consent mandatory.

---

## BR-002

Subscription mandatory.

---

## BR-003

Broker account mandatory.

---

## BR-004

Capital allocation mandatory.

---

## BR-005

Backup capital mandatory.

---

## BR-006

Lot multiplier configurable.

---

## BR-007

Daily loss limit configurable.

---

## BR-008

Profit resets multiplier.

---

## BR-009

Loss increases multiplier.

---

## BR-010

No trade execution without sufficient funds.

---

# 7. Data Requirements

Core entities:

* User
* Broker
* Subscription
* Strategy
* Signal
* Order
* Position
* Trade
* Consent
* Notification

---

# 8. Use Cases

---

## UC-001 Register User

Actor:

Client

---

Flow:

```text
Enter Mobile
↓
Verify OTP
↓
Create Account
↓
Set MPIN
```

---

## UC-002 Provide Consent

Actor:

Client

---

Flow:

```text
Open App
↓
Provide Consent
↓
Trading Activated
```

---

## UC-003 Execute Signal

Actor:

System

---

Flow:

```text
Receive Signal
↓
Validate User
↓
Validate Capital
↓
Execute Trade
```

---

# 9. Assumptions

* Broker APIs remain operational.
* User maintains sufficient funds.
* Users provide daily consent.

---

# 10. Constraints

* Market trading hours.
* Broker API limits.
* Regulatory requirements.

---

# 11. Acceptance Criteria

System shall be accepted when:

* All FR requirements pass testing.
* Broker integration succeeds.
* Risk controls function correctly.
* Trade execution success rate exceeds 99%.

---

# 12. Traceability Matrix

| Requirement | Module          |
| ----------- | --------------- |
| FR-001      | User            |
| FR-004      | Broker          |
| FR-009      | Signal          |
| FR-010      | Trading         |
| FR-015      | Strategy Engine |
| FR-016      | Risk Engine     |
| FR-018      | Notification    |

---

# 13. Approval

| Role           | Status  |
| -------------- | ------- |
| Product Owner  | Pending |
| Technical Lead | Pending |
| QA Lead        | Pending |

---

END OF DOCUMENT
