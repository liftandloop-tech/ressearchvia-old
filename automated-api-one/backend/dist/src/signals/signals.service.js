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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SignalsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma.service");
const client_1 = require("@prisma/client");
const queues_service_1 = require("../infrastructure/queues/queues.service");
const queue_constants_1 = require("../infrastructure/queues/queue.constants");
const metrics_service_1 = require("../infrastructure/metrics/metrics.service");
const redis_service_1 = require("../infrastructure/redis/redis.service");
const axios_1 = __importDefault(require("axios"));
let SignalsService = class SignalsService {
    prisma;
    queueService;
    metrics;
    redisService;
    constructor(prisma, queueService, metrics, redisService) {
        this.prisma = prisma;
        this.queueService = queueService;
        this.metrics = metrics;
        this.redisService = redisService;
    }
    async publishAndEnqueue(dto) {
        if (this.redisService.isHealthy()) {
            const isGlobalMaint = await this.redisService.getClient().get('system:maintenance:global');
            const isSignalsMaint = await this.redisService.getClient().get('system:maintenance:signals');
            if (isGlobalMaint === 'true' || isSignalsMaint === 'true') {
                throw new common_1.ServiceUnavailableException('Signals publishing is currently disabled due to system maintenance');
            }
        }
        const segment = await this.prisma.segmentMaster.findUnique({
            where: { id: dto.segmentId },
        });
        if (!segment) {
            throw new common_1.NotFoundException('Segment not found');
        }
        const signal = await this.prisma.signal.create({
            data: {
                segmentId: dto.segmentId,
                symbol: dto.symbol,
                exchange: dto.exchange,
                segment: dto.segment,
                side: dto.side,
                orderType: dto.orderType,
                entryPrice: dto.entryPrice,
                stopLoss: dto.stopLoss,
                targetPrice: dto.targetPrice,
                status: client_1.SignalStatus.PUBLISHED,
                publishedAt: new Date(),
            },
        });
        await this.queueService.addJob(queue_constants_1.Queues.SIGNAL_PROCESSING, `signal-${signal.id}`, { signalId: signal.id });
        this.metrics.incrementSignalsReceived();
        await this.forwardSignalToLlBackend(signal);
        return {
            success: true,
            signalId: signal.id,
        };
    }
    async forwardSignalToLlBackend(signal) {
        const baseUrl = process.env.LL_BACKEND_URL || 'http://localhost:8080';
        const apiKey = process.env.AUTOMATED_API_KEY || 'default_secret_key';
        try {
            await axios_1.default.post(`${baseUrl}/api/reports/automated-trading-call`, {
                symbol: signal.symbol,
                exchange: signal.exchange,
                side: signal.side,
                entryPrice: Number(signal.entryPrice),
                stopLoss: Number(signal.stopLoss),
                targetPrice: Number(signal.targetPrice),
                segment: signal.segment,
                rawSignalId: signal.id,
            }, {
                headers: {
                    'x-api-key': apiKey,
                },
                timeout: 5000,
            });
            console.log(`[Integration] Successfully forwarded signal ${signal.id} to l-l-backend`);
        }
        catch (error) {
            console.error(`[Integration] Failed to forward signal ${signal.id} to l-l-backend: ${error.message}`);
        }
    }
};
exports.SignalsService = SignalsService;
exports.SignalsService = SignalsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        queues_service_1.QueueService,
        metrics_service_1.MetricsService,
        redis_service_1.RedisService])
], SignalsService);
//# sourceMappingURL=signals.service.js.map