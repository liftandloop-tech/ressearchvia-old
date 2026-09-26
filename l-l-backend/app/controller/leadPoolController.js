import leadPoolModel from "../models/leadPoolModel.js";
import leadModel from "../models/leadModel.js";
import staffModel from "../models/staffModel.js";
import { getSupervisedStaffIds, getAccessibleLeadPoolFilter } from "../utils/staffHierarchy.js";

const ensureDefaultFreshPool = async (companyId) => {
    let pool = await leadPoolModel.findOne({ companyId, name: "Fresh Leads" });
    if (!pool) {
        pool = await leadPoolModel.create({
            companyId,
            name: "Fresh Leads",
            description: "Default lead pool for incoming fresh leads",
            pullSize: 20,
            maxPerStaff: 100,
            isActive: true,
            isGlobal: true,
            createdByName: "System Admin",
            creatorRole: "Admin"
        });
    } else if (pool.isGlobal !== true) {
        pool.isGlobal = true;
        if (!pool.createdByName) pool.createdByName = "System Admin";
        if (!pool.creatorRole) pool.creatorRole = "Admin";
        await pool.save();
    }
    // Auto-migrate any unassigned or null-pool leads to this default pool
    await leadModel.updateMany(
        {
            $or: [
                { companyId: companyId, leadPoolId: null },
                { companyId: companyId, leadPoolId: { $exists: false } },
                { leadPoolId: null },
                { leadPoolId: { $exists: false } }
            ]
        },
        { $set: { leadPoolId: pool._id, companyId: companyId } }
    );
    return pool;
};

const leadPoolController = {
    listLeadPools: async (req, res) => {
        try {
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const companyId = req.user?.companyId || req.user?.company || "default_company";
            await ensureDefaultFreshPool(companyId);

            const filter = await getAccessibleLeadPoolFilter(callerId, companyId);
            const pools = await leadPoolModel.find(filter).sort({ createdAt: -1 }).lean();

            const hierarchy = await getSupervisedStaffIds(callerId);
            const isSystemAdmin = hierarchy.isSystemAdmin;

            // Enrich pools with lead counts and access permissions
            const enrichedPools = await Promise.all(pools.map(async (pool) => {
                const totalLeads = await leadModel.countDocuments({ companyId, leadPoolId: pool._id });
                const availableLeads = await leadModel.countDocuments({ companyId, leadPoolId: pool._id, assignedRM: null });
                const assignedLeads = totalLeads - availableLeads;
                const isOwner = isSystemAdmin || (pool.createdBy && pool.createdBy.toString() === (callerId || "").toString());

                return {
                    ...pool,
                    totalLeads,
                    availableLeads,
                    assignedLeads,
                    pullSize: pool.pullSize || 20,
                    maxPerStaff: pool.maxPerStaff || 100,
                    isActive: pool.isActive !== false,
                    isGlobal: pool.isGlobal !== false,
                    createdByName: pool.createdByName || (pool.name === "Fresh Leads" ? "System Admin" : "Unknown"),
                    creatorRole: pool.creatorRole || (pool.name === "Fresh Leads" ? "Admin" : "Staff"),
                    isOwner,
                    canEdit: isOwner,
                    canDelete: isOwner && pool.name !== "Fresh Leads"
                };
            }));

            res.status(200).send({
                status: 200,
                message: "Lead pools retrieved successfully",
                data: enrichedPools
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    createLeadPool: async (req, res) => {
        try {
            const { name, description, pullSize, maxPerStaff } = req.body;
            if (!name || String(name).trim().length === 0) {
                return res.status(400).send({ status: 400, message: "Name is required and cannot be empty", data: {} });
            }

            if (String(name).trim().toLowerCase() === "fresh leads") {
                return res.status(400).send({ status: 400, message: "Fresh Leads is a system reserved pool name", data: {} });
            }

            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const companyId = req.user?.companyId || req.user?.company || "default_company";

            // Prevent duplicate pool names within the same company
            const exists = await leadPoolModel.findOne({ companyId, name: name.trim() });
            if (exists) {
                return res.status(400).send({ status: 400, message: "Lead pool with this name already exists", data: {} });
            }

            // Determine creator ownership & scope
            const hierarchy = await getSupervisedStaffIds(callerId);
            const isSystemAdmin = hierarchy.isSystemAdmin;

            let createdBy = null;
            let createdByName = "System Admin";
            let creatorRole = "Admin";
            let isGlobal = true;

            if (!isSystemAdmin) {
                const staffMember = hierarchy.staffMember || (callerId ? await staffModel.findById(callerId).populate('roleId').lean() : null);
                createdBy = callerId;
                createdByName = staffMember?.fullName || "Staff";
                creatorRole = staffMember?.roleId?.roleName || staffMember?.roleId?.name || staffMember?.role || "Manager";
                isGlobal = false;
            }

            const parsedPullSize = pullSize ? Math.max(1, parseInt(pullSize)) : 20;
            const parsedMaxPerStaff = maxPerStaff ? Math.max(1, parseInt(maxPerStaff)) : 100;

            const pool = await leadPoolModel.create({
                companyId,
                name: name.trim(),
                description: description || null,
                pullSize: parsedPullSize,
                maxPerStaff: parsedMaxPerStaff,
                isActive: true,
                createdBy,
                createdByName,
                creatorRole,
                isGlobal
            });

            res.status(200).send({
                status: 200,
                message: "Lead pool created successfully",
                data: {
                    ...pool.toObject(),
                    isOwner: true,
                    canEdit: true,
                    canDelete: true
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    updateLeadPool: async (req, res) => {
        try {
            const { id } = req.params;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const companyId = req.user?.companyId || req.user?.company || "default_company";
            const { name, description, pullSize, maxPerStaff, isActive } = req.body;

            const pool = await leadPoolModel.findOne({ _id: id, companyId });
            if (!pool) {
                return res.status(404).send({ status: 404, message: "Lead pool not found", data: {} });
            }

            // Authorization: System Admin or Pool Owner
            const hierarchy = await getSupervisedStaffIds(callerId);
            const isSystemAdmin = hierarchy.isSystemAdmin;
            const isOwner = pool.createdBy && pool.createdBy.toString() === (callerId || "").toString();

            if (!isSystemAdmin && !isOwner) {
                return res.status(403).send({
                    status: 403,
                    message: "Unauthorized: Only the pool owner or system admin can modify this lead pool",
                    data: {}
                });
            }

            // If renaming, ensure not renaming to Fresh Leads or conflicting with another pool
            if (name && name.trim() !== pool.name) {
                if (pool.name === "Fresh Leads") {
                    return res.status(400).send({ status: 400, message: "System pool 'Fresh Leads' cannot be renamed", data: {} });
                }
                if (name.trim().toLowerCase() === "fresh leads") {
                    return res.status(400).send({ status: 400, message: "Cannot rename to reserved pool name 'Fresh Leads'", data: {} });
                }
                const duplicate = await leadPoolModel.findOne({ companyId, name: name.trim(), _id: { $ne: id } });
                if (duplicate) {
                    return res.status(400).send({ status: 400, message: "Another lead pool with this name already exists", data: {} });
                }
                pool.name = name.trim();
            }

            if (description !== undefined) pool.description = description;
            if (pullSize !== undefined) pool.pullSize = Math.max(1, parseInt(pullSize) || 20);
            if (maxPerStaff !== undefined) pool.maxPerStaff = Math.max(1, parseInt(maxPerStaff) || 100);
            if (isActive !== undefined) pool.isActive = Boolean(isActive);

            await pool.save();

            res.status(200).send({
                status: 200,
                message: "Lead pool updated successfully",
                data: {
                    ...pool.toObject(),
                    isOwner: true,
                    canEdit: true,
                    canDelete: isSystemAdmin || (isOwner && pool.name !== "Fresh Leads")
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    deleteLeadPool: async (req, res) => {
        try {
            const { id } = req.params;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const companyId = req.user?.companyId || req.user?.company || "default_company";

            const pool = await leadPoolModel.findOne({ _id: id, companyId });
            if (!pool) {
                return res.status(404).send({ status: 404, message: "Lead pool not found", data: {} });
            }

            if (pool.name === "Fresh Leads") {
                return res.status(400).send({ status: 400, message: "System pool 'Fresh Leads' cannot be deleted", data: {} });
            }

            // Authorization: System Admin or Pool Owner
            const hierarchy = await getSupervisedStaffIds(callerId);
            const isSystemAdmin = hierarchy.isSystemAdmin;
            const isOwner = pool.createdBy && pool.createdBy.toString() === (callerId || "").toString();

            if (!isSystemAdmin && !isOwner) {
                return res.status(403).send({
                    status: 403,
                    message: "Unauthorized: Only the pool owner or system admin can delete this lead pool",
                    data: {}
                });
            }

            // Check if any leads exist in this pool
            const leadCount = await leadModel.countDocuments({ companyId, leadPoolId: id });
            if (leadCount > 0) {
                return res.status(400).send({
                    status: 400,
                    message: `Cannot delete lead pool containing ${leadCount} lead${leadCount === 1 ? '' : 's'}. Reassign leads before deleting.`,
                    data: {}
                });
            }

            await leadPoolModel.deleteOne({ _id: id });

            res.status(200).send({
                status: 200,
                message: "Lead pool deleted successfully",
                data: {}
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    }
};

export { ensureDefaultFreshPool };
export default leadPoolController;
