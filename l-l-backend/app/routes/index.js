import userRoutes from "./userRoutes/index.js"
import userKycRoutes from "./userKycRoutes/index.js";
import planPurchaseRoutes from "./planPurchaseRoutes/index.js"
import reportsRoutes from "./reportsRouters/index.js"
import segmentsRoutes from "./segmentsRoutes/index.js"
import staffRoutes from "./staffroutes/index.js";
import notificationRoutes from "./notificationRoutes/index.js";
import expiryRoutes from "./expiryRoutes/index.js";
import settingsRoutes from "./settingsRoutes/index.js";
import acquisitionRoutes from "./acquisitionRoutes/index.js";
import webhookRoutes from "./webhookRoutes/index.js";
import deviceRoutes from "./deviceRoutes/index.js";
import activityLogRoutes from "./activityLogRoutes/index.js";
import leadRoutes from "./leadRoutes/index.js";
import staffReportRoutes from "./staffReportRoutes/index.js";

const initRoutes = (app) => {
    app.get('/api/health', (req, res) => res.status(200).send({ status: 'OK', uptime: process.uptime() }));
    app.use('/api/user', userRoutes())
    app.use('/api/user/kyc', userKycRoutes())
    app.use('/api/user/purchase', planPurchaseRoutes())
    app.use('/api/reports', reportsRoutes())
    app.use('/api/segments', segmentsRoutes())
    app.use('/api/staff', staffRoutes())
    app.use('/api/notifications', notificationRoutes())
    app.use('/api/expiry', expiryRoutes())
    app.use('/api/settings', settingsRoutes())
    app.use('/api/acquisition', acquisitionRoutes())
    app.use('/api/webhooks', webhookRoutes())
    app.use('/api/device', deviceRoutes())
    app.use('/api/activity-log', activityLogRoutes())
    app.use('/api/leads', leadRoutes())
    app.use('/api/staff-reports', staffReportRoutes())
}
export default initRoutes;