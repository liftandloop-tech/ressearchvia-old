# 01-MRD.md

# Market Requirements Document (MRD)

| Field          | Value                                |
| -------------- | ------------------------------------ |
| Project Name   | Trading Strategy Automation Platform |
| Version        | 1.0                                  |
| Status         | Draft                                |
| Document Owner | Product Team                         |
| Prepared For   | Internal Stakeholders                |
| Last Updated   | June 2026                            |

---

# 1. Executive Summary

The Trading Strategy Automation Platform is a broker-integrated investment automation solution that enables retail investors to subscribe to professionally managed trading strategies and automatically execute trades within their own brokerage accounts.

The platform bridges the gap between research analysts and retail investors by providing automated trade execution, risk management controls, portfolio monitoring, and capital allocation management.

Initially launching with Angel One integration, the platform is designed with a broker-agnostic architecture to support additional brokers in future releases.

The solution targets active traders seeking disciplined strategy execution while retaining full ownership of their funds and brokerage accounts.

---

# 2. Business Opportunity

Retail traders often face:

* Emotional trading decisions
* Delayed trade execution
* Inconsistent strategy adherence
* Lack of professional guidance
* Difficulty managing risk

Research analysts and trading firms face:

* Manual trade communication
* Low scalability
* Execution delays
* Compliance challenges
* High operational overhead

The platform creates a scalable bridge between analysts and retail investors by automating signal execution while maintaining client control and transparency.

---

# 3. Problem Statement

## Investor Problems

### Manual Execution Delays

Investors often receive trade signals through:

* WhatsApp
* Telegram
* SMS
* Email

Execution delays frequently result in missed opportunities and slippage.

### Emotional Decision Making

Investors:

* Exit trades prematurely
* Ignore stop losses
* Overtrade
* Deviate from strategy

### Risk Management Challenges

Many investors struggle with:

* Position sizing
* Capital allocation
* Loss recovery planning
* Daily risk limits

### Monitoring Complexity

Investors must manually track:

* Active trades
* Profit and loss
* Targets
* Stop losses
* Capital utilization

---

## Analyst Problems

### Scaling Limitations

Analysts cannot efficiently manage thousands of clients manually.

### Signal Distribution Delays

Trade opportunities may be missed due to communication latency.

### Operational Burden

Analysts spend significant effort on:

* Client follow-ups
* Trade confirmations
* Position monitoring
* Support requests

---

# 4. Target Market

## Primary Market

Retail investors participating in:

* Intraday Trading
* Delivery Trading
* Futures Trading
* Options Trading

---

## Secondary Market

Professional research analysts and advisory firms seeking automated execution infrastructure.

---

## Geographic Scope

### Phase 1

India

---

### Future Expansion

* Southeast Asia
* Middle East
* Other broker-supported markets

---

# 5. User Personas

## Persona 1 – Retail Investor

### Characteristics

* Age: 21–55
* Active market participant
* Owns a Demat account
* Limited time for market monitoring

### Goals

* Improve execution discipline
* Reduce emotional trading
* Follow professional strategies

### Pain Points

* Missing entries
* Missing exits
* Poor risk management

---

## Persona 2 – Professional Trader

### Characteristics

* Experienced trader
* Uses systematic strategies
* Trades regularly

### Goals

* Automate execution
* Reduce manual intervention
* Scale trading operations

---

## Persona 3 – Research Analyst

### Characteristics

* Registered analyst or advisory provider
* Publishes market signals

### Goals

* Scale signal delivery
* Improve execution consistency
* Reduce operational overhead

---

# 6. Market Drivers

The following trends support adoption:

## Increasing Retail Participation

Growth in retail investor participation has increased demand for automated investment tools.

## Mobile-First Trading

Investors increasingly prefer:

* Mobile applications
* Real-time notifications
* Automated workflows

## API-Based Brokerage Ecosystem

Modern brokers provide APIs enabling:

* Automated execution
* Portfolio synchronization
* Real-time monitoring

## Demand for Managed Strategies

Investors increasingly seek:

* Expert-managed strategies
* Reduced emotional decision making
* Automated risk controls

---

# 7. Competitive Landscape

## Direct Competitors

### Strategy Automation Platforms

Capabilities commonly offered:

* Broker integrations
* Automated execution
* Portfolio tracking

---

## Indirect Competitors

### Signal Providers

Examples:

* Telegram Channels
* WhatsApp Groups
* SMS Signal Services

Limitations:

* Manual execution
* Human delays
* Poor tracking

---

## Traditional Advisory Services

Limitations:

* High operational costs
* Limited scalability
* Slow execution

---

# 8. Product Vision

To become a leading broker-agnostic strategy automation platform that enables retail investors to seamlessly participate in professionally managed trading strategies while maintaining full control of their brokerage accounts and capital.

---

# 9. Product Objectives

## Objective 1

Enable fully automated strategy execution.

---

## Objective 2

Support multiple brokers through a unified integration layer.

---

## Objective 3

Provide configurable risk management controls.

---

## Objective 4

Support up to 10,000 active trading clients.

---

## Objective 5

Reduce execution latency between analyst signal generation and client order placement.

---

# 10. Key Business Requirements

## Brokerage Integration

Support:

* Angel One (Initial)
* Future Broker Integrations

---

## Daily Client Consent

Clients must provide daily authorization before automated trading begins.

---

## Automated Trade Execution

Signals must execute automatically once consent is granted.

---

## Strategy Management

Support:

* Intraday
* Delivery
* Futures
* Options

---

## Risk Controls

Client configurable:

* Daily loss limits
* Maximum lot multiplier
* Capital allocation
* Backup capital

---

## Subscription Management

Platform must integrate with the existing billing system.

---

# 11. Success Metrics

## Business KPIs

### Client Acquisition

Target:

* 10,000 Active Clients

---

### Subscription Growth

Measure:

* Monthly recurring revenue
* Active subscriptions

---

### Client Retention

Measure:

* Renewal rates
* Churn rates

---

## Product KPIs

### Strategy Activation Rate

Percentage of subscribed clients activating automated strategies.

---

### Daily Active Traders

Number of unique users trading daily.

---

### Execution Success Rate

Target:

* Greater than 99%

---

### Trade Processing Latency

Target:

* Less than 2 seconds

---

# 12. Assumptions

The following assumptions apply:

* Broker APIs remain available.
* Users maintain sufficient capital.
* Daily consent is obtained.
* Regulatory requirements permit platform operation.
* Research analysts continue providing signals.

---

# 13. Constraints

## Regulatory Constraints

Platform operations must comply with applicable financial regulations.

---

## Broker Constraints

Execution capabilities depend on broker API availability.

---

## Market Constraints

Trading only occurs during market hours.

---

# 14. Risks

## Broker API Downtime

Impact:

* Trade execution interruption

Mitigation:

* Retry mechanisms
* Monitoring

---

## Regulatory Changes

Impact:

* Business model changes

Mitigation:

* Compliance reviews

---

## Market Volatility

Impact:

* Slippage
* Execution risk

Mitigation:

* Risk controls
* Client disclosures

---

# 15. Future Opportunities

* Additional broker integrations
* AI-assisted strategy insights
* Portfolio analytics
* Multi-account trading
* Advanced risk engines
* International expansion

---

# 16. Roadmap

## Phase 1

* Angel One Integration
* Strategy Automation
* Analyst Dashboard
* Client Dashboard
* Mobile Application

---

## Phase 2

* Multi-Broker Support
* Advanced Analytics
* Enhanced Risk Controls

---

## Phase 3

* AI Recommendations
* Portfolio Optimization
* Institutional Features

---

# 17. Approval

| Role               | Name | Status  |
| ------------------ | ---- | ------- |
| Product Owner      | TBD  | Pending |
| Technical Lead     | TBD  | Pending |
| Compliance Officer | TBD  | Pending |

---

END OF DOCUMENT
