import { PrismaService } from '../../prisma.service';
export declare class CsvCleanupProcessor {
    private readonly prisma;
    private readonly storageProvider;
    private readonly logger;
    constructor(prisma: PrismaService, storageProvider: any);
    cleanupExpiredExports(): Promise<void>;
}
