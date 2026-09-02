import firebaseAdmin from "../config/firebase.config.js";

const notificationService = {
    /**
     * Send a push notification to a list of tokens.
     * @param {string[]} tokens - Array of FCM tokens
     * @param {string} title - Notification title
     * @param {string} body - Notification body
     * @param {Object} data - Custom data payload (e.g., { type: 'TRADING_CALL', reportId: '...' })
     * @param {string} priority - 'high' | 'normal' (default 'high' for calls)
     * @param {string} channelId - Android channel ID (default 'high_importance_channel')
     */
    sendPushNotification: async (tokens, title, body, data = {}, priority = 'high', channelId = 'high_importance_channel') => {
        if (!tokens || tokens.length === 0) {
            return { success: false, message: "No tokens provided" };
        }

        // Logic to extract imageUrl if data is passed as a string or contains imageUrl property
        let imageUrl = null;
        let finalData = { eventVersion: "1" };

        if (typeof data === 'string') {
            imageUrl = data;
        } else if (data && typeof data === 'object') {
            // FCM 'data' must only contain string values
            for (const key in data) {
                if (data[key] !== null && data[key] !== undefined) {
                    finalData[key] = String(data[key]);
                }
            }
            if (data.imageUrl) {
                imageUrl = data.imageUrl;
            }
        }

        // Base Notification Payload - Modern FCM requires 'image' inside 'notification' for automatic display
        const notificationPayload = {
            title: title,
            body: body,
            ...(imageUrl && { image: imageUrl })
        };

        // Platform Specific Configs
        const androidConfig = {
            priority: priority, // 'high' or 'normal'
            notification: {
                channelId: channelId,
                sound: 'default',
                priority: priority === 'high' ? 'high' : 'default',
                defaultSound: true,
                defaultVibrateTimings: true,
                visibility: 'public', // Show on lock screen
                ...(imageUrl && { image: imageUrl }) // Android specific notification image
            },
            data: finalData // Android specific data placement
        };

        const apnsConfig = {
            payload: {
                aps: {
                    sound: 'default',
                    badge: 1,
                    contentAvailable: true, // For background updates
                    mutableContent: true,   // CRITICAL for iOS to download/show images via Service Extension
                    // Critical Alert Support (Requires Entitlement)
                    ...(priority === 'high' ? {
                        'interruption-level': 'time-sensitive', // or 'critical' if entitled
                        alert: {
                            title: title,
                            body: body,
                        }
                    } : {})
                }
            },
            fcm_options: {
                ...(imageUrl && { image: imageUrl }) // APNS image support
            }
        };

        const message = {
            notification: notificationPayload,
            data: finalData, // Common data
            tokens: tokens,
            android: androidConfig,
        };

        if (!firebaseAdmin || !firebaseAdmin.messaging) {
            console.warn("⚠️ Firebase Admin not initialized. Skipping push notification dispatch.");
            return { success: true, count: tokens.length, skipped: true };
        }

        try {
            if (tokens.length === 1) {
                // Single device
                try {
                    const singleMessage = {
                        ...message,
                        token: tokens[0]
                    };
                    delete singleMessage.tokens; // Remove array for single send

                    const response = await firebaseAdmin.messaging().send(singleMessage);
                    return {
                        success: true,
                        successCount: 1,
                        failureCount: 0,
                        details: [{ token: tokens[0], success: true, messageId: response }]
                    };
                } catch (error) {
                    console.error("Error sending single notification:", error);
                    return {
                        success: false,
                        successCount: 0,
                        failureCount: 1,
                        details: [{ token: tokens[0], success: false, error: error.message }],
                        error: error.message
                    };
                }
            } else {
                // Multicast (Batch)
                const response = await firebaseAdmin.messaging().sendEachForMulticast(message);

                const details = response.responses.map((resp, idx) => ({
                    token: tokens[idx],
                    success: resp.success,
                    error: resp.error ? resp.error.message : null,
                    errorCode: resp.error ? resp.error.code : null,
                    messageId: resp.messageId
                }));

                // Logic to identify expired tokens
                const expiredTokens = details.filter(d =>
                    d.errorCode === 'messaging/registration-token-not-registered' ||
                    d.errorCode === 'messaging/invalid-registration-token'
                ).map(d => d.token);

                if (expiredTokens.length > 0) {
                    console.log(`Found ${expiredTokens.length} expired/invalid tokens.`);
                }

                return {
                    success: true,
                    successCount: response.successCount,
                    failureCount: response.failureCount,
                    details: details,
                    expiredTokens: expiredTokens
                };
            }
        } catch (error) {
            console.error("Critical error in notification service:", error);
            return { success: false, error: error.message };
        }
    }
};

export default notificationService;
