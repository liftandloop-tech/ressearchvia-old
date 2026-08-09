import IORedis from "ioredis";
import dotenv from "dotenv";

dotenv.config();

export const redis = process.env.REDIS_URL
  ? new IORedis(process.env.REDIS_URL, { maxRetriesPerRequest: null })
  : new IORedis({
    host: process.env.REDIS_HOST,
    port: Number(process.env.REDIS_PORT),
    password: process.env.REDIS_PASSWORD,
    username: process.env.REDIS_USERNAME,
    maxRetriesPerRequest: null,
  });
