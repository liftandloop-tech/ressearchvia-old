import express from "express";
import auth from "../../config/auth.js";
import * as acquisitionController from "../../controller/acquisitionController.js";

import upload from "../../config/upload.js";

import { adminOnly, registrationAccess, adminStrictOnly } from "../../middleware/accessMiddleware.js";

const Router = express.Router();

const acquisitionRoutes = () => {
    // Online Flow (Self-Registered)
    Router.post("/registration-order", auth.tokenVerified, acquisitionController.initiateRegistration);
    Router.post("/plan-order", auth.tokenVerified, registrationAccess, acquisitionController.initiatePlan);
    Router.post("/verify-payment", auth.tokenVerified, acquisitionController.verifyPayment);
    Router.post("/upload-proof", auth.tokenVerified, (req, res, next) => { req.query.type = 'payment-proof'; next(); }, upload.array('file', 5), acquisitionController.uploadProof);
    Router.get("/active-partial-info", auth.tokenVerified, acquisitionController.getActivePartialInfo);
    Router.get("/partial-history", auth.tokenVerified, acquisitionController.getPartialHistory);
    Router.get("/partial-history/:intentId", auth.tokenVerified, acquisitionController.getPartialHistory);
    Router.get("/registration-details", auth.tokenVerified, acquisitionController.getRegistrationDetails);

    // Offline Flow (Admin)
    Router.post("/admin-onboard", auth.tokenVerified, adminOnly, acquisitionController.adminOnboardUser);
    Router.post("/approve-partial-payment", auth.tokenVerified, adminOnly, acquisitionController.approvePartialPayment);
    Router.post("/reject-partial-payment", auth.tokenVerified, adminOnly, acquisitionController.rejectPartialPayment);
    Router.post("/update-payment-discount", auth.tokenVerified, adminOnly, acquisitionController.updatePaymentDiscount);
    Router.post("/update-subscription-metadata", auth.tokenVerified, adminStrictOnly, acquisitionController.updateSubscriptionMetadata);

    return Router;
};


export default acquisitionRoutes;
