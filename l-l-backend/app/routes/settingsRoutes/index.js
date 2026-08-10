import express from "express";
import settingsController from "../../controller/settingsController.js";
import auth from "../../config/auth.js"; // Assuming auth middleware exists

import upload from "../../config/upload.js";
import { checkPermission } from "../../middleware/accessMiddleware.js";

const router = express.Router();

router.post("/upload-qr", auth.tokenVerified, checkPermission('Settings', 'update'), (req, res, next) => {
    req.uploadType = "image"; // Use custom property — req.query is read-only in Express
    next();
}, (req, res, next) => {
    upload.single("file")(req, res, function (err) {
        if (err) {
            return res.status(400).send({ status: 400, message: err.message || "Upload failed" });
        }
        next();
    });
}, settingsController.uploadQR);

router.get("/:key", settingsController.getSettings);
router.post("/:key", auth.tokenVerified, checkPermission('Settings', 'update'), settingsController.updateSettings);

const initSettingsRoutes = () => router;

export default initSettingsRoutes;
