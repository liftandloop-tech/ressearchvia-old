import express from "express";
import segmentsController from "../../controller/segmentsController.js";
import auth from "../../config/auth.js"
import { appAccess, registrationAccess, contentAccess, paymentGate, checkPermission } from "../../middleware/accessMiddleware.js";

const Router = express.Router();

const SegmentsRoutes = () => {
    // Admin Routes (appAccess skips admin)
    Router.post("/create-segments", auth.tokenVerified, segmentsController.createSegments)
    Router.post("/segment-plan-create", auth.tokenVerified, segmentsController.segmentsPlanCreate)
    Router.put("/segment-plan-update", auth.tokenVerified, segmentsController.segmentsPlanUpdate)
    Router.put("/update-segments", auth.tokenVerified, segmentsController.updateSegments)
    Router.post("/admin-grant-segment", auth.tokenVerified, segmentsController.adminGrantSegment)
    Router.post("/reject-bank-transfer", auth.tokenVerified, segmentsController.rejectBankTransfer)
    Router.post("/revert-to-rejected", auth.tokenVerified, segmentsController.revertApproval)
    Router.post("/revert-to-approved", auth.tokenVerified, segmentsController.revertRejection)
    Router.get("/pending-bank-transfers", auth.tokenVerified, checkPermission('Payments', 'read'), segmentsController.getPendingBankTransfers)
    Router.get("/hni-requests", auth.tokenVerified, segmentsController.getHniRequests)
    Router.post("/admin-grant-hni-plan", auth.tokenVerified, segmentsController.adminGrantHniPlan)
    Router.get("/segment-user-list", auth.tokenVerified, segmentsController.userSegmentPlanList)
    Router.delete("/delete-segments", auth.tokenVerified, segmentsController.segmentsDelete)
    Router.delete("/segment-plan-delete", auth.tokenVerified, segmentsController.segmentsPlanDelete)

    // User Routes - Purchasing
    // Must be registered to buy plans
    Router.post("/segment-purchase", auth.tokenVerified, appAccess, registrationAccess, paymentGate, segmentsController.segmentsPurchase)
    Router.post("/segment-payment-verify", auth.tokenVerified, appAccess, registrationAccess, segmentsController.segmentsPaymentVerify)

    // User Routes - Viewing Plans (Registration required - users cannot browse until approved)
    Router.get("/mo-segments-plan-list", auth.tokenVerified, appAccess, registrationAccess, segmentsController.userSegmentsPlansList)
    Router.get("/segment-drop-down-list", auth.tokenVerified, appAccess, registrationAccess, segmentsController.segmentsDropDownList)
    Router.get("/segment-plan-list", auth.tokenVerified, appAccess, registrationAccess, segmentsController.segmentsPlanList)
    Router.get("/subscriptions-plan-list", auth.tokenVerified, appAccess, registrationAccess, segmentsController.subscriptionsPlanList)
    Router.get("/subscriptions-segment-list", auth.tokenVerified, appAccess, registrationAccess, segmentsController.subscriptionsSegmentList)

    // User Routes - Viewing Active Content / History
    Router.get("/user-active-segment", auth.tokenVerified, appAccess, registrationAccess, segmentsController.getUserActiveSegment) // Just logic to see what I have
    Router.get("/segment-invoice", auth.tokenVerified, appAccess, registrationAccess, segmentsController.segmentInvoice)
    Router.get("/segment-payment-history/:id", auth.tokenVerified, appAccess, registrationAccess, segmentsController.segmentPaymentHistroy)

    // Note: Actual "Trading Calls" or "Research Reports" routes are likely elsewhere (reportsRoutes).
    // If there is a route here for fetching calls, apply contentAccess.
    // userSegmentsPlansList seems to be "mo-segments-plan-list" which implies Mobile Segment Plan List.
    // If there isn't a "Get Calls" route here, I'll move to reportsRoutes.





    return Router
}
export default SegmentsRoutes;