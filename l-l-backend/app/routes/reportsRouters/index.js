import express from "express";
import auth from "../../config/auth.js"
import upload from "../../config/upload.js";
import reportsController from "../../controller/reportController.js";
import { appAccess, registrationAccess, contentAccess, adminOnly, adminStrictOnly, reportManagementAccess } from "../../middleware/accessMiddleware.js";
import { disclaimerCheck } from "../../middleware/disclaimerMiddleware.js";

const Router = express.Router();

const reportsRoutes = () => {
  // Admin Routes - SECURITY HARDENING
  Router.post("/create-report", auth.tokenVerified, reportManagementAccess, upload.single('file'), reportsController.createReport)
  Router.post("/report-update", auth.tokenVerified, reportManagementAccess, upload.single('file'), reportsController.updateReport)
  Router.delete("/report-delete/:id", auth.tokenVerified, reportManagementAccess, reportsController.deleteReport)
  Router.put("/report-public-status-change", auth.tokenVerified, reportManagementAccess, reportsController.publishReportStatus)
  Router.get("/report-list", auth.tokenVerified, adminOnly, reportsController.reportList) // Admin list

  // Automated Integration Route from automated-api-one (Uses Header API Key Verification instead of User session tokens)
  Router.post("/automated-trading-call", reportsController.createAutomatedTradingCall)

  // User Content Access
  // Must have: App Access -> Registration -> Active Plan -> KYC Verified -> DISCLAIMER ACCEPTED
  Router.get("/download-report/:id", auth.tokenVerified, appAccess, registrationAccess, contentAccess, disclaimerCheck, reportsController.reportDownload)
  Router.get("/user-report-list/:id", auth.tokenVerified, appAccess, registrationAccess, contentAccess, disclaimerCheck, reportsController.userReportList)

  return Router
}
export default reportsRoutes;