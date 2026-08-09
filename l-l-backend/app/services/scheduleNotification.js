import { notificationQueue } from "../queues/notification.queue.js";

export async function scheduleNotification({
    userIds,
    title,
    body,
    imageUrl = null,
    sendAtUtc,
    data = {},
}) {
    const delay = new Date(sendAtUtc).getTime() - Date.now();

    if (delay < 0) {
        throw new Error("sendAtUtc must be in the future");
    }

    await notificationQueue.add(
        "send-notification",
        {
            userIds,
            title,
            body,
            imageUrl,
            data,
        },
        {
            delay,
            attempts: 3,
            backoff: {
                type: "exponential",
                delay: 5000,
            },
        }
    );
}
