# 07-LLD.md

# Low Level Design (LLD)

| Field        | Value                                |
| ------------ | ------------------------------------ |
| Project Name | Trading Strategy Automation Platform |
| Version      | 1.0                                  |
| Status       | Draft                                |
| Architecture | Modular Monolith                     |
| Framework    | NestJS                               |
| Last Updated | June 2026                            |

---

# 1. Introduction

## Purpose

This document defines the detailed implementation design of the Trading Strategy Automation Platform.

The document serves as the primary engineering reference for developers implementing:

* Backend Services
* Database Models
* Trading Engine
* Risk Engine
* Broker Integrations
* Queue Processing
* WebSocket Communication

---

# 2. Source Code Structure

```text
src/

├── app.module.ts

├── modules
│
├── auth
├── users
├── brokers
├── subscriptions
├── strategies
├── signals
├── trading
├── positions
├── risk
├── notifications
├── reports
├── audit
├── admin

├── core
│
├── database
├── queue
├── cache
├── logger
├── websocket

├── shared
│
├── dto
├── enums
├── constants
├── interfaces
├── decorators
├── guards
├── filters
├── interceptors
```

---

# 3. Module Structure Pattern

Each module follows:

```text
users/

├── controllers
├── services
├── repositories
├── dto
├── entities
├── interfaces
├── enums
├── validators
└── users.module.ts
```

---

# 4. Authentication Module

## Components

```text
auth/

├── auth.controller.ts
├── auth.service.ts
├── otp.service.ts
├── mpin.service.ts
├── token.service.ts
```

---

## Responsibilities

* OTP Generation
* OTP Validation
* MPIN Validation
* JWT Generation
* Refresh Token Rotation

---

# 5. User Module

## Services

### UserService

Responsibilities:

* Create User
* Update Profile
* Get User

---

### DeviceService

Responsibilities:

* Register Device
* Manage Devices

---

## Repository

### UserRepository

Functions:

```typescript
create()

findById()

findByMobile()

update()

delete()
```

---

# 6. Broker Module

---

## Components

```text
brokers/

├── broker.controller.ts
├── broker.service.ts
├── broker-session.service.ts
├── adapters/
```

---

## Broker Service

Responsibilities:

* Link Broker
* Refresh Sessions
* Validate Sessions

---

# 7. Broker Adapter Design

---

## Interface

```typescript
export interface BrokerAdapter {

authenticate()

refreshSession()

placeOrder()

modifyOrder()

cancelOrder()

getOrderBook()

getTradeBook()

getPositions()

getHoldings()

getFunds()

}
```

---

## AngelOneAdapter

```typescript
class AngelOneAdapter
implements BrokerAdapter
```

Responsibilities:

* SmartAPI Integration
* Session Handling
* Order Placement

---

## Future Adapters

```typescript
ZerodhaAdapter

UpstoxAdapter

FyersAdapter

DhanAdapter
```

---

# 8. Strategy Module

## Components

```text
strategies/

├── strategy.service.ts
├── activation.service.ts
├── multiplier.service.ts
```

---

## Strategy Service

Responsibilities:

* Create Strategy
* Activate Strategy
* Deactivate Strategy

---

## Multiplier Service

Responsibilities:

* Calculate Next Lot
* Reset Multiplier
* Validate Limit

---

## Example

```typescript
calculateNextLot(
 baseLot,
 currentLot,
 tradeResult
)
```

---

# 9. Signal Module

---

## Signal Service

Responsibilities:

* Create Signal
* Publish Signal
* Update Signal

---

## Signal DTO

```typescript
CreateSignalDto {

symbol

exchange

segment

side

entry

stopLoss

target

}
```

---

# 10. Trading Module

---

## Components

```text
trading/

├── trading.service.ts
├── execution.service.ts
├── order.service.ts
├── position.service.ts
```

---

## Execution Service

Responsibilities:

* Process Signal
* Validate Trade
* Execute Order

---

## Flow

```text
Signal
 ↓

Execution Service
 ↓

Risk Service
 ↓

Broker Adapter
 ↓

Broker API
```

---

# 11. Risk Module

---

## Components

```text
risk/

├── risk.service.ts
├── capital.service.ts
├── multiplier.service.ts
├── loss-limit.service.ts
```

---

## Risk Service

Responsibilities:

* Capital Validation
* Loss Validation
* Multiplier Validation

---

## Validation Order

```text
Consent
 ↓

Subscription
 ↓

Capital
 ↓

Loss Limit
 ↓

Multiplier
```

---

# 12. Notification Module

---

## Components

```text
notifications/

├── notification.service.ts
├── push.service.ts
├── sms.service.ts
```

---

## Events

* Trade Executed
* Target Hit
* Stop Loss Hit
* Consent Reminder

---

# 13. Audit Module

---

## Audit Service

Responsibilities:

* Log Events
* Store Audit Records

---

## Audit Events

```text
LOGIN

CONSENT_GRANTED

BROKER_LINKED

STRATEGY_ACTIVATED

ORDER_EXECUTED

POSITION_CLOSED
```

---

# 14. Queue Design

Technology:

```text
BullMQ
```

---

## Queues

### signal-queue

Purpose:

Process signals.

---

### execution-queue

Purpose:

Execute orders.

---

### notification-queue

Purpose:

Send notifications.

---

### report-queue

Purpose:

Generate reports.

---

# 15. BullMQ Job Design

---

## Signal Job

```typescript
SignalJob {

signalId

strategyId

createdAt

}
```

---

## Execution Job

```typescript
ExecutionJob {

signalId

userId

brokerId

}
```

---

## Notification Job

```typescript
NotificationJob {

userId

eventType

payload

}
```

---

# 16. Redis Design

---

## Redis Keys

### OTP

```text
otp:{mobile}
```

TTL:

```text
5 minutes
```

---

### User Session

```text
session:{userId}
```

TTL:

```text
30 days
```

---

### Broker Session

```text
broker:{userId}:{broker}
```

TTL:

Broker Controlled

---

### Active Consent

```text
consent:{userId}
```

TTL:

Market Close

---

# 17. Database Transaction Design

---

## Trade Execution Transaction

```text
BEGIN

Validate User

Validate Capital

Create Order

Create Position

Commit

END
```

---

## Rollback Conditions

* Broker Failure
* Validation Failure
* Database Failure

---

# 18. WebSocket Design

---

## Gateway

```typescript
TradingGateway
```

---

## Events

### order.executed

```json
{
 "orderId":"",
 "status":""
}
```

---

### position.updated

```json
{
 "positionId":"",
 "pnl":""
}
```

---

### strategy.paused

```json
{
 "reason":""
}
```

---

# 19. DTO Design

---

## Activate Strategy

```typescript
ActivateStrategyDto {

strategyId

capital

backupCapital

baseLot

maxMultiplier

dailyLossLimit

}
```

---

## Consent DTO

```typescript
ConsentDto {

userId

consent

}
```

---

# 20. Entity Design

---

## User

```typescript
User {

id

mobile

mpinHash

status

createdAt

}
```

---

## Strategy

```typescript
Strategy {

id

name

segment

status

}
```

---

## Signal

```typescript
Signal {

id

symbol

entry

target

stopLoss

}
```

---

## Order

```typescript
Order {

id

brokerOrderId

status

quantity

}
```

---

## Position

```typescript
Position {

id

quantity

entryPrice

exitPrice

pnl

}
```

---

# 21. Repository Pattern

---

## Example

```typescript
interface UserRepository {

create()

findOne()

findMany()

update()

delete()

}
```

---

# 22. API Versioning

Pattern:

```text
/api/v1/*
```

Future:

```text
/api/v2/*
```

---

# 23. Error Handling

---

## Standard Response

```json
{
 "success": false,
 "message": "",
 "errorCode": ""
}
```

---

## Categories

### Validation Error

400

---

### Unauthorized

401

---

### Forbidden

403

---

### Not Found

404

---

### Internal Error

500

---

# 24. Logging Structure

---

## Application Log

```json
{
 "timestamp":"",
 "module":"",
 "message":""
}
```

---

## Trade Log

```json
{
 "signalId":"",
 "userId":"",
 "orderId":""
}
```

---

# 25. Scheduled Jobs

---

## Daily Consent Reset

Time:

```text
00:00 IST
```

---

## Session Cleanup

Frequency:

```text
Every 1 Hour
```

---

## Report Generation

Frequency:

```text
Daily
```

---

# 26. Coding Standards

---

## Naming

Classes:

```text
PascalCase
```

---

Methods:

```text
camelCase
```

---

Constants:

```text
UPPER_SNAKE_CASE
```

---

# 27. Performance Optimizations

* Redis Caching
* Database Indexing
* Queue Processing
* Connection Pooling
* Lazy Loading

---

# 28. Security Controls

* JWT
* Refresh Token Rotation
* MPIN Hashing
* Rate Limiting
* Audit Logging

---

# 29. Future Extensions

Future extraction candidates:

```text
Trading Module

Notification Module

Reporting Module

Broker Module
```

for microservice migration.

---

# 30. Approval

| Role                | Status  |
| ------------------- | ------- |
| Lead Developer      | Pending |
| Solution Architect  | Pending |
| Engineering Manager | Pending |

---

END OF DOCUMENT
