import { Module, Global } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TradingGateway } from './gateway/trading.gateway';
import { WebsocketService } from './services/websocket.service';
import { WebsocketProcessor } from './processors/websocket.processor';
import { RedisModule } from '../infrastructure/redis/redis.module';
import { QueuesModule } from '../infrastructure/queues/queues.module';
import { PrismaService } from '../prisma.service';

@Global()
@Module({
  imports: [
    RedisModule,
    QueuesModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>(
          'JWT_SECRET',
          'super_secret_trading_platform_key',
        ),
      }),
    }),
  ],
  providers: [
    TradingGateway,
    WebsocketService,
    WebsocketProcessor,
    PrismaService,
  ],
  exports: [WebsocketService, TradingGateway],
})
export class WebsocketModule {}
