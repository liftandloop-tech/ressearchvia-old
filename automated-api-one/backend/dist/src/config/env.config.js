"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.envSchema = void 0;
exports.validateEnv = validateEnv;
const zod_1 = require("zod");
exports.envSchema = zod_1.z.object({
    NODE_ENV: zod_1.z
        .enum(['development', 'production', 'test'])
        .default('development'),
    PORT: zod_1.z.coerce.number().default(3000),
    DATABASE_URL: zod_1.z.string().url(),
    REDIS_HOST: zod_1.z.string().default('localhost'),
    REDIS_PORT: zod_1.z.coerce.number().default(6379),
    REDIS_USERNAME: zod_1.z.string().optional(),
    REDIS_PASSWORD: zod_1.z.string().optional(),
    JWT_SECRET: zod_1.z
        .string()
        .min(8, 'JWT_SECRET must be at least 8 characters long'),
    JWT_REFRESH_SECRET: zod_1.z
        .string()
        .min(8, 'JWT_REFRESH_SECRET must be at least 8 characters long'),
    MOCK_BROKERS: zod_1.z
        .preprocess((val) => {
        if (val === 'false' || val === '0')
            return false;
        if (val === 'true' || val === '1')
            return true;
        return val;
    }, zod_1.z.coerce.boolean())
        .default(true),
    ANGEL_ONE_API_KEY: zod_1.z.string().optional(),
    ANGEL_ONE_REDIRECT_URL: zod_1.z.string().optional(),
    MSG91_API_KEY: zod_1.z.string().optional(),
    FCM_PROJECT_ID: zod_1.z.string().optional(),
    FCM_PRIVATE_KEY: zod_1.z.string().optional(),
    RESEND_API_KEY: zod_1.z.string().optional(),
    OUTBOX_BATCH_SIZE: zod_1.z.coerce.number().default(50),
    ORDER_PLACEMENT_CONCURRENCY: zod_1.z.coerce.number().default(20),
    ORDER_MONITORING_CONCURRENCY: zod_1.z.coerce.number().default(50),
    BROKER_TIMEOUT_MS: zod_1.z.coerce.number().default(5000),
    BROKER_RATE_LIMIT_PER_MINUTE: zod_1.z.coerce.number().default(100),
    SIGNAL_PROCESSING_LIMIT: zod_1.z.coerce.number().default(50),
    CIRCUIT_BREAKER_FAILURE_THRESHOLD: zod_1.z.coerce.number().default(3),
    CIRCUIT_BREAKER_RESET_TIMEOUT_MS: zod_1.z.coerce.number().default(60000),
    AUTOMATED_API_KEY: zod_1.z.string().default('default_secret_key'),
    LL_BACKEND_URL: zod_1.z.string().url().default('http://localhost:8080'),
    RISK_DEFAULT_MODE: zod_1.z.enum(['BLOCK', 'ALLOW']).default('ALLOW'),
});
function validateEnv(config) {
    const result = exports.envSchema.safeParse(config);
    if (!result.success) {
        console.error('❌ Invalid environment variables validation schema:');
        console.error(JSON.stringify(result.error.format(), null, 2));
        throw new Error('Invalid environment configuration');
    }
    return result.data;
}
//# sourceMappingURL=env.config.js.map