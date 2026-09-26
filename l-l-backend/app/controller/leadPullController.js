import leadModel from "../models/leadModel.js";
import leadPoolModel from "../models/leadPoolModel.js";
import generalSettingsModel from "../models/generalSettingsModel.js";
import { ensureDefaultFreshPool } from "./leadPoolController.js";
import { getAccessibleLeadPoolFilter } from "../utils/staffHierarchy.js";

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
            const staffId = req.user?._id || req.user?.userId || req.user?.id;
            const companyId = req.user?.companyId || req.user?.company || "default_company";

            const config = await getDistributionConfig(companyId);
            const freshPool = await ensureDefaultFreshPool(companyId);

            // Fetch only active pools accessible to this staff member / role
            const poolFilter = await getAccessibleLeadPoolFilter(staffId, companyId);
            poolFilter.isActive = { $ne: false };
            const allPools = await leadPoolModel.find(poolFilter).sort({ createdAt: 1 }).lean();

            // Calculate live per-pool stats
            const poolsStats = await Promise.all(allPools.map(async (p) => {
                const isDefaultFresh = p.name === "Fresh Leads";
                const pMax = (isDefaultFresh && config.freshMaxPerStaff) ? config.freshMaxPerStaff : (p.maxPerStaff || config.freshMaxPerStaff || 100);
                const pSize = (isDefaultFresh && config.freshPullSize) ? config.freshPullSize : (p.pullSize || config.freshPullSize || 20);

                const availableLeads = await leadModel.countDocuments({
                    companyId,
                    leadPoolId: p._id,
                    assignedRM: null
                });

                const myLeads = await leadModel.countDocuments({
                    companyId,
                    leadPoolId: p._id,
                    assignedRM: staffId,
                    stage: 'New',
                    $or: [{ followUps: { $exists: false } }, { followUps: { $size: 0 } }]
                });

                const totalLeads = await leadModel.countDocuments({
                    companyId,
                    leadPoolId: p._id
                });

                return {
                    _id: p._id,
                    id: p._id,
                    name: p.name,
                    poolId: p._id,
                    poolName: p.name,
                    description: p.description,
                    pullSize: pSize,
                    maxPerStaff: pMax,
                    isActive: p.isActive !== false,
                    availableLeads,
                    myLeads,
                    remainingCapacity: Math.max(0, pMax - myLeads),
                    totalLeads,
                    isDefaultFresh: p.name === "Fresh Leads",
                    isGlobal: p.isGlobal !== false,
                    createdByName: p.createdByName || (p.name === "Fresh Leads" ? "System Admin" : "Staff")
                };
            }));

            // Backward compatible Fresh Pool metrics
            const freshStats = poolsStats.find(p => p.isDefaultFresh) || {
                availableLeads: 0,
                myLeads: 0,
                maxPerStaff: config.freshMaxPerStaff || 100
            };

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
                    freshAvailable: freshStats.availableLeads,
                    myFresh: freshStats.myLeads,
                    freshMax: freshStats.maxPerStaff,
                    myUnread,
                    unreadMax: config.unreadMaxPerStaff || 50,
                    pools: poolsStats
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    },

    pullLeads: async (req, res) => {
        try {
            const { type = "fresh", poolId, leadPoolId } = req.body;
            const staffId = req.user?._id || req.user?.userId || req.user?.id;
            const companyId = req.user?.companyId || req.user?.company || "default_company";

            const config = await getDistributionConfig(companyId);

            let targetPool = null;
            const targetPoolId = poolId || leadPoolId;

            if (targetPoolId) {
                const poolFilter = await getAccessibleLeadPoolFilter(staffId, companyId);
                poolFilter._id = targetPoolId;
                targetPool = await leadPoolModel.findOne(poolFilter);
                if (!targetPool) {
                    return res.status(404).send({ status: 404, message: "Specified Lead Pool not found or you do not have permission to access it" });
                }
            } else {
                targetPool = await ensureDefaultFreshPool(companyId);
            }

            if (targetPool.isActive === false) {
                return res.status(400).send({ status: 400, message: `Lead Pool '${targetPool.name}' is currently inactive` });
            }

            const isDefaultFresh = targetPool.name === "Fresh Leads";
            const poolMax = (isDefaultFresh && config.freshMaxPerStaff) ? config.freshMaxPerStaff : (targetPool.maxPerStaff || config.freshMaxPerStaff || 100);
            const poolPullSize = (isDefaultFresh && config.freshPullSize) ? config.freshPullSize : (targetPool.pullSize || config.freshPullSize || 20);

            // Count current leads held by this staff member in this specific pool
            const myPoolLeads = await leadModel.countDocuments({
                companyId,
                leadPoolId: targetPool._id,
                assignedRM: staffId,
                stage: 'New',
                $or: [{ followUps: { $exists: false } }, { followUps: { $size: 0 } }]
            });

            const remainingCapacity = Math.max(0, poolMax - myPoolLeads);

            const poolAvailable = await leadModel.countDocuments({
                companyId,
                leadPoolId: targetPool._id,
                assignedRM: null
            });

            if (remainingCapacity === 0) {
                return res.status(200).send({
                    status: 200,
                    message: `You have reached your limit (${poolMax}) for ${targetPool.name}`,
                    data: {
                        pulled: 0,
                        maximum: poolMax,
                        current: myPoolLeads,
                        remainingCapacity: 0,
                        availableInPool: poolAvailable,
                        poolId: targetPool._id,
                        poolName: targetPool.name
                    }
                });
            }

            if (poolAvailable === 0) {
                return res.status(200).send({
                    status: 200,
                    message: `No leads are currently available in ${targetPool.name}`,
                    data: {
                        pulled: 0,
                        maximum: poolMax,
                        current: myPoolLeads,
                        remainingCapacity,
                        availableInPool: 0,
                        poolId: targetPool._id,
                        poolName: targetPool.name
                    }
                });
            }

            const actualPull = Math.min(remainingCapacity, poolPullSize, poolAvailable);

            // Atomic per-lead assignment — prevents concurrent double-pull
            let pulled = 0;
            for (let i = 0; i < actualPull; i++) {
                const assigned = await leadModel.findOneAndUpdate(
                    { companyId, leadPoolId: targetPool._id, assignedRM: null },
                    { $set: { assignedRM: staffId } },
                    { new: true }
                );
                if (!assigned) break; // pool exhausted mid-pull
                pulled++;
            }

            const newCount = myPoolLeads + pulled;
            return res.status(200).send({
                status: 200,
                message: pulled > 0 ? `${pulled} lead${pulled === 1 ? '' : 's'} pulled from ${targetPool.name}` : `No leads available in ${targetPool.name}`,
                data: {
                    pulled,
                    maximum: poolMax,
                    current: newCount,
                    remainingCapacity: Math.max(0, poolMax - newCount),
                    availableInPool: Math.max(0, poolAvailable - pulled),
                    poolId: targetPool._id,
                    poolName: targetPool.name
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    }
};

export default leadPullController;
