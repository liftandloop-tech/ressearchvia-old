# 10-API-SPECIFICATION.md

# API Specification

| Field         | Value                                |
| ------------- | ------------------------------------ |
| Project Name  | Trading Strategy Automation Platform |
| Version       | 1.0                                  |
| Status        | Draft                                |
| API Style     | REST + WebSocket                     |
| Specification | OpenAPI 3.1                          |
| Base URL      | /api/v1                              |
| Last Updated  | June 2026                            |

---

# 1. Introduction

## Purpose

This document defines all public and internal APIs used by:

* Mobile Application
* Web Application
* Admin Portal
* Analyst Portal
* Trading Engine

---

# 2. Authentication

## Client Authentication

Method:

```text
Mobile OTP + MPIN
```

---

## Admin Authentication

Method:

```text
Email + Password + TOTP
```

---

## Authorization

Method:

```text
JWT Access Token
Refresh Token
```

---

# 3. Standard Response Format

## Success Response

```json
{
  "success": true,
  "message": "Success",
  "data": {}
}
```

---

## Error Response

```json
{
  "success": false,
  "message": "Validation Failed",
  "errorCode": "VALIDATION_ERROR"
}
```

---

# 4. Authentication APIs

---

## Send OTP

### Endpoint

```http
POST /auth/send-otp
```

### Request

```json
{
  "mobile": "9999999999"
}
```

### Response

```json
{
  "success": true
}
```

---

## Verify OTP

### Endpoint

```http
POST /auth/verify-otp
```

### Request

```json
{
  "mobile": "9999999999",
  "otp": "123456"
}
```

### Response

```json
{
  "accessToken": "",
  "refreshToken": "",
  "isMpinConfigured": true
}
```

---

## Set MPIN

### Endpoint

```http
POST /auth/mpin/set
```

### Request

```json
{
  "mpin": "1234"
}
```

---

## Login Using MPIN

### Endpoint

```http
POST /auth/mpin/login
```

### Request

```json
{
  "mobile": "9999999999",
  "mpin": "1234"
}
```

---

## Refresh Token

### Endpoint

```http
POST /auth/refresh-token
```

---

## Logout

### Endpoint

```http
POST /auth/logout
```

---

# 5. User APIs

---

## Get Profile

### Endpoint

```http
GET /users/me
```

---

## Update Profile

### Endpoint

```http
PUT /users/me
```

### Request

```json
{
  "firstName": "",
  "lastName": "",
  "email": ""
}
```

---

## Get Devices

### Endpoint

```http
GET /users/devices
```

---

# 6. Broker APIs

---

## List Supported Brokers

### Endpoint

```http
GET /brokers
```

---

## Connect Broker

### Endpoint

```http
POST /brokers/connect
```

### Request

```json
{
  "brokerId": "ANGEL_ONE"
}
```

---

## Get Connected Brokers

### Endpoint

```http
GET /brokers/connected
```

---

## Disconnect Broker

### Endpoint

```http
DELETE /brokers/{brokerId}
```

---

## Refresh Broker Session

### Endpoint

```http
POST /brokers/{brokerId}/refresh
```

---

# 7. Consent APIs

---

## Give Daily Consent

### Endpoint

```http
POST /consents
```

### Request

```json
{
  "consent": true
}
```

---

## Get Consent Status

### Endpoint

```http
GET /consents/today
```

---

## Revoke Consent

### Endpoint

```http
DELETE /consents/today
```

---

# 8. Subscription APIs

---

## Get Active Subscription

### Endpoint

```http
GET /subscriptions/current
```

---

## Get Subscription History

### Endpoint

```http
GET /subscriptions/history
```

---

# 9. Strategy APIs

---

## List Strategies

### Endpoint

```http
GET /strategies
```

---

## Get Strategy Details

### Endpoint

```http
GET /strategies/{id}
```

---

## Activate Strategy

### Endpoint

```http
POST /strategies/{id}/activate
```

### Request

```json
{
  "capital": 100000,
  "backupCapital": 50000,
  "baseLot": 1,
  "maxMultiplier": 8,
  "dailyLossLimit": 5000
}
```

---

## Pause Strategy

### Endpoint

```http
POST /strategies/{id}/pause
```

---

## Resume Strategy

### Endpoint

```http
POST /strategies/{id}/resume
```

---

## Deactivate Strategy

### Endpoint

```http
DELETE /strategies/{id}/activate
```

---

# 10. Signal APIs (Analyst)

---

## Create Signal

### Endpoint

```http
POST /analyst/signals
```

### Request

```json
{
  "strategyId": "",
  "symbol": "NIFTY",
  "segment": "OPTIONS",
  "side": "BUY",
  "entry": 100,
  "target": 120,
  "stopLoss": 90
}
```

---

## Update Signal

### Endpoint

```http
PUT /analyst/signals/{id}
```

---

## Publish Signal

### Endpoint

```http
POST /analyst/signals/{id}/publish
```

---

## Cancel Signal

### Endpoint

```http
DELETE /analyst/signals/{id}
```

---

# 11. Trading APIs

---

## Get Active Trades

### Endpoint

```http
GET /trades/active
```

---

## Get Trade History

### Endpoint

```http
GET /trades/history
```

---

## Get Trade Details

### Endpoint

```http
GET /trades/{id}
```

---

## Exit Trade

### Endpoint

```http
POST /trades/{id}/exit
```

---

## Get Trade P&L

### Endpoint

```http
GET /trades/pnl
```

---

# 12. Position APIs

---

## Get Positions

### Endpoint

```http
GET /positions
```

---

## Get Position Details

### Endpoint

```http
GET /positions/{id}
```

---

# 13. Notification APIs

---

## Get Notifications

### Endpoint

```http
GET /notifications
```

---

## Mark Read

### Endpoint

```http
POST /notifications/{id}/read
```

---

# 14. Report APIs

---

## Daily P&L

### Endpoint

```http
GET /reports/daily-pnl
```

---

## Monthly P&L

### Endpoint

```http
GET /reports/monthly-pnl
```

---

## Export Report

### Endpoint

```http
POST /reports/export
```

---

# 15. Admin APIs

---

## Get Users

### Endpoint

```http
GET /admin/users
```

---

## Get User

### Endpoint

```http
GET /admin/users/{id}
```

---

## Suspend User

### Endpoint

```http
POST /admin/users/{id}/suspend
```

---

## Activate User

### Endpoint

```http
POST /admin/users/{id}/activate
```

---

## Get Dashboard Metrics

### Endpoint

```http
GET /admin/dashboard
```

---

# 16. Analyst APIs

---

## Dashboard

### Endpoint

```http
GET /analyst/dashboard
```

---

## Strategy Performance

### Endpoint

```http
GET /analyst/strategies/{id}/performance
```

---

## Active Signals

### Endpoint

```http
GET /analyst/signals
```

---

# 17. Internal APIs

---

## Execute Signal

### Endpoint

```http
POST /internal/signals/execute
```

---

## Validate Risk

### Endpoint

```http
POST /internal/risk/validate
```

---

## Send Notification

### Endpoint

```http
POST /internal/notifications/send
```

---

# 18. WebSocket APIs

Namespace:

```text
/trading
```

---

## Connection Event

```json
{
  "token": ""
}
```

---

## Event: order.executed

```json
{
  "orderId": "",
  "status": "EXECUTED"
}
```

---

## Event: order.rejected

```json
{
  "orderId": "",
  "reason": ""
}
```

---

## Event: position.updated

```json
{
  "positionId": "",
  "pnl": 500
}
```

---

## Event: strategy.paused

```json
{
  "strategyId": "",
  "reason": "DAILY_LOSS_LIMIT"
}
```

---

## Event: consent.expiring

```json
{
  "expiresAt": ""
}
```

---

## Event: target.hit

```json
{
  "tradeId": "",
  "profit": 1500
}
```

---

## Event: stoploss.hit

```json
{
  "tradeId": "",
  "loss": 1000
}
```

---

# 19. Error Codes

| Code         | Description              |
| ------------ | ------------------------ |
| AUTH_001     | Invalid OTP              |
| AUTH_002     | Invalid MPIN             |
| AUTH_003     | Session Expired          |
| CONSENT_001  | Consent Missing          |
| STRATEGY_001 | Strategy Not Active      |
| TRADE_001    | Capital Insufficient     |
| TRADE_002    | Daily Loss Limit Reached |
| TRADE_003    | Multiplier Limit Reached |
| BROKER_001   | Broker Session Invalid   |
| BROKER_002   | Broker API Failure       |
| SYSTEM_001   | Internal Error           |

---

# 20. Rate Limits

## Public APIs

```text
100 Requests / Minute
```

---

## Auth APIs

```text
10 Requests / Minute
```

---

## Admin APIs

```text
300 Requests / Minute
```

---

# 21. API Versioning

Current:

```text
/api/v1
```

Future:

```text
/api/v2
```

---

# 22. Security Requirements

All APIs require:

* HTTPS
* JWT Authentication
* RBAC Authorization
* Audit Logging

---

# 23. OpenAPI Structure

```yaml
openapi: 3.1.0

info:
  title: Trading Platform API

servers:
  - url: /api/v1

paths:
  /auth/send-otp:
  /auth/verify-otp:
  /brokers:
  /strategies:
  /trades:
```

---

# 24. Approval

| Role               | Status  |
| ------------------ | ------- |
| Backend Lead       | Pending |
| Solution Architect | Pending |
| Product Owner      | Pending |

---

END OF DOCUMENT
