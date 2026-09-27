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
    const roleName = (staffMember.roleId?.name || staffMember.role || "").toLowerCase().trim();
    // Only real system admin role in staff model gets global access
    isSystemAdmin = roleName === 'admin' || roleName === 'super_admin' || roleName === 'super admin';
  } else {
    // Check primary userModel (system administrator account)
    const primaryUser = await userModel.findById(callerObjectId);
    if (primaryUser) {
      const uType = (primaryUser.userType || "").toLowerCase().trim();
      const uRole = (primaryUser.role || "").toLowerCase().trim();
      isSystemAdmin = uType === 'admin' || uType === 'super_admin' || uRole === 'admin' || uRole === 'super_admin';
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
    const levelObjIds = currentLevel.map(id => mongoose.isValidObjectId(id) ? new mongoose.Types.ObjectId(id.toString()) : id);
    const levelStrIds = currentLevel.map(id => id.toString());
    const queryDirectors = [...new Set([...levelObjIds, ...levelStrIds])];

    const subordinates = await staffModel.find({
      assignedDirector: { $in: queryDirectors },
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

  const roleName = (staffMember.roleId?.roleName || staffMember.roleId?.name || staffMember.role || "").toLowerCase().trim();
  const staffIds = Array.from(supervisedMap.values());
  const hasSubordinates = staffIds.length > 1;

  const isExecutiveTitle = /executive|analyst|bde|intern|trainee|junior|back office|associate/i.test(roleName);
  const isLeadershipTitle = /director|head|manager|team leader|lead|supervisor|vp|president/i.test(roleName);

  const isDirector = /director|head/i.test(roleName);
  const isManager = /manager|team leader|lead/i.test(roleName);
  const isSupervisor = hasSubordinates || (isLeadershipTitle && !isExecutiveTitle);

  return {
    isSystemAdmin: false,
    isSupervisor,
    isDirector,
    isManager,
    isGlobalAccess: false,
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

  if (hierarchy.isSystemAdmin) {
    return baseFilter;
  }

  const callerObjId = mongoose.isValidObjectId(callerId) ? new mongoose.Types.ObjectId(callerId.toString()) : null;
  const upstreamIds = await getUpstreamSupervisorIds(callerId);
  const supervisedIds = hierarchy.staffIds || [];

  // Allowed pool creators:
  // 1. The staff member themselves
  // 2. Upstream supervisors/directors (who created pools for their team)
  // 3. Subordinates reporting to this staff member (if caller is a team lead / manager viewing team pools)
  const allowedCreators = [
    ...new Set([
      ...(callerObjId ? [callerObjId] : []),
      ...upstreamIds,
      ...supervisedIds
    ])
  ];

  return {
    ...baseFilter,
    $or: [
      { isGlobal: true },
      { name: "Fresh Leads" },
      { createdBy: { $in: allowedCreators } }
    ]
  };
}

export default { getSupervisedStaffIds, getUpstreamSupervisorIds, getAccessibleLeadPoolFilter };
