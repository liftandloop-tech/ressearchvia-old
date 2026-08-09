-- Trim BrokerCode enum to only ANGEL_ONE and ZEBU
CREATE TYPE "BrokerCode_new" AS ENUM ('ANGEL_ONE', 'ZEBU');

ALTER TABLE "brokers"
  ALTER COLUMN "code" TYPE "BrokerCode_new"
  USING "code"::text::"BrokerCode_new";

ALTER TABLE "broker_auth_states"
  ALTER COLUMN "broker" TYPE "BrokerCode_new"
  USING "broker"::text::"BrokerCode_new";

DROP TYPE "BrokerCode";
ALTER TYPE "BrokerCode_new" RENAME TO "BrokerCode";
