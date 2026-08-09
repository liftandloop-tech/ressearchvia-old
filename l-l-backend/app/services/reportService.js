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
import notificationService from "./notificationService.js"
import devices from "../models/deviceModel.js";
import PaymentIntent from "../models/paymentIntentModel.js";
import { logCallAssignment } from "./activityLogService.js";

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

            title = isUpdate ? `🚨 Updated ${type} Call` : `🚨 New ${type} Call`;
            body = isUpdate ? `Update: ${report.title}` : report.title; // Assuming title contains the stock info "NIFTY..."
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
            console.log("DEBUG: Final report object before save:", {
                id: report._id,
                title: report.title,
                youtubeUrl: report.youtubeUrl
            });
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

            // Admin Override (Chunk 9.5) - Case-insensitive check
            const userType = (req.user?.userType || '').toLowerCase();
            const isAdmin = ['admin', 'super_admin', 'researcher', 'director'].includes(userType);

            if (!hasLifetimeOrActive && !isAdmin) {
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

            if (newStartDate && newEndDate == null) {
                queryArg.createdAt = { ...queryArg.createdAt, $gte: newStartDate };
            }
            if (newEndDate && newStartDate == null) {
                queryArg.createdAt = { ...queryArg.createdAt, $lte: newEndDate };
            }
            if (newStartDate && newEndDate) {
                queryArg.createdAt = { $gte: newStartDate, $lte: newEndDate }
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
                return { status: 200, message: "No active subscriptions found.", data: { reports: [] } };
            }

            // 3. Query Reports: Match specific allowed combinations
            // Combine strict user visibility filters
            const finalQuery = {
                ...queryArg,
                publishedStatus: 'published',
                $or: orConditions
            };

            // Fetch ALL reports first (we'll paginate after filtering locked ones)
            const allReports = await reportModel.find(finalQuery)
                .sort({ published_at: -1, createdAt: -1 })
                .exec();

            // 4. Add metadata for blur overlay (reports published before plan start date)
            // Create a map of plan/segment start dates for quick lookup
            const planStartDates = new Map();

            // Add entitlement start dates - USE SEGMENT IDs, not plan IDs
            activeEntitlements.forEach(ent => {
                const segmentId = ent.resourceId?.segmentsId?.toString();
                if (segmentId && ent.startDate) {
                    // Store by segment ID, keep earliest date if multiple plans in same segment
                    const existing = planStartDates.get(segmentId);
                    if (!existing || ent.startDate < existing) {
                        planStartDates.set(segmentId, ent.startDate);
                    }
                }
            });

            // Add legacy segment start dates
            activeSegments.forEach(seg => {
                const segId = seg.segmentId?.toString();
                if (segId && seg.purchaseDate) {
                    planStartDates.set(segId, seg.purchaseDate);
                }
            });

            console.log(`[DEBUG] Active Entitlements:`, activeEntitlements.map(e => ({ planId: e.resourceId?._id?.toString(), segmentId: e.resourceId?.segmentsId?.toString(), startDate: e.startDate })));
            console.log(`[DEBUG] Active Segments:`, activeSegments.map(s => ({ segmentId: s.segmentId?.toString(), purchaseDate: s.purchaseDate })));
            console.log(`[DEBUG] Plan Start Dates Map:`, Array.from(planStartDates.entries()).map(([id, date]) => ({ id, date: date?.toISOString ? date.toISOString() : date })));
            console.log(`[DEBUG] Total reports found: ${allReports.length}`);

            // Enhance ALL reports with access metadata
            const enhancedReports = allReports.map(report => {
                const reportObj = report.toObject();
                const reportPublishedDate = new Date(report.published_at || report.createdAt);

                // Find the earliest segment start date that covers this report
                let earliestPlanStart = null;

                // Check against segment IDs (NOT plan IDs)
                if (report.segment && report.segment.length > 0) {
                    report.segment.forEach(segId => {
                        const segStart = planStartDates.get(segId.toString());
                        if (segStart && (!earliestPlanStart || new Date(segStart) < new Date(earliestPlanStart))) {
                            earliestPlanStart = segStart;
                        }
                    });
                }

                // Determine if report should be locked (blurred)
                // Report is locked if published BEFORE user's plan started
                const isLocked = earliestPlanStart && reportPublishedDate < new Date(earliestPlanStart);

                // Debug logging for first few reports
                if (allReports.indexOf(report) < 5) {
                    console.log(`[DEBUG] Report "${report.title}":`);
                    console.log(`  - Published: ${reportPublishedDate.toISOString()}`);
                    console.log(`  - Plan Array:`, report.planArray?.map(p => p.toString()));
                    console.log(`  - Segment Array:`, report.segment?.map(s => s.toString()));
                    console.log(`  - Plan Start: ${earliestPlanStart ? new Date(earliestPlanStart).toISOString() : 'N/A'}`);
                    console.log(`  - Is Locked: ${isLocked}`);
                }

                return {
                    ...reportObj,
                    accessMetadata: {
                        isLocked: !!isLocked,
                        planStartDate: earliestPlanStart,
                        reportPublishedDate: reportPublishedDate
                    }
                };
            });

            // 5. Limit locked reports to maximum 10 GLOBALLY
            const unlockedReports = enhancedReports.filter(r => !r.accessMetadata.isLocked);
            const lockedReports = enhancedReports.filter(r => r.accessMetadata.isLocked);

            console.log(`[DEBUG] Filtering Summary:`);
            console.log(`  - Total enhanced reports: ${enhancedReports.length}`);
            console.log(`  - Unlocked reports: ${unlockedReports.length}`);
            console.log(`  - Locked reports: ${lockedReports.length}`);
            console.log(`  - Locked reports (first 10 titles):`, lockedReports.slice(0, 10).map(r => r.title));

            // Take only first 10 locked reports (they're already sorted newest first)
            const limitedLockedReports = lockedReports.slice(0, 10);

            console.log(`  - Limited locked reports: ${limitedLockedReports.length}`);

            // Combine all unlocked + limited locked, maintain sort order
            const allFilteredReports = [...unlockedReports, ...limitedLockedReports]
                .sort((a, b) => {
                    const dateA = a.accessMetadata.reportPublishedDate || a.createdAt;
                    const dateB = b.accessMetadata.reportPublishedDate || b.createdAt;
                    return new Date(dateB) - new Date(dateA); // Newest first
                });

            console.log(`  - Total filtered reports (before pagination): ${allFilteredReports.length}`);
            console.log(`  - Filtered reports locked status:`, allFilteredReports.map(r => ({ title: r.title, locked: r.accessMetadata.isLocked })));

            // 6. NOW apply pagination to the filtered list
            const startIndex = (page - 1) * pageSize;
            const endIndex = startIndex + pageSize;
            const finalReports = allFilteredReports.slice(startIndex, endIndex);

            // Should we return totalCount? Frontend handles simple list, but maybe not vital.
            // Keeping response structure consistent with previous userReportList: returning { reports: [...] }
            // Note: reportList returns { totalCount, reportData }
            // userReportList usually returned just { reports } inside data.

            if (finalReports && finalReports.length > 0) {
                return { status: 200, message: "User Report List", data: { reports: finalReports } }
            } else {
                return { status: 200, message: "Report Not Found", data: { reports: [] } }
            }
        } catch (error) {
            console.error("userReportList Error:", error);
            return { status: 400, message: error.message, data: {} }

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

            if (newStartDate && newEndDate == null) {
                queryArgs.createdAt = { $gte: newStartDate.toISOString() };
            }
            if (newEndDate && newStartDate == null) {
                queryArgs.createdAt = { $lte: newEndDate.toISOString() };
            }
            if (newStartDate && newEndDate) {
                queryArgs.createdAt = { $gte: newStartDate.toISOString(), $lte: newEndDate.toISOString() }
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
                report.updates.push({ text: body.newUpdate.trim(), timestamp: new Date() });
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
                    existingReport.updates.push({ text, timestamp: new Date() });
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

            // 2. Resolve segment IDs and segment names
            let targetSegmentIds = [];
            const cleanSegment = (segment || '').toUpperCase();

            if (cleanSegment === 'INTRADAY' || cleanSegment === 'DELIVERY') {
                targetSegmentIds = ['6990582719e0550821bb9436']; // EQUITY CASH
            } else if (cleanSegment === 'FNO' || cleanSegment === 'FO') {
                targetSegmentIds = [
                    '6990583319e0550821bb943b', // FUTURE DERIVATIVES
                    '6990584819e0550821bb9447', // STOCK OPTION
                    '6990585219e0550821bb945a'  // INDEX OPTION
                ];
            } else {
                // Default fallback if unknown segment
                targetSegmentIds = ['6990582719e0550821bb9436'];
            }

            const segmentsData = await segmentModel.find({ _id: { $in: targetSegmentIds } }).select("segmentName");
            const segmentNames = segmentsData.map(s => s.segmentName);
            const validSegmentIds = segmentsData.map(s => s._id);

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
    }

}
export default reportService;