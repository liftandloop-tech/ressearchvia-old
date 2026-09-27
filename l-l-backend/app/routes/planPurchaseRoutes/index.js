import express from "express";
import auth from "../../config/auth.js";
import planPurchaseController from "../../controller/planPurchaseController.js";
const Router = express.Router();

import { appAccess, paymentGate, checkPermission } from "../../middleware/accessMiddleware.js";

import upload from "../../config/upload.js";

const purchasePlanRoutes = () => {
  // Registration Purchase (User must be logged in and passed KYC Gate A)
  Router.post("/registration-purchase/:id", auth.tokenVerified, appAccess, paymentGate, planPurchaseController.purchaseRegistration);

  Router.post("/plan/:id", auth.tokenVerified, paymentGate, planPurchaseController.purchasePlan,);
  Router.get("/user-active-plan/:id", auth.tokenVerified, planPurchaseController.getUserActivePlan,);
  Router.patch("/expiry-reminders/:id", auth.tokenVerified, planPurchaseController.expiryReminderOnOff,);
  Router.post("/razorpay/verify", auth.tokenVerified, planPurchaseController.paymentVerify);

  Router.post("/upload-proof", auth.tokenVerified, (req, res, next) => { req.query.type = 'payment-proof'; next(); }, upload.array('file', 5), planPurchaseController.uploadPaymentProof);

  Router.get("/user-subscription-history/:id", auth.tokenVerified, planPurchaseController.subcriptionHistory);
  Router.get("/billing-history/:id", auth.tokenVerified, planPurchaseController.billingHistory);
  Router.get("/recent-plan-payment-list", auth.tokenVerified, planPurchaseController.recentPaymentList)

  // --- Admin Subscription Management (Permission Guarded) ---
  Router.put("/extend-subscription", auth.tokenVerified, checkPermission('subscriptions.edit_correction'), planPurchaseController.extendSubscription);
  // Router.put("/revoke-subscription", auth.tokenVerified, planPurchaseController.revokeSubscription); // Removed as per request
  Router.put("/change-plan", auth.tokenVerified, checkPermission('subscriptions.edit_correction'), planPurchaseController.changePlan);
  Router.put("/suspend-subscription", auth.tokenVerified, checkPermission('subscriptions.suspend'), planPurchaseController.suspendSubscription);
  Router.put("/activate-subscription", auth.tokenVerified, checkPermission('subscriptions.activate'), planPurchaseController.activateSubscription);
  Router.put("/update-subscription-dates", auth.tokenVerified, checkPermission('subscriptions.edit_correction'), planPurchaseController.updateSubscriptionDates);
  Router.post("/admin/create-plan", auth.tokenVerified, checkPermission('subscriptions.activate'), planPurchaseController.adminCreatePlan);
  Router.post("/admin/topup-partial-plan", auth.tokenVerified, checkPermission('subscriptions.activate'), planPurchaseController.adminTopUpPartialPlan);
  Router.post("/admin/update-payment", auth.tokenVerified, checkPermission('subscriptions.edit_correction'), (req, res, next) => { req.query.type = 'payment-proof'; next(); }, upload.array('file', 5), planPurchaseController.adminUpdatePayment);
  Router.post("/admin/preview-correction", auth.tokenVerified, checkPermission('subscriptions.view'), planPurchaseController.adminPreviewCorrection);

  return Router;
};
export default purchasePlanRoutes;
