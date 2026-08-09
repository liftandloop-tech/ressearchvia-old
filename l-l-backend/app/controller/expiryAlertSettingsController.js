import expiryAlertSettingsModel from "../models/expiryAlertSettingsModel.js";

const expiryAlertSettingsController = {
    getSettings: async (req, res) => {
        try {
            console.log("Fetching expiry settings...");
            // Find the single settings document. If not exists, return default.
            let settings = await expiryAlertSettingsModel.findOne();

            if (!settings) {
                console.log("No settings found. Creating default...");
                // Create default settings in DB so collection is created immediately
                settings = await expiryAlertSettingsModel.create({
                    isAutomatedAlertsEnabled: true,
                    alerts: [
                        { days: 7, enabled: true },
                        { days: 3, enabled: true },
                        { days: 1, enabled: true }
                    ]
                });
            }

            res.status(200).send({
                status: 200,
                message: "Settings retrieved",
                data: settings
            });
        } catch (error) {
            console.error("Error in getSettings:", error);
            res.status(500).send({ status: 500, message: error.message });
        }
    },

    updateSettings: async (req, res) => {
        try {
            console.log("Updating expiry settings. Body:", req.body);
            const { isAutomatedAlertsEnabled, alerts } = req.body;

            // Validate basic structure
            if (typeof isAutomatedAlertsEnabled !== 'boolean' || !Array.isArray(alerts)) {
                console.warn("Invalid payload structure:", req.body);
                return res.status(400).send({ status: 400, message: "Invalid payload structure" });
            }

            // Upsert: update if exists, insert if not
            const settings = await expiryAlertSettingsModel.findOneAndUpdate(
                {}, // match any (we assume singleton)
                { isAutomatedAlertsEnabled, alerts },
                { new: true, upsert: true, setDefaultsOnInsert: true }
            );

            console.log("Settings updated successfully:", settings);
            res.status(200).send({
                status: 200,
                message: "Settings updated successfully",
                data: settings
            });
        } catch (error) {
            console.error("Error in updateSettings:", error);
            res.status(500).send({ status: 500, message: error.message });
        }
    }
};

export default expiryAlertSettingsController;
