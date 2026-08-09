import express from "express";
import auth from "../../config/auth.js";
import staffReportController from "../../controller/staffReportController.js";

const Router = express.Router();

const staffReportRoutes = () => {
    Router.get("/attendance", auth.tokenVerified, staffReportController.getAttendanceReport);
    Router.get("/conversion", auth.tokenVerified, staffReportController.getConversionReport);
    Router.get("/performance", auth.tokenVerified, staffReportController.getPerformanceOverview);

    return Router;
};

export default staffReportRoutes;
