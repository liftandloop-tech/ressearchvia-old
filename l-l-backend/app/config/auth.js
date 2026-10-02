import jwt from 'jsonwebtoken'
import users from '../models/userModel.js'
import staffModel from '../models/staffModel.js'
import TokenBlacklist from '../models/tokenBlacklistModel.js'

const auth = {
    tokenVerified: async (req, res, next) => {
        try {
            const authHeader = req.headers['authorization'];
            if (!authHeader) {
                return res.status(401).json({ status: 401, error: "UNAUTHORIZED", message: "Unauthorized user" });
            }

            // Extract token from "Bearer <token>" format
            const token = authHeader.startsWith('Bearer ')
                ? authHeader.substring(7)
                : authHeader;

            // 1. Check if token has been revoked / blacklisted
            const isBlacklisted = await TokenBlacklist.findOne({ token }).lean();
            if (isBlacklisted) {
                return res.status(401).json({
                    error: "TOKEN_REVOKED",
                    message: "Session has expired or was logged out. Please log in again."
                });
            }

            // 2. Verify JWT signature & expiration
            const decoded = jwt.verify(token, process.env.JWT_TOKEN);

            // 3. Check Account Status (Active vs Suspended / Inactive / Deleted)
            if (decoded._id) {
                // Check if user is staff
                const staff = await staffModel.findById(decoded._id).select('status isDeleted').lean();
                if (staff) {
                    if (staff.isDeleted || (staff.status && staff.status.toLowerCase() !== 'active')) {
                        return res.status(401).json({
                            error: "ACCOUNT_DEACTIVATED",
                            message: "Your staff account has been deactivated or disabled. Please contact the administrator."
                        });
                    }
                } else {
                    // Check if regular user or admin
                    const user = await users.findById(decoded._id).select('userStatus sessionDeviceId').lean();
                    if (user) {
                        if (user.userStatus === 'SUSPENDED') {
                            return res.status(401).json({
                                error: "ACCOUNT_SUSPENDED",
                                message: "Your account has been suspended. Please contact support."
                            });
                        }

                        // Single Device Enforcement - SKIP for login and refresh endpoints
                        const isLoginEndpoint = req.path.includes('/login') || req.path.includes('/refresh-token');
                        if (!isLoginEndpoint) {
                            const requestDeviceId = req.headers['device-id'];
                            if (user.sessionDeviceId && requestDeviceId && requestDeviceId !== user.sessionDeviceId) {
                                console.log(`[Auth] Session Invalid: Device Mismatch. Header: ${requestDeviceId}, DB: ${user.sessionDeviceId}`);
                                return res.status(401).json({
                                    error: "SESSION_INVALID",
                                    reason: "LOGGED_IN_ON_ANOTHER_DEVICE",
                                    message: "Your account was logged in on another device."
                                });
                            }
                        }
                    }
                }
            }

            req.user = decoded;
            req.token = token;
            next();
        }
        catch (e) {
            console.error('[Auth] Token verification failed:', e.message);
            res.status(401).json('Token not valid');
        }

    }
}

export default auth