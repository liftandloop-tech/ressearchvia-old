-- AlterEnum
ALTER TYPE "QueueJobStatus" ADD VALUE 'CANCELLED';

-- AlterEnum
ALTER TYPE "OperationsAction" ADD VALUE 'QUEUE_DRAIN';
ALTER TYPE "OperationsAction" ADD VALUE 'MAINTENANCE_ENABLE';
ALTER TYPE "OperationsAction" ADD VALUE 'MAINTENANCE_DISABLE';
ALTER TYPE "OperationsAction" ADD VALUE 'TRADING_STOP';
ALTER TYPE "OperationsAction" ADD VALUE 'TRADING_START';

-- AlterTable
ALTER TABLE "signals" ADD COLUMN "metadata" JSONB;

-- AlterTable
ALTER TABLE "report_exports" ALTER COLUMN "user_id" DROP NOT NULL;
