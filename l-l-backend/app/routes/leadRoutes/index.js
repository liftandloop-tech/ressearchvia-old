import express from "express";
import auth from "../../config/auth.js";
import upload from "../../config/upload.js";
import leadController from "../../controller/leadController.js";

const Router = express.Router();

const leadRoutes = () => {
    Router.post("/create", auth.tokenVerified, leadController.createLead);
    Router.put("/update/:id", auth.tokenVerified, leadController.updateLead);
    Router.get("/", auth.tokenVerified, leadController.listLeads);
    Router.post("/follow-up/:id", auth.tokenVerified, leadController.addFollowUp);
    Router.get("/template", leadController.getTemplate);
    
    // Bulk Lead Ingestion Route
    Router.post(
        "/bulk-upload", 
        auth.tokenVerified, 
        (req, res, next) => { req.uploadType = 'bulk-import'; next(); }, 
        upload.single("file"), 
        leadController.bulkUpload
    );

    return Router;
};

export default leadRoutes;
