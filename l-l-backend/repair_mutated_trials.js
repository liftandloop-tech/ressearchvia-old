import 'dotenv/config';
import MONGO_CLIENT from './app/config/db.config.js';
import Entitlement from './app/models/entitlementModel.js';
import PaymentIntent from './app/models/paymentIntentModel.js';
import User from './app/models/userModel.js';

async function repairMutatedTrials() {
  console.log("Connecting to MongoDB...");
  await MONGO_CLIENT();
  console.log("Connected successfully. Scanning for hijacked trials and unseparated plans...\n");

  // 1. Find all paid PLAN PaymentIntents
  const planIntents = await PaymentIntent.find({
    purchaseType: 'PLAN',
    status: { $in: ['PAID', 'APPROVED', 'PARTIAL-PAID'] }
  }).lean();

  console.log(`Found ${planIntents.length} total paid/approved PLAN PaymentIntents.`);

  let repairedCount = 0;
  let alreadyCleanCount = 0;

  for (const pi of planIntents) {
    const userId = pi.userId;

    // Check if user already has an active, separate paid PLAN entitlement linked to this intent
    const existingPaidEnt = await Entitlement.findOne({
      userId,
      type: 'PLAN',
      sourceRefId: pi._id.toString(),
      grantReason: { $ne: 'REGISTRATION_TRIAL' }
    });

    if (existingPaidEnt) {
      alreadyCleanCount++;
      // Still ensure any lingering registration trial for this user is marked REVOKED
      await Entitlement.updateMany({
        userId,
        type: 'PLAN',
        grantReason: 'REGISTRATION_TRIAL',
        status: 'ACTIVE'
      }, {
        $set: { status: 'REVOKED', remarks: 'Superseded by paid plan' }
      });
      continue;
    }

    // User is missing a separate paid plan entitlement!
    // Check if the user's trial was hijacked
    const regIntent = await PaymentIntent.findOne({
      userId,
      purchaseType: 'REGISTRATION'
    }).lean();

    const trialEnt = await Entitlement.findOne({
      userId,
      type: 'PLAN',
      $or: [
        { grantReason: 'REGISTRATION_TRIAL' },
        { sourceRefId: pi._id.toString() },
        ...(regIntent ? [{ sourceRefId: regIntent._id.toString() }] : [])
      ]
    }).sort({ createdAt: 1 });

    if (trialEnt) {
      console.log(`[REPAIR] User ${userId}: untangling trial ${trialEnt._id} and creating separate paid plan`);

      // Reset trial document
      const trialStart = new Date(trialEnt.startDate || trialEnt.createdAt || Date.now());
      const trialEnd = new Date(trialStart.getTime() + 5 * 24 * 60 * 60 * 1000);

      trialEnt.grantReason = 'REGISTRATION_TRIAL';
      trialEnt.status = 'REVOKED';
      trialEnt.remarks = 'Superseded by paid plan';
      trialEnt.endDate = trialEnd;
      if (regIntent) {
        trialEnt.sourceRefId = regIntent._id.toString();
      }
      await trialEnt.save();

      // Create brand new separate PAID PLAN Entitlement
      const newPaidPlan = new Entitlement({
        userId,
        type: 'PLAN',
        resourceId: pi.planId || pi.preferredPlanId || trialEnt.resourceId,
        segmentId: pi.preferredSegmentId || trialEnt.segmentId || null,
        startDate: pi.serviceStartDate || pi.createdAt || new Date(),
        endDate: pi.currentExpiryDate,
        status: 'ACTIVE',
        grantedBy: 'ADMIN',
        grantReason: 'OFFLINE_PAYMENT',
        sourceRefId: pi._id.toString(),
        remarks: 'Restored separate paid plan entity'
      });
      await newPaidPlan.save();

      repairedCount++;
    } else {
      // No existing trial at all, just create the missing paid plan entitlement
      const newPaidPlan = new Entitlement({
        userId,
        type: 'PLAN',
        resourceId: pi.planId || pi.preferredPlanId,
        segmentId: pi.preferredSegmentId || null,
        startDate: pi.serviceStartDate || pi.createdAt || new Date(),
        endDate: pi.currentExpiryDate,
        status: 'ACTIVE',
        grantedBy: 'ADMIN',
        grantReason: 'OFFLINE_PAYMENT',
        sourceRefId: pi._id.toString(),
        remarks: 'Created missing paid plan entitlement from Payment Intent'
      });
      await newPaidPlan.save();
      repairedCount++;
    }
  }

  // 2. Extra safety pass: find any remaining active REGISTRATION_TRIAL that points to a PLAN intent
  const lingeringHijacks = await Entitlement.find({
    grantReason: 'REGISTRATION_TRIAL',
    status: 'ACTIVE'
  });

  for (const ent of lingeringHijacks) {
    const linkedPi = await PaymentIntent.findById(ent.sourceRefId).lean();
    if (linkedPi && linkedPi.purchaseType === 'PLAN') {
      console.log(`[EXTRA PASS] Fixing lingering hijacked trial ${ent._id} for user ${ent.userId}`);
      ent.status = 'REVOKED';
      ent.remarks = 'Superseded by paid plan';
      await ent.save();
    }
  }

  console.log("\n================ REPAIR SUMMARY ================");
  console.log(`Already Clean Users: ${alreadyCleanCount}`);
  console.log(`Repaired Users:        ${repairedCount}`);
  console.log("All trials and paid plans are now separate entities.");
  console.log("================================================\n");

  process.exit(0);
}

repairMutatedTrials().catch(err => {
  console.error("Repair failed:", err);
  process.exit(1);
});
