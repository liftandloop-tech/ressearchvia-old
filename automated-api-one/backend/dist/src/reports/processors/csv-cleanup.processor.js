"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var CsvCleanupProcessor_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.CsvCleanupProcessor = void 0;
const common_1 = require("@nestjs/common");
const schedule_1 = require("@nestjs/schedule");
const prisma_service_1 = require("../../prisma.service");
const report_storage_provider_1 = require("../providers/report-storage.provider");
const client_1 = require("@prisma/client");
const fs = __importStar(require("fs/promises"));
const path = __importStar(require("path"));
let CsvCleanupProcessor = CsvCleanupProcessor_1 = class CsvCleanupProcessor {
    prisma;
    storageProvider;
    logger = new common_1.Logger(CsvCleanupProcessor_1.name);
    constructor(prisma, storageProvider) {
        this.prisma = prisma;
        this.storageProvider = storageProvider;
    }
    async cleanupExpiredExports() {
        if (process.env.CONTAINER_ROLE && process.env.CONTAINER_ROLE !== 'cron') {
            return;
        }
        this.logger.log('Starting daily CSV export cleanup task...');
        const cutoffDate = new Date();
        cutoffDate.setDate(cutoffDate.getDate() - 7);
        try {
            const expiredExports = await this.prisma.reportExport.findMany({
                where: {
                    createdAt: {
                        lt: cutoffDate,
                    },
                    status: {
                        not: client_1.ExportState.EXPIRED,
                    },
                },
            });
            this.logger.log(`Found ${expiredExports.length} exports older than 7 days for cleanup.`);
            for (const exp of expiredExports) {
                if (exp.fileUrl && exp.fileUrl.startsWith('/uploads/reports/')) {
                    const fileName = exp.fileUrl.replace('/uploads/reports/', '');
                    const filePath = path.join(process.cwd(), 'uploads', 'reports', fileName);
                    try {
                        await fs.unlink(filePath);
                        this.logger.log(`Deleted file: ${filePath}`);
                    }
                    catch (err) {
                        this.logger.warn(`Failed to delete local file ${filePath}: ${err.message}`);
                    }
                }
                await this.prisma.reportExport.update({
                    where: { id: exp.id },
                    data: { status: client_1.ExportState.EXPIRED },
                });
            }
            this.logger.log('Finished CSV export cleanup task.');
        }
        catch (err) {
            this.logger.error(`CSV cleanup task failed: ${err.message}`);
        }
    }
};
exports.CsvCleanupProcessor = CsvCleanupProcessor;
__decorate([
    (0, schedule_1.Cron)('0 2 * * *'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], CsvCleanupProcessor.prototype, "cleanupExpiredExports", null);
exports.CsvCleanupProcessor = CsvCleanupProcessor = CsvCleanupProcessor_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(1, (0, common_1.Inject)(report_storage_provider_1.REPORT_STORAGE_PROVIDER)),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService, Object])
], CsvCleanupProcessor);
//# sourceMappingURL=csv-cleanup.processor.js.map