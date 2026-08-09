"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loggerConfig = void 0;
const crypto_1 = require("crypto");
exports.loggerConfig = {
    pinoHttp: {
        genReqId: (req) => {
            return req.headers['x-request-id'] || (0, crypto_1.randomUUID)();
        },
        messageKey: 'message',
        timestamp: () => `,"timestamp":"${new Date().toISOString()}"`,
        formatters: {
            level: (label) => {
                return { level: label };
            },
            bindings: () => ({}),
        },
        customProps: (req) => ({
            requestId: req.id,
            userId: req.user?.userId || req.user?.id || null,
        }),
        customSuccessObject: (req, res, val) => ({
            requestId: req.id,
            userId: req.user?.userId || req.user?.id || null,
            path: req.url?.split('?')[0],
            duration: val.responseTime,
        }),
        customErrorObject: (req, res, err, val) => ({
            requestId: req.id,
            userId: req.user?.userId || req.user?.id || null,
            path: req.url?.split('?')[0],
            duration: val.responseTime,
        }),
        transport: process.env.NODE_ENV !== 'production' && process.env.NODE_ENV !== 'test'
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
//# sourceMappingURL=logger.config.js.map