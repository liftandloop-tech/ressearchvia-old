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
var TradingService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.TradingService = void 0;
const common_1 = require("@nestjs/common");
const signal_orchestrator_service_1 = require("./services/signal-orchestrator.service");
const client_1 = require("@prisma/client");
let TradingService = TradingService_1 = class TradingService {
    orchestrator;
    logger = new common_1.Logger(TradingService_1.name);
    constructor(orchestrator) {
        this.orchestrator = orchestrator;
    }
    async executeSignal(signalId, segmentId) {
        this.logger.log(`Trading engine triggered: signalId=${signalId} segmentId=${segmentId}`);
        const result = await this.orchestrator.processSignal(signalId);
        return {
            success: result.state !== client_1.SignalState.FAILED,
            ...result,
        };
    }
};
exports.TradingService = TradingService;
exports.TradingService = TradingService = TradingService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [signal_orchestrator_service_1.SignalOrchestratorService])
], TradingService);
//# sourceMappingURL=trading.service.js.map