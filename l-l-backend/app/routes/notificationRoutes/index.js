import express from "express";
import notificationController from "../../controller/notificationController.js";
import auth from "../../config/auth.js";

import upload from "../../config/upload.js";

const Router = express.Router();

const notificationRoutes = () => {
    // Send notification (Admin only ideally, currently using tokenVerified)
    const setNotificationImageType = (req, res, next) => { req.query.type = 'image'; next(); };
    Router.post("/send", auth.tokenVerified, setNotificationImageType, upload.single("image"), notificationController.sendNotification);

    // Get metadata for segments and plans
    Router.get("/segments", auth.tokenVerified, notificationController.getSegments);
    Router.get("/plans", auth.tokenVerified, notificationController.getPlans);

    // Bulk Email Routes
    const setBulkType = (req, res, next) => { req.query.type = 'bulk-import'; next(); };
    Router.post("/send-bulk-email", auth.tokenVerified, setBulkType, upload.single("file"), notificationController.sendBulkEmail);
    Router.post("/preview-email", auth.tokenVerified, notificationController.previewEmail);

    // Register token (For mobile app usage)
    // Router.post("/register-token", auth.tokenVerified, notificationController.registerToken); // If needed

    // Scheduled Notifications
    Router.get("/scheduled", auth.tokenVerified, notificationController.getScheduledNotifications);
    Router.delete("/scheduled/:id", auth.tokenVerified, notificationController.deleteScheduledNotification);

    // Notification History
    Router.get("/history", auth.tokenVerified, notificationController.getNotificationHistory);

    return Router;
}

export default notificationRoutes;
