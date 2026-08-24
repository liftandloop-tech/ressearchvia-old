import { BrokerFactory } from './factory/broker.factory';
import { BrokerSessionService } from './services/broker-session.service';
import { PrismaService } from '../prisma.service';
import { RedisService } from '../infrastructure/redis/redis.service';
import { BrokerCode } from '@prisma/client';
export declare class LinkBrokerDto {
    brokerCode: BrokerCode;
    brokerClientId: string;
    apiKey?: string;
    apiSecret?: string;
    vendorCode?: string;
}
export declare class AuthorizeBrokerDto {
    brokerCode: BrokerCode;
    mpin: string;
    totpKey: string;
}
export declare class BrokersController {
    private readonly prisma;
    private readonly brokerFactory;
    private readonly brokerSessionService;
    private readonly redisService;
    constructor(prisma: PrismaService, brokerFactory: BrokerFactory, brokerSessionService: BrokerSessionService, redisService: RedisService);
    linkBroker(req: any, dto: LinkBrokerDto): Promise<any>;
    authorizeBroker(req: any, dto: AuthorizeBrokerDto): Promise<{
        success: boolean;
        message: string;
        expiry: Date;
    }>;
    getBrokerStatus(req: any): Promise<any[]>;
    listBrokers(req: any): Promise<any[]>;
    getAuthUrl(req: any, brokerCodeStr: string): Promise<{
        authUrl: string;
    }>;
    handleCallback(brokerCodeStr: string, queryParams: Record<string, string | undefined>, res: any): Promise<any>;
    showSuccessPage(brokerCode: string, res: any): Promise<any>;
    showFailurePage(brokerCode: string, errorMsg: string, res: any): Promise<any>;
    unlinkBroker(req: any, brokerCodeStr: string): Promise<{
        success: boolean;
        message: string;
    }>;
    private getActiveBroker;
    getLivePositions(req: any): Promise<any>;
    getLiveHoldings(req: any): Promise<any>;
    getLiveOrders(req: any): Promise<any>;
    getLiveTrades(req: any): Promise<any>;
}
