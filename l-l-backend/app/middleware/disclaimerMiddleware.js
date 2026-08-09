import userModel from "../models/userModel.js";

export const disclaimerCheck = async (req, res, next) => {
    try {
        const userType = (req.user?.userType || "").toLowerCase();
        if (userType === 'admin' ||
            userType === 'super_admin' ||
            userType === 'researcher' ||
            userType === 'director') {
            return next();
        }

        // req.user is populated by auth.tokenVerified
        if (!req.user || !req.user._id) {
            return res.status(401).json({ status: 401, message: "Unauthorized" });
        }

        const userId = req.user._id;
        const user = await userModel.findById(userId);

        if (user && user.disclaimer_acceptance && user.disclaimer_acceptance.status === true) {
            next();
        } else {
            return res.status(403).json({
                status: 403,
                message: "Trading Disclaimer not accepted. Please accept to proceed.",
                error: "DISCLAIMER_REQUIRED"
            });
        }
    } catch (error) {
        return res.status(500).json({ status: 500, message: "Server Error during disclaimer check" });
    }
};
