import users from "../models/userModel.js";
import staff from "../models/staffModel.js";
import departmentModel from "../models/departmentModel.js";
import roleModel from "../models/roleModel.js";

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
        if (userType === 'admin' || userType === 'super_admin') {
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
        if (userType === 'admin' || userType === 'super_admin') {
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
                return res.status(403).json({
                    message: "Registration required to access this resource.",
                    errorCode: "REGISTRATION_REQUIRED",
                    action: "REDIRECT_TO_REGISTRATION"
                });
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
        if (userType === 'admin' || userType === 'super_admin') {
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
        if (userType === 'admin' || userType === 'super_admin') {
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

/**
 * 4.1.1 Strict Admin Only (Excluding General Staff)
 * For sensitive financial operations like Refunds that only Admin/SuperAdmin can execute.
 */
export const adminStrictOnlyNoStaff = async (req, res, next) => {
    try {
        const userId = req.user?._id || req.user?.userId;
        if (!userId) return res.status(401).json({ message: "Identity not found in token." });

        // 1. Check primary users collection
        const user = await users.findById(userId).select('userType role');
        if (user && (user.userType === 'admin' || user.userType === 'super_admin' || user.role === 'admin' || user.role === 'super_admin')) {
            req.adminUser = user;
            return next();
        }

        // 2. Check staff collection - only allow if role or department is strictly admin/super_admin
        const staffMember = await staff.findById(userId).populate('roleId');
        if (staffMember) {
            const roleName = (staffMember.role || staffMember.roleId?.name || "").toLowerCase();
            const dept = (staffMember.department || staffMember.deparment || "").toLowerCase();
            const userType = (staffMember.userType || "").toLowerCase();


            if (roleName === 'admin' || roleName === 'super_admin' || roleName === 'super admin' ||
                dept === 'admin' || dept === 'super_admin' || dept === 'super admin' ||
                userType === 'admin' || userType === 'super_admin') {
                req.adminUser = staffMember;
                return next();
            }
        }

        return res.status(403).json({
            status: 403,
            message: "Access Denied. This action is strictly restricted to Administrators only, not general staff.",
            errorCode: "ADMIN_ONLY_RESTRICTION"
        });
    } catch (error) {
        console.error("adminStrictOnlyNoStaff Error:", error);
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

        return res.status(403).json({ message: "Access Denied. Staff or Administrator privileges required." });
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

        return res.status(403).json({ message: "Access Denied. Staff or Administrator privileges required." });
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

            // 2. Retrieve staff member and populate role, permission groups, and department
            const staffMember = await staff.findById(userId)
                .populate('departmentId')
                .populate({
                    path: 'roleId',
                    populate: [
                        { path: 'permissionGroups' },
                        { path: 'departmentId' }
                    ]
                });

            if (!staffMember) {
                return res.status(403).json({ message: "Access Denied. Staff record not found." });
            }

            // Fallback departmentId from roleId if staffMember.departmentId is null
            if (!staffMember.departmentId && staffMember.roleId?.departmentId) {
                staffMember.departmentId = staffMember.roleId.departmentId;
            }

            // Hierarchy Inheritance:
            // If staff has a role with level > 1 and belongs to a department,
            // inherit permission groups from all lower-level roles in the same department
            if (staffMember.roleId && staffMember.roleId.level > 1 && staffMember.roleId.departmentId) {
                const deptId = staffMember.roleId.departmentId._id || staffMember.roleId.departmentId;
                const lowerRoles = await roleModel.find({
                    departmentId: deptId,
                    level: { $lt: staffMember.roleId.level },
                    isActive: true
                }).populate('permissionGroups');

                const existingPgIds = new Set((staffMember.roleId.permissionGroups || []).map(g => (g._id || g).toString()));
                for (const lr of lowerRoles) {
                    for (const pg of (lr.permissionGroups || [])) {
                        const pgIdStr = (pg._id || pg).toString();
                        if (!existingPgIds.has(pgIdStr)) {
                            existingPgIds.add(pgIdStr);
                            staffMember.roleId.permissionGroups.push(pg);
                        }
                    }
                }
            }

            // If user's department, role, or userType is Admin or Super Admin, bypass
            const dept = (staffMember.departmentId?.name || staffMember.department || staffMember.deparment || "").toLowerCase();
            const roleName = (staffMember.roleId?.name || staffMember.role || "").toLowerCase();
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

            // Department page gating: If department specifies assignedPages, ensure requested module is allowed
            const effectiveDept = staffMember.departmentId || staffMember.roleId?.departmentId;
            if (effectiveDept && !effectiveDept.isGlobal && Array.isArray(effectiveDept.assignedPages) && effectiveDept.assignedPages.length > 0) {
                const assigned = new Set(effectiveDept.assignedPages.map(p => p.toLowerCase()));
                const targetMod = (feature || targetPermission.split('.')[0] || '').toLowerCase();
                const modPageMap = {
                    'leads': 'leads',
                    'users': 'users',
                    'client': 'users',
                    'clients': 'users',
                    'kyc': 'kyc',
                    'payments': 'payments',
                    'subscriptions': 'subscriptions',
                    'plans': 'subscriptions',
                    'segments': 'subscriptions',
                    'reports': 'reports',
                    'notifications': 'notifications',
                    'staff': 'staff',
                    'settings': 'settings'
                };
                const expectedPage = modPageMap[targetMod];
                if (expectedPage && !assigned.has(expectedPage)) {
                    return res.status(403).json({
                        message: `Access Denied. Department "${effectiveDept.name}" does not have access to the ${expectedPage} module.`
                    });
                }
            }

            // If staff has no role assigned, deny access
            if (!staffMember.roleId || !staffMember.roleId.permissionGroups || staffMember.roleId.permissionGroups.length === 0) {
                return res.status(403).json({ message: `Access Denied. No active role permissions assigned. Required permission: ${requiredKey}` });
            }

            // Check if staff has the exact canonical key, alias key, or legacy feature/action match
            const hasPermission = staffMember.roleId.permissionGroups.some(group => {
                return group.permissions.some(perm => {
                    if (!perm.actions) return false;
                    // Direct canonical key match
                    if (perm.actions.includes(requiredKey)) return true;

                    // Alias resolution for legacy route keys and new button-level permission keys
                    if ((requiredKey === 'users.read' || requiredKey === 'users:read' || requiredKey === 'users.view_assigned' || requiredKey === 'users.view_all') &&
                        (perm.actions.includes('users.view') || perm.actions.includes('users.view_all') || perm.actions.includes('users.view_assigned') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'kyc.read' || requiredKey === 'kyc:read') &&
                        (perm.actions.includes('kyc.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'payments.read' || requiredKey === 'payments:read') &&
                        (perm.actions.includes('payments.view_pending') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'reports.read' || requiredKey === 'reports:read') &&
                        (perm.actions.includes('reports.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'subscriptions.read' || requiredKey === 'subscriptions:read') &&
                        (perm.actions.includes('subscriptions.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'reports.trading_call_popup') &&
                        (perm.actions.includes('reports.trading_call_popup') || perm.actions.includes('trading_call_popup'))) return true;

                    if ((requiredKey === 'notifications.read' || requiredKey === 'notifications:read' || requiredKey === 'notifications.view') &&
                        (perm.actions.includes('notifications.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'notifications.send') &&
                        (perm.actions.includes('notifications.send') || perm.actions.includes('notifications.create') || perm.actions.includes('create'))) return true;

                    if ((requiredKey === 'notifications.send_bulk_email') &&
                        (perm.actions.includes('notifications.send_bulk_email') || perm.actions.includes('notifications.send') || perm.actions.includes('notifications.create') || perm.actions.includes('create'))) return true;

                    if ((requiredKey === 'notifications.preview') &&
                        (perm.actions.includes('notifications.preview') || perm.actions.includes('notifications.view') || perm.actions.includes('notifications.send') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'notifications.cancel_scheduled') &&
                        (perm.actions.includes('notifications.cancel_scheduled') || perm.actions.includes('notifications.delete') || perm.actions.includes('delete'))) return true;

                    if ((requiredKey === 'staff.read' || requiredKey === 'staff:read') &&
                        (perm.actions.includes('staff.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'staff.login' || requiredKey === 'staff:login') &&
                        (perm.actions.includes('staff.login') || perm.actions.includes('staff.update') || perm.actions.includes('staff.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'users.manage' || requiredKey === 'users:manage') &&
                        (perm.actions.includes('users.manage') || perm.actions.includes('users.update') || perm.actions.includes('subscriptions.manage') || perm.actions.includes('subscriptions.activate'))) return true;

                    if ((requiredKey === 'staff.view_applicants') &&
                        (perm.actions.includes('staff.view_applicants') || perm.actions.includes('staff.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'staff.approve_applicant') &&
                        (perm.actions.includes('staff.approve_applicant') || perm.actions.includes('staff.create') || perm.actions.includes('staff.update'))) return true;

                    if (requiredKey === 'staff.reset' &&
                        (perm.actions.includes('staff.reset_mpin') || perm.actions.includes('staff.update') || perm.actions.includes('staff.reset'))) return true;

                    if ((requiredKey === 'settings.read' || requiredKey === 'settings:read') &&
                        (perm.actions.includes('settings.view') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'leads.read' || requiredKey === 'leads:read' || requiredKey === 'leads.view_all' || requiredKey === 'leads.view_assigned') &&
                        (perm.actions.includes('leads.view') || perm.actions.includes('leads.view_all') || perm.actions.includes('leads.view_assigned') || perm.actions.includes('leads.pull') || perm.actions.includes('read'))) return true;

                    if ((requiredKey === 'leads.update_all' || requiredKey === 'leads.update_assigned') &&
                        (perm.actions.includes('leads.update') || perm.actions.includes('leads.update_all') || perm.actions.includes('leads.update_assigned'))) return true;

                    if ((requiredKey === 'leads.follow_up_all' || requiredKey === 'leads.follow_up_assigned') &&
                        (perm.actions.includes('leads.follow_up') || perm.actions.includes('leads.follow_up_all') || perm.actions.includes('leads.follow_up_assigned'))) return true;

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

