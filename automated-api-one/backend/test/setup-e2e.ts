process.env.NODE_ENV = 'test';
process.env.PORT = '3000';
process.env.DATABASE_URL =
  'postgresql://postgres:postgrespassword@localhost:5432/trading_platform?schema=public';
process.env.JWT_SECRET = 'super_secret_jwt_key_that_is_at_least_eight_chars';
process.env.JWT_REFRESH_SECRET = 'super_secret_jwt_refresh_key_that_is_long';
process.env.MOCK_BROKERS = 'true';
process.env.REDIS_HOST = 'localhost';
process.env.REDIS_PORT = '6379';
process.env.AUTOMATED_API_KEY = 'default_secret_key';
process.env.LL_BACKEND_URL = 'http://localhost:8080';
process.env.EGRESS_MANAGER_URL = 'http://localhost:8080';
process.env.EGRESS_PROXY_HOST = 'localhost';
process.env.EGRESS_PROXY_PORT = '8888';
process.env.PROXY_CONTROL_SECRET = 's8_egress_super_secret_control_key_2026';

jest.mock('@nestjs/bullmq', () => {
  const { Inject } = require('@nestjs/common');
  const getQueueToken = (name: string) => `BullQueue_${name}`;
  return {
    BullModule: {
      forRoot: () => ({ module: class {}, providers: [] }),
      forRootAsync: () => ({ module: class {}, providers: [] }),
      registerQueue: (config: any) => ({
        module: class {},
        providers: [
          {
            provide: getQueueToken(config.name),
            useValue: { add: jest.fn().mockResolvedValue({}) },
          },
        ],
        exports: [getQueueToken(config.name)],
      }),
    },
    InjectQueue: (name: string) => Inject(getQueueToken(name)),
    Queue: class {},
    WorkerHost: class {
      process() {}
    },
    Processor: () => () => {},
    QueueEventsHost: class {},
    QueueEventsListener: () => () => {},
    OnQueueEvent: () => () => {},
  };
});
