import { Params } from 'nestjs-pino';
import { randomUUID } from 'crypto';

export const loggerConfig: Params = {
  pinoHttp: {
    genReqId: (req) => {
      return req.headers['x-request-id'] || randomUUID();
    },
    messageKey: 'message',
    timestamp: () => `,"timestamp":"${new Date().toISOString()}"`,
    formatters: {
      level: (label) => {
        return { level: label };
      },
      // Remove default pid and hostname fields to keep logs clean
      bindings: () => ({}),
    },
    // Map request ID to requestId field in the log JSON object
    customProps: (req: any) => ({
      requestId: req.id,
      userId: req.user?.userId || req.user?.id || null,
    }),
    customSuccessObject: (req: any, res: any, val: any) => ({
      requestId: req.id,
      userId: req.user?.userId || req.user?.id || null,
      path: req.url?.split('?')[0],
      duration: val.responseTime,
    }),
    customErrorObject: (req: any, res: any, err: any, val: any) => ({
      requestId: req.id,
      userId: req.user?.userId || req.user?.id || null,
      path: req.url?.split('?')[0],
      duration: val.responseTime,
    }),
    transport:
      process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test'
        ? {
            target: 'pino-pretty',
            options: {
              colorize: true,
              singleLine: true,
              translateTime: 'UTC:yyyy-mm-dd HH:MM:ss.l',
              messageKey: 'message',
            },
          }
        : undefined,
  },
};
