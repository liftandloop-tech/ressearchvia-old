import "dotenv/config";
import { Worker } from "bullmq";
import admin from "../config/firebase.config.js";
import { redis } from "../redis/connection.js";
import { getUserTokens } from "../repositories/user.repository.js";
import MONGO_CLIENT from "../config/db.config.js";

// Connect to MongoDB
MONGO_CLIENT();

new Worker(
    "notifications",
    async job => {
        const { userIds, title, body, imageUrl, data } = job.data;

        const tokens = await getUserTokens(userIds);
        if (!tokens.length) return;

        const messageBase = {
            notification: {
                title,
                body,
            },
            data,
        };

        // Add image ONLY if present
        if (imageUrl) {
            messageBase.notification.image = imageUrl;

            messageBase.android = {
                notification: {
                    imageUrl,
                    channelId: "trade_calls",
                },
            };

            messageBase.apns = {
                payload: {
                    aps: { "mutable-content": 1 },
                },
                fcm_options: {
                    image: imageUrl,
                },
            };
        }

        // Send in batches (safe for 10k users)
        const batchSize = 500;

        for (let i = 0; i < tokens.length; i += batchSize) {
            const batch = tokens.slice(i, i + batchSize);

            // Ensure data values are strings (FCM requirement)
            if (messageBase.data) {
                Object.keys(messageBase.data).forEach(key => {
                    messageBase.data[key] = String(messageBase.data[key]);
                });
            }

            await admin.messaging().sendEachForMulticast({
                ...messageBase,
                tokens: batch,
            });
        }
    },
    {
        connection: redis,
        concurrency: 5,
    }
);
