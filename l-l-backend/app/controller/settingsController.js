import generalSettingsModel from "../models/generalSettingsModel.js";

const settingsController = {
    getSettings: async (req, res) => {
        try {
            const { key } = req.params;
            const settings = await generalSettingsModel.findOne({ key });
            // Return default if not found
            if (!settings) {
                // Return default values based on key
                if (key === 'lead_distribution') {
                    return res.status(200).send({
                        status: 200,
                        data: {
                            freshMaxPerStaff: 100,
                            freshPullSize: 20,
                            unreadMaxPerStaff: 50,
                            unreadPullSize: 10
                        }
                    });
                }
                if (key === 'expiry_alerts') {
                    return res.status(200).send({
                        status: 200,
                        data: { enabled: true, days: [7, 3] } // Default
                    });
                }
                if (key === 'bank_details') {
                    return res.status(200).send({
                        status: 200,
                        data: {
                            bankName: "HDFC Bank",
                            accountName: "SP ResearchVia Pvt Ltd",
                            accountNumber: "50200012345678",
                            ifscCode: "HDFC0001234"
                        }
                    });
                }
                return res.status(404).send({ status: 404, message: "Settings not found" });
            }
            res.status(200).send({ status: 200, data: settings.value });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    },

    updateSettings: async (req, res) => {
        try {
            const { key } = req.params;
            const { value } = req.body; // Expect JSON object

            const settings = await generalSettingsModel.findOneAndUpdate(
                { key },
                { value },
                { new: true, upsert: true }
            );

            res.status(200).send({ status: 200, message: "Settings updated", data: settings.value });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    },

    uploadQR: async (req, res) => {
        try {
            if (!req.file) {
                return res.status(400).send({ status: 400, message: "No file uploaded" });
            }
            // req.file.path can be absolute or relative; normalize to 'uploads/...'
            const rawPath = req.file.path.replace(/\\/g, "/");
            // Extract only the 'uploads/...' portion
            const uploadsIndex = rawPath.indexOf("uploads/");
            const publicPath = uploadsIndex !== -1 ? rawPath.substring(uploadsIndex) : rawPath;

            console.log("[uploadQR] rawPath:", rawPath, "-> publicPath:", publicPath);

            res.status(200).send({
                status: 200,
                message: "QR Code uploaded successfully",
                data: publicPath
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    }
};

export default settingsController;
