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
var PrismaService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PrismaService = void 0;
const common_1 = require("@nestjs/common");
const client_1 = require("@prisma/client");
const prisma_extension_1 = require("./extensions/prisma.extension");
let PrismaService = PrismaService_1 = class PrismaService {
    logger = new common_1.Logger(PrismaService_1.name);
    _prisma;
    client;
    constructor() {
        const { Pool } = require('pg');
        const { PrismaPg } = require('@prisma/adapter-pg');
        const pool = new Pool({ connectionString: process.env.DATABASE_URL });
        const adapter = new PrismaPg(pool);
        this._prisma = new client_1.PrismaClient({ adapter });
        this.client = (0, prisma_extension_1.prismaExtension)(this._prisma);
    }
    get baseClient() {
        return this._prisma;
    }
    get user() {
        return this.client.user;
    }
    get segmentMaster() {
        return this.client.segmentMaster;
    }
    get userSegment() {
        return this.client.userSegment;
    }
    get userBroker() {
        return this.client.userBroker;
    }
    get userDevice() {
        return this.client.userDevice;
    }
    get broker() {
        return this.client.broker;
    }
    get subscription() {
        return this.client.subscription;
    }
    get consent() {
        return this.client.consent;
    }
    get signal() {
        return this.client.signal;
    }
    get trade() {
        return this.client.trade;
    }
    get order() {
        return this.client.order;
    }
    get position() {
        return this.client.position;
    }
    get segmentMultiplier() {
        return this.client.segmentMultiplier;
    }
    get riskEvent() {
        return this.client.riskEvent;
    }
    get notification() {
        return this.client.notification;
    }
    get auditLog() {
        return this.client.auditLog;
    }
    get adminUser() {
        return this.client.adminUser;
    }
    get analyst() {
        return this.client.analyst;
    }
    get report() {
        return this.client.report;
    }
    get outboxEvent() {
        return this.client.outboxEvent;
    }
    get brokerSession() {
        return this.client.brokerSession;
    }
    get brokerAuthState() {
        return this.client.brokerAuthState;
    }
    get idempotencyKey() {
        return this.client.idempotencyKey;
    }
    get queueJob() {
        return this.client.queueJob;
    }
    get segmentExecution() {
        return this.client.segmentExecution;
    }
    get operationsAudit() {
        return this.client.operationsAudit;
    }
    get reportExport() {
        return this.client.reportExport;
    }
    get analyticsSnapshot() {
        return this.client.analyticsSnapshot;
    }
    get reconciliationRun() {
        return this.client.reconciliationRun;
    }
    get reconciliationShard() {
        return this.client.reconciliationShard;
    }
    get reconciliationIssue() {
        return this.client.reconciliationIssue;
    }
    get reconciliationSnapshot() {
        return this.client.reconciliationSnapshot;
    }
    get riskProfile() {
        return this.client.riskProfile;
    }
    get riskViolation() {
        return this.client.riskViolation;
    }
    get riskSnapshot() {
        return this.client.riskSnapshot;
    }
    get riskEvaluation() {
        return this.client.riskEvaluation;
    }
    get dailyPortfolioSnapshot() {
        return this.client.dailyPortfolioSnapshot;
    }
    get equityCurvePoint() {
        return this.client.equityCurvePoint;
    }
    get segmentPerformance() {
        return this.client.segmentPerformance;
    }
    get userPerformance() {
        return this.client.userPerformance;
    }
    get benchmarkSnapshot() {
        return this.client.benchmarkSnapshot;
    }
    get analyticsJobRun() {
        return this.client.analyticsJobRun;
    }
    get notificationPreference() {
        return this.client.notificationPreference;
    }
    get notificationDelivery() {
        return this.client.notificationDelivery;
    }
    get sreAlert() {
        return this.client.sreAlert;
    }
    get $transaction() {
        return this.client.$transaction.bind(this.client);
    }
    get $executeRaw() {
        return this.client.$executeRaw.bind(this.client);
    }
    get $queryRaw() {
        return this.client.$queryRaw.bind(this.client);
    }
    async onModuleInit() {
        await this._prisma.$connect();
        this.logger.log('Prisma database client connected and extended successfully.');
    }
    async onModuleDestroy() {
        await this._prisma.$disconnect();
        this.logger.log('Prisma database client disconnected.');
    }
    async findActiveUsers() {
        return this.client.user.findActive();
    }
    async findTradesByUser(userId) {
        return this.client.trade.findMany({ where: { userId } });
    }
};
exports.PrismaService = PrismaService;
exports.PrismaService = PrismaService = PrismaService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], PrismaService);
//# sourceMappingURL=prisma.service.js.map