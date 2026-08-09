import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import Entitlement from "./app/models/entitlementModel.js";
import reports from "./app/models/reportsModel.js";
import userActiveSegmentModel from "./app/models/userActiveSegmentsModel.js";
import segmentsPayment from "./app/models/segmentsPaymentModel.js";
import users from "./app/models/userModel.js";

async function run() {
    await mongoose.connect(process.env.DB_URL);
    
    // Get a user who has an active plan
    const someEntitlement = await Entitlement.findOne({ type: 'PLAN', status: 'ACTIVE' });
    if (!someEntitlement) {
        console.log("No active plans found for ANY user.");
        process.exit(0);
    }
    const id = someEntitlement.userId.toString();
    console.log("Testing with user:", id);

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

    const activeSegments = await userActiveSegmentModel.find({
        userId: id,
        isActive: true,
        expiryDate: { $gte: now }
    });

    const legacyPayments = await segmentsPayment.find({
        userId: id,
        paymentStatus: 'paid',
        expiryDate: { $gte: now }
    });

    const orConditions = [];
    const segmentsWithPlan = new Set();

    activeEntitlements.forEach(e => {
        const planId = e.resourceId?._id || e.resourceId;
        const segmentId = e.segmentId || e.resourceId?.segmentsId;

        if (planId && segmentId) {
            orConditions.push({ planArray: planId, segment: segmentId });
            segmentsWithPlan.add(segmentId.toString());
        } else if (planId) {
            orConditions.push({ planArray: planId });
        } else if (segmentId) {
            orConditions.push({ segment: segmentId });
            segmentsWithPlan.add(segmentId.toString());
        }
    });

    legacyPayments.forEach(p => {
        if (p.segmentPlanId && p.segmentId) {
            orConditions.push({ planArray: p.segmentPlanId, segment: p.segmentId });
            segmentsWithPlan.add(p.segmentId.toString());
        }
    });

    activeSegments.forEach(s => {
        if (s.segmentId && !segmentsWithPlan.has(s.segmentId.toString())) {
            orConditions.push({ segment: s.segmentId });
        }
    });

    console.log("orConditions generated:", JSON.stringify(orConditions, null, 2));

    const finalQuery = {
        publishedStatus: 'published',
        $or: orConditions
    };

    const allReports = await reports.find(finalQuery).select('title planArray segment').limit(5);
    console.log("Sample Reports User Will See:", JSON.stringify(allReports, null, 2));

    process.exit(0);
}
run();
