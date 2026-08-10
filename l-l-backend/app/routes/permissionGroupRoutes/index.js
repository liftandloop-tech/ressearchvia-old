import express from "express";
import auth from "../../config/auth.js";
import permissionGroupController from "../../controller/permissionGroupController.js";

const Router = express.Router();

const permissionGroupRoutes = () => {
    Router.post("/", auth.tokenVerified, permissionGroupController.createPermissionGroup);
    Router.get("/", auth.tokenVerified, permissionGroupController.getPermissionGroups);
    Router.get("/:id", auth.tokenVerified, permissionGroupController.getPermissionGroupById);
    Router.put("/:id", auth.tokenVerified, permissionGroupController.updatePermissionGroup);
    Router.delete("/:id", auth.tokenVerified, permissionGroupController.deletePermissionGroup);

    return Router;
};

export default permissionGroupRoutes;
