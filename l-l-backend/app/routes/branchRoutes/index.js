import express from "express";
import auth from "../../config/auth.js";
import branchController from "../../controller/branchController.js";
import { checkPermission } from "../../middleware/accessMiddleware.js";

const Router = express.Router();

const branchRoutes = () => {
    // List branches - accessible to authenticated staff
    Router.get("/", auth.tokenVerified, branchController.getBranches);
    Router.get("/list", auth.tokenVerified, branchController.getBranches);

    // Detail
    Router.get("/:id", auth.tokenVerified, branchController.getBranchById);

    // Mutations - require Settings permission or admin
    Router.post("/", auth.tokenVerified, checkPermission('Settings', 'create'), branchController.createBranch);
    Router.post("/create", auth.tokenVerified, checkPermission('Settings', 'create'), branchController.createBranch);
    Router.put("/:id", auth.tokenVerified, checkPermission('Settings', 'update'), branchController.updateBranch);
    Router.delete("/:id", auth.tokenVerified, checkPermission('Settings', 'delete'), branchController.deleteBranch);

    return Router;
};

export default branchRoutes;

