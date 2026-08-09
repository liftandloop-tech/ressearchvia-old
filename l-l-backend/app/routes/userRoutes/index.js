import express from "express";
import auth from "../../config/auth.js"
import usersController from "../../controller/userController.js"
import upload from "../../config/upload.js";
import { appAccess, adminOnly, adminStrictOnly } from "../../middleware/accessMiddleware.js";
const Router = express.Router();

const usersRoutes = () => {
  Router.post("/create-user", usersController.userCreate)
  Router.put("/sign-up", usersController.userSignUp)
  Router.post("/verify-otp", usersController.verifyOtp)
  Router.post("/set-mpin", usersController.setMpin)
  Router.post("/login", usersController.login)
  Router.post("/send-otp", usersController.sendOpt)
  Router.post("/refresh-token", usersController.refreshToken)
  Router.post("/logout", auth.tokenVerified, usersController.logOutUser)

  // Disclaimer (Chunk 2)
  Router.post("/accept-disclaimer", auth.tokenVerified, usersController.acceptDisclaimer)

  // Admin Routes (appAccess skips for admin, but good to have if we want to enforce user status)
  Router.get("/user-list", auth.tokenVerified, adminOnly, usersController.userList)
  Router.delete("/delete-user/:id", auth.tokenVerified, adminStrictOnly, usersController.userDelete)
  Router.put("/suspend-user/:id", auth.tokenVerified, adminStrictOnly, usersController.userSuspend)
  Router.put("/activate-user/:id", auth.tokenVerified, adminStrictOnly, usersController.userActivate)
  Router.get("/user-details/:id", auth.tokenVerified, (req, res, next) => {
    // Allow if Admin, Director, Researcher OR if accessing own data
    if (
      req.user?.userType === 'admin' ||
      req.user?.userType === 'super_admin' ||
      req.user?.userType === 'Director' ||
      req.user?._id == req.params?.id
    ) {
      return next();
    }
    return res.status(403).json({ message: "Access Denied" });
  }, usersController.userDetails)
  Router.get("/dashboard-count", auth.tokenVerified, adminOnly, usersController.dashboardCount)

  // User Routes - Protected
  Router.post("/image-change/:id", auth.tokenVerified, appAccess, upload.single("file"), usersController.userImageUpdate)
  Router.put("/update/:id", auth.tokenVerified, appAccess, usersController.updateProfile)

  // CRITICAL SECURITY FIX: Lock down Admin Provisioning
  Router.post("/admin-create", auth.tokenVerified, adminStrictOnly, usersController.adminCreate)
  Router.put("/admin-update-user/:id", auth.tokenVerified, adminStrictOnly, usersController.adminUpdateUser)
  Router.post("/admin-login", usersController.adminLogin) // Login must be public
  Router.post("/bypass-payment", auth.tokenVerified, adminStrictOnly, usersController.bypassPayment)
  Router.put("/generate-temp-pin/:id", auth.tokenVerified, adminStrictOnly, usersController.adminGenerateTempPin)


  return Router

}
export default usersRoutes;