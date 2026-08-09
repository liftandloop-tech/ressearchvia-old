import jwt from 'jsonwebtoken'
import users from '../models/userModel.js'

const auth = {
    tokenVerified: async (req, res, next) => {
        try {
            const authHeader = req.headers['authorization'];
            console.log('[Auth] Token verification:', { hasToken: !!authHeader, path: req.path });
            if (!authHeader) {
                console.log('[Auth] No token provided');
                return res.status(401).json('Unauthorize user');
            }

            // Extract token from "Bearer <token>" format
            const token = authHeader.startsWith('Bearer ')
                ? authHeader.substring(7)
                : authHeader;

            const decoded = jwt.verify(token, process.env.JWT_TOKEN);
            console.log('[Auth] Token verified:', { userId: decoded._id, email: decoded.email });

            // Single Device Enforcement - SKIP for login and refresh endpoints
            const isLoginEndpoint = req.path.includes('/login') || req.path.includes('/refresh-token');

            if (!isLoginEndpoint) {
                const freshUser = await users.findById(decoded._id).select('sessionDeviceId');
                if (freshUser) {
                    const requestDeviceId = req.headers['device-id'];
                    // Only enforce if user has an active session device set
                    if (freshUser.sessionDeviceId && requestDeviceId && requestDeviceId !== freshUser.sessionDeviceId) {
                        console.log(`[Auth] Session Invalid: Device Mismatch. Header: ${requestDeviceId}, DB: ${freshUser.sessionDeviceId}`);
                        return res.status(401).json({
                            error: "SESSION_INVALID",
                            reason: "LOGGED_IN_ON_ANOTHER_DEVICE",
                            message: "Your account was logged in on another device."
                        });
                    }
                }
            }

            req.user = decoded
            next()
        }
        catch (e) {
            console.error('[Auth] Token verification failed:', e.message);
            res.status(401).json('Token not valid')
        }

    }
}

export default auth