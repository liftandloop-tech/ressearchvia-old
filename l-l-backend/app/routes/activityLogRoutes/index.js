import express from "express";
import auth from "../../config/auth.js";
import { getActivityLogs } from "../../services/activityLogService.js";
import { adminOnly } from "../../middleware/accessMiddleware.js";

const Router = express.Router();

const activityLogRoutes = () => {
    /**
     * GET /api/activity-log/user/:userId
     * Returns the compliance activity log for a user.
     * Supports:
     *   ?types=USER_LOGIN,MANAGER_ASSIGNED    (comma-separated event types)
     *   ?severity=CRITICAL,WARNING            (comma-separated severity levels)
     *   ?limit=200
     */
    Router.get("/user/:userId", auth.tokenVerified, adminOnly, async (req, res) => {
        try {
            const { userId } = req.params;
            const { types, severity, limit } = req.query;

            const eventTypes = types ? types.split(',').map(t => t.trim()).filter(Boolean) : [];
            const severities = severity ? severity.split(',').map(s => s.trim()).filter(Boolean) : [];
            const parsedLimit = limit ? parseInt(limit) : 500;

            const logs = await getActivityLogs({
                userId,
                eventTypes,
                severities,
                limit: parsedLimit
            });

            return res.status(200).json({
                status: 200,
                message: "Activity logs fetched",
                data: { logs }
            });
        } catch (error) {
            console.error("ActivityLog API Error:", error);
            return res.status(500).json({ status: 500, message: error.message });
        }
    });

    return Router;
};

export default activityLogRoutes;
