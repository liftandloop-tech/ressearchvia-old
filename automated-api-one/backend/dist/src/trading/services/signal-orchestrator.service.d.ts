import { PrismaService } from '../../prisma.service';
import { QueueService } from '../../infrastructure/queues/queues.service';
import { IdempotencyService } from '../../infrastructure/idempotency/idempotency.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
import { MultiplierService } from './multiplier.service';
import { AuditService } from '../../audit/audit.service';
import { SignalState } from '@prisma/client';
export declare class SignalOrchestratorService {
    private readonly prisma;
    private readonly queueService;
    private readonly idempotencyService;
    private readonly redisService;
    private readonly multiplierService;
    private readonly auditService;
    private readonly logger;
    constructor(prisma: PrismaService, queueService: QueueService, idempotencyService: IdempotencyService, redisService: RedisService, multiplierService: MultiplierService, auditService: AuditService);
    private validateTransition;
    private updateExecutionState;
    processSignal(signalId: string): Promise<{
        state: SignalState;
        totalUsers: number;
        successUsers: number;
        rejectedUsers: number;
        correlationId: string;
    }>;
    private sendAppliedStatusUpdate;
    private paginatedFanOut;
    private fetchSubscriberBatch;
    private enqueueForUser;
    private resolvePlan;
}
