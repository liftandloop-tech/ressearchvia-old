import express from "express";
import auth from "../../config/auth.js";
import departmentController from "../../controller/departmentController.js";

import { checkPermission } from "../../middleware/accessMiddleware.js";

const Router = express.Router();

const departmentRoutes = () => {
    Router.get("/pages", auth.tokenVerified, checkPermission('Settings', 'read'), departmentController.getAvailablePages);
    Router.post("/", auth.tokenVerified, checkPermission('Settings', 'create'), departmentController.createDepartment);
    Router.get("/", auth.tokenVerified, departmentController.getDepartments);
    Router.get("/:id", auth.tokenVerified, departmentController.getDepartmentById);
    Router.put("/:id", auth.tokenVerified, checkPermission('Settings', 'update'), departmentController.updateDepartment);
    Router.delete("/:id", auth.tokenVerified, checkPermission('Settings', 'delete'), departmentController.deleteDepartment);

    return Router;
};

export default departmentRoutes;
