import { Queue } from "bullmq";
import { redis } from "../redis/connection.js";

export const notificationQueue = new Queue("notifications", {
    connection: redis,
    defaultJobOptions: {
        removeOnComplete: true,
        removeOnFail: false,
    },
});
