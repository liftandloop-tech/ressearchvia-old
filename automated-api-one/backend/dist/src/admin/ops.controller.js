"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OpsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const roles_guard_1 = require("../auth/roles.guard");
const roles_decorator_1 = require("../auth/roles.decorator");
const ops_service_1 = require("./ops.service");
let OpsController = class OpsController {
    opsService;
    constructor(opsService) {
        this.opsService = opsService;
    }
    async replaySignal(req, signalId) {
        const operatorId = req.user.userId;
        return this.opsService.replaySignal(operatorId, signalId);
    }
    async replayOutboxEvent(req, eventId) {
        const operatorId = req.user.userId;
        return this.opsService.replayOutboxEvent(operatorId, eventId);
    }
    async getDlqMetrics(req) {
        const operatorId = req.user.userId;
        return this.opsService.getDlqMetrics(operatorId);
    }
    async getDlqJobs(req, queue) {
        const operatorId = req.user.userId;
        return this.opsService.getDlqJobs(operatorId, queue);
    }
    async replayDlqJob(req, queue, jobId) {
        const operatorId = req.user.userId;
        return this.opsService.replayDlqJob(operatorId, queue, jobId);
    }
    async deleteDlqJob(req, queue, jobId) {
        const operatorId = req.user.userId;
        return this.opsService.deleteDlqJob(operatorId, queue, jobId);
    }
    async pauseQueue(req, queue, force, reason) {
        const operatorId = req.user.userId;
        const isForce = force === 'true';
        return this.opsService.pauseQueue(operatorId, queue, isForce, reason);
    }
    async resumeQueue(req, queue, reason) {
        const operatorId = req.user.userId;
        return this.opsService.resumeQueue(operatorId, queue, reason);
    }
    async drainQueue(req, queue, reason) {
        const operatorId = req.user.userId;
        return this.opsService.drainQueue(operatorId, queue, reason);
    }
    async unlockSegment(req, segmentId) {
        const operatorId = req.user.userId;
        return this.opsService.unlockSegment(operatorId, segmentId);
    }
    async forceBrokerRefresh(req, userBrokerId) {
        const operatorId = req.user.userId;
        return this.opsService.forceBrokerSessionRefresh(operatorId, userBrokerId);
    }
    async rebuildAllPositions(req) {
        const operatorId = req.user.userId;
        return this.opsService.rebuildPositions(operatorId);
    }
    async rebuildUserPositions(req, userId) {
        const operatorId = req.user.userId;
        return this.opsService.rebuildPositions(operatorId, userId);
    }
    async enableMaintenance(req, type) {
        const operatorId = req.user.userId;
        return this.opsService.enableMaintenance(operatorId, type || 'global');
    }
    async disableMaintenance(req, type) {
        const operatorId = req.user.userId;
        return this.opsService.disableMaintenance(operatorId, type || 'global');
    }
    async stopTrading(req, permanent, reason) {
        const operatorId = req.user.userId;
        const isPermanent = permanent === 'true';
        return this.opsService.stopTrading(operatorId, isPermanent, reason);
    }
    async startTrading(req) {
        const operatorId = req.user.userId;
        return this.opsService.startTrading(operatorId);
    }
    async exportAudit(req) {
        const operatorId = req.user.userId;
        return this.opsService.exportAuditLogs(operatorId);
    }
    async getAudits(req, action, operatorId, status, from, page, limit) {
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
    async getReconciliationRuns() {
        return this.opsService.getReconciliationRuns();
    }
    async getReconciliationIssues(resolved) {
        const isResolved = resolved === 'true' ? true : resolved === 'false' ? false : undefined;
        return this.opsService.getReconciliationIssues(isResolved);
    }
    async getReconciliationIssuesSummary() {
        return this.opsService.getReconciliationIssuesSummary();
    }
    async resolveReconciliationIssue(req, issueId) {
        const operatorId = req.user.userId;
        return this.opsService.resolveReconciliationIssue(operatorId, issueId);
    }
    async escalateReconciliationIssue(req, issueId) {
        const operatorId = req.user.userId;
        return this.opsService.escalateReconciliationIssue(operatorId, issueId);
    }
    async triggerReconciliationRun(req) {
        const operatorId = req.user.userId;
        return this.opsService.triggerReconciliationRun(operatorId);
    }
    async forceRecalculate(req, userId) {
        const operatorId = req.user.userId;
        return this.opsService.recalculateRiskSnapshot(operatorId, userId);
    }
    async unblockUserRisk(req, userId) {
        const operatorId = req.user.userId;
        return this.opsService.unblockUserRisk(operatorId, userId);
    }
    async toggleGlobalLock(req, blocked, reason) {
        const operatorId = req.user.userId;
        return this.opsService.toggleGlobalEmergencyLock(operatorId, blocked, reason);
    }
    async acknowledgeAlert(req, alertId) {
        const operatorId = req.user.userId;
        return this.opsService.acknowledgeAlert(operatorId, alertId);
    }
    async resolveAlert(req, alertId) {
        const operatorId = req.user.userId;
        return this.opsService.resolveAlert(operatorId, alertId);
    }
    async getUserLiveBrokerData(identifier) {
        return this.opsService.getUserLiveBrokerData(identifier);
    }
};
exports.OpsController = OpsController;
__decorate([
    (0, common_1.Post)('signals/:signalId/replay'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Replay a signal by ID' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('signalId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "replaySignal", null);
__decorate([
    (0, common_1.Post)('outbox/:eventId/replay'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Replay an outbox event by ID' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('eventId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "replayOutboxEvent", null);
__decorate([
    (0, common_1.Get)('dlq'),
    (0, swagger_1.ApiOperation)({ summary: 'Get overall DLQ metrics' }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "getDlqMetrics", null);
__decorate([
    (0, common_1.Get)('dlq/:queue'),
    (0, swagger_1.ApiOperation)({ summary: 'Get jobs in a specific DLQ queue' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('queue')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "getDlqJobs", null);
__decorate([
    (0, common_1.Post)('dlq/:queue/:jobId/replay'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Replay a specific job from DLQ' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('queue')),
    __param(2, (0, common_1.Param)('jobId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "replayDlqJob", null);
__decorate([
    (0, common_1.Post)('dlq/:queue/:jobId/delete'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Delete/purge a job from DLQ' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('queue')),
    __param(2, (0, common_1.Param)('jobId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "deleteDlqJob", null);
__decorate([
    (0, common_1.Post)('queues/:queue/pause'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Pause a queue' }),
    (0, swagger_1.ApiQuery)({ name: 'force', type: Boolean, required: false }),
    (0, swagger_1.ApiQuery)({ name: 'reason', type: String, required: false }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('queue')),
    __param(2, (0, common_1.Query)('force')),
    __param(3, (0, common_1.Query)('reason')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "pauseQueue", null);
__decorate([
    (0, common_1.Post)('queues/:queue/resume'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Resume a queue' }),
    (0, swagger_1.ApiQuery)({ name: 'reason', type: String, required: false }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('queue')),
    __param(2, (0, common_1.Query)('reason')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "resumeQueue", null);
__decorate([
    (0, common_1.Post)('queues/:queue/drain'),
    (0, roles_decorator_1.Roles)('SUPERADMIN'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Drain a queue (SUPERADMIN only)' }),
    (0, swagger_1.ApiQuery)({ name: 'reason', type: String, required: true }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('queue')),
    __param(2, (0, common_1.Query)('reason')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "drainQueue", null);
__decorate([
    (0, common_1.Post)('segments/:segmentId/unlock'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Unlock segment active locks in Redis' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('segmentId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "unlockSegment", null);
__decorate([
    (0, common_1.Post)('brokers/:userBrokerId/refresh'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Force refresh user broker session token' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('userBrokerId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "forceBrokerRefresh", null);
__decorate([
    (0, common_1.Post)('positions/rebuild'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Queue a global position cache rebuild' }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "rebuildAllPositions", null);
__decorate([
    (0, common_1.Post)('positions/:userId/rebuild'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Queue a position cache rebuild for specific user' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "rebuildUserPositions", null);
__decorate([
    (0, common_1.Post)('maintenance/enable'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Enable maintenance mode' }),
    (0, swagger_1.ApiQuery)({ name: 'type', type: String, required: false, example: 'global' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('type')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "enableMaintenance", null);
__decorate([
    (0, common_1.Post)('maintenance/disable'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Disable maintenance mode' }),
    (0, swagger_1.ApiQuery)({ name: 'type', type: String, required: false, example: 'global' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('type')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "disableMaintenance", null);
__decorate([
    (0, common_1.Post)('trading/stop'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Stop trading globally (15 min TTL or permanent kill switch)' }),
    (0, swagger_1.ApiQuery)({ name: 'permanent', type: Boolean, required: false }),
    (0, swagger_1.ApiQuery)({ name: 'reason', type: String, required: false }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('permanent')),
    __param(2, (0, common_1.Query)('reason')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "stopTrading", null);
__decorate([
    (0, common_1.Post)('trading/start'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Start trading globally (clear kill switch)' }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "startTrading", null);
__decorate([
    (0, common_1.Post)('audit/export'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Export SRE operations audit logs to CSV' }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "exportAudit", null);
__decorate([
    (0, common_1.Get)('audit'),
    (0, swagger_1.ApiOperation)({ summary: 'Retrieve operations SRE audit logs with filters' }),
    (0, swagger_1.ApiQuery)({ name: 'action', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'operatorId', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'status', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'from', required: false }),
    (0, swagger_1.ApiQuery)({ name: 'page', type: Number, required: false }),
    (0, swagger_1.ApiQuery)({ name: 'limit', type: Number, required: false }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Query)('action')),
    __param(2, (0, common_1.Query)('operatorId')),
    __param(3, (0, common_1.Query)('status')),
    __param(4, (0, common_1.Query)('from')),
    __param(5, (0, common_1.Query)('page')),
    __param(6, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String, String, String, String, String, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "getAudits", null);
__decorate([
    (0, common_1.Get)('reconciliation/runs'),
    (0, swagger_1.ApiOperation)({ summary: 'Get all reconciliation runs' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "getReconciliationRuns", null);
__decorate([
    (0, common_1.Get)('reconciliation/issues'),
    (0, swagger_1.ApiOperation)({ summary: 'Get all reconciliation issues' }),
    (0, swagger_1.ApiQuery)({ name: 'resolved', type: Boolean, required: false }),
    __param(0, (0, common_1.Query)('resolved')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "getReconciliationIssues", null);
__decorate([
    (0, common_1.Get)('reconciliation/issues/summary'),
    (0, swagger_1.ApiOperation)({ summary: 'Get summary counts of reconciliation issues' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "getReconciliationIssuesSummary", null);
__decorate([
    (0, common_1.Post)('reconciliation/:issueId/resolve'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Manually resolve a reconciliation issue' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('issueId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "resolveReconciliationIssue", null);
__decorate([
    (0, common_1.Post)('reconciliation/:issueId/escalate'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Manually escalate a reconciliation issue' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('issueId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "escalateReconciliationIssue", null);
__decorate([
    (0, common_1.Post)('reconciliation/run'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Trigger a manual reconciliation run' }),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "triggerReconciliationRun", null);
__decorate([
    (0, common_1.Post)('risk/recalculate'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Force risk snapshot recalculation for a user' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "forceRecalculate", null);
__decorate([
    (0, common_1.Post)('risk/unblock/:userId'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Manually unblock risk circuit breaker for a user' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "unblockUserRisk", null);
__decorate([
    (0, common_1.Post)('risk/global-lock'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Toggle global emergency risk lock' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Body)('blocked')),
    __param(2, (0, common_1.Body)('reason')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Boolean, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "toggleGlobalLock", null);
__decorate([
    (0, common_1.Post)('alerts/:alertId/acknowledge'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Manually acknowledge an SRE alert' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('alertId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "acknowledgeAlert", null);
__decorate([
    (0, common_1.Post)('alerts/:alertId/resolve'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, swagger_1.ApiOperation)({ summary: 'Manually resolve an SRE alert' }),
    __param(0, (0, common_1.Request)()),
    __param(1, (0, common_1.Param)('alertId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "resolveAlert", null);
__decorate([
    (0, common_1.Get)('users/:identifier/live-broker-data'),
    (0, swagger_1.ApiOperation)({ summary: 'Get live broker portfolio and books for a specific user' }),
    __param(0, (0, common_1.Param)('identifier')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], OpsController.prototype, "getUserLiveBrokerData", null);
exports.OpsController = OpsController = __decorate([
    (0, swagger_1.ApiTags)('Operations (SRE)'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)('SUPERADMIN', 'SRE'),
    (0, common_1.Controller)('ops'),
    __metadata("design:paramtypes", [ops_service_1.OpsService])
], OpsController);
//# sourceMappingURL=ops.controller.js.map