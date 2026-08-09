import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { RedisService, PlatformMode, RedisDegradedException } from './redis.service';
import Redis from 'ioredis';

jest.mock('ioredis', () => {
  return jest.fn().mockImplementation(() => {
    const events: Record<string, Function[]> = {};
    return {
      on: jest.fn().mockImplementation((event, callback) => {
        if (!events[event]) events[event] = [];
        events[event].push(callback);
      }),
      emitEvent: (event: string, ...args: any[]) => {
        if (events[event]) {
          events[event].forEach((cb) => cb(...args));
        }
      },
      quit: jest.fn().mockResolvedValue('OK'),
      ping: jest.fn().mockResolvedValue('PONG'),
    };
  });
});

describe('RedisService', () => {
  let service: RedisService;
  let configService: ConfigService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RedisService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key, defaultValue) => defaultValue),
          },
        },
      ],
    }).compile();

    service = module.get<RedisService>(RedisService);
    configService = module.get<ConfigService>(ConfigService);
    service.onModuleInit();
  });

  afterEach(async () => {
    await service.onModuleDestroy();
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should initialize client on init', () => {
    expect(Redis).toHaveBeenCalled();
    expect(service.getClient()).toBeDefined();
  });

  it('should track health status on events', () => {
    const client: any = service.getClient();
    
    // Initially false (until ready is emitted)
    expect(service.isHealthy()).toBe(false);
    expect(service.getPlatformMode()).toBe(PlatformMode.NORMAL);

    // Trigger ready event
    client.emitEvent('ready');
    expect(service.isHealthy()).toBe(true);
    expect(service.getPlatformMode()).toBe(PlatformMode.NORMAL);

    // Trigger close event
    client.emitEvent('close');
    expect(service.isHealthy()).toBe(false);
    expect(service.getPlatformMode()).toBe(PlatformMode.REDIS_DEGRADED);

    // Trigger ready again
    client.emitEvent('ready');
    expect(service.isHealthy()).toBe(true);
    expect(service.getPlatformMode()).toBe(PlatformMode.NORMAL);

    // Trigger error event
    client.emitEvent('error', new Error('Connection refused'));
    expect(service.isHealthy()).toBe(false);
    expect(service.getPlatformMode()).toBe(PlatformMode.REDIS_DEGRADED);
  });

  it('should throw RedisDegradedException when unhealthy', () => {
    const client: any = service.getClient();
    expect(() => service.assertHealthy()).toThrow(RedisDegradedException);

    client.emitEvent('ready');
    expect(() => service.assertHealthy()).not.toThrow();

    client.emitEvent('close');
    expect(() => service.assertHealthy()).toThrow(RedisDegradedException);
  });
});
