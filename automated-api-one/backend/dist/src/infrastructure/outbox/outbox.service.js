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
var OutboxService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OutboxService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../../prisma.service");
const client_1 = require("@prisma/client");
const queues_service_1 = require("../queues/queues.service");
const queue_constants_1 = require("../queues/queue.constants");
const metrics_service_1 = require("../metrics/metrics.service");
let OutboxService = OutboxService_1 = class OutboxService {
    prisma;
    queueService;
    metrics;
    logger = new common_1.Logger(OutboxService_1.name);
    constructor(prisma, queueService, metrics) {
        this.prisma = prisma;
        this.queueService = queueService;
        this.metrics = metrics;
    }
    async createEvent(eventType, payload, tx, options) {
        const db = tx || this.prisma;
        const correlationId = options?.correlationId || payload?.correlationId || null;
        const version = options?.version || payload?.version || 1;
        const eventKey = options?.eventKey || null;
        const aggregateId = options?.aggregateId || null;
        const event = await db.outboxEvent.create({
            data: {
                eventType,
                eventKey,
                aggregateId,
                version,
                correlationId,
                payload: payload || {},
                status: client_1.OutboxStatus.PENDING,
                attempts: 0,
            },
        });
        this.metrics.incrementOutboxEventsCreated();
        if (!tx) {
            await this.enqueueEvent(event.id);
        }
        return event;
    }
    async enqueueEvent(eventId) {
        try {
            await this.queueService.addJob(queue_constants_1.Queues.OUTBOX_DISPATCHER, eventId, { outboxEventId: eventId });
        }
        catch (err) {
            this.logger.error(`Failed to enqueue outbox dispatcher job for event ${eventId}: ${err.message}`);
        }
    }
};
exports.OutboxService = OutboxService;
exports.OutboxService = OutboxService = OutboxService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService])
], OutboxService);
//# sourceMappingURL=outbox.service.js.map