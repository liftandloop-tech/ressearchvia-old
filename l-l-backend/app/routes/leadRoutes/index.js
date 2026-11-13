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
    // Lead Pools
    Router.get("/pools", auth.tokenVerified, checkPermission('leads.view_pools'), leadPoolController.listLeadPools);
    Router.post("/pools", auth.tokenVerified, checkPermission('leads.view_pools'), leadPoolController.createLeadPool);
    Router.put("/pools/:id", auth.tokenVerified, checkPermission('leads.view_pools'), leadPoolController.updateLeadPool);
    Router.delete("/pools/:id", auth.tokenVerified, checkPermission('leads.view_pools'), leadPoolController.deleteLeadPool);
    Router.post("/pools/:id/assign", auth.tokenVerified, checkPermission('leads.view_pools'), leadPoolController.assignLeadPool);
    Router.get("/pools/:id/assignable-staff", auth.tokenVerified, checkPermission('leads.view_pools'), leadPoolController.getAssignableStaff);

    // Campaigns
    Router.get("/campaigns", auth.tokenVerified, checkPermission('leads.view'), leadController.listCampaigns);
    Router.post("/campaigns", auth.tokenVerified, checkPermission('leads.create'), leadController.createCampaign);
    Router.put("/campaigns/:id", auth.tokenVerified, checkPermission('leads.update'), leadController.updateCampaign);
    Router.delete("/campaigns/:id", auth.tokenVerified, checkPermission('leads.update'), leadController.deleteCampaign);

    // Vendors
    Router.get("/vendors", auth.tokenVerified, checkPermission('leads.view'), leadController.listVendors);
    Router.post("/vendors", auth.tokenVerified, checkPermission('leads.create'), leadController.createVendor);
    Router.put("/vendors/:id", auth.tokenVerified, checkPermission('leads.update'), leadController.updateVendor);
    Router.delete("/vendors/:id", auth.tokenVerified, checkPermission('leads.update'), leadController.deleteVendor);

    // Segments for Leads
    Router.get("/segments", auth.tokenVerified, checkPermission('leads.view'), leadController.listLeadSegments);
    Router.post("/:id/segments", auth.tokenVerified, checkPermission('leads.update'), leadController.assignLeadSegments);

    // Free Trial
    Router.patch("/:id/free-trial", auth.tokenVerified, checkPermission('leads.update'), leadController.updateFreeTrial);

    // Timeline & Activity History
    Router.get("/:id/timeline", auth.tokenVerified, checkPermission('leads.view'), leadController.getLeadTimeline);

    // Dedicated Pending Follow-ups View
    Router.get("/pending-followups", auth.tokenVerified, checkPermission('leads.view'), leadController.getPendingFollowups);
    Router.patch("/:id/follow-up/:followUpId", auth.tokenVerified, checkPermission('leads.follow_up'), leadController.updateFollowUpStatus);

    // Pull system
    Router.post("/pull", auth.tokenVerified, leadPullController.pullLeads);
    Router.get("/pull-stats", auth.tokenVerified, leadPullController.getPullStats);
    Router.patch("/:id/read", auth.tokenVerified, checkPermission('leads.view'), leadController.markAsRead);

    Router.post("/create", auth.tokenVerified, checkPermission('leads.create'), leadController.createLead);
    Router.post("/bulk-assign", auth.tokenVerified, checkPermission('leads.bulk_assign'), leadController.bulkAssign);
    Router.post("/bulk-assign-by-numbers", auth.tokenVerified, checkPermission('leads.bulk_assign'), leadController.bulkAssignByNumbers);
    Router.put("/update/:id", auth.tokenVerified, checkPermission('leads.update'), leadController.updateLead);
    Router.get("/", auth.tokenVerified, checkPermission('leads.view'), leadController.listLeads);
    Router.post("/follow-up/:id", auth.tokenVerified, checkPermission('leads.follow_up'), leadController.addFollowUp);
    Router.get("/template", leadController.getTemplate);

    // Dynamic Import Endpoints
    Router.get("/import-fields", auth.tokenVerified, checkPermission('leads.bulk_upload'), importController.getImportFields);
    Router.post("/import/:importId/preview", auth.tokenVerified, checkPermission('leads.bulk_upload'), importController.getPreview);
    Router.post("/import/:importId/start", auth.tokenVerified, checkPermission('leads.bulk_upload'), importController.startImport);
    Router.get("/import/:importId/status", auth.tokenVerified, checkPermission('leads.view'), importController.getImportStatus);
    Router.get("/import/:importId/errors", auth.tokenVerified, checkPermission('leads.view'), importController.getImportErrors);
    Router.get("/import/templates", auth.tokenVerified, checkPermission('leads.view'), importController.getTemplates);
    Router.post("/import/templates", auth.tokenVerified, checkPermission('leads.bulk_upload'), importController.saveTemplate);
    
    // Bulk Lead Ingestion Route (Re-used for initial file upload)
    Router.post(
        "/bulk-upload", 
        auth.tokenVerified, 
        checkPermission('leads.bulk_upload'),
        (req, res, next) => { req.uploadType = 'bulk-import'; next(); }, 
        upload.single("file"), 
        leadController.bulkUpload
    );

    // Bulk Paste Ingestion Route (Line breaks / commas / semicolons separated numbers)
    Router.post(
        "/bulk-paste",
        auth.tokenVerified,
        checkPermission('leads.bulk_upload'),
        leadController.bulkPaste
    );

    return Router;
};

export default leadRoutes;
