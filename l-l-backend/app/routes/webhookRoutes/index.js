import express from "express";
import webhookController from "../../controller/webhookController.js";

const Router = express.Router();

const webhookRoutes = () => {
    Router.post("/digio", webhookController.digioWebhook);
    return Router;
}

export default webhookRoutes;
