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
var ReconciliationScheduler_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReconciliationScheduler = void 0;
const common_1 = require("@nestjs/common");
const schedule_1 = require("@nestjs/schedule");
const reconciliation_service_1 = require("./reconciliation.service");
let ReconciliationScheduler = ReconciliationScheduler_1 = class ReconciliationScheduler {
    reconciliationService;
    logger = new common_1.Logger(ReconciliationScheduler_1.name);
    constructor(reconciliationService) {
        this.reconciliationService = reconciliationService;
    }
    async runScheduledReconciliation() {
        if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
            return;
        }
        this.logger.log('Triggering daily scheduled broker reconciliation run...');
        try {
            const runId = await this.reconciliationService.triggerReconciliation();
            this.logger.log(`Scheduled reconciliation run triggered successfully: ${runId}`);
        }
        catch (err) {
            this.logger.error(`Failed to trigger scheduled reconciliation: ${err.message}`);
        }
    }
};
exports.ReconciliationScheduler = ReconciliationScheduler;
__decorate([
    (0, schedule_1.Cron)('30 23 * * *', { timeZone: 'Asia/Kolkata' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], ReconciliationScheduler.prototype, "runScheduledReconciliation", null);
exports.ReconciliationScheduler = ReconciliationScheduler = ReconciliationScheduler_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [reconciliation_service_1.ReconciliationService])
], ReconciliationScheduler);
//# sourceMappingURL=reconciliation.scheduler.js.map