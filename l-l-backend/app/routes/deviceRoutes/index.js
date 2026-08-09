import express from "express";
import deviceController from "../../controller/deviceController.js";
import auth from "../../config/auth.js"; // Optional if we want to guard unlink

const Router = express.Router();

const deviceRoutes = () => {
    // Public endpoint because we register device before login
    Router.post("/register", deviceController.registerDevice);

    // Unlink can be protected or public with deviceId check
    Router.post("/unlink", deviceController.unlinkUser);

    return Router;
}

export default deviceRoutes;
