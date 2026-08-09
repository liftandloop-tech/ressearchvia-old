import ScheduledNotification from "../models/scheduledNotificationModel.js";
import users from "../models/userModel.js";
import userActiveSegment from "../models/userActiveSegmentsModel.js";
import planPurchaseModel from "../models/planPurchaseModel.js";
import segmentsPlanModel from "../models/segmentsPlansModel.js";
import notificationService from "../services/notificationService.js";
import NotificationLog from "../models/notificationLogModel.js";
import Entitlement from "../models/entitlementModel.js";
import segmentsPayment from "../models/segmentsPaymentModel.js";

let timer = null;

const processDueNotifications = async () => {
    try {
        const now = new Date();
        const notifications = await ScheduledNotification.find({
            status: 'pending',
            scheduleTime: { $lte: now }
        });

        if (notifications.length > 0) {
            console.log(`Processing ${notifications.length} scheduled notifications...`);
        }

        for (const notif of notifications) {
            try {
                let userIds = [];
                let query = { fcmToken: { $exists: true, $ne: null } };
                const { audience, audienceId, title, message, imageUrl } = notif;

                if (audience === 'Active Users') {
                    query.userStatus = 'ACTIVE';
                } else if (audience === 'Segment Specific') {
                    if (audienceId) {
                        const activeEntitlements = await Entitlement.find({
                            segmentId: audienceId,
                            type: 'PLAN',
                            status: 'ACTIVE',
                            startDate: { $lte: now },
                            $or: [{ endDate: null }, { endDate: { $gte: now } }]
                        }).select('userId');

                        const activeSegments = await userActiveSegment.find({
                            segmentId: audienceId,
                            isActive: true,
                            expiryDate: { $gte: now }
                        }).select('userId');

                        const combinedIds = new Set([
                            ...activeEntitlements.map(e => e.userId.toString()),
                            ...activeSegments.map(s => s.userId.toString())
                        ]);

                        // CRITICAL PROTECTION: Exclude those with SUSPENDED status for this segment
                        const suspendedUsers = await Entitlement.find({
                            userId: { $in: Array.from(combinedIds) },
                            segmentId: audienceId,
                            status: 'SUSPENDED',
                            type: 'PLAN'
                        }).select('userId');

                        for (const u of suspendedUsers) {
                            combinedIds.delete(u.userId.toString());
                        }

                        userIds = Array.from(combinedIds);
                        query._id = { $in: userIds };

                        if (userIds.length === 0) {
                            console.log(`No active users found for scheduled notification (Segment Specific): ${title}`);
                            notif.status = 'sent';
                            await notif.save();
                            continue;
                        }
                    }
                } else if (audience === 'Plan Specific') {
                    if (audienceId) {
                        const activeEntitlements = await Entitlement.find({
                            resourceId: audienceId,
                            type: 'PLAN',
                            status: 'ACTIVE',
                            startDate: { $lte: now },
                            $or: [{ endDate: null }, { endDate: { $gte: now } }]
                        }).select('userId');

                        const legacyPayments = await segmentsPayment.find({
                            segmentPlanId: audienceId,
                            paymentStatus: 'paid',
                            expiryDate: { $gte: now }
                        }).select('userId');

                        const combinedIds = new Set([
                            ...activeEntitlements.map(e => e.userId.toString()),
                            ...legacyPayments.map(p => p.userId.toString())
                        ]);

                        // CRITICAL PROTECTION: Exclude those with SUSPENDED status for this plan
                        const suspendedUsers = await Entitlement.find({
                            userId: { $in: Array.from(combinedIds) },
                            resourceId: audienceId,
                            status: 'SUSPENDED',
                            type: 'PLAN'
                        }).select('userId');

                        for (const u of suspendedUsers) {
                            combinedIds.delete(u.userId.toString());
                        }

                        userIds = Array.from(combinedIds);
                        query._id = { $in: userIds };

                        if (userIds.length === 0) {
                            console.log(`No active users found for scheduled notification (Plan Specific): ${title}`);
                            notif.status = 'sent';
                            await notif.save();
                            continue;
                        }
                    }
                }

                const userList = await users.find(query).select('fcmToken');
                const tokens = userList.map(u => u.fcmToken).filter(t => t);

                if (tokens.length > 0) {
                    const response = await notificationService.sendPushNotification(tokens, title, message, imageUrl);
                    console.log(`Scheduled notification sent to ${tokens.length} users.`);

                    // Save to NotificationLog
                    try {
                        const logEntry = new NotificationLog({
                            type: 'push',
                            title: title,
                            message: message,
                            audience: audience,
                            audienceId: audienceId || null,
                            audienceModel: audience === 'Segment Specific' ? 'Segment' : (audience === 'Plan Specific' ? 'SegmentPlan' : null),
                            recipientCount: tokens.length,
                            successCount: response.successCount || 0,
                            failureCount: response.failureCount || 0,
                            status: (response.failureCount === 0) ? 'sent' : (response.successCount > 0 ? 'partially_failed' : 'failed'),
                            imageUrl: imageUrl,
                            details: response.details || {}
                        });
                        await logEntry.save();
                    } catch (logError) {
                        console.error("Error saving scheduled notification log:", logError);
                    }

                    // Clean up expired tokens
                    if (response.expiredTokens && response.expiredTokens.length > 0) {
                        await users.updateMany(
                            { fcmToken: { $in: response.expiredTokens } },
                            { $set: { fcmToken: null } }
                        );
                        console.log(`Cleaned up ${response.expiredTokens.length} invalid FCM tokens from scheduled run.`);
                    }

                } else {
                    console.log(`No users found for scheduled notification: ${title}`);
                }

                notif.status = 'sent';
                await notif.save();

            } catch (err) {
                console.error(`Error processing scheduled notification ${notif._id}:`, err);
                notif.status = 'failed';
                await notif.save();
            }
        }
    } catch (error) {
        console.error("Error in processDueNotifications:", error);
    }
};

const runCheck = async () => {
    try {
        await processDueNotifications();
    } catch (err) {
        console.error("Critical error in scheduler runCheck:", err);
    }

    const now = new Date();
    // Look ahead 4 hours
    const fourHoursLater = new Date(now.getTime() + 4 * 60 * 60 * 1000);

    let nextInterval;
    try {
        // Check if any pending notifications are scheduled in the next 4 hours
        const upcomingCount = await ScheduledNotification.countDocuments({
            status: 'pending',
            scheduleTime: { $lte: fourHoursLater }
        });

        if (upcomingCount > 0) {
            // "Busy Mode": something is coming up soon, check frequently
            nextInterval = 5 * 60 * 1000; // 5 minutes
            console.log(`Scheduler: Active notifications in next 4hrs. Next check in 5 mins.`);
        } else {
            // "Relaxed Mode": nothing soon, check later
            nextInterval = 4 * 60 * 60 * 1000; // 4 hours
            console.log(`Scheduler: No notifications imminent. Next check in 4 hrs.`);
        }
    } catch (countError) {
        console.error("Error counting upcoming notifications:", countError);
        nextInterval = 5 * 60 * 1000; // On error, retry in 5 mins
    }

    if (timer) clearTimeout(timer);
    timer = setTimeout(runCheck, nextInterval);
};

export const initScheduler = () => {
    console.log("Initializing Dynamic Notification Scheduler...");
    runCheck();
};

export const forceSchedulerCheck = () => {
    console.log("Scheduler Forced Check triggered.");
    if (timer) clearTimeout(timer);
    runCheck();
};

export default { initScheduler, forceSchedulerCheck };
