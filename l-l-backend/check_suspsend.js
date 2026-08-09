import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import Entitlement from "./app/models/entitlementModel.js";
import planPurchaseModel from "./app/models/planPurchaseModel.js";
import segmentsPaymentModel from "./app/models/segmentsPaymentModel.js";
import userActiveSegmentModel from "./app/models/userActiveSegmentsModel.js";

async function run() {
    await mongoose.connect(process.env.DB_URL);

    // Find latest suspended plan
    const suspendedPlans = await planPurchaseModel.find({ status: 'suspended' }).sort({ updatedAt: -1 }).limit(1).lean();
    if(suspendedPlans.length === 0) {
        console.log("No suspended plans.");
        return process.exit(0);
    }
    const p = suspendedPlans[0];
    console.log("Latest suspended planPurchase:", JSON.stringify(p, null, 2));

    const ents = await Entitlement.find({ userId: p.userId, type: 'PLAN' }).lean();
    console.log(`Entitlements for user ${p.userId}:`, JSON.stringify(ents, null, 2));

    const activeSegs = await userActiveSegmentModel.find({ userId: p.userId, isActive: true }).lean();
    console.log(`userActiveSegmentModel active for user ${p.userId}:`, JSON.stringify(activeSegs, null, 2));

    const segPays = await segmentsPaymentModel.find({ userId: p.userId, paymentStatus: 'paid' }).lean();
    console.log(`segmentsPaymentModel paid for user ${p.userId}:`, JSON.stringify(segPays, null, 2));

    process.exit(0);
}
run();
