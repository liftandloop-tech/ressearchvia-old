import express from "express";
import auth from "../../config/auth.js";
import telephonyController from "../../controller/telephonyController.js";

const Router = express.Router();

const telephonyRoutes = () => {
    // Click to Call
    Router.post("/click-to-call", auth.tokenVerified, telephonyController.initiateClickToCall);

    // Call status and control
    Router.get("/calls/:callId/status", auth.tokenVerified, telephonyController.getCallStatus);
    Router.post("/calls/:callId/hangup", auth.tokenVerified, telephonyController.terminateCall);

    // Call history per lead
    Router.get("/lead/:leadId/calls", auth.tokenVerified, telephonyController.getLeadCallHistory);

    // Convert/Log call into follow-up
    Router.post("/calls/:callLogId/log-followup", auth.tokenVerified, telephonyController.logCallFollowUp);

    // Extensions & staff configuration
    Router.get("/extensions", auth.tokenVerified, telephonyController.getExtensions);
    Router.put("/staff/:staffId/extension", auth.tokenVerified, telephonyController.updateStaffExtension);

    return Router;
};

export default telephonyRoutes;
