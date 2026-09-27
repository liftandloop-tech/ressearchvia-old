import express from "express";
import notificationController from "../../controller/notificationController.js";
import auth from "../../config/auth.js";
import upload from "../../config/upload.js";
import { checkPermission } from "../../middleware/accessMiddleware.js";

const Router = express.Router();

const notificationRoutes = () => {
    // Send notification (Permission Guarded)
    const setNotificationImageType = (req, res, next) => { req.query.type = 'image'; next(); };
    Router.post("/send", auth.tokenVerified, checkPermission('notifications.send'), setNotificationImageType, upload.single("image"), notificationController.sendNotification);

    // Get metadata for segments and plans
    Router.get("/segments", auth.tokenVerified, checkPermission('notifications.view'), notificationController.getSegments);
    Router.get("/plans", auth.tokenVerified, checkPermission('notifications.view'), notificationController.getPlans);

    // Bulk Email Routes
    const setBulkType = (req, res, next) => { req.query.type = 'bulk-import'; next(); };
    Router.post("/send-bulk-email", auth.tokenVerified, checkPermission('notifications.send_bulk_email'), setBulkType, upload.single("file"), notificationController.sendBulkEmail);
    Router.post("/preview-email", auth.tokenVerified, checkPermission('notifications.preview'), notificationController.previewEmail);

    // Scheduled Notifications
    Router.get("/scheduled", auth.tokenVerified, checkPermission('notifications.view'), notificationController.getScheduledNotifications);
    Router.delete("/scheduled/:id", auth.tokenVerified, checkPermission('notifications.cancel_scheduled'), notificationController.deleteScheduledNotification);

    // Notification History
    Router.get("/history", auth.tokenVerified, checkPermission('notifications.view'), notificationController.getNotificationHistory);

    return Router;
}

export default notificationRoutes;
