-- Add ZEBU to BrokerCode enum
ALTER TYPE "BrokerCode" ADD VALUE IF NOT EXISTS 'ZEBU';

-- Add per-user api_key and vendor_code columns to user_brokers
ALTER TABLE "user_brokers"
  ADD COLUMN IF NOT EXISTS "api_key"     TEXT,
  ADD COLUMN IF NOT EXISTS "vendor_code" TEXT;
