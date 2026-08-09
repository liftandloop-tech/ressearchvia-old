-- DropIndex
DROP INDEX "signals_segment_id_idx";

-- CreateIndex
CREATE INDEX "signals_segment_id_status_idx" ON "signals"("segment_id", "status");
CREATE INDEX "report_exports_user_id_status_idx" ON "report_exports"("user_id", "status");
CREATE INDEX "report_exports_created_at_idx" ON "report_exports"("created_at");
