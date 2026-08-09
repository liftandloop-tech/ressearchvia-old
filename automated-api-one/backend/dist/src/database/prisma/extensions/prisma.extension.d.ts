import { PrismaClient } from '@prisma/client';
export declare const prismaExtension: (prisma: PrismaClient) => import("@prisma/client/runtime/client").DynamicClientExtensionThis<import("@prisma/client").Prisma.TypeMap<import("@prisma/client/runtime/client").InternalArgs & {
    result: {};
    model: {
        $allModels: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        user: {
            findActive: () => () => Promise<{
                id: string;
                mobile: string;
                mpinHash: string;
                firstName: string | null;
                lastName: string | null;
                email: string | null;
                status: import("@prisma/client").$Enums.UserStatus;
                createdAt: Date;
                updatedAt: Date;
                deletedAt: Date | null;
                quietEnd: string | null;
                quietHoursEnabled: boolean;
                quietStart: string | null;
                quietTimezone: string | null;
            }[]>;
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        analyticsSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        auditLog: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        consent: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        dailyPortfolioSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        equityCurvePoint: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        notificationPreference: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        notification: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        paymentIntent: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reconciliationIssue: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reconciliationShard: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reconciliationSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reportExport: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        report: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskEvaluation: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskEvent: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskProfile: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskViolation: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        segmentMultiplier: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        segmentPerformance: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        subscription: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        trade: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userBroker: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userDevice: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userSegment: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        broker: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        segmentMaster: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        signal: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        order: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        position: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        adminUser: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        analyst: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        outboxEvent: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        brokerSession: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        idempotencyKey: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        queueJob: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        segmentExecution: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        operationsAudit: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reconciliationRun: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userPerformance: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        benchmarkSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        analyticsJobRun: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        notificationDelivery: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        sreAlert: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userKyc: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        kycDocument: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        researchReport: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        generalSetting: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        brokerAuthState: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
    };
    query: {};
    client: {};
}, {}>, import("@prisma/client").Prisma.TypeMapCb<import("@prisma/client").Prisma.PrismaClientOptions>, {
    result: {};
    model: {
        $allModels: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        user: {
            findActive: () => () => Promise<{
                id: string;
                mobile: string;
                mpinHash: string;
                firstName: string | null;
                lastName: string | null;
                email: string | null;
                status: import("@prisma/client").$Enums.UserStatus;
                createdAt: Date;
                updatedAt: Date;
                deletedAt: Date | null;
                quietEnd: string | null;
                quietHoursEnabled: boolean;
                quietStart: string | null;
                quietTimezone: string | null;
            }[]>;
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        analyticsSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        auditLog: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        consent: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        dailyPortfolioSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        equityCurvePoint: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        notificationPreference: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        notification: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        paymentIntent: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reconciliationIssue: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reconciliationShard: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reconciliationSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reportExport: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        report: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskEvaluation: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskEvent: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskProfile: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskViolation: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        segmentMultiplier: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        segmentPerformance: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        subscription: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        trade: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userBroker: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userDevice: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userSegment: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        broker: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        segmentMaster: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        signal: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        order: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        position: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        adminUser: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        analyst: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        outboxEvent: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        brokerSession: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        idempotencyKey: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        queueJob: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        segmentExecution: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        operationsAudit: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        reconciliationRun: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        riskSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userPerformance: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        benchmarkSnapshot: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        analyticsJobRun: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        notificationDelivery: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        sreAlert: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        userKyc: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        kycDocument: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        researchReport: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        generalSetting: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
        brokerAuthState: {
            paginate: () => <T, A>(this: T, args?: {
                page?: number;
                limit?: number;
                where?: any;
                orderBy?: any;
                include?: any;
            }) => Promise<{
                data: any;
                total: any;
                page: number;
                limit: number;
                totalPages: number;
            }>;
        };
    };
    query: {};
    client: {};
}>;
export type ExtendedPrismaClient = ReturnType<typeof prismaExtension>;
