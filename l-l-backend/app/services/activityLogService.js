import UserActivityLog from "../models/userActivityLogModel.js";
import AuditLog from "../models/auditLogModel.js";

/**
 * Audit Trail Logger for sensitive administrative and security operations.
 * Immutable, fire-and-forget safe.
 */
export const logAuditTrail = async ({
    actorUserId,
    action,
    resourceType,
    resourceId = null,
    oldValue = null,
    newValue = null,
    metadata = {},
    req = null,
    correlationId = null,
    success = true
}) => {
    try {
        if (!actorUserId) return;
        await AuditLog.create({
            actorUserId,
            action,
            resourceType,
            resourceId,
            oldValue,
            newValue,
            metadata,
            ipAddress: req ? (req.headers?.['x-forwarded-for']?.split(',')[0]?.trim() || req.socket?.remoteAddress || req.ip) : null,
            userAgent: req ? req.headers?.['user-agent'] : null,
            correlationId: correlationId || req?.headers?.['x-correlation-id'] || null,
            success
        });
    } catch (err) {
        console.error(`[AuditLog] Failed to record audit entry (${action}):`, err);
    }
};

/**
 * ActivityLogService — Compliance-grade logger.
 * All methods are fire-and-forget safe: they catch their own errors
 * so they NEVER break the calling flow.
 *
 * Severity guide:
 *   INFO     — routine, expected events (login, app open, profile view)
 *   WARNING  — admin-initiated changes that affect user access (plan changes, profile edits)
 *   SECURITY — access anomalies (new device login, suspended account access)
 *   CRITICAL — high-risk events (payment changes, subscription revoke, account suspension)
 */

/** Extract client IP address from a request object */
const getIp = (req) => {
    if (!req) return null;
    return (
        req.headers?.['x-forwarded-for']?.split(',')[0]?.trim() ||
        req.socket?.remoteAddress ||
        req.ip ||
        null
    );
};

/**
 * Core logger — always resolves, never throws.
 */
export const logActivity = async ({
    userId,
    eventType,
    severity = 'INFO',
    description,
    req = null,
    deviceId = null,
    platform = null,
    performedBy = { id: null, name: null, role: 'SYSTEM' },
    metadata = {}
}) => {
    try {
        await UserActivityLog.create({
            userId,
            eventType,
            severity,
            description,
            eventTimestamp: new Date(),
            ipAddress: getIp(req),
            deviceId,
            platform,
            performedBy,
            metadata
        });
    } catch (err) {
        console.error(`[ActivityLog] Failed to write log (${eventType}) for user ${userId}:`, err);
    }
};

/* ======================================================================
   Shorthand helpers
   ====================================================================== */

/** USER_LOGIN / NEW_DEVICE_LOGIN */
export const logUserLogin = async ({ user, req, deviceId, platform, isNewDevice = false }) => {
    await logActivity({
        userId: user._id,
        eventType: isNewDevice ? 'NEW_DEVICE_LOGIN' : 'USER_LOGIN',
        severity: isNewDevice ? 'SECURITY' : 'INFO',
        description: isNewDevice
            ? `⚠️ User logged in on a NEW device (${platform || 'unknown'}) — Device: ${deviceId || 'N/A'}`
            : `User logged in via MPIN on ${platform || 'unknown'}`,
        req,
        deviceId,
        platform,
        performedBy: { id: user._id.toString(), name: user.fullName, role: 'USER' },
        metadata: { phone: user.phone, deviceId: deviceId || null, platform: platform || null }
    });
};

/** APP_SESSION_START (fires on every token refresh = every app open) */
export const logAppSessionStart = async ({ user, req, deviceId, platform }) => {
    await logActivity({
        userId: user._id,
        eventType: 'APP_SESSION_START',
        severity: 'INFO',
        description: `App opened / session resumed on ${platform || 'unknown'}`,
        req,
        deviceId,
        platform,
        performedBy: { id: user._id.toString(), name: user.fullName, role: 'USER' },
        metadata: { deviceId: deviceId || null }
    });
};

/** USER_LOGOUT */
export const logUserLogout = async ({ user, req, deviceId }) => {
    await logActivity({
        userId: user._id,
        eventType: 'USER_LOGOUT',
        severity: 'INFO',
        description: `User logged out`,
        req,
        deviceId,
        performedBy: { id: user._id.toString(), name: user.fullName, role: 'USER' }
    });
};

/** MANAGER_ASSIGNED */
export const logManagerAssigned = async ({ userId, manager, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'MANAGER_ASSIGNED',
        severity: 'WARNING',
        description: `Manager "${manager.name}" (Staff ID: ${manager.staffId || manager.id}) assigned to user`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: {
            managerId: manager.id || manager._id?.toString(),
            managerName: manager.name,
            managerStaffId: manager.staffId
        }
    });
};

/** ADMIN_PROFILE_EDIT — admin changed user profile fields */
export const logAdminProfileEdit = async ({ userId, changedFields, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'ADMIN_PROFILE_EDIT',
        severity: 'WARNING',
        description: `Admin edited profile: [${changedFields.join(', ')}]`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { changedFields }
    });
};

/** CALL_ASSIGNED — a trading call / research report was published and assigned */
export const logCallAssignment = async ({ userId, report, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'CALL_ASSIGNED',
        severity: 'INFO',
        description: `${report.reportType === 'Trading calls' ? '🚨 Trading Call' : '📄 Report'} published: "${report.title}"`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: {
            reportId: report._id?.toString(),
            reportType: report.reportType,
            title: report.title
        }
    });
};

/** PAYMENT_APPROVED */
export const logPaymentApproved = async ({ userId, amount, paymentId, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'PAYMENT_APPROVED',
        severity: 'CRITICAL',
        description: `💰 Payment of ₹${amount} APPROVED (Ref: ${paymentId})`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { amount, paymentId }
    });
};

/** PAYMENT_REJECTED */
export const logPaymentRejected = async ({ userId, amount, paymentId, reason, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'PAYMENT_REJECTED',
        severity: 'CRITICAL',
        description: `❌ Payment of ₹${amount} REJECTED — Reason: ${reason || 'N/A'} (Ref: ${paymentId})`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { amount, paymentId, reason }
    });
};

/** SUBSCRIPTION_EXTENDED */
export const logSubscriptionExtended = async ({ userId, days, planName, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'SUBSCRIPTION_EXTENDED',
        severity: 'WARNING',
        description: `Subscription extended by ${days} days${planName ? ` (${planName})` : ''}`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { days, planName }
    });
};

/** SUBSCRIPTION_REVOKED */
export const logSubscriptionRevoked = async ({ userId, planName, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'SUBSCRIPTION_REVOKED',
        severity: 'CRITICAL',
        description: `🚫 Subscription REVOKED${planName ? ` (${planName})` : ''}`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { planName }
    });
};

/** SUBSCRIPTION_SUSPENDED */
export const logSubscriptionSuspended = async ({ userId, planId, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'SUBSCRIPTION_SUSPENDED',
        severity: 'CRITICAL',
        description: `⏸️ Subscription SUSPENDED by admin`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { planId }
    });
};

/** SUBSCRIPTION_ACTIVATED */
export const logSubscriptionActivated = async ({ userId, planId, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'SUBSCRIPTION_ACTIVATED',
        severity: 'WARNING',
        description: `✅ Subscription ACTIVATED by admin`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { planId }
    });
};

/** PLAN_CREATED */
export const logPlanCreated = async ({ userId, packageName, amount, days, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'PLAN_CREATED',
        severity: 'WARNING',
        description: `Plan "${packageName}" manually created — ₹${amount || 'N/A'} for ${days || 'N/A'} days`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { packageName, amount, days }
    });
};

/** PLAN_TOPUP */
export const logPlanTopup = async ({ userId, topUpAmount, additionalDays, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'PLAN_TOPUP',
        severity: 'WARNING',
        description: `Partial plan top-up: ₹${topUpAmount} (+${additionalDays} days)`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { topUpAmount, additionalDays }
    });
};

/** KYC_STATUS_CHANGED */
export const logKycStatusChange = async ({ user, fromStatus, toStatus, changedBy, req }) => {
    await logActivity({
        userId: user._id,
        eventType: 'KYC_STATUS_CHANGED',
        severity: toStatus === 'REJECTED' ? 'CRITICAL' : 'WARNING',
        description: `KYC status changed: "${fromStatus}" → "${toStatus}" by ${changedBy?.role || 'ADMIN'}`,
        req,
        performedBy: {
            id: changedBy?.id || null,
            name: changedBy?.name || 'Admin',
            role: changedBy?.role || 'ADMIN'
        },
        metadata: { fromStatus, toStatus }
    });
};

/** ACCOUNT_SUSPENDED */
export const logAccountSuspended = async ({ userId, reason, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'ACCOUNT_SUSPENDED',
        severity: 'CRITICAL',
        description: `🔒 User account SUSPENDED — Reason: ${reason || 'N/A'}`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: { reason }
    });
};

/**
 * Fetch activity logs for a user with optional filters.
 * Returns newest-first.
 */
export const getActivityLogs = async ({ userId, eventTypes = [], severities = [], limit = 500 }) => {
    const filter = { userId };
    if (eventTypes.length > 0) {
        filter.eventType = { $in: eventTypes };
    }
    if (severities.length > 0) {
        filter.severity = { $in: severities };
    }
    return await UserActivityLog.find(filter)
        .sort({ eventTimestamp: -1 })
        .limit(limit)
        .lean();
};

/** SUBSCRIPTION_METADATA_UPDATED */
export const logSubscriptionMetadataUpdate = async ({ userId, description, metadata, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'SUBSCRIPTION_METADATA_UPDATED',
        severity: 'WARNING',
        description: description || `Admin updated subscription metadata`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: metadata || {}
    });
};

/** UPDATE_PAYMENT_DISCOUNT */
export const logUpdatePaymentDiscount = async ({ userId, paymentIntentId, oldDiscount, newDiscount, originalPrice, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'UPDATE_PAYMENT_DISCOUNT',
        severity: 'WARNING',
        description: `Admin updated payment discount to ₹${newDiscount} (Original: ₹${originalPrice})`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        },
        metadata: {
            paymentIntentId,
            oldDiscount,
            newDiscount,
            originalPrice
        }
    });
};


/** TEMP_PIN_GENERATED */
export const logTempPinGenerated = async ({ userId, performedBy, req }) => {
    await logActivity({
        userId,
        eventType: 'TEMP_PIN_GENERATED',
        severity: 'SECURITY',
        description: `Admin generated a TEMPORARY PIN for user login`,
        req,
        performedBy: {
            id: performedBy?.id || null,
            name: performedBy?.name || 'Admin',
            role: performedBy?.role || 'ADMIN'
        }
    });
};

/** ALIAS_LOGIN */
export const logAliasLogin = async ({ user, req, deviceId, platform }) => {
    await logActivity({
        userId: user._id,
        eventType: 'ALIAS_LOGIN',
        severity: 'SECURITY',
        description: `Admin/Alias login performed via one-time temporary PIN`,
        req,
        deviceId,
        platform,
        performedBy: { id: user._id.toString(), name: user.fullName, role: 'USER' }
    });
};
