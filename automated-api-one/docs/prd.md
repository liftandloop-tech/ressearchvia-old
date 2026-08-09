# 02-PRD.md

# Product Requirements Document (PRD)

| Field        | Value                                |
| ------------ | ------------------------------------ |
| Product Name | Trading Strategy Automation Platform |
| Version      | 1.0                                  |
| Status       | Draft                                |
| Owner        | Product Team                         |
| Last Updated | June 2026                            |

---

# 1. Introduction

## Purpose

This document defines the product requirements, features, workflows, user journeys, business rules, and acceptance criteria for the Trading Strategy Automation Platform.

The platform enables investors to subscribe to analyst-driven trading strategies and automatically execute trades in their brokerage accounts after providing daily trading consent.

---

# 2. Product Overview

The platform consists of:

* Web Application
* Mobile Application
* Admin Portal
* Analyst Portal
* Trading Engine
* Broker Integration Layer

Supported Segments:

* Intraday
* Delivery
* Futures
* Options

Supported Broker (Phase 1):

* Angel One

Future Brokers:

* Zerodha
* Upstox
* Fyers
* Dhan
* Others

---

# 3. Product Goals

## Goal 1

Provide automated trade execution.

---

## Goal 2

Enable analysts to manage thousands of clients.

---

## Goal 3

Allow clients to configure risk controls.

---

## Goal 4

Provide complete trade visibility.

---

## Goal 5

Support up to 10,000 active clients.

---

# 4. User Roles

## Client

Capabilities:

* Register account
* Complete onboarding
* Link broker account
* Activate strategies
* Provide daily consent
* Monitor trades
* Configure risk settings

---

## Analyst

Capabilities:

* Create signals
* Update targets
* Update stop losses
* Monitor strategy performance

---

## Administrator

Capabilities:

* Manage users
* Manage subscriptions
* Manage strategies
* Monitor execution
* Handle compliance actions

---

# 5. Functional Modules

## User Management Module

### Features

* Mobile OTP Login
* MPIN Setup
* MPIN Login
* Profile Management
* Device Management

### Acceptance Criteria

* User can register using mobile number.
* OTP verification is mandatory.
* MPIN must be configured after first login.

---

## Broker Integration Module

### Features

* Broker Linking
* Broker Authentication
* Daily Authorization
* Session Validation

### Acceptance Criteria

* User can connect supported broker.
* System validates broker connectivity.
* User can revoke broker access.

---

## Subscription Module

### Features

* View Plans
* Purchase Plan
* Renew Plan
* Cancel Plan

### Acceptance Criteria

* User can purchase strategy subscription.
* Active subscription required for execution.

---

## Strategy Module

### Features

* Strategy Listing
* Strategy Details
* Risk Disclosure
* Strategy Activation

### Acceptance Criteria

* User must accept disclaimer.
* User must provide consent before activation.

---

# 6. Daily Consent Workflow

## Objective

Obtain daily authorization from users before automated trading begins.

---

## Workflow

```text
Market Day Starts
      ↓
User Opens App
      ↓
Daily Consent Request
      ↓
User Approves
      ↓
Trading Activated
```

---

## Rules

* Consent valid only for current trading day.
* Consent expires after market close.
* No trades executed without consent.

---

# 7. Broker Linking Workflow

## Workflow

```text
User Login
    ↓
Select Broker
    ↓
Authenticate Broker
    ↓
Grant API Access
    ↓
Broker Linked
```

---

## Validation

* Broker account must be active.
* API trading must be enabled.
* Authentication must succeed.

---

# 8. Strategy Activation Workflow

## Workflow

```text
Purchase Plan
      ↓
View Strategy
      ↓
Accept Disclaimer
      ↓
Configure Settings
      ↓
Activate Strategy
```

---

## Configuration Parameters

### Capital Allocation

User selects:

* Trading Capital
* Backup Capital

---

### Trade Quantity

Cash Segment:

* Quantity

F&O Segment:

* Lot Size

---

### Multiplier Settings

User Configurable:

* Base Lot
* Maximum Multiplier

Examples:

```text
1 → 2 → 4 → 8
```

```text
1 → 2 → 4 → 8 → 16
```

```text
1 → 2 → 4 → 8 → 16 → 32
```

---

### Daily Loss Limit

User Configurable

Examples:

* ₹5,000
* ₹10,000
* ₹25,000

---

# 9. Signal Management

## Analyst Creates Signal

Signal contains:

* Symbol
* Segment
* Entry
* Stop Loss
* Target
* Trade Type

---

## Signal Lifecycle

```text
Draft
 ↓
Published
 ↓
Executed
 ↓
Completed
```

---

# 10. Automated Trade Execution

## Workflow

```text
Signal Published
      ↓
Validate Client Consent
      ↓
Validate Subscription
      ↓
Validate Broker Session
      ↓
Validate Capital
      ↓
Execute Trade
      ↓
Track Position
```

---

## Validation Checks

Before execution:

* Strategy Active
* Subscription Active
* Daily Consent Available
* Broker Connected
* Sufficient Capital Available

---

# 11. Lot Multiplication Logic

## Loss Scenario

Example:

```text
Base Lot = 1

Trade 1 Loss
Next Lot = 2

Trade 2 Loss
Next Lot = 4

Trade 3 Loss
Next Lot = 8
```

---

## Profit Scenario

Example:

```text
Current Lot = 8

Trade Result = Profit

Next Lot = 1
```

---

## Rules

* Multiplier limit configurable.
* Capital validation mandatory.
* Reset on profit.

---

# 12. Risk Management Module

## Features

### Daily Loss Protection

When limit reached:

```text
Stop Strategy
Notify Client
Notify Admin
```

---

### Capital Validation

Before each trade:

* Verify available margin.
* Verify backup capital.

---

### Multiplier Validation

Ensure:

* Multiplier within configured limit.
* Capital sufficient for escalation.

---

# 13. Active Trades Module

## Features

* Live Positions
* Entry Price
* Current Price
* Target
* Stop Loss
* Current P&L

---

## Actions

User can:

* View Trade
* Exit Trade
* Pause Strategy

---

# 14. Trade History Module

## Features

* Historical Trades
* Profit/Loss Summary
* Export Reports

---

# 15. Notifications Module

## Channels

* Push Notifications
* SMS
* In-App Notifications

---

## Events

### Trade Executed

Notify user when trade executes.

---

### Target Hit

Notify user when target achieved.

---

### Stop Loss Hit

Notify user when stop loss triggered.

---

### Daily Consent Pending

Notify before market opens.

---

### Capital Shortage

Notify when insufficient capital available.

---

# 16. Analyst Portal

## Features

### Strategy Management

* Create Strategy
* Update Strategy
* Disable Strategy

---

### Signal Management

* Publish Signal
* Modify Target
* Modify Stop Loss

---

### Performance Dashboard

* Active Users
* Trade Statistics
* Strategy Performance

---

# 17. Admin Portal

## Features

### User Management

* Search Users
* Suspend Users
* Manage Accounts

---

### Subscription Management

* Manage Plans
* Renewals
* Billing Visibility

---

### Broker Monitoring

* Connection Status
* API Health

---

### System Monitoring

* Execution Health
* Queue Health
* Notification Health

---

# 18. Mobile Application

## Features

* Login
* Daily Consent
* Dashboard
* Active Trades
* Trade History
* Notifications
* Profile

---

# 19. Reporting

## User Reports

* Daily P&L
* Monthly P&L
* Trade Summary

---

## Admin Reports

* Revenue Reports
* User Activity Reports
* Execution Reports

---

# 20. Success Metrics

## Product Metrics

### Daily Active Users

Target:

> 60%

---

### Consent Conversion

Target:

> 80%

---

### Execution Success Rate

Target:

> 99%

---

### Broker Connection Success

Target:

> 99.5%

---

# 21. Out of Scope (Version 1)

* AI Generated Signals
* Social Trading
* Copy Other Clients
* International Brokers
* Cryptocurrency Trading
* Manual Strategy Builder

---

# 22. Future Enhancements

* Multi-Broker Execution
* AI Insights
* Portfolio Analytics
* Strategy Marketplace
* White Label Platform

---

# 23. Approval

| Role            | Status  |
| --------------- | ------- |
| Product Owner   | Pending |
| Technical Lead  | Pending |
| Compliance Team | Pending |

---

END OF DOCUMENT
