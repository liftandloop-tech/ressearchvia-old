import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaService } from './prisma.service';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { BrokersModule } from './brokers/brokers.module';
import { ConsentsModule } from './consents/consents.module';
import { SegmentsModule } from './segments/segments.module';
import { BullModule } from '@nestjs/bullmq';
import { SignalsModule } from './signals/signals.module';
import { TradesModule } from './trades/trades.module';
import { PositionsModule } from './positions/positions.module';
import { NotificationsModule } from './notifications/notifications.module';
import { RiskModule } from './risk/risk.module';
import { HealthModule } from './health/health.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { TradingModule } from './trading/trading.module';
import { AuditModule } from './audit/audit.module';
import { WebsocketModule } from './websocket/websocket.module';
import { ReportsModule } from './reports/reports.module';
import { AdminModule } from './admin/admin.module';
import { ReconciliationModule } from './reconciliation/reconciliation.module';
import { AnalyticsModule } from './analytics/analytics.module';
import { AuditInterceptor } from './audit/interceptors/audit.interceptor';
import { APP_INTERCEPTOR } from '@nestjs/core';

import { LoggerModule } from 'nestjs-pino';
import { validateEnv } from './config/env.config';
import { loggerConfig } from './config/logger.config';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from './database/prisma/prisma.module';
import { InfrastructureModule } from './infrastructure/infrastructure.module';
import { InstrumentsModule } from './instruments/instruments.module';
import { ProxyManagerModule } from './proxy-manager/proxy-manager.module';
import { EgressModule } from './egress/egress.module';

@Module({
  imports: [
    ScheduleModule.forRoot(),
    ConfigModule.forRoot({
      isGlobal: true,
      validate: validateEnv,
    }),
    LoggerModule.forRoot(loggerConfig),
    BullModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
        useFactory: (config: ConfigService) => {
          const connectionOptions: any = {
            host: config.get<string>('REDIS_HOST', 'localhost'),
            port: config.get<number>('REDIS_PORT', 6379),
            password: config.get<string>('REDIS_PASSWORD'),
          };
          const username = config.get<string>('REDIS_USERNAME');
          if (username && username !== 'default' && username !== 'sp-redis') {
            connectionOptions.username = username;
          }
          return { connection: connectionOptions };
        },
    }),
    PrismaModule,
    InfrastructureModule,
    AuthModule,
    UsersModule,
    BrokersModule,
    ConsentsModule,
    SegmentsModule,
    SignalsModule,
    TradesModule,
    PositionsModule,
    NotificationsModule,
    RiskModule,
    HealthModule,
    SubscriptionsModule,
    TradingModule,
    AuditModule,
    WebsocketModule,
    ReportsModule,
    AdminModule,
    ReconciliationModule,
    AnalyticsModule,
    InstrumentsModule,
    ProxyManagerModule,
    EgressModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    {
      provide: APP_INTERCEPTOR,
      useClass: AuditInterceptor,
    },
  ],
})
export class AppModule {}
