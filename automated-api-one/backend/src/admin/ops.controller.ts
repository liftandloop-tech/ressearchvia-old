import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  UseGuards,
  Request,
  HttpCode,
  HttpStatus,
  Body,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { OpsService } from './ops.service';

@ApiTags('Operations (SRE)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('SUPERADMIN', 'SRE')
@Controller('ops')
export class OpsController {
  constructor(private readonly opsService: OpsService) {}

  @Post('signals/:signalId/replay')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Replay a signal by ID' })
  async replaySignal(@Request() req, @Param('signalId') signalId: string) {
    const operatorId = req.user.userId;
    return this.opsService.replaySignal(operatorId, signalId);
  }

  @Post('outbox/:eventId/replay')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Replay an outbox event by ID' })
  async replayOutboxEvent(@Request() req, @Param('eventId') eventId: string) {
    const operatorId = req.user.userId;
    return this.opsService.replayOutboxEvent(operatorId, eventId);
  }

  @Get('dlq')
  @ApiOperation({ summary: 'Get overall DLQ metrics' })
  async getDlqMetrics(@Request() req) {
    const operatorId = req.user.userId;
    return this.opsService.getDlqMetrics(operatorId);
  }

  @Get('dlq/:queue')
  @ApiOperation({ summary: 'Get jobs in a specific DLQ queue' })
  async getDlqJobs(@Request() req, @Param('queue') queue: string) {
    const operatorId = req.user.userId;
    return this.opsService.getDlqJobs(operatorId, queue);
  }

  @Post('dlq/:queue/:jobId/replay')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Replay a specific job from DLQ' })
  async replayDlqJob(
    @Request() req,
    @Param('queue') queue: string,
    @Param('jobId') jobId: string,
  ) {
    const operatorId = req.user.userId;
    return this.opsService.replayDlqJob(operatorId, queue, jobId);
  }

  @Post('dlq/:queue/:jobId/delete')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete/purge a job from DLQ' })
  async deleteDlqJob(
    @Request() req,
    @Param('queue') queue: string,
    @Param('jobId') jobId: string,
  ) {
    const operatorId = req.user.userId;
    return this.opsService.deleteDlqJob(operatorId, queue, jobId);
  }

  @Post('queues/:queue/pause')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Pause a queue' })
  @ApiQuery({ name: 'force', type: Boolean, required: false })
  @ApiQuery({ name: 'reason', type: String, required: false })
  async pauseQueue(
    @Request() req,
    @Param('queue') queue: string,
    @Query('force') force?: string,
    @Query('reason') reason?: string,
  ) {
    const operatorId = req.user.userId;
    const isForce = force === 'true';
    return this.opsService.pauseQueue(operatorId, queue, isForce, reason);
  }

  @Post('queues/:queue/resume')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Resume a queue' })
  @ApiQuery({ name: 'reason', type: String, required: false })
  async resumeQueue(
    @Request() req,
    @Param('queue') queue: string,
    @Query('reason') reason?: string,
  ) {
    const operatorId = req.user.userId;
    return this.opsService.resumeQueue(operatorId, queue, reason);
  }

  @Post('queues/:queue/drain')
  @Roles('SUPERADMIN')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Drain a queue (SUPERADMIN only)' })
  @ApiQuery({ name: 'reason', type: String, required: true })
  async drainQueue(
    @Request() req,
    @Param('queue') queue: string,
    @Query('reason') reason: string,
  ) {
    const operatorId = req.user.userId;
    return this.opsService.drainQueue(operatorId, queue, reason);
  }

  @Post('segments/:segmentId/unlock')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Unlock segment active locks in Redis' })
  async unlockSegment(@Request() req, @Param('segmentId') segmentId: string) {
    const operatorId = req.user.userId;
    return this.opsService.unlockSegment(operatorId, segmentId);
  }

  @Post('brokers/:userBrokerId/refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Force refresh user broker session token' })
  async forceBrokerRefresh(@Request() req, @Param('userBrokerId') userBrokerId: string) {
    const operatorId = req.user.userId;
    return this.opsService.forceBrokerSessionRefresh(operatorId, userBrokerId);
  }

  @Post('positions/rebuild')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Queue a global position cache rebuild' })
  async rebuildAllPositions(@Request() req) {
    const operatorId = req.user.userId;
    return this.opsService.rebuildPositions(operatorId);
  }

  @Post('positions/:userId/rebuild')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Queue a position cache rebuild for specific user' })
  async rebuildUserPositions(@Request() req, @Param('userId') userId: string) {
    const operatorId = req.user.userId;
    return this.opsService.rebuildPositions(operatorId, userId);
  }

  @Post('maintenance/enable')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Enable maintenance mode' })
  @ApiQuery({ name: 'type', type: String, required: false, example: 'global' })
  async enableMaintenance(@Request() req, @Query('type') type?: string) {
    const operatorId = req.user.userId;
    return this.opsService.enableMaintenance(operatorId, type || 'global');
  }

  @Post('maintenance/disable')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Disable maintenance mode' })
  @ApiQuery({ name: 'type', type: String, required: false, example: 'global' })
  async disableMaintenance(@Request() req, @Query('type') type?: string) {
    const operatorId = req.user.userId;
    return this.opsService.disableMaintenance(operatorId, type || 'global');
  }

  @Post('trading/stop')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Stop trading globally (15 min TTL or permanent kill switch)' })
  @ApiQuery({ name: 'permanent', type: Boolean, required: false })
  @ApiQuery({ name: 'reason', type: String, required: false })
  async stopTrading(
    @Request() req,
    @Query('permanent') permanent?: string,
    @Query('reason') reason?: string,
  ) {
    const operatorId = req.user.userId;
    const isPermanent = permanent === 'true';
    return this.opsService.stopTrading(operatorId, isPermanent, reason);
  }

  @Post('trading/start')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Start trading globally (clear kill switch)' })
  async startTrading(@Request() req) {
    const operatorId = req.user.userId;
    return this.opsService.startTrading(operatorId);
  }

  @Post('audit/export')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Export SRE operations audit logs to CSV' })
  async exportAudit(@Request() req) {
    const operatorId = req.user.userId;
    return this.opsService.exportAuditLogs(operatorId);
  }

  @Get('audit')
  @ApiOperation({ summary: 'Retrieve operations SRE audit logs with filters' })
  @ApiQuery({ name: 'action', required: false })
  @ApiQuery({ name: 'operatorId', required: false })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'from', required: false })
  @ApiQuery({ name: 'page', type: Number, required: false })
  @ApiQuery({ name: 'limit', type: Number, required: false })
  async getAudits(
    @Request() req,
    @Query('action') action?: string,
    @Query('operatorId') operatorId?: string,
    @Query('status') status?: string,
    @Query('from') from?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const operator = req.user.userId;
    const pageNum = page ? parseInt(page, 10) : 1;
    const limitNum = limit ? parseInt(limit, 10) : 50;
    return this.opsService.getAudits(operator, {
      action,
      operatorId,
      status,
      from,
      page: pageNum,
      limit: limitNum,
    });
  }

  @Get('reconciliation/runs')
  @ApiOperation({ summary: 'Get all reconciliation runs' })
  async getReconciliationRuns() {
    return this.opsService.getReconciliationRuns();
  }

  @Get('reconciliation/issues')
  @ApiOperation({ summary: 'Get all reconciliation issues' })
  @ApiQuery({ name: 'resolved', type: Boolean, required: false })
  async getReconciliationIssues(@Query('resolved') resolved?: string) {
    const isResolved = resolved === 'true' ? true : resolved === 'false' ? false : undefined;
    return this.opsService.getReconciliationIssues(isResolved);
  }

  @Get('reconciliation/issues/summary')
  @ApiOperation({ summary: 'Get summary counts of reconciliation issues' })
  async getReconciliationIssuesSummary() {
    return this.opsService.getReconciliationIssuesSummary();
  }

  @Post('reconciliation/:issueId/resolve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Manually resolve a reconciliation issue' })
  async resolveReconciliationIssue(
    @Request() req,
    @Param('issueId') issueId: string,
  ) {
    const operatorId = req.user.userId;
    return this.opsService.resolveReconciliationIssue(operatorId, issueId);
  }

  @Post('reconciliation/:issueId/escalate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Manually escalate a reconciliation issue' })
  async escalateReconciliationIssue(
    @Request() req,
    @Param('issueId') issueId: string,
  ) {
    const operatorId = req.user.userId;
    return this.opsService.escalateReconciliationIssue(operatorId, issueId);
  }

  @Post('reconciliation/run')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Trigger a manual reconciliation run' })
  async triggerReconciliationRun(@Request() req) {
    const operatorId = req.user.userId;
    return this.opsService.triggerReconciliationRun(operatorId);
  }

  @Post('risk/recalculate')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Force risk snapshot recalculation for a user' })
  async forceRecalculate(@Request() req, @Body('userId') userId: string) {
    const operatorId = req.user.userId;
    return this.opsService.recalculateRiskSnapshot(operatorId, userId);
  }

  @Post('risk/unblock/:userId')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Manually unblock risk circuit breaker for a user' })
  async unblockUserRisk(@Request() req, @Param('userId') userId: string) {
    const operatorId = req.user.userId;
    return this.opsService.unblockUserRisk(operatorId, userId);
  }

  @Post('risk/global-lock')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Toggle global emergency risk lock' })
  async toggleGlobalLock(
    @Request() req,
    @Body('blocked') blocked: boolean,
    @Body('reason') reason?: string,
  ) {
    const operatorId = req.user.userId;
    return this.opsService.toggleGlobalEmergencyLock(operatorId, blocked, reason);
  }

  @Post('alerts/:alertId/acknowledge')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Manually acknowledge an SRE alert' })
  async acknowledgeAlert(@Request() req, @Param('alertId') alertId: string) {
    const operatorId = req.user.userId;
    return this.opsService.acknowledgeAlert(operatorId, alertId);
  }

  @Post('alerts/:alertId/resolve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Manually resolve an SRE alert' })
  async resolveAlert(@Request() req, @Param('alertId') alertId: string) {
    const operatorId = req.user.userId;
    return this.opsService.resolveAlert(operatorId, alertId);
  }

  @Get('users/:identifier/live-broker-data')
  @ApiOperation({ summary: 'Get live broker portfolio and books for a specific user' })
  async getUserLiveBrokerData(@Param('identifier') identifier: string) {
    return this.opsService.getUserLiveBrokerData(identifier);
  }
}

