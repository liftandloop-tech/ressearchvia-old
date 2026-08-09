import { PrismaService } from '../../prisma.service';
import { BrokerFactory } from '../factory/broker.factory';
import { BrokerCode } from '@prisma/client';
import { SessionResponse } from '../interfaces/broker-client.interface';
import { AuditService } from '../../audit/audit.service';
import { RedisService } from '../../infrastructure/redis/redis.service';
export declare class BrokerSessionService {
    private readonly prisma;
    private readonly brokerFactory;
    private readonly auditService;
    private readonly redisService;
    private readonly logger;
    constructor(prisma: PrismaService, brokerFactory: BrokerFactory, auditService: AuditService, redisService: RedisService);
    storeSession(userId: string, brokerCode: BrokerCode, session: SessionResponse, userBrokerId: string): Promise<void>;
    refreshSession(userId: string, brokerCode: BrokerCode): Promise<SessionResponse>;
    invalidateSession(userId: string, brokerCode: BrokerCode): Promise<void>;
    isSessionExpired(tokenExpiry: Date | null): boolean;
    validateSession(userId: string, brokerCode: BrokerCode): Promise<boolean>;
    cleanupExpiredAuthStates(): Promise<void>;
}
