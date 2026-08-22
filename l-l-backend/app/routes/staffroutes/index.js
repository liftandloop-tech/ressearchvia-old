import express from "express";
import auth from "../../config/auth.js"
import upload from "../../config/upload.js";
import staffController from "../../controller/staffController.js";
import staffDocController from "../../controller/staffDocController.js";
import staffAttendanceController from "../../controller/staffAttendanceController.js";
import applicantController from "../../controller/applicantController.js";
import { checkPermission, adminOnly } from "../../middleware/accessMiddleware.js";
const Router = express.Router();

const staffRoutes = () => {
    Router.post("/staff-login", staffController.staffLogin)
    Router.post("/staff-mpin-login", staffController.staffMpinLogin)
    Router.post("/staff-otp-verify", staffController.staffOtpVerify)
    Router.post("/create", auth.tokenVerified, checkPermission('Staff', 'create'), staffController.staffCreate)
    Router.put("/reset", auth.tokenVerified, checkPermission('Staff', 'update'), staffController.staffReset)
    Router.delete("/delete", auth.tokenVerified, checkPermission('Staff', 'delete'), staffController.cancleStaff)
    Router.get("/list", auth.tokenVerified, adminOnly, staffController.staffList)
    Router.delete("/cancle/:id", auth.tokenVerified, checkPermission('Staff', 'delete'), staffController.cancleStaff)
    Router.post("/staff-assignment", auth.tokenVerified, checkPermission('Staff', 'update'), staffController.StaffAssignment)
    Router.get("/assigned-users", auth.tokenVerified, checkPermission('Users', 'read'), staffController.getStaffAssignedUsers)
    Router.get("/my-rm", auth.tokenVerified, staffController.getUserAssignedRM)

    // Public applicant routes
    Router.post("/applicant/register", applicantController.registerApplicant)
    Router.post("/applicant/verify", applicantController.verifyOtp)
    Router.post("/applicant/upload-doc/:id", (req, res, next) => { req.uploadType = req.query.type; next(); }, upload.single("file"), applicantController.uploadApplicantDoc)
    Router.post("/applicant/upload-video/:id", (req, res, next) => { req.uploadType = 'staff-video'; next(); }, upload.single("file"), applicantController.uploadApplicantVideo)
    Router.get("/applicant/:id", applicantController.getApplicantDetails)
    Router.post("/applicant/continue-init", applicantController.initiateContinueApplication)
    Router.post("/applicant/continue-verify", applicantController.verifyContinueApplication)

    // Admin applicant review & approval
    Router.get("/applicants", auth.tokenVerified, applicantController.listApplicants)
    Router.post("/applicant/approve/:id", auth.tokenVerified, applicantController.approveApplicant)

    // Document uploads for staff onboarding
    Router.post("/upload-doc/:id", auth.tokenVerified, (req, res, next) => { req.uploadType = req.query.type; next(); }, upload.single("file"), staffDocController.uploadDocument)
    Router.post("/upload-video/:id", auth.tokenVerified, (req, res, next) => { req.uploadType = 'staff-video'; next(); }, upload.single("file"), staffDocController.uploadVideo)

    // Attendance and face pings
    Router.post("/attendance/login", staffAttendanceController.loginSession)
    Router.post("/attendance/logout", staffAttendanceController.logoutSession)
    Router.post("/attendance/ping", staffAttendanceController.pingSession)
    Router.get("/attendance/summary/:staffId", auth.tokenVerified, staffAttendanceController.getDailyWorkSummary)

    return Router
}
export default staffRoutes;