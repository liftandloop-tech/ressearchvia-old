import mongoose from "mongoose";
import staffModel from "../models/staffModel.js";
import userModel from "../models/userModel.js";
import roleModel from "../models/roleModel.js";
import departmentModel from "../models/departmentModel.js";
import permissionGroupModel from "../models/permissionGroupModel.js";

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
 * Resolves the Branch Director's ObjectId for a given staff member.
 * Finds the topmost non-admin supervisor in the caller's upstream management chain.
 * - If caller is a Director or has no upstream supervisor, returns callerId.
 * - If caller has an upstream chain, climbs up (excluding System Admins)
 *   and picks the supervisor whose role indicates Director/Head,
 *   or the topmost non-admin supervisor in the branch tree.
 */
export async function getBranchDirectorId(callerId) {
  if (!callerId || !mongoose.isValidObjectId(callerId)) return null;
  const callerObjectId = new mongoose.Types.ObjectId(callerId.toString());

  const callerStaff = await staffModel.findById(callerObjectId)
    .populate('departmentId')
    .populate('roleId');

  if (!callerStaff) return callerObjectId;

  // Check if caller is System Admin
  const callerRoleName = (callerStaff.roleId?.roleName || callerStaff.roleId?.name || callerStaff.role || "").toLowerCase().trim();
  const callerDeptName = (callerStaff.departmentId?.name || callerStaff.deparment || "").toLowerCase().trim();
  if (callerRoleName === 'admin' || callerRoleName === 'super_admin' || callerRoleName === 'super admin' ||
      callerDeptName === 'admin' || callerDeptName === 'super_admin') {
    return null; // System Admin is not a branch director
  }

  // Get upstream supervisor IDs
  const rawUpstreamIds = await getUpstreamSupervisorIds(callerObjectId);

  // If no upstream supervisor, caller is the root of their branch
  if (!rawUpstreamIds || rawUpstreamIds.length === 0) {
    return callerObjectId;
  }

  // Fetch upstream staff records to filter out System Admins and find Director
  const upstreamStaffDocs = await staffModel.find({
    _id: { $in: rawUpstreamIds },
    stage: { $ne: 'Applicant' }
  }).populate('roleId').populate('departmentId');

  // Map by id string for lookup in chain order
  const docMap = new Map();
  for (const doc of upstreamStaffDocs) {
    docMap.set(doc._id.toString(), doc);
  }

  // Filter upstream chain to only non-admin staff
  const nonAdminUpstream = [];
  for (const upId of rawUpstreamIds) {
    const doc = docMap.get(upId.toString());
    if (doc) {
      const rName = (doc.roleId?.roleName || doc.roleId?.name || doc.role || "").toLowerCase().trim();
      const dName = (doc.departmentId?.name || doc.deparment || "").toLowerCase().trim();
      const isAdmin = rName === 'admin' || rName === 'super_admin' || rName === 'super admin' ||
                      dName === 'admin' || dName === 'super_admin';
      if (!isAdmin) {
        nonAdminUpstream.push(doc);
      }
    }
  }

  if (nonAdminUpstream.length === 0) {
    return callerObjectId;
  }

  // If caller themselves has a Director role, caller is the branch director
  if (/director|head/i.test(callerRoleName)) {
    return callerObjectId;
  }

  // Search from the top of the non-admin chain (last element) down to caller
  // Look for a supervisor with Director / Head title
  for (let i = nonAdminUpstream.length - 1; i >= 0; i--) {
    const doc = nonAdminUpstream[i];
    const rName = (doc.roleId?.roleName || doc.roleId?.name || doc.role || "").toLowerCase().trim();
    if (/director|head/i.test(rName)) {
      return doc._id;
    }
  }

  // If no explicit 'director'/'head' role title in chain,
  // the topmost non-admin supervisor in the branch tree is the branch director
  return nonAdminUpstream[nonAdminUpstream.length - 1]._id;
}

/**
 * Resolves all staff ObjectIds belonging to the caller's branch.
 * - System Admin: returns null (global boundary)
 * - Branch Staff: finds caller's Branch Director, then gathers the Director
 *   plus all direct and indirect downstream subordinates under that Director.
 */
export async function getBranchStaffIds(callerId) {
  if (!callerId) return [];
  const callerObjectId = mongoose.isValidObjectId(callerId)
    ? new mongoose.Types.ObjectId(callerId.toString())
    : null;
  if (!callerObjectId) return [];

  // Check if caller is System Admin
  const hierarchy = await getSupervisedStaffIds(callerObjectId);
  if (hierarchy.isSystemAdmin) {
    return null; // Global boundary
  }

  const branchDirectorId = await getBranchDirectorId(callerObjectId);
  if (!branchDirectorId) {
    return [callerObjectId];
  }

  // Get all staff supervised directly or indirectly by the branch director
  const directorHierarchy = await getSupervisedStaffIds(branchDirectorId);

  const staffIdSet = new Set();
  staffIdSet.add(branchDirectorId.toString());

  if (Array.isArray(directorHierarchy.staffIds)) {
    for (const sid of directorHierarchy.staffIds) {
      if (sid) staffIdSet.add(sid.toString());
    }
  }

  // Always include caller themselves
  staffIdSet.add(callerObjectId.toString());

  return Array.from(staffIdSet).map(id => new mongoose.Types.ObjectId(id));
}

/**
 * Resolves the data access scope for a given staff member and module based on atomic permissions.
 * Priority order:
 *   1. System Admin or {module}.view_all -> { type: 'global', staffIds: null }
 *   2. {module}.view_branch               -> { type: 'branch', staffIds: [...] }
 *   3. Default / {module}.view_assigned   -> { type: 'assigned', staffIds: [...] }
 *
 * @param {string|ObjectId} callerId - Authenticated staff member ObjectId
 * @param {string} module - Module name (default: 'users')
 * @returns {Promise<{ type: 'global'|'branch'|'assigned', staffIds: ObjectId[]|null }>}
 */
export async function resolveUserScope(callerId, module = 'users') {
  if (!callerId) {
    return { type: 'assigned', staffIds: [] };
  }

  const callerObjectId = mongoose.isValidObjectId(callerId)
    ? new mongoose.Types.ObjectId(callerId.toString())
    : null;

  if (!callerObjectId) {
    return { type: 'assigned', staffIds: [] };
  }

  // 1. Check if caller is System Admin via getSupervisedStaffIds
  const hierarchy = await getSupervisedStaffIds(callerObjectId);
  if (hierarchy.isSystemAdmin) {
    return { type: 'global', staffIds: null };
  }

  // 2. Fetch staff member with role and permission groups
  const staffMember = await staffModel.findById(callerObjectId)
    .populate('departmentId')
    .populate({
      path: 'roleId',
      populate: [
        { path: 'permissionGroups' },
        { path: 'departmentId' }
      ]
    });

  if (!staffMember) {
    // If not in staffModel, check primary userModel (system admin)
    const primaryUser = await userModel.findById(callerObjectId);
    if (primaryUser) {
      const uType = (primaryUser.userType || "").toLowerCase().trim();
      const uRole = (primaryUser.role || "").toLowerCase().trim();
      if (uType === 'admin' || uType === 'super_admin' || uRole === 'admin' || uRole === 'super_admin') {
        return { type: 'global', staffIds: null };
      }
    }
    return { type: 'assigned', staffIds: [callerObjectId] };
  }

  // Role or Department admin bypass
  const roleName = (staffMember.roleId?.name || staffMember.role || "").toLowerCase().trim();
  const deptName = (staffMember.departmentId?.name || staffMember.deparment || "").toLowerCase().trim();
  if (roleName === 'admin' || roleName === 'super_admin' || roleName === 'super admin' ||
      deptName === 'admin' || deptName === 'super_admin' || deptName === 'super admin') {
    return { type: 'global', staffIds: null };
  }

  // Hierarchy Inheritance: Inherit permission groups from lower-level roles in same department if level > 1
  if (staffMember.roleId && staffMember.roleId.level > 1 && staffMember.roleId.departmentId) {
    const deptId = staffMember.roleId.departmentId._id || staffMember.roleId.departmentId;
    const lowerRoles = await roleModel.find({
      departmentId: deptId,
      level: { $lt: staffMember.roleId.level },
      isActive: true
    }).populate('permissionGroups');

    const existingPgIds = new Set((staffMember.roleId.permissionGroups || []).map(g => (g._id || g).toString()));
    for (const lr of lowerRoles) {
      for (const pg of (lr.permissionGroups || [])) {
        const pgIdStr = (pg._id || pg).toString();
        if (!existingPgIds.has(pgIdStr)) {
          existingPgIds.add(pgIdStr);
          staffMember.roleId.permissionGroups.push(pg);
        }
      }
    }
  }

  // 3. Extract all action strings from permission groups
  const actions = new Set();
  if (staffMember.roleId && Array.isArray(staffMember.roleId.permissionGroups)) {
    for (const group of staffMember.roleId.permissionGroups) {
      if (Array.isArray(group?.permissions)) {
        for (const perm of group.permissions) {
          const permFeature = (perm?.feature || "").toLowerCase().trim();
          if (Array.isArray(perm?.actions)) {
            for (const act of perm.actions) {
              if (act) {
                const lowerAct = act.toLowerCase().trim();
                actions.add(lowerAct);
                if (permFeature && !lowerAct.includes('.')) {
                  actions.add(`${permFeature}.${lowerAct}`);
                }
              }
            }
          }
        }
      }
    }
  }

  const modKey = (module || 'users').toLowerCase().trim();

  // 4. Resolve scope based on atomic permissions:
  // Priority 1: Global scope
  if (actions.has(`${modKey}.view_all`) || actions.has('view_all')) {
    return { type: 'global', staffIds: null };
  }

  // Priority 2: Branch scope
  if (actions.has(`${modKey}.view_branch`) || actions.has('view_branch')) {
    const branchStaffIds = await getBranchStaffIds(callerObjectId);
    return { type: 'branch', staffIds: branchStaffIds };
  }

  // Priority 3: Assigned scope (default)
  return {
    type: 'assigned',
    staffIds: hierarchy.staffIds || [callerObjectId]
  };
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

export default {
  getSupervisedStaffIds,
  getUpstreamSupervisorIds,
  getBranchDirectorId,
  getBranchStaffIds,
  resolveUserScope,
  getAccessibleLeadPoolFilter
};
