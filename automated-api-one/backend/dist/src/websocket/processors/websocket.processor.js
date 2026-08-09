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
var WebsocketProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.WebsocketProcessor = void 0;
const bullmq_1 = require("@nestjs/bullmq");
const common_1 = require("@nestjs/common");
const websocket_service_1 = require("../services/websocket.service");
const queues_service_1 = require("../../infrastructure/queues/queues.service");
const queue_constants_1 = require("../../infrastructure/queues/queue.constants");
const client_1 = require("@prisma/client");
let WebsocketProcessor = WebsocketProcessor_1 = class WebsocketProcessor extends bullmq_1.WorkerHost {
    websocketService;
    queueService;
    logger = new common_1.Logger(WebsocketProcessor_1.name);
    constructor(websocketService, queueService) {
        super();
        this.websocketService = websocketService;
        this.queueService = queueService;
    }
    async process(job) {
        const { event, room, payload } = job.data;
        const eventId = job.data.eventId || job.id || `ws-${event}-${Date.now()}`;
        this.logger.log(`Processing WebSocket job: event=${event} room=${room} jobId=${job.id}`);
        try {
            await this.websocketService.broadcast(eventId, event, room, payload);
            await this.queueService.updateJobStatus(queue_constants_1.Queues.WEBSOCKET, job.id ?? eventId, client_1.QueueJobStatus.COMPLETED, job.attemptsMade);
        }
        catch (err) {
            this.logger.error(`WebSocket processor job ${job.id} failed: ${err.message}`);
            await this.queueService.updateJobStatus(queue_constants_1.Queues.WEBSOCKET, job.id ?? eventId, client_1.QueueJobStatus.FAILED, job.attemptsMade);
            throw err;
        }
    }
};
exports.WebsocketProcessor = WebsocketProcessor;
exports.WebsocketProcessor = WebsocketProcessor = WebsocketProcessor_1 = __decorate([
    (0, bullmq_1.Processor)(queue_constants_1.Queues.WEBSOCKET, {
        concurrency: Number(process.env.WS_WORKER_CONCURRENCY || 20),
    }),
    __metadata("design:paramtypes", [websocket_service_1.WebsocketService,
        queues_service_1.QueueService])
], WebsocketProcessor);
//# sourceMappingURL=websocket.processor.js.map