import leadModel from "../models/leadModel.js";
import generalSettingsModel from "../models/generalSettingsModel.js";
import { ensureDefaultFreshPool } from "./leadPoolController.js";

// Load lead distribution config with defaults
const getDistributionConfig = async (companyId) => {
    const key = `lead_distribution_${companyId}`;
    const doc = await generalSettingsModel.findOne({ key });
    if (doc && doc.value) return doc.value;
    // Fallback to global key
    const global = await generalSettingsModel.findOne({ key: 'lead_distribution' });
    if (global && global.value) return global.value;
    // Hard defaults
    return { freshMaxPerStaff: 100, freshPullSize: 20, unreadMaxPerStaff: 50, unreadPullSize: 10 };
};

const leadPullController = {
    getPullStats: async (req, res) => {
        try {
            const staffId = req.user._id;
            const companyId = req.user.companyId || req.user.company || "default_company";

            const config = await getDistributionConfig(companyId);
            const freshPool = await ensureDefaultFreshPool(companyId);

            // Count leads in Fresh Pool not yet assigned (available for pulling)
            const freshAvailable = await leadModel.countDocuments({
                companyId,
                leadPoolId: freshPool._id,
                assignedRM: null
            });

            // Count staff's currently assigned fresh leads (only active unworked fresh leads: stage 'New' and no follow-ups)
            const myFresh = await leadModel.countDocuments({
                companyId,
                leadPoolId: freshPool._id,
                assignedRM: staffId,
                stage: 'New',
                $or: [{ followUps: { $exists: false } }, { followUps: { $size: 0 } }]
            });

            // Count staff's unread leads across any pool
            const myUnread = await leadModel.countDocuments({
                companyId,
                assignedRM: staffId,
                stage: 'New',
                followUps: { $size: 0 }
            });

            res.status(200).send({
                status: 200,
                message: "Pull stats retrieved",
                data: {
                    freshAvailable,
                    myFresh,
                    freshMax: config.freshMaxPerStaff,
                    myUnread,
                    unreadMax: config.unreadMaxPerStaff
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    },

    pullLeads: async (req, res) => {
        try {
            const { type = "fresh" } = req.body;
            const staffId = req.user._id;
            const companyId = req.user.companyId || req.user.company || "default_company";

            const config = await getDistributionConfig(companyId);

            if (type === "fresh") {
                const freshPool = await ensureDefaultFreshPool(companyId);
                const freshMax = config.freshMaxPerStaff || 100;
                const freshPullSize = config.freshPullSize || 20;

                // Count current fresh leads held by this staff member (only active unworked fresh leads: stage 'New' and no follow-ups)
                const myFresh = await leadModel.countDocuments({
                    companyId,
                    leadPoolId: freshPool._id,
                    assignedRM: staffId,
                    stage: 'New',
                    $or: [{ followUps: { $exists: false } }, { followUps: { $size: 0 } }]
                });

                const remainingCapacity = Math.max(0, freshMax - myFresh);

                if (remainingCapacity === 0) {
                    const freshAvailable = await leadModel.countDocuments({
                        companyId, leadPoolId: freshPool._id, assignedRM: null
                    });
                    return res.status(200).send({
                        status: 200,
                        message: "You have reached your Fresh Lead limit",
                        data: { pulled: 0, maximum: freshMax, current: myFresh, remainingCapacity: 0, availableFresh: freshAvailable }
                    });
                }

                // How many we can pull
                const freshAvailable = await leadModel.countDocuments({
                    companyId, leadPoolId: freshPool._id, assignedRM: null
                });

                if (freshAvailable === 0) {
                    return res.status(200).send({
                        status: 200,
                        message: "No fresh leads are currently available",
                        data: { pulled: 0, maximum: freshMax, current: myFresh, remainingCapacity, availableFresh: 0 }
                    });
                }

                const actualPull = Math.min(remainingCapacity, freshPullSize, freshAvailable);

                // Atomic per-lead assignment — prevents concurrent double-pull
                let pulled = 0;
                for (let i = 0; i < actualPull; i++) {
                    const assigned = await leadModel.findOneAndUpdate(
                        { companyId, leadPoolId: freshPool._id, assignedRM: null },
                        { $set: { assignedRM: staffId } },
                        { new: true }
                    );
                    if (!assigned) break; // pool exhausted mid-pull
                    pulled++;
                }

                const newCount = myFresh + pulled;
                return res.status(200).send({
                    status: 200,
                    message: pulled > 0 ? `${pulled} lead${pulled === 1 ? '' : 's'} pulled successfully` : "No fresh leads available",
                    data: {
                        pulled,
                        maximum: freshMax,
                        current: newCount,
                        remainingCapacity: Math.max(0, freshMax - newCount),
                        availableFresh: Math.max(0, freshAvailable - pulled)
                    }
                });
            }

            res.status(400).send({ status: 400, message: "Invalid pull type. Use 'fresh'." });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    }
};

export default leadPullController;
