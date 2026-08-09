import devices from "../models/deviceModel.js";
import users from "../models/userModel.js";

const deviceController = {
    registerDevice: async (req, res) => {
        try {
            const { deviceId, platform, pushToken, userId } = req.body;

            if (!deviceId || !pushToken || !platform) {
                return res.status(400).json({
                    status: 400,
                    message: "Missing required fields: deviceId, platform, pushToken"
                });
            }

            if (userId) {
                // SINGLE ACTIVE DEVICE ENFORCEMENT
                // Deactivate all other devices associated with this user (But keep userId for notifications)
                await devices.updateMany(
                    { userId: userId, deviceId: { $ne: deviceId } },
                    { $set: { isActive: false } }
                );

                // SYNC userModel fcmToken (CRITICAL FIX)
                try {
                    await users.findByIdAndUpdate(userId, {
                        fcmToken: pushToken,
                        sessionDeviceId: deviceId,
                        sessionIssuedAt: new Date()
                    });
                } catch (e) {
                    console.error("Failed to sync fcmToken to User:", e);
                }
            }

            // Upsert current device
            const filter = { deviceId: deviceId };
            const update = {
                platform: platform,
                pushToken: pushToken,
                isActive: true, // Always mark current as active
                lastSeenAt: new Date(),
                ...(userId ? { userId: userId } : {})
            };

            const options = { new: true, upsert: true, setDefaultsOnInsert: true };

            const device = await devices.findOneAndUpdate(filter, update, options);

            return res.status(200).json({
                status: 200,
                message: "Device registered successfully",
                data: { device }
            });

        } catch (error) {
            console.error("Device Registration Error:", error);
            return res.status(500).json({
                status: 500,
                message: error.message
            });
        }
    },

    // Optional: Call this on logout if you want to unlink user but keep device active for general alerts
    unlinkUser: async (req, res) => {
        try {
            const { deviceId } = req.body;
            if (!deviceId) return res.status(400).json({ message: "DeviceId required" });

            await devices.updateOne(
                { deviceId: deviceId },
                { $set: { userId: null, lastSeenAt: new Date() } }
            );

            return res.status(200).json({ status: 200, message: "User unlinked from device" });
        } catch (error) {
            return res.status(500).json({ status: 500, message: error.message });
        }
    }
};

export default deviceController;
