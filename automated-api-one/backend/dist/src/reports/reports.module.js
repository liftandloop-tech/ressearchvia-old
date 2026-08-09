"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReportsModule = void 0;
const common_1 = require("@nestjs/common");
const reports_service_1 = require("./reports.service");
const report_storage_provider_1 = require("./providers/report-storage.provider");
const report_generation_processor_1 = require("./processors/report-generation.processor");
const analytics_snapshot_processor_1 = require("./processors/analytics-snapshot.processor");
const csv_cleanup_processor_1 = require("./processors/csv-cleanup.processor");
const prisma_module_1 = require("../database/prisma/prisma.module");
const infrastructure_module_1 = require("../infrastructure/infrastructure.module");
let ReportsModule = class ReportsModule {
};
exports.ReportsModule = ReportsModule;
exports.ReportsModule = ReportsModule = __decorate([
    (0, common_1.Module)({
        imports: [prisma_module_1.PrismaModule, infrastructure_module_1.InfrastructureModule],
        providers: [
            reports_service_1.ReportsService,
            {
                provide: report_storage_provider_1.REPORT_STORAGE_PROVIDER,
                useClass: report_storage_provider_1.LocalStorageProvider,
            },
            report_generation_processor_1.ReportGenerationProcessor,
            report_generation_processor_1.ReportExportProcessor,
            analytics_snapshot_processor_1.AnalyticsSnapshotProcessor,
            csv_cleanup_processor_1.CsvCleanupProcessor,
        ],
        exports: [reports_service_1.ReportsService],
    })
], ReportsModule);
//# sourceMappingURL=reports.module.js.map