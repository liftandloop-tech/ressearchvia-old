# Environment Configuration Audit

| Environment Variable | Required | Default Value | Production Value | Purpose |
| --- | --- | --- | --- | --- |
| `DATABASE_URL` | Yes | Local Prisma Postgres URL | `postgresql://user:pass@host:5432/db` | Primary PostgreSQL connection string |
| `REDIS_HOST` | Yes | `localhost` | `redis-cluster.prod` | Host address of Redis Cluster/Instance |
| `REDIS_PORT` | No | `6379` | `6379` | Port of Redis Instance |
| `JWT_SECRET` | Yes | `super_secret_jwt_key` | Generated Secure High-Entropy Key | Signing secret for OAuth/API Access Tokens |
| `JWT_REFRESH_SECRET` | Yes | `super_secret_jwt_refresh_key` | Generated Secure High-Entropy Key | Signing secret for OAuth Refresh Tokens |
| `PORT` | No | `3000` | `8080` | Port NestJS listens on |
| `MOCK_BROKERS` | No | `true` | `false` | Enables/Disables Broker Mocks |
| `WS_WORKER_CONCURRENCY` | No | `5` | `25` | Concurrency for WebSocket worker queue |
| `OUTBOX_WORKER_CONCURRENCY` | No | `10` | `50` | Concurrency for Outbox worker queue |
| `REPORT_WORKER_CONCURRENCY` | No | `2` | `8` | Concurrency for Report generator |
| `POSITION_REBUILD_CONCURRENCY` | No | `1` | `5` | Concurrency for position rebuild queue |
| `BROKER_TIMEOUT_MS` | No | `5000` | `2500` | Gateway timeout for Broker session HTTP requests |
| `MAX_SIGNAL_REPLAYS` | No | `5` | `5` | Maximum replays permitted per signal |
| `MSG91_API_KEY` | Yes | `mock_msg91_key` | Production API Key | Key for SMS gateway OTP dispatches |
| `FCM_PROJECT_ID` | Yes | `mock_fcm` | Production Project ID | Project ID for Firebase push notifications |
| `FCM_PRIVATE_KEY` | Yes | `mock_fcm_private_key` | Production Private Key | Private key credentials for Firebase SDK |
| `RESEND_API_KEY` | Yes | `mock_resend_key` | Production Resend Key | API key for transactional email dispatches |
| `RISK_FREE_RATE_ANNUAL` | No | `6.5` | `6.5` | Configurable annual risk-free rate percentage used in Sharpe/Sortino calculations |

