import express from "express";
import auth from "../../config/auth.js";
import upload from "../../config/upload.js";
import leadController from "../../controller/leadController.js";
import importController from "../../controller/importController.js";
import leadPoolController from "../../controller/leadPoolController.js";
import leadPullController from "../../controller/leadPullController.js";
import { checkPermission } from "../../middleware/accessMiddleware.js";

const Router = express.Router();

const leadRoutes = () => {
    Router.get("/pools", auth.tokenVerified, checkPermission('Leads', 'read'), leadPoolController.listLeadPools);
    Router.post("/pools", auth.tokenVerified, checkPermission('Leads', 'create'), leadPoolController.createLeadPool);

    // Pull system
    Router.post("/pull", auth.tokenVerified, leadPullController.pullLeads);
    Router.get("/pull-stats", auth.tokenVerified, leadPullController.getPullStats);
    Router.patch("/:id/read", auth.tokenVerified, leadController.markAsRead);

    Router.post("/create", auth.tokenVerified, checkPermission('Leads', 'create'), leadController.createLead);
    Router.post("/bulk-assign", auth.tokenVerified, checkPermission('Leads', 'update'), leadController.bulkAssign);
    Router.put("/update/:id", auth.tokenVerified, checkPermission('Leads', 'update'), leadController.updateLead);
    Router.get("/", auth.tokenVerified, checkPermission('Leads', 'read'), leadController.listLeads);
    Router.post("/follow-up/:id", auth.tokenVerified, checkPermission('Leads', 'update'), leadController.addFollowUp);
    Router.get("/template", leadController.getTemplate);

    // Dynamic Import Endpoints
    Router.get("/import-fields", auth.tokenVerified, checkPermission('Leads', 'create'), importController.getImportFields);
    Router.post("/import/:importId/preview", auth.tokenVerified, checkPermission('Leads', 'create'), importController.getPreview);
    Router.post("/import/:importId/start", auth.tokenVerified, checkPermission('Leads', 'create'), importController.startImport);
    Router.get("/import/:importId/status", auth.tokenVerified, checkPermission('Leads', 'read'), importController.getImportStatus);
    Router.get("/import/:importId/errors", auth.tokenVerified, checkPermission('Leads', 'read'), importController.getImportErrors);
    Router.get("/import/templates", auth.tokenVerified, checkPermission('Leads', 'read'), importController.getTemplates);
    Router.post("/import/templates", auth.tokenVerified, checkPermission('Leads', 'create'), importController.saveTemplate);
    
    // Bulk Lead Ingestion Route (Re-used for initial file upload)
    Router.post(
        "/bulk-upload", 
        auth.tokenVerified, 
        checkPermission('Leads', 'create'),
        (req, res, next) => { req.uploadType = 'bulk-import'; next(); }, 
        upload.single("file"), 
        leadController.bulkUpload
    );

    return Router;
};

export default leadRoutes;
