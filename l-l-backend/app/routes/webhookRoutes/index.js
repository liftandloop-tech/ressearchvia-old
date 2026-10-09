import express from "express";
import webhookController from "../../controller/webhookController.js";
import { handleRazorpayWebhook } from "../../controller/razorpayWebhookController.js";

const Router = express.Router();

const webhookRoutes = () => {
    Router.post("/digio", webhookController.digioWebhook);
    Router.post("/razorpay", handleRazorpayWebhook);
    return Router;
}

export default webhookRoutes;

