import express from "express";
import expiryAlertSettingsController from "../../controller/expiryAlertSettingsController.js";
import auth from "../../config/auth.js";

const router = express.Router();

router.get("/settings", auth.tokenVerified, expiryAlertSettingsController.getSettings);
router.post("/settings", auth.tokenVerified, expiryAlertSettingsController.updateSettings);

const initExpiryRoutes = () => router;

export default initExpiryRoutes;
