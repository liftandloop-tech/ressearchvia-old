import express from "express";
import auth from "../../config/auth.js";
import departmentController from "../../controller/departmentController.js";

const Router = express.Router();

const departmentRoutes = () => {
    Router.get("/pages", auth.tokenVerified, departmentController.getAvailablePages);
    Router.post("/", auth.tokenVerified, departmentController.createDepartment);
    Router.get("/", auth.tokenVerified, departmentController.getDepartments);
    Router.get("/:id", auth.tokenVerified, departmentController.getDepartmentById);
    Router.put("/:id", auth.tokenVerified, departmentController.updateDepartment);
    Router.delete("/:id", auth.tokenVerified, departmentController.deleteDepartment);

    return Router;
};

export default departmentRoutes;
