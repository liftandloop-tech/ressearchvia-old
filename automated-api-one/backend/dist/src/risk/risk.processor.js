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
var RiskProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.RiskProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const risk_service_1 = require("./risk.service");
const queue_constants_1 = require("../infrastructure/queues/queue.constants");
let RiskProcessor = RiskProcessor_1 = class RiskProcessor extends bullmq_1.WorkerHost {
    riskService;
    logger = new common_1.Logger(RiskProcessor_1.name);
    constructor(riskService) {
        super();
        this.riskService = riskService;
    }
    async process(job) {
        const { userId } = job.data;
        this.logger.log(`Processing risk recalculation job ${job.id} for user: ${userId}`);
        try {
            await this.riskService.recalculateRiskSnapshot(userId);
        }
        catch (err) {
            this.logger.error(`Failed to recalculate risk snapshot for user ${userId}: ${err.message}`, err.stack);
            throw err;
        }
    }
};
exports.RiskProcessor = RiskProcessor;
exports.RiskProcessor = RiskProcessor = RiskProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.RISK_RECALCULATE),
    __metadata("design:paramtypes", [risk_service_1.RiskService])
], RiskProcessor);
//# sourceMappingURL=risk.processor.js.map