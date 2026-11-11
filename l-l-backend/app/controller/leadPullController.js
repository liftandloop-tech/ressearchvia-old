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
                const pMax = (isDefaultFresh && config.freshMaxPerStaff) 
                    ? config.freshMaxPerStaff 
                    : (p.maxPerStaff || 50);
                const pInitialSize = (isDefaultFresh && config.freshPullSize) 
                    ? config.freshPullSize 
                    : (p.initialPullSize || p.pullSize || 20);
                const pSubsequentSize = p.subsequentPullSize || 30;

                const availableLeads = await leadModel.countDocuments({
                    companyId,
                    leadPoolId: p._id,
                    assignedRM: null
                });

                // Total leads ever pulled/held by this staff member in this pool
                const totalHeld = await leadModel.countDocuments({
                    companyId,
                    leadPoolId: p._id,
                    assignedRM: staffId
                });

                // Current unworked new leads in this pool
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

                const nextPullSize = totalHeld === 0 ? pInitialSize : pSubsequentSize;
                const remainingCapacity = Math.max(0, pMax - totalHeld);
                const currentStage = totalHeld === 0 ? 1 : 2;

                return {
                    _id: p._id,
                    id: p._id,
                    name: p.name,
                    poolId: p._id,
                    poolName: p.name,
                    description: p.description,
                    pullSize: nextPullSize,
                    initialPullSize: pInitialSize,
                    subsequentPullSize: pSubsequentSize,
                    nextPullSize: Math.min(nextPullSize, remainingCapacity),
                    maxPerStaff: pMax,
                    isActive: p.isActive !== false,
                    availableLeads,
                    myLeads,
                    totalHeld,
                    remainingCapacity,
                    currentStage,
                    totalLeads,
                    isDefaultFresh: p.name === "Fresh Leads",
                    isGlobal: p.isGlobal !== false,
                    assignedStaffCount: (p.assignedStaffIds || []).length,
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
            const poolMax = (isDefaultFresh && config.freshMaxPerStaff) 
                ? config.freshMaxPerStaff 
                : (targetPool.maxPerStaff || 50);
            const initialSize = (isDefaultFresh && config.freshPullSize)
                ? config.freshPullSize
                : (targetPool.initialPullSize || targetPool.pullSize || 20);
            const subsequentSize = targetPool.subsequentPullSize || 30;

            // 1. Total leads ever allocated to / held by this staff member in this pool
            const totalHeld = await leadModel.countDocuments({
                companyId,
                leadPoolId: targetPool._id,
                assignedRM: staffId
            });

            // 2. Hard Cap Check
            if (totalHeld >= poolMax) {
                return res.status(200).send({
                    status: 200,
                    message: `You have reached the maximum allowed limit of ${poolMax} leads for ${targetPool.name}.`,
                    data: {
                        pulled: 0,
                        maximum: poolMax,
                        current: totalHeld,
                        totalHeld,
                        remainingCapacity: 0,
                        availableInPool: 0,
                        poolId: targetPool._id,
                        poolName: targetPool.name
                    }
                });
            }

            const poolAvailable = await leadModel.countDocuments({
                companyId,
                leadPoolId: targetPool._id,
                assignedRM: null
            });

            if (poolAvailable === 0) {
                return res.status(200).send({
                    status: 200,
                    message: `No leads are currently available in ${targetPool.name}`,
                    data: {
                        pulled: 0,
                        maximum: poolMax,
                        current: totalHeld,
                        totalHeld,
                        remainingCapacity: Math.max(0, poolMax - totalHeld),
                        availableInPool: 0,
                        poolId: targetPool._id,
                        poolName: targetPool.name
                    }
                });
            }

            // 3. Dynamic Tiered Quota: Step 1 (Initial = 20) vs Step 2 (Subsequent = 30)
            const requestedBatchSize = totalHeld === 0 ? initialSize : subsequentSize;
            const headroom = poolMax - totalHeld;
            const actualPull = Math.min(requestedBatchSize, headroom, poolAvailable);

            if (actualPull <= 0) {
                return res.status(200).send({
                    status: 200,
                    message: `No additional capacity available for ${targetPool.name}`,
                    data: {
                        pulled: 0,
                        maximum: poolMax,
                        current: totalHeld,
                        totalHeld,
                        remainingCapacity: 0,
                        availableInPool: poolAvailable,
                        poolId: targetPool._id,
                        poolName: targetPool.name
                    }
                });
            }

            // 4. Atomic per-lead assignment with pulledAt timestamp
            let pulled = 0;
            const pullTimestamp = new Date();
            for (let i = 0; i < actualPull; i++) {
                const assigned = await leadModel.findOneAndUpdate(
                    { companyId, leadPoolId: targetPool._id, assignedRM: null },
                    { $set: { assignedRM: staffId, pulledAt: pullTimestamp } },
                    { new: true }
                );
                if (!assigned) break; // pool exhausted mid-pull
                pulled++;
            }

            const newTotalHeld = totalHeld + pulled;
            const nextPullBatch = Math.min(subsequentSize, Math.max(0, poolMax - newTotalHeld));
            const currentStage = totalHeld === 0 ? 1 : 2;

            return res.status(200).send({
                status: 200,
                message: pulled > 0 
                    ? `Successfully pulled ${pulled} lead${pulled === 1 ? '' : 's'} from ${targetPool.name} (Stage ${currentStage}: ${newTotalHeld}/${poolMax} quota used)` 
                    : `No leads available in ${targetPool.name}`,
                data: {
                    pulled,
                    maximum: poolMax,
                    current: newTotalHeld,
                    totalHeld: newTotalHeld,
                    remainingCapacity: Math.max(0, poolMax - newTotalHeld),
                    availableInPool: Math.max(0, poolAvailable - pulled),
                    poolId: targetPool._id,
                    poolName: targetPool.name,
                    initialPullSize: initialSize,
                    subsequentPullSize: subsequentSize,
                    nextPullBatch,
                    currentStage
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message });
        }
    }
};

export default leadPullController;
