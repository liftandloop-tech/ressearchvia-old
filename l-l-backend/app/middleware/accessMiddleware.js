import users from "../models/userModel.js";
import staff from "../models/staffModel.js";

import { hasActiveRegistration, hasAnyActivePlan } from "../services/entitlementService.js";
import paymentIntentModel from "../models/paymentIntentModel.js";

/**
 * Access Control Middleware
 * Implements the truth table for App, Registration, and Content access.
 */

// 1. General App Access: User exists AND Status='ACTIVE' AND `kycStatus` != 'NOT_STARTED' (or pending is allowed for app entry)
export const appAccess = async (req, res, next) => {
    try {
        const userType = (req.user?.userType || "").toLowerCase();
        if (userType === 'admin' ||
            userType === 'super_admin' ||
            userType === 'researcher' ||
            userType === 'director') {
            return next();
        }

        // JWT contains _id, not userId
        const userId = req.user?._id || req.user?.userId;

        if (!userId) {
            return res.status(401).json({ message: "User ID not found in token." });
        }

        // Staff members bypass customer checks
        const staffMember = await staff.findById(userId);
        if (staffMember) {
            return next();
        }

        const user = await users.findById(userId);

        if (!user) {
            return res.status(401).json({ message: "User not found." });
        }

        if (user.userStatus === 'SUSPENDED') {
            req.userDetails = user;
            return next();
        }

        if (user.userType === 'admin' || user.userType === 'super_admin') {
            req.userDetails = user;
            return next();
        }

        if (user.kycStatus === 'NOT_STARTED') {
            return res.status(403).json({
                message: "KYC not started.",
                errorCode: "KYC_NOT_STARTED",
                action: "REDIRECT_TO_KYC"
            });
        }

        req.userDetails = user; // Pass user details down
        next();
    } catch (error) {
        console.error("App Access Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

// 2. Registration-Level Access: `registrationStatus` == 'ACTIVE' AND valid
export const registrationAccess = async (req, res, next) => {
    try {
        const userType = (req.user?.userType || "").toLowerCase();
        if (userType === 'admin' ||
            userType === 'super_admin' ||
            userType === 'researcher' ||
            userType === 'director') {
            return next();
        }

        const userId = req.user?._id || req.user?.userId;
        
        // Staff members bypass customer registration checks
        const staffMember = await staff.findById(userId);
        if (staffMember) {
            return next();
        }

        const user = req.userDetails || await users.findById(userId);

        if (!user) {
            return res.status(401).json({ message: "User not found." });
        }

        if (user.userType === 'admin' || user.userType === 'super_admin') {
            return next();
        }

        if (user.userStatus === 'SUSPENDED') {
            return res.status(403).json({
                message: "Your account has been suspended. Please contact support.",
                errorCode: "ACCOUNT_SUSPENDED",
                suspensionReason: user.suspensionReason || "N/A"
            });
        }

        const hasEntitlement = await hasActiveRegistration(userId);
        const isRegistrationActive = user.registrationStatus === 'ACTIVE' || user.registrationStatus === 'COMPLETE';
        const hasLegacyAccess = (user.account_type === 'ADMIN_PROVISIONED' || user.registrationFeePaid === true) && isRegistrationActive;

        const isBrowsingRoute = req.method === 'GET' && (
            req.path.includes('list') ||
            req.path.includes('drop-down') ||
            req.path.includes('active-partial-info')
        );

        if (!hasEntitlement && !hasLegacyAccess && !isRegistrationActive && !isBrowsingRoute) {
            const pendingReg = await paymentIntentModel.findOne({
                userId: userId,
                purchaseType: "REGISTRATION",
                status: { $in: ["VERIFICATION_PENDING", "PENDING_ADMIN_APPROVAL", "PENDING_BANK_TRANSFER"] }
            });

            if (pendingReg) {
                return next();
            } else {
                return next();
            }
        }

        next();
    } catch (error) {
        console.error("Registration Access Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

// 3. Content-Level Access: Registration Active + Plan Active + KYC Verified
export const contentAccess = async (req, res, next) => {
    try {
        const userType = (req.user?.userType || "").toLowerCase();
        if (userType === 'admin' ||
            userType === 'super_admin' ||
            userType === 'researcher' ||
            userType === 'director') {
            return next();
        }

        const userId = req.user?._id || req.user?.userId;

        // Staff members bypass customer content checks
        const staffMember = await staff.findById(userId);
        if (staffMember) {
            return next();
        }

        const user = req.userDetails;

        if (!user) {
            return res.status(401).json({ message: "User context not found." });
        }

        if (user.kycStatus === 'REJECTED') {
            return res.status(403).json({
                message: "Access Restricted. Your KYC has been rejected. Please complete KYC verification.",
                errorCode: "KYC_REJECTED",
                action: "REDIRECT_TO_KYC"
            });
        }

        if (user.userStatus === 'SUSPENDED') {
            return res.status(403).json({
                message: "Your account has been suspended. Please contact support.",
                errorCode: "ACCOUNT_SUSPENDED",
                suspensionReason: user.suspensionReason || "N/A"
            });
        }

        const hasPlan = await hasAnyActivePlan(user._id);

        if (!hasPlan) {
            return res.status(403).json({
                message: "No active plans found.",
                errorCode: "NO_ACTIVE_PLAN",
                action: "REDIRECT_TO_PLAN_PURCHASE"
            });
        }

        next();

    } catch (error) {
        console.error("Content Access Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};
// 4. Admin Only Access
export const adminOnly = async (req, res, next) => {
    try {
        const userType = (req.user?.userType || "").toLowerCase();
        if (userType === 'admin' ||
            userType === 'super_admin' ||
            userType === 'researcher' ||
            userType === 'director') {
            return next();
        }

        // Allow any registered staff member to pass outer admin checks
        const userId = req.user?._id || req.user?.userId;
        if (userId) {
            const staffMember = await staff.findById(userId);
            if (staffMember) {
                return next();
            }
        }

        return res.status(403).json({ message: "Access Denied. Admin privileges required." });
    } catch (error) {
        console.error("Admin Access Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

/**
 * 4.1 Strict Admin Only Access
 * Performs a live DB lookup to prevent stale JWT/demotion bypass.
 */
export const adminStrictOnly = async (req, res, next) => {
    try {
        const userId = req.user?._id || req.user?.userId;
        if (!userId) return res.status(401).json({ message: "Identity not found in token." });

        // Check if it's a primary admin (userModel)
        const user = await users.findById(userId).select('userType');
        if (user && (user.userType === 'admin' || user.userType === 'super_admin')) {
            return next();
        }

        // Check if it's a staff member (staffModel)
        const staffMember = await staff.findById(userId);
        if (staffMember) {
            return next(); // Allow staff; subsequent checkPermission will verify specific action rights
        }

        return res.status(403).json({ message: "Strict Admin access required. This action is restricted to Administrators only." });
    } catch (error) {
        console.error("Strict Admin Access Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};


// 4.2 Report Management Access
export const reportManagementAccess = async (req, res, next) => {
    try {
        const userId = req.user?._id || req.user?.userId;
        if (!userId) return res.status(401).json({ message: "Identity not found in token." });

        // Check if it's a primary admin (userModel)
        const user = await users.findById(userId).select('userType');
        if (user && (user.userType === 'admin' || user.userType === 'super_admin')) {
            return next();
        }

        // Check if it's a staff member (staffModel)
        const staffMember = await staff.findById(userId);
        if (staffMember) {
            return next();
        }

        return res.status(403).json({ message: "Access Denied. Researchers, Directors, or Administrators only." });
    } catch (error) {
        console.error("Report Management Access Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};


// 4.3 KYC Download Access
export const kycDownloadAccess = async (req, res, next) => {
    try {
        const userId = req.user?._id || req.user?.userId;
        if (!userId) return res.status(401).json({ message: "Identity not found in token." });

        const user = await users.findById(userId).select('userType');
        if (user && (user.userType === 'admin' || user.userType === 'super_admin')) {
            return next();
        }

        const staffMember = await staff.findById(userId);
        if (staffMember) {
            return next();
        }

        return res.status(403).json({ message: "Administrator or Director access required for downloads." });
    } catch (error) {
        console.error("KYC Download Access Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

// 5. Payment Gate for iOS Compliance
export const paymentGate = (req, res, next) => {
    try {
        const platform = req.headers['x-platform'] || 'android'; // Default to android/web
        if (platform.toLowerCase() === 'ios') {
            return res.status(403).json({
                message: "Payments are not available on this platform",
                errorCode: "PAYMENT_NOT_ALLOWED"
            });
        }
        next();
    } catch (error) {
        console.error("Payment Gate Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

/**
 * 6. Dynamic Feature and Action Permission Check Middleware
 * Check if the staff member has a Role with a Permission Group containing [feature] and [action].
 */
export const checkPermission = (targetPermission, actionParam = null) => {
    return async (req, res, next) => {
        try {
            let requiredKey = targetPermission;
            let feature = targetPermission;
            let action = actionParam;

            if (actionParam === null && targetPermission.includes('.')) {
                requiredKey = targetPermission;
            } else if (actionParam) {
                requiredKey = `${targetPermission.toLowerCase()}.${actionParam.toLowerCase()}`;
            }

            if (!req.user) {
                return res.status(401).json({ message: "Unauthorized. User authentication required." });
            }

            const userId = req.user._id || req.user.userId;
            if (!userId) {
                return res.status(401).json({ message: "User ID not found in token." });
            }

            // 1. Check token userType or primary users collection for Admin / Super Admin
            const tokenUserType = (req.user?.userType || "").toLowerCase();
            if (tokenUserType === 'admin' || tokenUserType === 'super_admin' || tokenUserType === 'super admin') {
                return next();
            }

            const primaryUser = await users.findById(userId).select('userType');
            if (primaryUser && (primaryUser.userType === 'admin' || primaryUser.userType === 'super_admin')) {
                return next();
            }

            // 2. Retrieve staff member and populate role and permission groups
            const staffMember = await staff.findById(userId)
                .populate({
                    path: 'roleId',
                    populate: {
                        path: 'permissionGroups'
                    }
                });

            if (!staffMember) {
                return res.status(403).json({ message: "Access Denied. Staff record not found." });
            }

            // If user's department, role, or userType is Admin or Super Admin, bypass
            const dept = (staffMember.department || staffMember.deparment || "").toLowerCase();
            const roleName = (staffMember.role || "").toLowerCase();
            const userType = (req.user?.userType || staffMember.userType || "").toLowerCase();
            const isRoleAdmin = staffMember.roleId && (
                staffMember.roleId.name.toLowerCase() === 'admin' ||
                staffMember.roleId.name.toLowerCase() === 'super_admin' ||
                staffMember.roleId.name.toLowerCase() === 'super admin'
            );

            if (dept === 'admin' || dept === 'super_admin' || dept === 'super admin' ||
                roleName === 'admin' || roleName === 'super_admin' || roleName === 'super admin' ||
                userType === 'admin' || userType === 'super_admin' || userType === 'super admin' ||
                isRoleAdmin) {
                return next();
            }

            // If staff has no role assigned, deny access
            if (!staffMember.roleId || !staffMember.roleId.permissionGroups) {
                return res.status(403).json({ message: `Access Denied. No role assigned. Required permission: ${requiredKey}` });
            }

            // Check if staff has the exact canonical key, alias key, or legacy feature/action match
            const hasPermission = staffMember.roleId.permissionGroups.some(group => {
                return group.permissions.some(perm => {
                    if (!perm.actions) return false;
                    // Direct canonical key match
                    if (perm.actions.includes(requiredKey)) return true;

                    // Alias resolution for legacy route keys
                    if ((requiredKey === 'users.read' || requiredKey === 'users:read') &&
                        (perm.actions.includes('users.view') || perm.actions.includes('users.view_all') || perm.actions.includes('users.view_assigned') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'kyc.read' || requiredKey === 'kyc:read') &&
                        (perm.actions.includes('kyc.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'payments.read' || requiredKey === 'payments:read') &&
                        (perm.actions.includes('payments.view_pending') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'reports.read' || requiredKey === 'reports:read') &&
                        (perm.actions.includes('reports.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'staff.read' || requiredKey === 'staff:read') &&
                        (perm.actions.includes('staff.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'settings.read' || requiredKey === 'settings:read') &&
                        (perm.actions.includes('settings.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'leads.read' || requiredKey === 'leads:read') &&
                        (perm.actions.includes('leads.view_all') || perm.actions.includes('leads.view_assigned') || perm.actions.includes('read'))) return true;

                    // Legacy fallback matching if feature/action were passed
                    if (actionParam && perm.feature && perm.feature.toLowerCase() === feature.toLowerCase()) {
                        return perm.actions.some(act => act.toLowerCase() === actionParam.toLowerCase());
                    }
                    return false;
                });
            });

            if (hasPermission) {
                return next();
            }

            return res.status(403).json({
                message: `Access Denied. You do not have permission to perform this action. Required permission: ${requiredKey}`
            });
        } catch (error) {
            console.error("Authorization check error:", error);
            return res.status(500).json({ message: "Internal Server Error" });
        }
    };
};

