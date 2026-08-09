import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { createTestApp } from './helpers/test-app';

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

describe('AppController (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const testEnv = await createTestApp();
    app = testEnv.app;
  });

  it('/ (GET)', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  afterEach(async () => {
    if (app) {
      await app.close();
    }
  });
});
