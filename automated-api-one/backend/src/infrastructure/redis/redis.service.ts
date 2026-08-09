import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

export enum PlatformMode {
  NORMAL = 'NORMAL',
  REDIS_DEGRADED = 'REDIS_DEGRADED',
}

export class RedisDegradedException extends Error {
  constructor(message = 'Redis is currently down. Write/Trading operations are suspended.') {
    super(message);
    this.name = 'RedisDegradedException';
  }
}

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis;
  private isConnected = false;
  private mode: PlatformMode = PlatformMode.NORMAL;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit(): Promise<void> {
    const host = this.configService.get<string>('REDIS_HOST', 'localhost');
    const port = this.configService.get<number>('REDIS_PORT', 6379);
    const username = this.configService.get<string>('REDIS_USERNAME');
    const password = this.configService.get<string>('REDIS_PASSWORD');

    this.logger.log(`Initializing Redis client on ${host}:${port}`);

    const redisOptions: any = {
      host,
      port,
      password,
      maxRetriesPerRequest: null, // Required by BullMQ
      enableReadyCheck: true,
      reconnectOnError: () => true,
    };

    if (username) {
      redisOptions.username = username;
    }

    this.client = new Redis(redisOptions);

    this.client.on('connect', () => {
      this.logger.log('Redis client connecting...');
    });

    this.client.on('ready', () => {
      this.isConnected = true;
      this.mode = PlatformMode.NORMAL;
      this.logger.log('Redis client ready. Platform mode: NORMAL');
    });

    this.client.on('error', (err) => {
      this.logger.error(`Redis connection error: ${err.message}`);
      if (this.isConnected) {
        this.isConnected = false;
        this.mode = PlatformMode.REDIS_DEGRADED;
        this.logger.error('Redis connection lost. Platform mode: REDIS_DEGRADED');
      }
    });

    this.client.on('close', () => {
      this.isConnected = false;
      this.mode = PlatformMode.REDIS_DEGRADED;
      this.logger.warn('Redis connection closed. Platform mode: REDIS_DEGRADED');
    });

    this.client.on('end', () => {
      this.isConnected = false;
      this.mode = PlatformMode.REDIS_DEGRADED;
      this.logger.warn('Redis connection ended. Platform mode: REDIS_DEGRADED');
    });

    return new Promise<void>((resolve) => {
      const timeout = setTimeout(() => {
        this.logger.warn('Redis connection startup timeout reached (2s). Bootstrapping anyway.');
        resolve();
      }, 2000);

      this.client.once('ready', () => {
        clearTimeout(timeout);
        resolve();
      });

      this.client.once('error', () => {
        clearTimeout(timeout);
        resolve();
      });
    });
  }

  async onModuleDestroy() {
    this.logger.log('Disconnecting from Redis...');
    if (this.client) {
      await this.client.quit().catch(() => {});
    }
  }

  getClient(): Redis {
    return this.client;
  }

  isHealthy(): boolean {
    return this.isConnected;
  }

  getPlatformMode(): PlatformMode {
    return this.mode;
  }

  assertHealthy(): void {
    if (!this.isHealthy() || this.mode === PlatformMode.REDIS_DEGRADED) {
      throw new RedisDegradedException();
    }
  }
}
