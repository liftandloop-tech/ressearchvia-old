import express from "express";
import auth from "../../config/auth.js";
import roleController from "../../controller/roleController.js";

import { checkPermission } from "../../middleware/accessMiddleware.js";

const Router = express.Router();

const roleRoutes = () => {
    Router.post("/", auth.tokenVerified, checkPermission('Settings', 'create'), roleController.createRole);
    Router.get("/", auth.tokenVerified, roleController.getRoles);
    Router.get("/:id", auth.tokenVerified, roleController.getRoleById);
    Router.put("/:id", auth.tokenVerified, checkPermission('Settings', 'update'), roleController.updateRole);
    Router.delete("/:id", auth.tokenVerified, checkPermission('Settings', 'delete'), roleController.deleteRole);

    return Router;
};

export default roleRoutes;
