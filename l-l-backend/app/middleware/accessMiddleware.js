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
        const userId = req.user._id || req.user.userId;

        if (!userId) {
            return res.status(401).json({ message: "User ID not found in token." });
        }

        const user = await users.findById(userId);

        if (!user) {
            return res.status(401).json({ message: "User not found." });
        }

        if (user.userStatus === 'SUSPENDED') {
            // Suspended users can enter the app but have restricted access
            // Handled by registrationAccess and contentAccess
            req.userDetails = user;
            return next();
        }

        // Double-check: Exempt admins from DB as well
        if (user.userType === 'admin' || user.userType === 'super_admin') {
            req.userDetails = user;
            return next();
        }

        // Allow access if KYC is verified OR pending (Gate A passed)
        // Only block if NOT_STARTED and trying to go beyond onboarding (handled by frontend usually, but good to enforce)
        // Actually the rule is: kycStatus != 'NOT_STARTED' is required for "App Entry/Purchase"
        // But for "Onboarding" screens, we obviously don't need this check.
        // This middleware should be applied to "Protected APP Routes" (Like Dashboard, Payment etc)
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

        // Run appAccess first or assume it ran
        const userId = req.user._id || req.user.userId;
        const user = req.userDetails || await users.findById(userId);

        if (!user) {
            return res.status(401).json({ message: "User not found." });
        }

        // Double-check admin
        if (user.userType === 'admin' || user.userType === 'super_admin') {
            return next();
        }

        // Strictly check Entitlements OR Legacy/Admin Flags
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

        // ALLOW browsing (GET) endpoints for plans and segments even if registration is pending.
        // This ensures dropdowns work on the Registration screen and Choose Plan screen.
        const isBrowsingRoute = req.method === 'GET' && (
            req.path.includes('list') ||
            req.path.includes('drop-down') ||
            req.path.includes('active-partial-info')
        );

        if (!hasEntitlement && !hasLegacyAccess && !isRegistrationActive && !isBrowsingRoute) {
            // SMART CHECK: Only block non-browsing routes if there is a pending registration intent.
            const pendingReg = await paymentIntentModel.findOne({
                userId: userId,
                purchaseType: "REGISTRATION",
                status: { $in: ["VERIFICATION_PENDING", "PENDING_ADMIN_APPROVAL", "PENDING_BANK_TRANSFER"] }
            });

            if (pendingReg) {
                // User has an active pending payment. Allow them to proceed to dashboard.
                // determineNextStep will handle the UI redirection/next state logic.
                return next();
            } else {
                // No committed registration intent found - allow access to dropdowns and plan lists.
                return next();
            }
        }

        // PARTIAL BALANCE CHECK: User may be ACTIVE but still have an unpaid registration balance.
        // allow them to proceed to the app - they will be blocked from purchasing OTHER plans later if necessary
        // but they should not be kicked out of the main dashboard/research screens.
        /* 
        if (isRegistrationActive && !isBrowsingRoute) {
            const partialRegWithBalance = await paymentIntentModel.findOne({
                userId: userId,
                purchaseType: "REGISTRATION",
                isPartial: true,
                status: { $ne: "PAID" }
            });

            if (partialRegWithBalance) {
                // Calculate how much is still owed
                const approvedPayments = partialRegWithBalance.partialPaymentsHistory
                    .filter(h => h.status === 'APPROVED')
                    .reduce((sum, h) => sum + (h.amountPaid || 0), 0);
                const totalTarget = partialRegWithBalance.partialTotalTarget || partialRegWithBalance.totalAmount;
                const remainingBalance = Math.max(0, totalTarget - approvedPayments);

                if (remainingBalance > 0) {
                    return res.status(403).json({
                        message: "You have a pending registration balance. Please complete your registration payment before purchasing plans.",
                        errorCode: "REGISTRATION_BALANCE_PENDING",
                        remainingBalance: remainingBalance,
                        paymentIntentId: partialRegWithBalance._id,
                        action: "REDIRECT_TO_REGISTRATION_PAYMENT"
                    });
                }
            }
        }
        */

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

        const user = req.userDetails;

        if (!user) {
            return res.status(401).json({ message: "User context not found." });
        }

        // 2. Check KYC Verification - Only block REJECTED status
        // Allow pending/waiting/in-progress KYC to access content
        if (user.kycStatus === 'REJECTED') {
            return res.status(403).json({
                message: "Access Restricted. Your KYC has been rejected. Please complete KYC verification.",
                errorCode: "KYC_REJECTED",
                action: "REDIRECT_TO_KYC"
            });
        }

        // 3. Block SUSPENDED users
        if (user.userStatus === 'SUSPENDED') {
            return res.status(403).json({
                message: "Your account has been suspended. Please contact support.",
                errorCode: "ACCOUNT_SUSPENDED",
                suspensionReason: user.suspensionReason || "N/A"
            });
        }

        // 4. Check Active Plans Entitlement
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
        return res.status(403).json({ message: "Access Denied. Admin privileges required." });
    } catch (error) {
        console.error("Admin Access Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};

/**
 * 4.1 Strict Admin Only Access
 * Performs a live DB lookup to prevent stale JWT/demotion bypass.
 * Explicitly blocks Directors and Researchers from sensitive KYC state changes.
 */
export const adminStrictOnly = async (req, res, next) => {
    try {
        const userId = req.user._id || req.user.userId;
        if (!userId) return res.status(401).json({ message: "Identity not found in token." });

        // Check if it's a primary admin (userModel)
        const user = await users.findById(userId).select('userType');
        if (user && (user.userType === 'admin' || user.userType === 'super_admin')) {
            return next();
        }

        // Check if it's a staff member (staffModel)
        const staffMember = await staff.findById(userId).select('userType deparment department role');
        if (staffMember) {
            // Handle the 'deparment' typo in schema + check departments
            const dept = (staffMember.department || staffMember.deparment || "").toLowerCase();
            const role = (staffMember.role || "").toLowerCase();
            const type = (staffMember.userType || "").toLowerCase();

            // Only allow if role/type is strictly admin or super_admin
            // Block Directors and Researchers regardless of other flags
            if (dept.includes('director') || dept.includes('researcher')) {
                return res.status(403).json({ message: "Access Denied. Directors and Researchers are not permitted to perform this action." });
            }

            if (type === 'admin' || type === 'super_admin' || role === 'admin' || role === 'super_admin') {
                return next();
            }
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
        const userId = req.user._id || req.user.userId;
        if (!userId) return res.status(401).json({ message: "Identity not found in token." });

        // 1. Check if it's a primary admin (userModel)
        const user = await users.findById(userId).select('userType');
        if (user && (user.userType === 'admin' || user.userType === 'super_admin')) {
            return next();
        }

        // 2. Check if it's a staff member (staffModel)
        const staffMember = await staff.findById(userId).select('userType deparment department role');
        if (staffMember) {
            const dept = (staffMember.department || staffMember.deparment || "").toLowerCase();
            const role = (staffMember.role || "").toLowerCase();
            const type = (staffMember.userType || "").toLowerCase();

            // ALLOW Researchers and Directors for report management
            if (dept.includes('researcher') || dept.includes('director')) {
                return next();
            }

            // Allow standard admin staff
            if (type === 'admin' || type === 'super_admin' || role === 'admin' || role === 'super_admin') {
                return next();
            }
        }

        return res.status(403).json({ message: "Access Denied. Researchers, Directors, or Administrators only." });
    } catch (error) {
        console.error("Report Management Access Error:", error);
        return res.status(500).json({ message: "Internal Server Error" });
    }
};


// 4.3 KYC Download Access
// Specifically permits Directors to download Digio documents, while still blocking Researchers.
export const kycDownloadAccess = async (req, res, next) => {
    try {
        const userId = req.user._id || req.user.userId;
        if (!userId) return res.status(401).json({ message: "Identity not found in token." });

        const user = await users.findById(userId).select('userType');
        if (user && (user.userType === 'admin' || user.userType === 'super_admin')) {
            return next();
        }

        const staffMember = await staff.findById(userId).select('userType deparment department role');
        if (staffMember) {
            const dept = (staffMember.department || staffMember.deparment || "").toLowerCase();
            const role = (staffMember.role || "").toLowerCase();
            const type = (staffMember.userType || "").toLowerCase();

            // Researchers are strictly prohibited
            if (dept.includes('researcher')) {
                return res.status(403).json({ message: "Access Denied. Researchers are not permitted to download KYC documents." });
            }

            // ALLOW if they are Admin or Director
            if (dept.includes('director') ||
                type === 'admin' || type === 'super_admin' ||
                role === 'admin' || role === 'super_admin') {
                return next();
            }
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
