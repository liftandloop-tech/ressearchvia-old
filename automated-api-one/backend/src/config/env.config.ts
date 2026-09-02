import { z } from 'zod';

export const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'production', 'test'])
    .default('development'),
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  REDIS_HOST: z.string().default('localhost'),
  REDIS_PORT: z.coerce.number().default(6379),
  REDIS_USERNAME: z.string().optional(),
  REDIS_PASSWORD: z.string().optional(),
  JWT_SECRET: z
    .string()
    .min(8, 'JWT_SECRET must be at least 8 characters long'),
  JWT_REFRESH_SECRET: z
    .string()
    .min(8, 'JWT_REFRESH_SECRET must be at least 8 characters long'),
  MOCK_BROKERS: z
    .preprocess((val) => {
      if (val === 'false' || val === '0') return false;
      if (val === 'true' || val === '1') return true;
      return val;
    }, z.coerce.boolean())
    .default(true),
  ANGEL_ONE_API_KEY: z.string().optional(),
  ANGEL_ONE_REDIRECT_URL: z.string().optional(),
  MSG91_API_KEY: z.string().optional(),
  FCM_PROJECT_ID: z.string().optional(),
  FCM_PRIVATE_KEY: z.string().optional(),
  RESEND_API_KEY: z.string().optional(),
  OUTBOX_BATCH_SIZE: z.coerce.number().default(50),
  ORDER_PLACEMENT_CONCURRENCY: z.coerce.number().default(20),
  ORDER_MONITORING_CONCURRENCY: z.coerce.number().default(50),
  BROKER_TIMEOUT_MS: z.coerce.number().default(5000),
  BROKER_RATE_LIMIT_PER_MINUTE: z.coerce.number().default(100),
  SIGNAL_PROCESSING_LIMIT: z.coerce.number().default(50),
  CIRCUIT_BREAKER_FAILURE_THRESHOLD: z.coerce.number().default(3),
  CIRCUIT_BREAKER_RESET_TIMEOUT_MS: z.coerce.number().default(60000),
  AUTOMATED_API_KEY: z.string().default('default_secret_key'),
  LL_BACKEND_URL: z.string().url().default('http://localhost:8080'),
  RISK_DEFAULT_MODE: z.enum(['BLOCK', 'ALLOW']).default('ALLOW'),
  EGRESS_MANAGER_URL: z.string().default('http://localhost:8080'),
  EGRESS_PROXY_HOST: z.string().default('localhost'),
  EGRESS_PROXY_PORT: z.coerce.number().default(8888),
  PROXY_CONTROL_SECRET: z.string().default('s8_egress_super_secret_control_key_2026'),
});

export type EnvConfig = z.infer<typeof envSchema>;

export function validateEnv(config: Record<string, unknown>): EnvConfig {
  const result = envSchema.safeParse(config);

  if (!result.success) {
    console.error('❌ Invalid environment variables validation schema:');
    console.error(JSON.stringify(result.error.format(), null, 2));
    throw new Error('Invalid environment configuration');
  }

  return result.data;
}
