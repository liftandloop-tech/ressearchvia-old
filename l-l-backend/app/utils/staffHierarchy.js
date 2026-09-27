import mongoose from "mongoose";
import staffModel from "../models/staffModel.js";
import userModel from "../models/userModel.js";
import roleModel from "../models/roleModel.js";

/**
 * Resolves the list of staff ObjectIds supervised directly or indirectly by callerId.
 * - System Admin: returns { isSystemAdmin: true, staffIds: null }
 * - Director / Manager / Supervisor: returns { isSystemAdmin: false, isSupervisor: true, staffIds: [callerId, ...subordinates] }
 * - Regular Staff: returns { isSystemAdmin: false, isSupervisor: false, staffIds: [callerId] }
 */
export async function getSupervisedStaffIds(callerId) {
  if (!callerId) {
    return { isSystemAdmin: false, isSupervisor: false, staffIds: [] };
  }

  const callerObjectId = mongoose.isValidObjectId(callerId)
    ? new mongoose.Types.ObjectId(callerId.toString())
    : null;

  if (!callerObjectId) {
    return { isSystemAdmin: false, isSupervisor: false, staffIds: [] };
  }

  // Check if caller is in staffModel
  const staffMember = await staffModel.findById(callerObjectId)
    .populate('departmentId')
    .populate({
      path: 'roleId',
      populate: [
        { path: 'permissionGroups' },
        { path: 'departmentId' }
      ]
    });

  let isSystemAdmin = false;

  if (staffMember) {
    const roleName = (staffMember.roleId?.name || staffMember.role || "").toLowerCase();
    const dept = (staffMember.departmentId?.name || staffMember.deparment || staffMember.department || "").toLowerCase();
    isSystemAdmin = roleName === 'admin' || roleName === 'super_admin' || dept === 'admin' || dept === 'super_admin';
  } else {
    // Check primary userModel (e.g. system admin)
    const primaryUser = await userModel.findById(callerObjectId);
    if (primaryUser) {
      const uType = (primaryUser.userType || "").toLowerCase();
      isSystemAdmin = uType === 'admin' || uType === 'super_admin';
    }
  }

  if (isSystemAdmin) {
    return { isSystemAdmin: true, isSupervisor: true, isDirector: true, isGlobalAccess: true, staffIds: null };
  }

  // If not staff member and not admin, return empty
  if (!staffMember) {
    return { isSystemAdmin: false, isSupervisor: false, isDirector: false, isGlobalAccess: false, staffIds: [callerObjectId] };
  }

  // Recursive traversal to collect all direct and indirect subordinates
  const supervisedMap = new Map();
  supervisedMap.set(callerObjectId.toString(), callerObjectId);

  let currentLevel = [callerObjectId];
  while (currentLevel.length > 0) {
    const subordinates = await staffModel.find({
      assignedDirector: { $in: currentLevel },
      stage: { $ne: 'Applicant' }
    }).select('_id');

    const nextLevel = [];
    for (const sub of subordinates) {
      const subIdStr = sub._id.toString();
      if (!supervisedMap.has(subIdStr)) {
        supervisedMap.set(subIdStr, sub._id);
        nextLevel.push(sub._id);
      }
    }
    currentLevel = nextLevel;
  }

  const roleLevel = staffMember.roleId?.level;
  const roleName = (staffMember.roleId?.name || staffMember.role || "").toLowerCase();
  const deptName = (staffMember.departmentId?.name || staffMember.deparment || staffMember.department || "").toLowerCase();

  // Dynamic role level classification
  const isDirector = roleLevel === 1 || roleName === 'director' || deptName === 'management';
  const isManager = roleLevel === 2 || roleName.includes('manager') || roleName.includes('head');

  // Dynamic global access check:
  // 1. Department explicitly flagged isGlobal
  // 2. Or role permissions include global pool / view_all access
  // 3. Or non-sales hierarchy departments (departments that are not pipeline-scoped)
  const hasGlobalPoolPermission = Boolean(
    staffMember.roleId?.permissionGroups?.some(pg =>
      pg?.permissions?.some(perm =>
        perm?.actions?.some(act => act === '*' || act.includes('view_pools') || act.includes('view_all'))
      )
    )
  );

  const isSalesHierarchy = deptName === 'sales' && !isDirector;
  const isGlobalAccess = staffMember.departmentId?.isGlobal === true || hasGlobalPoolPermission || !isSalesHierarchy;

  const staffIds = Array.from(supervisedMap.values());
  const isSupervisor = staffIds.length > 1 || isDirector || isManager;

  return {
    isSystemAdmin: false,
    isSupervisor,
    isDirector,
    isManager,
    isGlobalAccess,
    staffIds,
    staffMember
  };
}

/**
 * Resolves all direct and indirect upstream managers/directors for a given staff member.
 * e.g., if Staff -> Team Lead -> Sales Director, returns [TeamLeadId, SalesDirectorId].
 */
export async function getUpstreamSupervisorIds(callerId) {
  if (!callerId || !mongoose.isValidObjectId(callerId)) return [];
  const upstream = [];
  const visited = new Set();
  let currentId = callerId.toString();
  visited.add(currentId);

  while (currentId) {
    const staff = await staffModel.findById(currentId).select('assignedDirector').lean();
    if (!staff || !staff.assignedDirector) break;

    const nextId = staff.assignedDirector.toString();
    if (nextId === 'admin' || nextId === 'unassigned' || !mongoose.isValidObjectId(nextId)) break;
    if (visited.has(nextId)) break; // avoid loops

    visited.add(nextId);
    upstream.push(new mongoose.Types.ObjectId(nextId));
    currentId = nextId;
  }
  return upstream;
}

/**
 * Generates the MongoDB filter for Lead Pools based on caller's hierarchy.
 * - System Admin: Sees all pools within company.
 * - Non-Admin: Sees global pools + pools created by themselves + pools created by their upstream managers (owner's team).
 */
export async function getAccessibleLeadPoolFilter(callerId, companyId) {
  const baseFilter = { companyId: companyId || "default_company" };
  const hierarchy = await getSupervisedStaffIds(callerId);

  if (hierarchy.isSystemAdmin || hierarchy.isGlobalAccess) {
    return baseFilter;
  }

  const callerObjId = mongoose.isValidObjectId(callerId) ? new mongoose.Types.ObjectId(callerId.toString()) : null;
  const upstreamIds = await getUpstreamSupervisorIds(callerId);
  const allowedCreators = callerObjId ? [callerObjId, ...upstreamIds] : upstreamIds;

  return {
    ...baseFilter,
    $or: [
      { isGlobal: true },
      { isGlobal: { $exists: false } },
      { createdBy: null },
      { createdBy: { $in: allowedCreators } }
    ]
  };
}

export default { getSupervisedStaffIds, getUpstreamSupervisorIds, getAccessibleLeadPoolFilter };
