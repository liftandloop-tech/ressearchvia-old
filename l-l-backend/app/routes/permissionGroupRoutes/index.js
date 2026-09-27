import express from "express";
import auth from "../../config/auth.js";
import permissionGroupController from "../../controller/permissionGroupController.js";

import { checkPermission } from "../../middleware/accessMiddleware.js";

const Router = express.Router();

const permissionGroupRoutes = () => {
    Router.post("/", auth.tokenVerified, checkPermission('Settings', 'create'), permissionGroupController.createPermissionGroup);
    Router.get("/", auth.tokenVerified, checkPermission('Settings', 'read'), permissionGroupController.getPermissionGroups);
    Router.get("/:id", auth.tokenVerified, checkPermission('Settings', 'read'), permissionGroupController.getPermissionGroupById);
    Router.put("/:id", auth.tokenVerified, checkPermission('Settings', 'update'), permissionGroupController.updatePermissionGroup);
    Router.delete("/:id", auth.tokenVerified, checkPermission('Settings', 'delete'), permissionGroupController.deletePermissionGroup);

    return Router;
};

export default permissionGroupRoutes;
