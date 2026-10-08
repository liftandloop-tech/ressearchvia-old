import Entitlement from "../models/entitlementModel.js";
import User from "../models/userModel.js";

/**
 * ENTITLEMENT SERVICE
 * Single source of truth for granting and checking access.
 */

export const grantEntitlement = async ({
    userId,
    type, // "REGISTRATION" | "PLAN"
    resourceId = null, // planId or null
    segmentId = null, // segmentId or null
    days = 0, // Duration in days
    isLifetime = false,
    grantedBy, // "SYSTEM" | "ADMIN"
    grantReason, // "ONLINE_PAYMENT" | "OFFLINE_PAYMENT" | "MANUAL"
    sourceRefId = null,
    startDate: customStartDate = null,
    remarks = null,
    session = null // Support for transactions
}) => {
    const now = new Date();
    let startDate = customStartDate ? new Date(customStartDate) : now;
    let newEndDate = null;

    // 1. If granting a paid plan, revoke any active REGISTRATION_TRIAL entitlements for this user
    let regIntentIds = [];
    if (type === 'PLAN' && grantReason !== 'REGISTRATION_TRIAL') {
        try {
            const PaymentIntent = (await import("../models/paymentIntentModel.js")).default;
            const regIntents = await PaymentIntent.find({
                userId,
                purchaseType: 'REGISTRATION'
            }).select('_id').session(session).lean();
            regIntentIds = regIntents.map(r => r._id.toString());
        } catch (e) {
            // fallback
        }

        const revokeConditions = [{ grantReason: 'REGISTRATION_TRIAL' }];
        if (regIntentIds.length > 0) {
            revokeConditions.push({ sourceRefId: { $in: regIntentIds } });
        }

        await Entitlement.updateMany({
            userId,
            type: 'PLAN',
            status: 'ACTIVE',
            $or: revokeConditions
        }, {
            $set: { status: 'REVOKED', remarks: 'Superseded by paid plan' }
        }).session(session);
    }

    // 2. Check for existing active entitlement to extend (Stacking)
    // For PLAN type, search for existing non-trial plan + SAME segment.
    const stackingQuery = {
        userId,
        type,
        resourceId: resourceId || undefined,
        segmentId: segmentId || undefined,
        status: 'ACTIVE',
        grantReason: grantReason === 'REGISTRATION_TRIAL' ? 'REGISTRATION_TRIAL' : { $ne: 'REGISTRATION_TRIAL' },
        $or: [
            { endDate: null }, // Existing Lifetime
            { endDate: { $gte: now } } // Existing Active Term
        ]
    };

    if (type === 'PLAN' && grantReason !== 'REGISTRATION_TRIAL' && regIntentIds.length > 0) {
        stackingQuery.sourceRefId = { $nin: regIntentIds };
    }

    const existingEntitlement = await Entitlement.findOne(stackingQuery).session(session).sort({ endDate: -1 });

    if (existingEntitlement) {
        if (isLifetime) {
            existingEntitlement.endDate = null;
            existingEntitlement.grantReason = grantReason;
            existingEntitlement.sourceRefId = sourceRefId;
            if (remarks) existingEntitlement.remarks = remarks;
            await existingEntitlement.save({ session });
            return existingEntitlement;
        }

        if (existingEntitlement.endDate) {
            const currentEndDate = new Date(existingEntitlement.endDate);
            const extendedDate = new Date(currentEndDate);
            extendedDate.setDate(extendedDate.getDate() + days);
            newEndDate = extendedDate;

            existingEntitlement.endDate = newEndDate;
            existingEntitlement.grantReason = grantReason;
            existingEntitlement.sourceRefId = sourceRefId;
            if (remarks) existingEntitlement.remarks = remarks;
            await existingEntitlement.save({ session });
            return existingEntitlement;
        } else {
            return existingEntitlement;
        }
    }

    // 2. No existing active entitlement, create NEW.
    if (!isLifetime) {
        if (days > 0) {
            newEndDate = new Date(startDate);
            newEndDate.setDate(newEndDate.getDate() + days);
        } else {
            throw new Error("Duration required for non-lifetime entitlement");
        }
    }

    const entitlement = new Entitlement({
        userId,
        type,
        resourceId,
        segmentId,
        startDate,
        endDate: newEndDate,
        status: 'ACTIVE',
        grantedBy,
        grantReason,
        sourceRefId,
        remarks: remarks || ""
    });

    await entitlement.save({ session });
    return entitlement;
};

export const hasActiveRegistration = async (userId) => {
    const today = new Date();
    const entitlement = await Entitlement.findOne({
        userId,
        type: 'REGISTRATION',
        status: 'ACTIVE',
        startDate: { $lte: today },
        $or: [
            { endDate: null },
            { endDate: { $gte: today } }
        ]
    });
    return !!entitlement;
};

export const hasActivePlan = async (userId, planId, segmentId) => {
    const today = new Date();
    const query = {
        userId,
        type: 'PLAN',
        resourceId: planId,
        status: 'ACTIVE',
        startDate: { $lte: today },
        $or: [
            { endDate: null },
            { endDate: { $gte: today } }
        ]
    };
    if (segmentId) query.segmentId = segmentId;

    const entitlement = await Entitlement.findOne(query);
    return !!entitlement;
};

export const hasActiveSegment = async (userId, segmentId) => {
    const today = new Date();
    const entitlement = await Entitlement.findOne({
        userId,
        type: 'PLAN',
        segmentId: segmentId,
        status: 'ACTIVE',
        startDate: { $lte: today },
        $or: [
            { endDate: null },
            { endDate: { $gte: today } }
        ]
    });
    return !!entitlement;
};

import userActiveSegmentModel from "../models/userActiveSegmentsModel.js";

export const hasAnyActivePlan = async (userId) => {
    const today = new Date();

    // 1. Check Entitlements (New System)
    const entitlement = await Entitlement.findOne({
        userId,
        type: 'PLAN',
        status: 'ACTIVE',
        startDate: { $lte: today },
        $or: [
            { endDate: null }, // Lifetime
            { endDate: { $gte: today } }
        ]
    });

    if (entitlement) return true;

    // 2. Check Legacy Active Segments (Fallback)
    // Many existing users only have this record.
    const legacyPlan = await userActiveSegmentModel.findOne({
        userId,
        isActive: true,
        expiryDate: { $gte: today }
    });

    return !!legacyPlan;
};

// Admin helper: Revoke
export const revokeEntitlement = async (entitlementId, adminId) => {
    return await Entitlement.findByIdAndUpdate(entitlementId, {
        status: 'REVOKED'
    });
}
