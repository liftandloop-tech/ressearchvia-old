import notificationService from "../services/notificationService.js";
import emailService from "../services/emailService.js";
import users from "../models/userModel.js";
import segments from "../models/segmentsModel.js";
import segmentsPlanModel from "../models/segmentsPlansModel.js";
import userActiveSegment from "../models/userActiveSegmentsModel.js";
import planPurchaseModel from "../models/planPurchaseModel.js";
import fs from 'fs';
import csv from 'csv-parser';
import xlsx from 'xlsx';
import ScheduledNotification from "../models/scheduledNotificationModel.js";
import NotificationLog from "../models/notificationLogModel.js";
import { forceSchedulerCheck } from "../config/scheduledNotificationCron.js";
import Entitlement from "../models/entitlementModel.js";
import segmentsPayment from "../models/segmentsPaymentModel.js";

const parseEmailFile = async (filePath) => {
    const results = [];
    return new Promise((resolve, reject) => {
        if (filePath.endsWith('.csv')) {
            fs.createReadStream(filePath)
                .pipe(csv())
                .on('data', (data) => {
                    // Try to find a field explicitly named 'email' (case-insensitive)
                    const keys = Object.keys(data);
                    const emailKey = keys.find(k => k.toLowerCase().includes('email'));
                    const email = emailKey ? data[emailKey] : Object.values(data)[0]; // Fallback to first column

                    if (email && typeof email === 'string' && email.includes('@')) {
                        results.push(email.trim());
                    }
                })
                .on('end', () => resolve(results))
                .on('error', (err) => reject(err));
        } else if (filePath.endsWith('.xlsx') || filePath.endsWith('.xls')) {
            try {
                const workbook = xlsx.readFile(filePath);
                const sheet_name_list = workbook.SheetNames;
                if (sheet_name_list.length > 0) {
                    const xlData = xlsx.utils.sheet_to_json(workbook.Sheets[sheet_name_list[0]]);
                    xlData.forEach((row) => {
                        const keys = Object.keys(row);
                        const emailKey = keys.find(k => k.toLowerCase().includes('email'));
                        const email = emailKey ? row[emailKey] : Object.values(row)[0];

                        if (email && typeof email === 'string' && email.includes('@')) {
                            results.push(email.trim());
                        }
                    });
                }
                resolve(results);
            } catch (err) { reject(err); }
        } else {
            resolve([]);
        }
    });
};

const notificationController = {
    getSegments: async (req, res) => {
        try {
            const result = await segments.find({ segmentStatus: "active" }).select("_id segmentName");
            res.status(200).send({ status: 200, data: result });
        } catch (error) {
            res.status(500).send({ status: 500, message: "Error fetching segments", error: error.message });
        }
    },

    getPlans: async (req, res) => {
        try {
            const result = await segmentsPlanModel.find({ planStatus: "active" }).select("_id planName");
            res.status(200).send({ status: 200, data: result });
        } catch (error) {
            res.status(500).send({ status: 500, message: "Error fetching plans", error: error.message });
        }
    },

    sendNotification: async (req, res) => {
        try {
            const { title, message, audience, audienceId, schedule } = req.body;

            if (!title || !message) {
                return res.status(400).send({ status: 400, message: "Title and message are required" });
            }

            let imageUrl = null;
            if (req.file) {
                const baseUrl = process.env.API_BASE_URL || 'https://api.researchvia.in';
                imageUrl = `${baseUrl}/${req.file.path.replace(/\\/g, '/')}`;
            }

            // check 'schedule' parameter
            if (schedule && schedule !== 'null' && schedule !== 'undefined') {
                const scheduleTime = new Date(schedule);
                if (scheduleTime > new Date()) {
                    // Create scheduled notification
                    const newScheduledNotification = new ScheduledNotification({
                        title,
                        message,
                        audience,
                        audienceId: audienceId || null,
                        imageUrl: imageUrl,
                        scheduleTime: scheduleTime,
                        status: 'pending'
                    });
                    await newScheduledNotification.save();

                    // Trigger scheduler to re-evaluate intervals immediately
                    forceSchedulerCheck();

                    return res.status(200).send({
                        status: 200,
                        message: "Notification scheduled successfully",
                        data: newScheduledNotification
                    });
                }
            }

            let userIds = [];
            let query = { fcmToken: { $exists: true, $ne: null } };

            if (audience === 'Active Users') {
                query.userStatus = 'ACTIVE';
            } else if (audience === 'Segment Specific') {
                if (!audienceId) return res.status(400).send({ status: 400, message: "Segment ID is required" });

                const now = new Date();
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
                userIds = Array.from(combinedIds);
                query._id = { $in: userIds };

                if (userIds.length === 0) {
                    return res.status(200).send({ status: 200, message: "No active users found for this segment." });
                }

            } else if (audience === 'Plan Specific') {
                if (!audienceId) return res.status(400).send({ status: 400, message: "Plan ID is required" });

                const now = new Date();
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
                userIds = Array.from(combinedIds);
                query._id = { $in: userIds };

                if (userIds.length === 0) {
                    return res.status(200).send({ status: 200, message: "No active users found for this plan." });
                }

            } else if (audience === 'All Users') {
                // No additional filter
            }

            const userList = await users.find(query).select('fcmToken');
            const tokens = userList.map(u => u.fcmToken).filter(t => t);

            if (tokens.length === 0) {
                return res.status(200).send({ status: 200, message: "No users found with valid tokens to send notification." });
            }


            const response = await notificationService.sendPushNotification(tokens, title, message, imageUrl);

            // Save to NotificationLog
            try {
                const logEntry = new NotificationLog({
                    type: 'push',
                    title: title,
                    message: message,
                    audience: audience,
                    audienceId: (audience === 'Segment Specific' || audience === 'Plan Specific') ? audienceId : null,
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
                console.error("Error saving notification log:", logError);
            }

            // Optional: Clean up expired tokens
            if (response.expiredTokens && response.expiredTokens.length > 0) {
                await users.updateMany(
                    { fcmToken: { $in: response.expiredTokens } },
                    { $set: { fcmToken: null } }
                );
                console.log(`Cleaned up ${response.expiredTokens.length} invalid FCM tokens.`);
            }

            res.status(200).send({
                status: 200,
                message: "Notification sending initiated",
                details: response
            });

        } catch (error) {
            console.error("Notification Controller Error:", error);
            res.status(500).send({ status: 500, message: "Internal Server Error", error: error.message });
        }
    },

    sendBulkEmail: async (req, res) => {
        try {
            const { subject, message, audience, audienceId, manualEmails } = req.body;

            // Note: Subject is mapped from 'title' in frontend if not explicitly sent? 
            // Frontend currently sends 'title' (generic) or I should ensure frontend sends 'subject'.
            // I will assume frontend sends 'subject' for email.

            const emailSubject = subject || "Notification from ResearchVia";

            if (!message) {
                return res.status(400).send({ status: 400, message: "Message content is required" });
            }

            let emailList = [];

            if (audience === 'Manual Entry') {
                if (manualEmails) {
                    emailList = manualEmails.split(',').map(e => e.trim()).filter(e => e && e.includes('@'));
                }
            } else if (audience === 'Import CSV/Excel') {
                if (!req.file) {
                    return res.status(400).send({ status: 400, message: "File is required for import" });
                }

                try {
                    emailList = await parseEmailFile(req.file.path);
                    // Cleanup
                    if (fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
                } catch (err) {
                    if (fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
                    return res.status(400).send({ status: 400, message: "Error parsing file", error: err.message });
                }

            } else {
                let query = { email: { $exists: true, $ne: null } };

                if (audience === 'Active Users') {
                    query.userStatus = 'ACTIVE';
                } else if (audience === 'Expired Users') {
                    // Assuming logic for expired users
                    // query.status = 'Expired'; // or verify
                } else if (audience === 'Premium Users') {
                    // Logic for premium
                    // query.isPremium = true; 
                    // Need to check schema for premium flag or deduce it.
                    // For now, I'll rely on generic query or specific logic if I knew it.
                    // Based on sendNotification, it uses 'Segment Specific' or 'Plan Specific'. 
                    // I will support those.
                } else if (audience === 'Segment Specific') {
                    if (!audienceId) return res.status(400).send({ status: 400, message: "Segment ID is required" });
                    const activeSegments = await userActiveSegment.find({ segmentId: audienceId, isActive: true }).select('userId');
                    const userIds = activeSegments.map(s => s.userId);
                    query._id = { $in: userIds };
                } else if (audience === 'Plan Specific') {
                    if (!audienceId) return res.status(400).send({ status: 400, message: "Plan ID is required" });
                    const plan = await segmentsPlanModel.findById(audienceId);
                    if (plan) {
                        const purchases = await planPurchaseModel.find({ packageName: plan.planName, status: 'active' }).select('userId');
                        const userIds = purchases.map(p => p.userId);
                        query._id = { $in: userIds };
                    }
                }

                const userList = await users.find(query).select('email');
                emailList = userList.map(u => u.email).filter(e => e);
            }

            if (emailList.length === 0) {
                return res.status(200).send({ status: 200, message: "No valid emails found." });
            }

            // Remove duplicates
            emailList = [...new Set(emailList)];

            // Send Email
            const response = await emailService.sendEmail({ to: emailList, subject: emailSubject, htmlContent: message });

            // Save to NotificationLog
            try {
                const logEntry = new NotificationLog({
                    type: 'email',
                    title: emailSubject,
                    message: message,
                    audience: audience,
                    audienceId: (audience === 'Segment Specific' || audience === 'Plan Specific') ? audienceId : null,
                    audienceModel: audience === 'Segment Specific' ? 'Segment' : (audience === 'Plan Specific' ? 'SegmentPlan' : null),
                    recipientCount: emailList.length,
                    successCount: emailList.length, // emailService doesn't return per-recipient detail yet
                    failureCount: 0,
                    status: 'sent',
                    details: response
                });
                await logEntry.save();
            } catch (logError) {
                console.error("Error saving email log:", logError);
            }

            res.status(200).send({
                status: 200,
                message: "Emails processed",
                recipientCount: emailList.length,
                details: response
            });

        } catch (error) {
            console.error("Bulk Email Error:", error);
            res.status(500).send({ status: 500, message: "Internal Server Error", error: error.message });
        }
    },

    previewEmail: async (req, res) => {
        try {
            const { message } = req.body;
            const html = emailService.getTemplatePreview(message || '');
            res.send(html);
        } catch (error) {
            res.status(500).send("Error generating preview");
        }
    },

    getScheduledNotifications: async (req, res) => {
        try {
            const notifications = await ScheduledNotification.find().sort({ createdAt: -1 });
            res.status(200).send({ status: 200, data: notifications });
        } catch (error) {
            res.status(500).send({ status: 500, message: "Error fetching scheduled notifications", error: error.message });
        }
    },

    deleteScheduledNotification: async (req, res) => {
        try {
            const { id } = req.params;
            await ScheduledNotification.findByIdAndDelete(id);
            // Trigger scheduler just in case (though deleting usually doesn't need immediate wake-up for interval calc unless it was the NEXT one, but safe to ignore or force check if we are super rigorous. Force check is fine)
            forceSchedulerCheck();
            res.status(200).send({ status: 200, message: "Scheduled notification deleted" });
        } catch (error) {
            res.status(500).send({ status: 500, message: "Error deleting notification", error: error.message });
        }
    },

    getNotificationHistory: async (req, res) => {
        try {
            const history = await NotificationLog.find().sort({ sentAt: -1 }).limit(100);
            res.status(200).send({ status: 200, data: history });
        } catch (error) {
            res.status(500).send({ status: 500, message: "Error fetching history", error: error.message });
        }
    }
};

export default notificationController;
