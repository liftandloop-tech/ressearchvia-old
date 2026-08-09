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
var SignalExecutionProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.SignalExecutionProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const signal_orchestrator_service_1 = require("../services/signal-orchestrator.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const client_1 = require("@prisma/client");
const metrics_service_1 = require("../../infrastructure/metrics/metrics.service");
let SignalExecutionProcessor = SignalExecutionProcessor_1 = class SignalExecutionProcessor extends bullmq_1.WorkerHost {
    orchestrator;
    queueService;
    metrics;
    logger = new common_1.Logger(SignalExecutionProcessor_1.name);
    constructor(orchestrator, queueService, metrics) {
        super();
        this.orchestrator = orchestrator;
        this.queueService = queueService;
        this.metrics = metrics;
    }
    async process(job) {
        const { signalId } = job.data;
        const jobId = job.id ?? `signal-${signalId}`;
        this.logger.log(`Processing signal execution job: signalId=${signalId} jobId=${jobId}`);
        try {
            const result = await this.orchestrator.processSignal(signalId);
            await this.queueService.updateJobStatus(queue_constants_1.Queues.SIGNAL_PROCESSING, jobId, client_1.QueueJobStatus.COMPLETED, job.attemptsMade);
            this.metrics.incrementSignalsProcessed();
            this.logger.log(`Signal ${signalId} processed. State=${result.state} ` +
                `Success=${result.successUsers} Rejected=${result.rejectedUsers}`);
        }
        catch (err) {
            this.metrics.incrementSignalsFailed();
            this.logger.error(`Signal execution job ${jobId} failed: ${err.message}`, err.stack);
            await this.queueService.updateJobStatus(queue_constants_1.Queues.SIGNAL_PROCESSING, jobId, client_1.QueueJobStatus.FAILED, job.attemptsMade);
            throw err;
        }
    }
};
exports.SignalExecutionProcessor = SignalExecutionProcessor;
exports.SignalExecutionProcessor = SignalExecutionProcessor = SignalExecutionProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.SIGNAL_PROCESSING, {
        concurrency: 1,
    }),
    __metadata("design:paramtypes", [signal_orchestrator_service_1.SignalOrchestratorService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService])
], SignalExecutionProcessor);
//# sourceMappingURL=signal-execution.processor.js.map