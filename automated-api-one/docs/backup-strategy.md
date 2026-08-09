# Backup Strategy

This document outlines the backup policies, schedules, and tools for the database and caching layers.

## PostgreSQL Backups

### Schedule & Sizing
- **Daily Incremental Backups**: Every night at 01:00 AM IST. Retained for 30 days.
- **Weekly Full Backups**: Every Sunday at 02:00 AM IST. Retained for 12 weeks.
- **Monthly Archival Backups**: First of every month. Retained for 12 months.

### Tooling
- We use `pg_dump` for backup generation and `pg_restore` for restoration validation:
  ```bash
  # Daily cron backup execution command
  pg_dump -h postgres-prod -U postgres -d trading_platform_prod -F c -b -v -f /backups/db/daily/db_backup_$(date +\%F).dump
  ```
- Backups are encrypted at rest using AES-256 and pushed to AWS S3 bucket `s3://trading-platform-db-backups/`.

---

## Redis Backups

### Policy
- Since Redis is used as the transactional state engine for BullMQ queues and locks, backups focus on capturing the `.rdb` file.
- `AOF` (Append Only File) is enabled globally with `appendfsync everysec` to ensure high durability.
- Hourly snapshots are triggered via:
  ```redis
  BGSAVE
  ```
- The resulting `/data/dump.rdb` file is uploaded to `s3://trading-platform-redis-backups/` hourly.
