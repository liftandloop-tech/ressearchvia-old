import express from "express";
import auth from "../../config/auth.js";
import roleController from "../../controller/roleController.js";

const Router = express.Router();

const roleRoutes = () => {
    Router.post("/", auth.tokenVerified, roleController.createRole);
    Router.get("/", auth.tokenVerified, roleController.getRoles);
    Router.get("/:id", auth.tokenVerified, roleController.getRoleById);
    Router.put("/:id", auth.tokenVerified, roleController.updateRole);
    Router.delete("/:id", auth.tokenVerified, roleController.deleteRole);

    return Router;
};

export default roleRoutes;
