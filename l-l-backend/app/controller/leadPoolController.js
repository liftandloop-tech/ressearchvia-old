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
    // Auto-migrate any unassigned or null-pool leads to this default pool only if needed
    const hasUnassignedLeads = await leadModel.exists({
        $or: [
            { companyId: companyId, leadPoolId: null },
            { companyId: companyId, leadPoolId: { $exists: false } },
            { leadPoolId: null },
            { leadPoolId: { $exists: false } }
        ]
    });
    if (hasUnassignedLeads) {
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
    }
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
            const isSystemAdmin = hierarchy.isSystemAdmin || req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role?.toLowerCase() === 'admin' || req.user?.role?.toLowerCase() === 'superadmin';

            // Enrich pools with lead counts and access permissions
            const enrichedPools = await Promise.all(pools.map(async (pool) => {
                const totalLeads = await leadModel.countDocuments({ companyId, leadPoolId: pool._id });
                const availableLeads = await leadModel.countDocuments({ companyId, leadPoolId: pool._id, assignedRM: null });
                const assignedLeads = totalLeads - availableLeads;
                
                const hasSubordinates = (hierarchy.staffIds || []).length > 1;
                const isLeadership = isSystemAdmin || hierarchy.isDirector || hierarchy.isSupervisor || hierarchy.isManager || hasSubordinates;
                const isOwner = isSystemAdmin || (pool.createdBy && pool.createdBy.toString() === (callerId || "").toString());
                const isUnassignedPool = !pool.createdBy;

                const callerAssignment = (pool.assignments || []).find(
                    a => a.staffId && a.staffId.toString() === (callerId || "").toString()
                );

                const canEdit = isSystemAdmin || isOwner || isLeadership || isUnassignedPool || (callerAssignment?.canDelegate === true);
                const canDelegate = isSystemAdmin || (isOwner && hasSubordinates) || (isLeadership && hasSubordinates) || (callerAssignment?.canDelegate === true && hasSubordinates);
                const canAssign = canDelegate && pool.name !== "Fresh Leads";
                const canDelete = (isSystemAdmin || isOwner || hierarchy.isDirector) && pool.name !== "Fresh Leads";

                return {
                    ...pool,
                    totalLeads,
                    availableLeads,
                    assignedLeads,
                    pullSize: pool.pullSize || pool.initialPullSize || 20,
                    initialPullSize: pool.initialPullSize || pool.pullSize || 20,
                    subsequentPullSize: pool.subsequentPullSize || 30,
                    maxPerStaff: pool.maxPerStaff || 50,
                    isActive: pool.isActive !== false,
                    isGlobal: pool.isGlobal !== false,
                    assignedStaffIds: pool.assignedStaffIds || [],
                    assignedStaffCount: (pool.assignedStaffIds || []).length,
                    assignments: pool.assignments || [],
                    createdByName: pool.createdByName || (pool.name === "Fresh Leads" ? "System Admin" : "Unknown"),
                    creatorRole: pool.creatorRole || (pool.name === "Fresh Leads" ? "Admin" : "Staff"),
                    isOwner,
                    canEdit,
                    canDelete,
                    canDelegate,
                    canAssign
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
            const isSystemAdmin = hierarchy.isSystemAdmin || req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role?.toLowerCase() === 'admin' || req.user?.role?.toLowerCase() === 'superadmin';

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

            const parsedInitialPull = req.body.initialPullSize 
                ? Math.max(1, parseInt(req.body.initialPullSize)) 
                : (pullSize ? Math.max(1, parseInt(pullSize)) : 20);
            const parsedSubsequentPull = req.body.subsequentPullSize 
                ? Math.max(1, parseInt(req.body.subsequentPullSize)) 
                : 30;
            const parsedMaxPerStaff = maxPerStaff ? Math.max(1, parseInt(maxPerStaff)) : 50;

            // Handle initial assignment if provided upon creation
            const initialAssignees = (Array.isArray(req.body.assignedStaffIds) 
                ? req.body.assignedStaffIds 
                : [req.body.initialAssigneeId]).filter(Boolean);
            const assignedStaffIds = [];
            const assignments = [];

            if (initialAssignees.length > 0) {
                for (const tId of initialAssignees) {
                    if (mongoose.isValidObjectId(tId)) {
                        const tObjId = new mongoose.Types.ObjectId(tId.toString());
                        assignedStaffIds.push(tObjId);
                        const tHierarchy = await getSupervisedStaffIds(tObjId);
                        assignments.push({
                            staffId: tObjId,
                            assignedBy: callerId,
                            assignedAt: new Date(),
                            canPull: true,
                            canDelegate: (tHierarchy.staffIds || []).length > 1
                        });
                    }
                }
            }

            const pool = await leadPoolModel.create({
                companyId,
                name: name.trim(),
                description: description || null,
                pullSize: parsedInitialPull,
                initialPullSize: parsedInitialPull,
                subsequentPullSize: parsedSubsequentPull,
                maxPerStaff: parsedMaxPerStaff,
                assignedStaffIds,
                assignments,
                isActive: true,
                createdBy,
                createdByName,
                creatorRole,
                isGlobal: false // Custom pools are strictly private upon creation
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

            // Authorization: System Admin, Pool Owner, Director/Manager with subordinates, or Delegate
            const hierarchy = await getSupervisedStaffIds(callerId);
            const isSystemAdmin = hierarchy.isSystemAdmin || req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role?.toLowerCase() === 'admin' || req.user?.role?.toLowerCase() === 'superadmin';
            const isOwner = !pool.createdBy || (pool.createdBy && pool.createdBy.toString() === (callerId || "").toString());
            const hasSubordinates = (hierarchy.staffIds || []).length > 1;
            const isLeadership = isSystemAdmin || hierarchy.isDirector || hierarchy.isSupervisor || hierarchy.isManager || hasSubordinates;
            const isUnassignedPool = !pool.createdBy;
            const callerAssignment = (pool.assignments || []).find(
                a => a.staffId && a.staffId.toString() === (callerId || "").toString()
            );

            const canEdit = isSystemAdmin || isOwner || isLeadership || isUnassignedPool || (callerAssignment?.canDelegate === true);

            if (!canEdit) {
                return res.status(403).send({
                    status: 403,
                    message: "Unauthorized: You do not have permission to modify this lead pool",
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
            if (req.body.initialPullSize !== undefined) pool.initialPullSize = Math.max(1, parseInt(req.body.initialPullSize) || 20);
            if (req.body.subsequentPullSize !== undefined) pool.subsequentPullSize = Math.max(1, parseInt(req.body.subsequentPullSize) || 30);
            if (pullSize !== undefined) pool.pullSize = Math.max(1, parseInt(pullSize) || pool.initialPullSize || 20);
            if (maxPerStaff !== undefined) pool.maxPerStaff = Math.max(1, parseInt(maxPerStaff) || 50);
            if (isActive !== undefined) pool.isActive = Boolean(isActive);

            await pool.save();

            res.status(200).send({
                status: 200,
                message: "Lead pool updated successfully",
                data: {
                    ...pool.toObject(),
                    initialPullSize: pool.initialPullSize || pool.pullSize || 20,
                    subsequentPullSize: pool.subsequentPullSize || 30,
                    maxPerStaff: pool.maxPerStaff || 50,
                    isOwner: true,
                    canEdit: true,
                    canDelete: isSystemAdmin || (isOwner && pool.name !== "Fresh Leads")
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    assignLeadPool: async (req, res) => {
        try {
            const { id } = req.params;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const companyId = req.user?.companyId || req.user?.company || "default_company";
            const { staffIds, canDelegate: overrideCanDelegate } = req.body;

            const pool = await leadPoolModel.findOne({ _id: id, companyId });
            if (!pool) {
                return res.status(404).send({ status: 404, message: "Lead pool not found", data: {} });
            }

            const hierarchy = await getSupervisedStaffIds(callerId);
            const isSystemAdmin = hierarchy.isSystemAdmin || req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role?.toLowerCase() === 'admin' || req.user?.role?.toLowerCase() === 'superadmin';
            const isOwner = !pool.createdBy || (pool.createdBy && pool.createdBy.toString() === (callerId || "").toString());

            const callerAssignment = (pool.assignments || []).find(
                a => a.staffId && a.staffId.toString() === (callerId || "").toString()
            );
            const hasSubordinates = (hierarchy.staffIds || []).length > 1;

            const canDelegate = isSystemAdmin || (isOwner && hasSubordinates) || (callerAssignment?.canDelegate === true && hasSubordinates);

            if (!canDelegate) {
                return res.status(403).send({
                    status: 403,
                    message: "Unauthorized: You do not have permission to assign or delegate this lead pool. Only managers with reporting subordinates can delegate pools.",
                    data: {}
                });
            }

            // Raw input array of staffIds
            const targetIds = (Array.isArray(staffIds) ? staffIds : [staffIds]).filter(Boolean);
            if (targetIds.length === 0) {
                return res.status(400).send({ status: 400, message: "At least one target staffId must be provided", data: {} });
            }

            // Validate targets against caller's subordinate hierarchy if not System Admin
            const validTargetObjectIds = [];
            const supervisedStrSet = new Set((hierarchy.staffIds || []).map(sid => sid.toString()));

            for (const tId of targetIds) {
                const targetStr = tId.toString();
                if (targetStr === (callerId || "").toString()) {
                    continue; // Skip self assignment
                }
                if (!isSystemAdmin && !supervisedStrSet.has(targetStr)) {
                    return res.status(400).send({
                        status: 400,
                        message: `Target staff (${targetStr}) is outside your reporting hierarchy. Delegation must strictly flow downward.`,
                        data: {}
                    });
                }
                if (mongoose.isValidObjectId(targetStr)) {
                    validTargetObjectIds.push(new mongoose.Types.ObjectId(targetStr));
                }
            }

            if (validTargetObjectIds.length === 0) {
                return res.status(400).send({ status: 400, message: "No valid subordinate staff members provided for assignment", data: {} });
            }

            // Update assignments array and assignedStaffIds array
            const currentAssignedSet = new Set((pool.assignedStaffIds || []).map(sid => sid.toString()));
            const currentAssignments = pool.assignments || [];

            for (const targetObjId of validTargetObjectIds) {
                const targetStr = targetObjId.toString();
                currentAssignedSet.add(targetStr);

                // Determine if target can delegate: must have reporting subordinates
                const targetHierarchy = await getSupervisedStaffIds(targetObjId);
                const targetHasSubordinates = (targetHierarchy.staffIds || []).length > 1;
                const targetCanDelegate = overrideCanDelegate !== undefined 
                    ? Boolean(overrideCanDelegate && targetHasSubordinates) 
                    : targetHasSubordinates;

                const existingIdx = currentAssignments.findIndex(a => a.staffId && a.staffId.toString() === targetStr);
                if (existingIdx >= 0) {
                    currentAssignments[existingIdx].assignedBy = callerId;
                    currentAssignments[existingIdx].assignedAt = new Date();
                    currentAssignments[existingIdx].canPull = true;
                    currentAssignments[existingIdx].canDelegate = targetCanDelegate;
                } else {
                    currentAssignments.push({
                        staffId: targetObjId,
                        assignedBy: callerId,
                        assignedAt: new Date(),
                        canPull: true,
                        canDelegate: targetCanDelegate
                    });
                }
            }

            pool.assignedStaffIds = Array.from(currentAssignedSet).map(sid => new mongoose.Types.ObjectId(sid));
            pool.assignments = currentAssignments;
            await pool.save();

            // Fetch populated staff details for display
            const assignedStaffDocs = await staffModel.find({ _id: { $in: pool.assignedStaffIds } })
                .select('_id fullName email role')
                .lean();

            res.status(200).send({
                status: 200,
                message: `Lead pool successfully assigned to ${validTargetObjectIds.length} staff member(s)`,
                data: {
                    ...pool.toObject(),
                    assignedStaffCount: pool.assignedStaffIds.length,
                    assignedStaff: assignedStaffDocs
                }
            });
        } catch (error) {
            res.status(500).send({ status: 500, message: error.message, data: {} });
        }
    },

    getAssignableStaff: async (req, res) => {
        try {
            const { id } = req.params;
            const callerId = req.user?._id || req.user?.userId || req.user?.id;
            const companyId = req.user?.companyId || req.user?.company || "default_company";

            const pool = await leadPoolModel.findOne({ _id: id, companyId });
            if (!pool) {
                return res.status(404).send({ status: 404, message: "Lead pool not found", data: {} });
            }

            const hierarchy = await getSupervisedStaffIds(callerId);
            const isSystemAdmin = hierarchy.isSystemAdmin || req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role?.toLowerCase() === 'admin' || req.user?.role?.toLowerCase() === 'superadmin';
            const isOwner = !pool.createdBy || (pool.createdBy && pool.createdBy.toString() === (callerId || "").toString());

            const callerAssignment = (pool.assignments || []).find(
                a => a.staffId && a.staffId.toString() === (callerId || "").toString()
            );
            const hasSubordinates = (hierarchy.staffIds || []).length > 1;

            const canDelegate = isSystemAdmin || (isOwner && hasSubordinates) || (callerAssignment?.canDelegate === true && hasSubordinates);

            if (!canDelegate) {
                return res.status(403).send({
                    status: 403,
                    message: "Unauthorized: You do not have delegation rights for this pool",
                    data: {}
                });
            }

            let candidateStaffDocs = [];
            const callerStr = (callerId || "").toString();

            if (isSystemAdmin) {
                candidateStaffDocs = await staffModel.find({
                    companyId,
                    isActive: { $ne: false },
                    stage: { $ne: 'Applicant' }
                })
                .populate('roleId', 'name roleName')
                .populate('departmentId', 'name')
                .select('_id fullName email role roleId departmentId assignedDirector')
                .lean();
            } else {
                const subordinateObjIds = (hierarchy.staffIds || []).filter(sid => sid.toString() !== callerStr);
                candidateStaffDocs = await staffModel.find({
                    _id: { $in: subordinateObjIds },
                    isActive: { $ne: false },
                    stage: { $ne: 'Applicant' }
                })
                .populate('roleId', 'name roleName')
                .populate('departmentId', 'name')
                .select('_id fullName email role roleId departmentId assignedDirector')
                .lean();
            }

            const assignedSet = new Set((pool.assignedStaffIds || []).map(sid => sid.toString()));

            const enrichedStaff = await Promise.all(candidateStaffDocs.map(async (st) => {
                const stStr = st._id.toString();
                const stHierarchy = await getSupervisedStaffIds(st._id);
                const stHasSubordinates = (stHierarchy.staffIds || []).length > 1;
                const existingAssignment = (pool.assignments || []).find(a => a.staffId && a.staffId.toString() === stStr);

                return {
                    _id: st._id,
                    id: st._id,
                    fullName: st.fullName,
                    email: st.email,
                    role: st.roleId?.name || st.roleId?.roleName || st.role || 'Staff',
                    department: st.departmentId?.name || null,
                    isAssigned: assignedSet.has(stStr),
                    canDelegate: existingAssignment ? existingAssignment.canDelegate : stHasSubordinates,
                    hasSubordinates: stHasSubordinates
                };
            }));

            res.status(200).send({
                status: 200,
                message: "Assignable staff retrieved successfully",
                data: enrichedStaff
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
            const isSystemAdmin = hierarchy.isSystemAdmin || req.user?.userType === 'admin' || req.user?.userType === 'super_admin' || req.user?.role?.toLowerCase() === 'admin' || req.user?.role?.toLowerCase() === 'superadmin';
            const isOwner = !pool.createdBy || (pool.createdBy && pool.createdBy.toString() === (callerId || "").toString());

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
