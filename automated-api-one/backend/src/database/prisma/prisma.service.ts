import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { prismaExtension } from './extensions/prisma.extension';

@Injectable()
export class PrismaService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);
  private readonly _prisma: PrismaClient;
  public readonly client: any;

  constructor() {
    const { Pool } = require('pg');
    const { PrismaPg } = require('@prisma/adapter-pg');
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    const adapter = new PrismaPg(pool);
    this._prisma = new PrismaClient({ adapter });
    this.client = prismaExtension(this._prisma);
  }

  // Expose base prisma client for health checks
  get baseClient(): PrismaClient {
    return this._prisma;
  }

  // Delegate model properties dynamically to the extended client
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

  // Delegate transactions and raw queries
  get $transaction() {
    return (this.client.$transaction as any).bind(this.client);
  }
  get $executeRaw() {
    return this.client.$executeRaw.bind(this.client);
  }
  get $queryRaw() {
    return this.client.$queryRaw.bind(this.client);
  }

  async onModuleInit() {
    await this._prisma.$connect();
    this.logger.log(
      'Prisma database client connected and extended successfully.',
    );
  }

  async onModuleDestroy() {
    await this._prisma.$disconnect();
    this.logger.log('Prisma database client disconnected.');
  }

  async findActiveUsers() {
    return this.client.user.findActive();
  }

  async findTradesByUser(userId: string) {
    return this.client.trade.findMany({ where: { userId } });
  }
}
