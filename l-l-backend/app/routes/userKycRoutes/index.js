import express from "express";
import auth from "../../config/auth.js"
import upload from "../../config/upload.js";
import usersKycController from "../../controller/userKycController.js";
const Router = express.Router();

import { adminOnly, adminStrictOnly, kycDownloadAccess, checkPermission } from "../../middleware/accessMiddleware.js";

const userKycRoutes = () => {
  Router.post("/pancard-upload/:id", (req, res, next) => { req.query.type = 'pancard'; next(); }, upload.single("file"), usersKycController.pancardUpload)
  Router.post("/aadhaar-upload/:id", (req, res, next) => { req.query.type = 'aadhaar'; next(); }, upload.array("files", 5), usersKycController.aadhaarUpload)
  Router.post("/document-kyc/:id", auth.tokenVerified, usersKycController.usersDocKyc)

  // SECURED ADMIN KYC ROUTES
  Router.patch("/document/kyc-status-change", auth.tokenVerified, adminStrictOnly, checkPermission('KYC', 'update'), usersKycController.kycStatusChange)
  Router.put("/gate-status/:id", auth.tokenVerified, adminStrictOnly, checkPermission('KYC', 'update'), usersKycController.updateGateStatus)  // NEW: Per-gate approval/rejection
  Router.get("/document/kyc-list", auth.tokenVerified, adminOnly, checkPermission('KYC', 'read'), usersKycController.kycDocList)
  Router.post("/kyc-video-upload/:id", auth.tokenVerified, (req, res, next) => { req.uploadType = 'kyc-video'; next(); }, upload.single("file"), usersKycController.uploadKycVideo)
  Router.post("/admin/document/update-file/:id", auth.tokenVerified, adminStrictOnly, checkPermission('KYC', 'update'), (req, res, next) => {
    const docType = req.query?.docType;
    if (docType === 'video') {
      req.uploadType = 'kyc-video';
    } else if (docType === 'serviceAgreement' || docType === 'agreement' || docType === 'signedDocument') {
      req.uploadType = 'serviceAgreement';
    } else {
      req.uploadType = 'pancard';
    }
    next();
  }, upload.single("file"), usersKycController.updateAdminKycDocument)
  Router.get("/stream-video/:filename", usersKycController.streamKycVideo) // Public stream endpoint
  Router.get("/image/:filename", usersKycController.serveKycImage) // Public image endpoint
 
  // PROXY DIGIO DOWNLOAD
  Router.get("/document/download", auth.tokenVerified, kycDownloadAccess, checkPermission('KYC', 'read'), usersKycController.downloadDigioDocument)

  return Router

}
export default userKycRoutes;