import express from "express";
import auth from "../../config/auth.js";
import { adminStrictOnlyNoStaff } from "../../middleware/accessMiddleware.js";
import refundController from "../../controller/refundController.js";

const Router = express.Router();

const refundRoutes = () => {
    // 1. Preview refund calculation (Admin Only)
    Router.post("/preview", auth.tokenVerified, adminStrictOnlyNoStaff, refundController.previewRefund);

    // 2. Execute & record refund (Admin Only)
    Router.post("/process", auth.tokenVerified, adminStrictOnlyNoStaff, refundController.processRefund);

    // 3. Get user refund history (Admin Only)
    Router.get("/user/:userId", auth.tokenVerified, adminStrictOnlyNoStaff, refundController.getUserRefunds);

    return Router;
};

export default refundRoutes;
