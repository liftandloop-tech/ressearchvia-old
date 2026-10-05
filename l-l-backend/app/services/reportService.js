import reportModel from "../models/reportsModel.js"
import mongoose from "mongoose";
import path from "path"
import fs from "fs"
import segmentsPayment from "../models/segmentsPaymentModel.js"
import segmentsPlanModel from "../models/segmentsPlansModel.js"
import segmentModel from "../models/segmentsModel.js"
import Entitlement from "../models/entitlementModel.js" // Chunk 9
import userActiveSegmentModel from "../models/userActiveSegmentsModel.js"
import users from "../models/userModel.js"
import userKycModel from "../models/userKycModel.js"
import staffModel from "../models/staffModel.js";
import notificationService from "./notificationService.js"
import devices from "../models/deviceModel.js";
import PaymentIntent from "../models/paymentIntentModel.js";
import { logCallAssignment } from "./activityLogService.js";

const detectUpdateStatus = (text, explicitStatus) => {
    if (explicitStatus && explicitStatus !== 'null' && explicitStatus !== 'undefined' && explicitStatus.trim() !== '') {
        return explicitStatus.trim();
    }
    if (!text) return 'general';
    const t = text.toLowerCase();
    if (t.includes('sl triggered') || t.includes('sl hit') || t.includes('stoploss') || t.includes('stop loss') || t.includes('exit sl') || t.includes('kindly exit') || t.includes('exit in') || t.includes('sl tirgger') || t.includes('sl ttigger') || t.includes('stoploss triggered')) {
        return 'stoploss_hit';
    }
    if (t.includes('partial profit') || t.includes('part profit') || t.includes('partial') || t.includes('book partial') || t.includes('parital profit')) {
        return 'partial_profit';
    }
    if (t.includes('target achieved') || t.includes('target hit') || t.includes('tgt achieved') || t.includes('tgt hit') || t.includes('target') || t.includes('tgt') || t.includes('trgt') || t.includes('full profit') || t.includes('book full profit') || t.includes('porfit') || t.includes('book profit')) {
        return 'target_achieved';
    }
    return 'general';
};

const sendReportNotification = async (report, isUpdate = false) => {
    try {
        if (report.publishedStatus !== 'published') return;

        // 1. Identify Target Audience
        // Users who have Active Entitlement for BOTH the specific Plan AND Segment
        const now = new Date();
        const activeEntitlements = await Entitlement.find({
            resourceId: { $in: report.planArray },
            segmentId: { $in: report.segment },
            type: 'PLAN',
            status: 'ACTIVE',
            startDate: { $lte: now },
            $or: [{ endDate: null }, { endDate: { $gte: now } }]
        }).select('userId');

        // For Legacy Users: Check segmentsPayment to find active payments that match BOTH
        const legacyPayments = await segmentsPayment.find({
            segmentId: { $in: report.segment },
            segmentPlanId: { $in: report.planArray },
            paymentStatus: 'paid',
            expiryDate: { $gte: now }
        }).select('userId');

        const userIds = new Set([
            ...activeEntitlements.map(e => e.userId.toString()),
            ...legacyPayments.map(p => p.userId.toString())
        ]);

        // CRITICAL PROTECTION: Exclude users who are SUSPENDED (account level) or have any SUSPENDED entitlement
        if (userIds.size > 0) {
            // Check Account Level Suspension
            const accountSuspendedUsers = await users.find({
                _id: { $in: Array.from(userIds) },
                userStatus: 'SUSPENDED'
            }).select('_id');

            const accountSuspendedIds = new Set(accountSuspendedUsers.map(u => u._id.toString()));

            // Check Entitlement Level Suspension
            const suspendedEntitlements = await Entitlement.find({
                userId: { $in: Array.from(userIds) },
                status: 'SUSPENDED',
                type: 'PLAN',
                $or: [
                    { resourceId: { $in: report.planArray } },
                    { segmentId: { $in: report.segment } }
                ]
            }).select('userId');

            const entitlementSuspendedIds = new Set(suspendedEntitlements.map(u => u.userId.toString()));

            // Combine and remove
            const allSuspendedIds = new Set([...accountSuspendedIds, ...entitlementSuspendedIds]);

            for (const id of allSuspendedIds) {
                // Remove from target list
                userIds.delete(id);
            }
        }

        if (userIds.size === 0) {
            console.log(`[Notification] No target users found for report: ${report.title} (Plans: ${report.planArray}, Segments: ${report.segment})`);
            return;
        }

        // 2. Fetch Tokens from Devices (Decoupled from Session)
        const deviceDocs = await devices.find({
            userId: { $in: Array.from(userIds) },
            isActive: true, // Only active devices
            pushToken: { $ne: null }
        }).select('pushToken');

        const tokens = deviceDocs.map(d => d.pushToken).filter(t => t);
        if (tokens.length === 0) {
            console.log(`[Notification] No active device tokens found for ${userIds.size} target users of report: ${report.title}`);
            return;
        }

        // 3. Determine Notification Content & Priority
        const isTradingCall = report.reportType === 'Trading calls';

        let title, body, priority, channelId, data;

        if (isTradingCall) {
            // Critical
            const type = report.title.toLowerCase().includes('buy') ? 'BUY' :
                report.title.toLowerCase().includes('sell') ? 'SELL' : 'TRADE';

            const latestUpdate = (isUpdate && report.updates && report.updates.length > 0)
                ? report.updates[report.updates.length - 1]
                : null;

            let updatePrefix = '';
            if (latestUpdate) {
                const normStatus = detectUpdateStatus(latestUpdate.text, latestUpdate.status);
                if (normStatus === 'target_achieved') updatePrefix = '🎯 Target Achieved: ';
                else if (normStatus === 'stoploss_hit') updatePrefix = '🛑 Stoploss Hit: ';
                else if (normStatus === 'partial_profit') updatePrefix = '💰 Partial Profit: ';
            }

            title = isUpdate ? `🚨 Updated ${type} Call` : `🚨 New ${type} Call`;
            body = isUpdate
                ? (latestUpdate ? `${updatePrefix}${latestUpdate.text}` : `Update: ${report.title}`)
                : report.title;
            priority = 'high';
            channelId = 'high_importance_channel';
            data = { type: 'TRADING_CALL', reportId: report._id.toString() };
        } else {
            // Standard
            title = isUpdate ? `📄 Report Updated` : `📄 New Report Published`;
            body = isUpdate ? `Update: ${report.title}` : report.title;
            priority = 'normal';
            channelId = 'default_channel'; // Or whatever standard channel
            data = { type: 'RESEARCH_REPORT', reportId: report._id.toString() };
        }

        // 4. Send
        console.log(`Sending notification for report ${report._id} to ${tokens.length} users.`);
        await notificationService.sendPushNotification(tokens, title, body, data, priority, channelId);

    } catch (error) {
        console.error("Error sending report notification:", error);
    }
};


const reportService = {
    createReport: async ({ body, file }) => {
        try {
            console.log("=== CREATE REPORT BODY ===", body);
            let { title, segment, reportType, planArray, description, youtubeUrl } = body
            let reportPath = file ? file.path : ""
            let reportOriginalName = file ? file.originalname : ""
            let reportName = file ? file.filename : ""

            const isTradingCall = (reportType || '').toLowerCase().includes('trading');
            if (!isTradingCall && !file) {
                return { status: 400, message: "A document file is required for research reports", data: {} };
            }

            // Handle segment as array (stringified if form-data)
            let segmentIds = [];
            if (typeof segment === 'string') {
                try {
                    // Try parsing if it looks like array
                    if (segment.startsWith('[')) {
                        segmentIds = JSON.parse(segment);
                    } else {
                        segmentIds = [segment];
                    }
                } catch (e) {
                    segmentIds = [segment];
                }
            } else if (Array.isArray(segment)) {
                segmentIds = segment;
            }

            // Fetch Segment Names
            const segmentsData = await segmentModel.find({ _id: { $in: segmentIds } }).select("segmentName");
            // Map names in order? Or just store all valid names found.
            // Ideally we store [id] and [name]. Order doesn't strictly matter for filtering but good for display.
            const segmentNames = segmentsData.map(s => s.segmentName);

            // Re-verify IDs found to ensure data consistency
            const validSegmentIds = segmentsData.map(s => s._id);

            console.log("Setting youtubeUrl in create:", youtubeUrl);

            const report = new reportModel({
                title: title,
                segment: validSegmentIds,
                segmentName: segmentNames,
                reportType: reportType,
                planArray: (function () {
                    if (Array.isArray(planArray)) return planArray;
                    if (typeof planArray === 'string') {
                        try {
                            if (planArray.trim().startsWith('[')) return JSON.parse(planArray);
                            return [planArray];
                        } catch (e) { return [planArray]; }
                    }
                    return [];
                })(),
                description: description,
                // YouTube URL mapping - using direct body access for robustness
                youtubeUrl: (body.youtubeUrl && body.youtubeUrl.toString().trim()) ? body.youtubeUrl.toString().trim() : null,
                reportPath: reportPath,
                reportOriginalName: reportOriginalName,
                reportName: reportName,
                published_at: Date.now()
            })
            console.log("DEBUG: Created report with youtubeUrl:", report.youtubeUrl);
            console.log("DEBUG: All body keys received:", Object.keys(body));
            if (body.newUpdate && body.newUpdate.trim() !== '') {
                const updateStatus = detectUpdateStatus(body.newUpdate, body.newUpdateStatus || body.updateStatus);
                report.updates = [{
                    text: body.newUpdate.trim(),
                    status: updateStatus,
                    timestamp: new Date()
                }];
            }
            await report.save()

            // Trigger Notification
            if (report.publishedStatus === 'published') {
                sendReportNotification(report);
            }

            return { status: 200, message: "Report created successfully", data: { report } }
        }
        catch (error) {
            console.error("Create Report Error", error);
            return { status: 400, message: error.message || error, data: {} }
        }
    },
    reportDownload: async (req, res) => {
        try {
            let { id } = req.params;
            // req.user is available via auth middleware, use it for security instead of trusting params if possible.
            // But controller uses params for reportId `id`.
            // User ID comes from token.
            const userId = req.user._id;

            const report = await reportModel.findOne({ _id: id });
            if (!report) {
                return res.status(404).json({ status: 404, message: "Report Not Found", data: {} });
            }

            // Chunk 9.3: Harden Download
            // Check Entitlements Logic (Reuse query logic or explicit check)
            const now = new Date();
            const hasEntitlement = await Entitlement.findOne({
                userId: userId,
                type: 'PLAN',
                status: 'ACTIVE',
                startDate: { $lte: now },
                endDate: { $gte: now }, // or null
                resourceId: { $in: report.planArray } // Must have ONE of the plans this report belongs to
            });

            // Handle Lifetime separately if query complex, or just use $or in findOne
            const hasLifetimeOrActive = await Entitlement.findOne({
                userId: userId,
                type: 'PLAN',
                status: 'ACTIVE',
                startDate: { $lte: now },
                $or: [
                    { endDate: null },
                    { endDate: { $gte: now } }
                ],
                resourceId: { $in: report.planArray }
            });

            const userType = (req.user?.userType || '').toLowerCase();
            const isSystemAdmin = userType === 'admin' || userType === 'super_admin';
            const isStaff = await staffModel.exists({ _id: userId });

            if (!hasLifetimeOrActive && !isSystemAdmin && !isStaff) {
                console.log(`[Security] Blocked download for User ${userId} on Report ${id}`);
                return res.status(403).json({ status: 403, message: "Access Denied. No active subscription for this report.", data: {} });
            }

            if (report) { // Redundant check but ok
                if (!report.reportPath || !fs.existsSync(report.reportPath)) {
                    return res.status(404).json({ status: 404, message: "File not found on server", data: {} });
                }
                res.download(report.reportPath, report.reportOriginalName)
            }
        }
        catch (error) {
            console.log(error)
            return res.status(500).json({ status: 500, message: error.message, data: {} })
        }
    },


    userReportList: async ({ params, query }) => {
        try {
            let { id } = params
            let { reportType, date, search, startDate, endDate, page, pageSize } = query;
            let queryArg = {}

            // Handle Pagination - First page loads 20, subsequent pages load 10
            page = page ? parseInt(page) : 1;
            const isFirstPage = page === 1;
            const currentPageSize = isFirstPage ? 20 : 10;
            pageSize = pageSize ? parseInt(pageSize) : currentPageSize;

            if (reportType) {
                queryArg.reportType = reportType;
            }

            // Legacy 'date' param support (<= date)
            if (date) {
                const parsedDate = new Date(date);
                queryArg.createdAt = { $lte: parsedDate };
            }

            // Enhanced Date Range Support
            let newStartDate = startDate ? new Date(startDate) : null;
            let newEndDate = endDate ? new Date(endDate) : null;
            if (newStartDate) newStartDate.setHours(0, 0, 0, 0);
            if (newEndDate) newEndDate.setHours(23, 59, 59, 999);

            if (newStartDate && newEndDate == null) {
                queryArg.published_at = { $gte: newStartDate };
            } else if (newEndDate && newStartDate == null) {
                queryArg.published_at = { $lte: newEndDate };
            } else if (newStartDate && newEndDate) {
                queryArg.published_at = { $gte: newStartDate, $lte: newEndDate };
            }

            // Search Support
            if (search) {
                search = search.trim();
                const searchCriteria = {
                    "$or": [
                        { segmentName: { $regex: search, $options: 'i' } },
                        { publishedStatus: { $regex: search, $options: 'i' } }, // Usually always 'published' here but valid check
                        { title: { $regex: search, $options: 'i' } }
                    ]
                };
                // If search is a valid MongoDB ID, also check the segment field
                if (search.match(/^[0-9a-fA-F]{24}$/)) {
                    searchCriteria["$or"].push({ segment: search });
                }
                queryArg = { ...queryArg, ...searchCriteria };
            }

            // Chunk 9.2: Harden /user-report-list/:id
            // Enforce Access at Query Level using ENTITLEMENTS + LEGACY SEGMENTS

            // 0. KYC Rejection Check - Block if KYC is REJECTED
            const userDoc = await users.findById(id).select('kycStatus');
            const userKycDoc = await userKycModel.findOne({ userId: id }).select('kycStatus');

            // Check both sources: users.kycStatus (Video KYC admin approval) and userKyc.kycStatus (Digio webhook)
            const isKycRejected =
                userDoc?.kycStatus === 'REJECTED' ||
                userKycDoc?.kycStatus === 'rejected';

            if (isKycRejected) {
                return {
                    status: 403,
                    message: "Access denied. Your KYC has been rejected. Please complete KYC verification to access reports.",
                    data: { reports: [] }
                };
            }

            // 1. Fetch Active Entitlements (Plans)
            const now = new Date();
            const activeEntitlements = await Entitlement.find({
                userId: id,
                type: 'PLAN',
                status: 'ACTIVE',
                startDate: { $lte: now },
                $or: [
                    { endDate: null },
                    { endDate: { $gte: now } }
                ]
            }).populate({
                path: 'resourceId',
                model: 'segmentsPlan',
                select: 'segmentsId'
            });

            // 2. Fetch Legacy Active Segments
            const activeSegments = await userActiveSegmentModel.find({
                userId: id,
                isActive: true,
                expiryDate: { $gte: now }
            });

            // 2.5. Fetch Legacy Segments Payments (Plan+Segment)
            const legacyPayments = await segmentsPayment.find({
                userId: id,
                paymentStatus: 'paid',
                expiryDate: { $gte: now }
            });

            const orConditions = [];
            const segmentsWithPlan = new Set();
            const allValidSegmentIds = new Set();

            // Gather all segments the user truly owns across all systems
            activeSegments.forEach(s => s.segmentId && allValidSegmentIds.add(s.segmentId.toString()));
            legacyPayments.forEach(p => p.segmentId && allValidSegmentIds.add(p.segmentId.toString()));
            activeEntitlements.forEach(e => {
                if (e.segmentId) allValidSegmentIds.add(e.segmentId.toString());
            });

            // 2.5 Auto-Heal strictly missing segment IDs (from broken Trial Registrations)
            await Promise.all(activeEntitlements.map(async (e) => {
                if (!e.segmentId && e.sourceRefId) {
                    try {
                        const intent = await PaymentIntent.findById(e.sourceRefId).select('preferredSegmentId');
                        if (intent && intent.preferredSegmentId) {
                            e.segmentId = intent.preferredSegmentId;
                            allValidSegmentIds.add(intent.preferredSegmentId.toString());
                            e.save().catch(() => { }); // Fire and forget db fix
                        }
                    } catch (err) { }
                }
            }));

            // Modern Entitlements: Must match exact Plan AND Segment
            activeEntitlements.forEach(e => {
                const planId = e.resourceId?._id || e.resourceId;
                const segmentId = e.segmentId || e.resourceId?.segmentsId;

                if (planId && segmentId) {
                    orConditions.push({ planArray: planId, segment: segmentId });
                    segmentsWithPlan.add(segmentId.toString());
                } else if (planId) {
                    // Fallback for stubbornly missing segment data - restrict plan access to known segments
                    if (allValidSegmentIds.size > 0) {
                        orConditions.push({ planArray: planId, segment: { $in: Array.from(allValidSegmentIds) } });
                    } else {
                        orConditions.push({ planArray: planId });
                    }
                } else if (segmentId) {
                    orConditions.push({
                        segment: segmentId,
                        $or: [{ planArray: { $exists: false } }, { planArray: { $size: 0 } }]
                    });
                    segmentsWithPlan.add(segmentId.toString());
                }
            });

            // Legacy Payments: Exact combination (like modern Entitlements)
            legacyPayments.forEach(p => {
                if (p.segmentPlanId && p.segmentId) {
                    orConditions.push({ planArray: p.segmentPlanId, segment: p.segmentId });
                    segmentsWithPlan.add(p.segmentId.toString());
                }
            });

            // Legacy Segments: Broad segment access ONLY handles broadcast reports (Free for all in segment)
            activeSegments.forEach(s => {
                if (s.segmentId && !segmentsWithPlan.has(s.segmentId.toString())) {
                    orConditions.push({
                        segment: s.segmentId,
                        $or: [{ planArray: { $exists: false } }, { planArray: { $size: 0 } }]
                    });
                }
            });

            // Allow user to see any broadcast report (no plan required) in any of their valid segments
            if (allValidSegmentIds.size > 0) {
                orConditions.push({
                    segment: { $in: Array.from(allValidSegmentIds) },
                    $or: [{ planArray: { $exists: false } }, { planArray: { $size: 0 } }]
                });
            }

            if (orConditions.length === 0) {
                return {
                    status: 200,
                    message: "No active subscriptions found.",
                    data: {
                        reports: [],
                        totalReports: 0,
                        hasMore: false,
                        hasActiveSubscription: false
                    }
                };
            }

            // 3. Query Reports: Match specific allowed combinations
            // Combine strict user visibility filters
            const finalQuery = {
                ...queryArg,
                publishedStatus: 'published',
                $or: orConditions
            };

            // Fetch ALL reports first
            const allReports = await reportModel.find(finalQuery)
                .sort({ published_at: -1, createdAt: -1 })
                .exec();

            // 4. Add metadata for blur overlay (reports published before plan start date)
            // Create a map of plan/segment start dates for quick lookup
            const planStartDates = new Map();

            // Check all user entitlements (active + expired) to find earliest start date for each segment
            // This ensures renewing users do not have previously accessible historical reports locked
            const allUserEntitlements = await Entitlement.find({
                userId: id,
                type: 'PLAN',
                status: { $in: ['ACTIVE', 'EXPIRED'] }
            }).select('segmentId startDate resourceId');

            allUserEntitlements.forEach(ent => {
                const segmentId = (ent.segmentId?._id || ent.segmentId || ent.resourceId?.segmentsId)?.toString();
                if (segmentId && ent.startDate) {
                    const existing = planStartDates.get(segmentId);
                    if (!existing || new Date(ent.startDate) < new Date(existing)) {
                        planStartDates.set(segmentId, ent.startDate);
                    }
                }
            });

            // Active entitlements override / fallback
            activeEntitlements.forEach(ent => {
                const segmentId = (ent.segmentId?._id || ent.segmentId || ent.resourceId?.segmentsId)?.toString();
                if (segmentId && ent.startDate) {
                    const existing = planStartDates.get(segmentId);
                    if (!existing || new Date(ent.startDate) < new Date(existing)) {
                        planStartDates.set(segmentId, ent.startDate);
                    }
                }
            });

            // Add legacy segment start dates
            activeSegments.forEach(seg => {
                const segId = seg.segmentId?.toString();
                if (segId && seg.purchaseDate) {
                    const existing = planStartDates.get(segId);
                    if (!existing || new Date(seg.purchaseDate) < new Date(existing)) {
                        planStartDates.set(segId, seg.purchaseDate);
                    }
                }
            });

            // 5. Enhance ALL reports with access metadata (DO NOT drop or truncate reports)
            const allFilteredReports = allReports.map(report => {
                const reportObj = report.toObject();
                const reportPublishedDate = new Date(report.published_at || report.createdAt);

                // Find the earliest segment start date that covers this report
                let earliestPlanStart = null;

                if (report.segment && report.segment.length > 0) {
                    report.segment.forEach(segId => {
                        const segStart = planStartDates.get(segId.toString());
                        if (segStart && (!earliestPlanStart || new Date(segStart) < new Date(earliestPlanStart))) {
                            earliestPlanStart = segStart;
                        }
                    });
                }

                // Report lock overlay removed per UX requirement (all entitled reports accessible)
                return {
                    ...reportObj,
                    accessMetadata: {
                        isLocked: false,
                        planStartDate: earliestPlanStart,
                        reportPublishedDate: reportPublishedDate
                    }
                };
            });

            // 5.5 Calculate Trading Call Accuracy statistics across all accessible reports (target achieved, partially booked, stoploss hit)
            const getReportCallStatus = (report) => {
                const updates = report.updates || [];
                // Check updates in reverse order (latest decisive outcome first)
                for (let i = updates.length - 1; i >= 0; i--) {
                    const u = updates[i];
                    const s = (u.status || '').toLowerCase().trim();
                    const t = (u.text || '').toLowerCase();

                    if (s === 'target_achieved' || s === 'target' || s === 'target achieved' || s === 'full_profit' || s === 'tgt_achieved' ||
                        t.includes('target achieved') || t.includes('target hit') || t.includes('tgt achieved') ||
                        t.includes('full profit') || t.includes('all targets') || t.includes('target met')) {
                        return 'target_achieved';
                    }
                    if (s === 'partial_profit' || s === 'partial' || s === 'partial profit' || s === 'part_profit' ||
                        t.includes('partial profit') || t.includes('part profit') || t.includes('book partial') || t.includes('partially booked')) {
                        return 'partial_profit';
                    }
                    if (s === 'stoploss_hit' || s === 'stoploss' || s === 'stop_loss' || s === 'sl_hit' || s === 'stop loss hit' ||
                        t.includes('sl hit') || t.includes('stoploss') || t.includes('stop loss') || t.includes('sl triggered') || t.includes('hit sl')) {
                        return 'stoploss_hit';
                    }
                }

                // Fallback check on title and description
                const combined = ((report.title || '') + ' ' + (report.description || '')).toLowerCase();
                if (combined.includes('target achieved') || combined.includes('target hit') || combined.includes('tgt achieved')) {
                    return 'target_achieved';
                }
                if (combined.includes('partial profit') || combined.includes('partially booked') || combined.includes('book partial')) {
                    return 'partial_profit';
                }
                if (combined.includes('stop loss hit') || combined.includes('stoploss hit') || combined.includes('sl hit') || combined.includes('sl triggered')) {
                    return 'stoploss_hit';
                }

                return 'active';
            };

            let targetAchievedCount = 0;
            let partiallyBookedCount = 0;
            let stoplossHitCount = 0;
            let activeCallsCount = 0;

            allFilteredReports.forEach(r => {
                const status = getReportCallStatus(r);
                if (status === 'target_achieved') targetAchievedCount++;
                else if (status === 'partial_profit') partiallyBookedCount++;
                else if (status === 'stoploss_hit') stoplossHitCount++;
                else activeCallsCount++;
            });

            const totalCalls = allFilteredReports.length;
            const closedCalls = targetAchievedCount + partiallyBookedCount + stoplossHitCount;
            const accuracyRate = closedCalls > 0
                ? Math.round(((targetAchievedCount + partiallyBookedCount) / closedCalls) * 1000) / 10
                : 0;

            const accuracyStats = {
                totalCalls,
                closedCalls,
                targetAchieved: targetAchievedCount,
                partiallyBooked: partiallyBookedCount,
                stoplossHit: stoplossHitCount,
                active: activeCallsCount,
                accuracyRate
            };

            // 6. Pagination offset calculation
            // Handles both uniform pageSize and mobile variable pageSize (page 1: 20, page 2+: 10)
            let startIndex;
            if (query.skip !== undefined || query.offset !== undefined) {
                startIndex = parseInt(query.skip || query.offset) || 0;
            } else if (page === 1) {
                startIndex = 0;
            } else if (pageSize === 10) {
                // Client requested page > 1 with default secondary page size 10 (first page was 20)
                startIndex = 20 + (page - 2) * 10;
            } else {
                // Standard uniform pagination: (page - 1) * pageSize
                startIndex = (page - 1) * pageSize;
            }

            const endIndex = startIndex + pageSize;
            const finalReports = allFilteredReports.slice(startIndex, endIndex);

            return {
                status: 200,
                message: finalReports.length > 0 ? "User Report List" : "No reports found",
                data: {
                    reports: finalReports,
                    totalReports: allFilteredReports.length,
                    hasMore: endIndex < allFilteredReports.length,
                    hasActiveSubscription: true,
                    page,
                    pageSize,
                    accuracyStats
                }
            };
        } catch (error) {
            console.error("userReportList Error:", error);
            return { status: 400, message: error.message, data: {} };
        }
    },
    reportList: async ({ query }) => {
        try {
            let { page, pageSize, startDate, endDate, search, segmentId, planId, status, reportType } = query
            let queryArgs = {}
            page = page ? parseInt(page) : ''
            pageSize = pageSize ? parseInt(pageSize) : ''
            search = search ? search.trim() : ""

            let newStartDate = startDate ? new Date(startDate) : null;
            let newEndDate = endDate ? new Date(endDate) : null;
            if (newStartDate) newStartDate.setHours(0, 0, 0, 0);
            if (newEndDate) newEndDate.setHours(23, 59, 59, 999);

            if (newStartDate && newEndDate == null) {
                queryArgs.createdAt = { $gte: newStartDate };
            }
            if (newEndDate && newStartDate == null) {
                queryArgs.createdAt = { $lte: newEndDate };
            }
            if (newStartDate && newEndDate) {
                queryArgs.createdAt = { $gte: newStartDate, $lte: newEndDate };
            }

            if (segmentId) {
                queryArgs.segment = segmentId;
            }

            if (planId) {
                try {
                    queryArgs.planArray = { $in: [new mongoose.Types.ObjectId(planId)] };
                } catch (e) {
                    // if planId is invalid hex, just ignore or fallback
                    queryArgs.planArray = { $in: [planId] };
                }
            }

            if (status) {
                queryArgs.publishedStatus = status;
            }

            if (reportType) {
                queryArgs.reportType = reportType;
            }

            if (search) {
                const searchCriteria = {
                    "$or": [
                        { segmentName: { $regex: search, $options: 'i' } },
                        { publishedStatus: { $regex: search, $options: 'i' } },
                        { title: { $regex: search, $options: 'i' } }
                    ]
                };

                // If search is a valid MongoDB ID, also check the segment field
                if (search.match(/^[0-9a-fA-F]{24}$/)) {
                    searchCriteria["$or"].push({ segment: search });
                }

                queryArgs = { ...queryArgs, ...searchCriteria };
            }
            let reportrData = reportModel.find(queryArgs).sort({ createdAt: -1 }).lean()
            let totalCount = await reportModel.countDocuments(queryArgs).exec()
            if (page && pageSize) {
                reportrData = reportrData.skip((page - 1) * pageSize).limit(pageSize);
            }
            const data = await reportrData.exec();
            return { status: 200, message: "success", data: { totalCount, data: data } }

        } catch (error) {
            return { status: 400, message: error, data: {} }
        }
    },

    deleteReport: async ({ params }) => {
        try {
            let { id } = params
            let report = await reportModel.findOne({ _id: id });
            if (!report) {
                return { status: 200, message: "Report not found ", data: {} }
            }
            if (report.reportPath) {
                const reportPath = path.join(report.reportPath);
                if (fs.existsSync(reportPath)) {
                    fs.unlinkSync(reportPath);
                }
            }
            await reportModel.deleteOne({ _id: id });
            return { status: 200, message: "Report deleted successfully", data: {} }
        }
        catch (error) {
            return { status: 400, message: error, data: {} }
        }
    },
    updateReport: async ({ query, body, file }) => {
        try {
            let { id } = query
            console.log("=== UPDATE REPORT BODY ===", body);
            let { title, segment, reportType, planArray, description, youtubeUrl } = body
            let report = await reportModel.findOne({ _id: id });
            if (!report) {
                return { status: 200, message: "Report not found ", data: {} }
            }
            // Handle segment as array (stringified if form-data)
            let segmentIds = [];
            if (segment) {
                if (typeof segment === 'string') {
                    try {
                        if (segment.startsWith('[')) {
                            segmentIds = JSON.parse(segment);
                        } else {
                            segmentIds = [segment];
                        }
                    } catch (e) {
                        segmentIds = [segment];
                    }
                } else if (Array.isArray(segment)) {
                    segmentIds = segment;
                }

                // Fetch Segment Names
                const segmentsData = await segmentModel.find({ _id: { $in: segmentIds } }).select("segmentName");
                const segmentNames = segmentsData.map(s => s.segmentName);
                const validSegmentIds = segmentsData.map(s => s._id);

                report.segment = validSegmentIds;
                report.segmentName = segmentNames;
            }

            if (file) {
                if (report.reportPath) {
                    const filePath = path.join(report.reportPath);
                    if (fs.existsSync(filePath)) {
                        fs.unlinkSync(filePath);
                    }
                }
                report.reportPath = file.path;
                report.reportOriginalName = file.originalname;
                report.reportName = file.filename;
            } else if (body.removeFile === 'true') {
                const currentReportType = reportType || report.reportType || '';
                const isTradingCall = currentReportType.toLowerCase().includes('trading');
                if (!isTradingCall) {
                    return { status: 400, message: "A document file is required for research reports", data: {} };
                }
                if (report.reportPath) {
                    const filePath = path.join(report.reportPath);
                    if (fs.existsSync(filePath)) {
                        fs.unlinkSync(filePath);
                    }
                }
                report.reportPath = "";
                report.reportOriginalName = "";
                report.reportName = "";
            }
            if (title) report.title = title
            if (reportType) report.reportType = reportType
            if (description) report.description = description

            console.log("DEBUG: youtubeUrl in body:", body.youtubeUrl);
            console.log("DEBUG: Body keys in update:", Object.keys(body));

            // Explicit assignment with presence check
            if (Object.prototype.hasOwnProperty.call(body, 'youtubeUrl')) {
                const val = body.youtubeUrl ? body.youtubeUrl.toString().trim() : null;
                report.youtubeUrl = val === "" ? null : val;
            } else {
                console.log("WARNING: youtubeUrl missing from update payload");
            }
            console.log("DEBUG: newUpdate from body:", body.newUpdate);
            if (body.newUpdate && body.newUpdate.trim() !== '') {
                console.log("DEBUG: Pushing new update to report");
                if (!report.updates) report.updates = [];
                const updateStatus = detectUpdateStatus(body.newUpdate, body.newUpdateStatus || body.updateStatus);
                report.updates.push({
                    text: body.newUpdate.trim(),
                    status: updateStatus,
                    timestamp: new Date()
                });
                report.markModified('updates');
                console.log("DEBUG: Updates array length:", report.updates.length);
            } else {
                console.log("DEBUG: No new update to push");
            }


            if (planArray) {
                let parsedPlans = [];
                if (Array.isArray(planArray)) {
                    parsedPlans = planArray;
                } else if (typeof planArray === 'string') {
                    try {
                        if (planArray.trim().startsWith('[')) {
                            parsedPlans = JSON.parse(planArray);
                        } else {
                            parsedPlans = [planArray];
                        }
                    } catch (e) {
                        parsedPlans = [planArray];
                    }
                }
                report.planArray = parsedPlans;
            }
            if (report.publishedStatus === 'published' && !report.published_at) {
                report.published_at = Date.now();
            }
            report.updatedAt = new Date();
            await report.save();

            // Also update published_at if we are explicitly publishing a draft or it was already published but we want to bump it
            if (report.publishedStatus === 'published') {
                sendReportNotification(report, true);
            }

            return { status: 200, message: "Report updated successfully", data: { report } }
        }
        catch (error) {
            return { status: 400, message: error, data: {} }

        }
    },
    publishReportStatus: async ({ query, body, user: adminUser, req }) => {
        try {
            let { id } = query
            let { publishedStatus } = body
            let reportPublishedStatus = ''
            const report = await reportModel.findOne({ _id: id })
            if (!report) {
                return { status: 200, message: "Report not found ", data: {} }
            }
            if (publishedStatus == "draft") {
                // Ensure idempotency: Only publish if currently NOT published
                if (report.publishedStatus !== "published") {
                    report.publishedStatus = "published"
                    report.published_at = Date.now()
                    await report.save()

                    // Trigger Push Notification
                    sendReportNotification(report);

                    // --- COMPLIANCE LOG: Call Assignment to all entitled users ---
                    // Find all users entitled to this report and log for each
                    try {
                        const now = new Date();
                        const entitlements = await Entitlement.find({
                            resourceId: { $in: report.planArray },
                            type: 'PLAN',
                            status: 'ACTIVE',
                            startDate: { $lte: now },
                            $or: [{ endDate: null }, { endDate: { $gte: now } }]
                        }).select('userId').lean();

                        const uniqueUserIds = [...new Set(entitlements.map(e => e.userId.toString()))];
                        for (const userId of uniqueUserIds) {
                            logCallAssignment({
                                userId,
                                report,
                                performedBy: {
                                    id: adminUser?._id?.toString(),
                                    name: adminUser?.fullName || 'Admin',
                                    role: adminUser?.userType || 'ADMIN'
                                },
                                req
                            });
                        }
                    } catch (logErr) {
                        console.error('[ActivityLog] Failed logging call assignment:', logErr.message);
                    }
                }

                reportPublishedStatus = "published"
                return { status: 200, message: "Report published status updated successfully", data: { publishedStatus: "published" } }
            } else if (publishedStatus == "published") {
                report.publishedStatus = "draft"
                await report.save()
                reportPublishedStatus = "draft"
                return { status: 200, message: "Report published status updated successfully", data: { publishedStatus: "draft" } }
            }
        }
        catch (error) {
            return { status: 400, message: error, data: {} }
        }
    },

    createOrUpdateAutomatedTradingCall: async ({ body, headers }) => {
        try {
            const apiKey = headers['x-api-key'] || headers['authorization']?.replace('Bearer ', '');
            const expectedApiKey = process.env.AUTOMATED_API_KEY || 'default_secret_key';

            if (!apiKey || apiKey !== expectedApiKey) {
                return { status: 401, message: "Unauthorized. Invalid API Key.", data: {} };
            }

            const { symbol, exchange, side, entryPrice, stopLoss, targetPrice, segment, rawSignalId, isAppliedUpdate, updateText } = body;

            // 1. Check if report already exists for this signal
            if (rawSignalId) {
                const existingReport = await reportModel.findOne({ automatedSignalId: rawSignalId });
                if (existingReport) {
                    const text = updateText || `Trade Applied: ${side} ${symbol} call has been executed.`;
                    const updateStatus = detectUpdateStatus(text, body.newUpdateStatus || body.updateStatus || body.status);
                    existingReport.updates.push({ text, status: updateStatus, timestamp: new Date() });
                    existingReport.markModified('updates');
                    await existingReport.save();

                    // Trigger Push Notification for the update
                    sendReportNotification(existingReport, true);

                    return { status: 200, message: "Automated trading call updated successfully", data: { report: existingReport } };
                }
            }

            if (isAppliedUpdate) {
                return { status: 404, message: "Report not found for update", data: {} };
            }

            // 2. Resolve segment IDs dynamically by name (no hardcoded ObjectIds)
            const cleanSegment = (segment || '').toUpperCase();

            let segmentNamePatterns = [];
            if (cleanSegment === 'INTRADAY' || cleanSegment === 'DELIVERY') {
                segmentNamePatterns = [/equity/i, /cash/i];
            } else if (cleanSegment === 'FNO' || cleanSegment === 'FO') {
                segmentNamePatterns = [/future/i, /option/i, /derivative/i];
            } else {
                // Default fallback to equity/cash
                segmentNamePatterns = [/equity/i, /cash/i];
            }

            const segmentsData = await segmentModel.find({
                segmentStatus: 'active',
                $or: segmentNamePatterns.map(p => ({ segmentName: { $regex: p } })),
            }).select("segmentName");
            const segmentNames = segmentsData.map(s => s.segmentName);
            const validSegmentIds = segmentsData.map(s => s._id);

            if (validSegmentIds.length === 0) {
                console.warn(`[AutomatedReport] No matching segments found for cleanSegment="${cleanSegment}". Falling back to all active segments.`);
                const fallback = await segmentModel.find({ segmentStatus: 'active' }).select("segmentName").limit(1);
                if (fallback.length > 0) {
                    validSegmentIds.push(fallback[0]._id);
                    segmentNames.push(fallback[0].segmentName);
                }
            }

            // 3. Fetch all active plans
            const activePlans = await segmentsPlanModel.find({ planStatus: 'active' }).select('_id');
            const planIds = activePlans.map(p => p._id);

            // 4. Formulate title and description
            const title = `${side} ${symbol}`;
            const description = `${side} ${symbol} @ ${entryPrice} | SL: ${stopLoss} | TGT: ${targetPrice} (Exchange: ${exchange})`;

            const report = new reportModel({
                title: title,
                segment: validSegmentIds,
                segmentName: segmentNames,
                reportType: "Trading calls",
                planArray: planIds,
                description: description,
                reportPath: "",
                reportOriginalName: "",
                reportName: "",
                publishedStatus: "published",
                published_at: Date.now(),
                automatedSignalId: rawSignalId
            });

            await report.save();

            // Trigger Push Notification
            sendReportNotification(report);

            return { status: 200, message: "Automated trading call created successfully", data: { report } };
        } catch (error) {
            console.error("Error in createOrUpdateAutomatedTradingCall:", error);
            return { status: 400, message: error.message || error, data: {} };
        }
    },

    getLiveActivities: async () => {
        try {
            const reports = await reportModel.find({ publishedStatus: 'published' })
                .sort({ updatedAt: -1, createdAt: -1 })
                .limit(10)
                .lean();

            let latestTimestamp = 0;
            const activities = reports.map(r => {
                const hasUpdates = Array.isArray(r.updates) && r.updates.length > 0;
                const lastUpdate = hasUpdates ? r.updates[r.updates.length - 1] : null;
                const updateTime = lastUpdate?.timestamp ? new Date(lastUpdate.timestamp).getTime() : 0;
                const updatedTime = r.updatedAt ? new Date(r.updatedAt).getTime() : 0;
                const createdTime = r.createdAt ? new Date(r.createdAt).getTime() : 0;
                const itemTime = Math.max(updateTime, updatedTime, createdTime, 1);

                if (itemTime > latestTimestamp) {
                    latestTimestamp = itemTime;
                }

                return {
                    id: r._id.toString(),
                    reportId: r.reportId || '',
                    title: r.title || 'Untitled Research',
                    reportType: r.reportType || 'Trading calls',
                    segmentName: Array.isArray(r.segmentName) ? r.segmentName.join(', ') : (r.segmentName || ''),
                    description: r.description || '',
                    publishedStatus: r.publishedStatus,
                    latestUpdate: lastUpdate ? lastUpdate.text : null,
                    updatesCount: hasUpdates ? r.updates.length : 0,
                    timestamp: itemTime,
                    isAutomated: !!r.automatedSignalId,
                    createdAt: r.createdAt,
                    updatedAt: r.updatedAt
                };
            });

            // Activity is proceeding if the latest activity or update is within the last 15 minutes
            const now = Date.now();
            const fifteenMinutesAgo = now - (15 * 60 * 1000);
            const isProceeding = latestTimestamp >= fifteenMinutesAgo;

            return {
                status: 200,
                message: "Live research activities retrieved successfully",
                data: {
                    isProceeding,
                    latestTimestamp,
                    latestActivity: activities[0] || null,
                    activities
                }
            };
        } catch (error) {
            console.error("getLiveActivities Error:", error);
            return {
                status: 500,
                message: error.message || "Failed to fetch live activities",
                data: { isProceeding: false, latestTimestamp: 0, latestActivity: null, activities: [] }
            };
        }
    }

}
export default reportService;