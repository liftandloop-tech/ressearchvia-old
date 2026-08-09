import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import Entitlement from "./app/models/entitlementModel.js";
import planPurchaseModel from "./app/models/planPurchaseModel.js";

async function run() {
    await mongoose.connect(process.env.DB_URL);

    // Find a recently suspended plan
    const suspendedPlans = await planPurchaseModel.find({ status: 'suspended' }).sort({ updatedAt: -1 }).limit(5).lean();
    console.log("Suspended Plans:", JSON.stringify(suspendedPlans, null, 2));

    for (const p of suspendedPlans) {
        // See if there's any active entitlement for this user
        const ents = await Entitlement.find({ userId: p.userId, type: 'PLAN', status: 'ACTIVE' }).lean();
        if (ents.length > 0) {
            console.log(`User ${p.userId} still has ACTIVE entitlements:`, JSON.stringify(ents, null, 2));
        }
    }

    process.exit(0);
}
run();
