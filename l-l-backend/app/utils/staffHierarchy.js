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
  const staffMember = await staffModel.findById(callerObjectId).populate('roleId');
  let isSystemAdmin = false;

  if (staffMember) {
    const roleName = (staffMember.roleId?.roleName || staffMember.roleId?.name || "").toLowerCase();
    const dept = (staffMember.deparment || staffMember.department || "").toLowerCase();
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
    return { isSystemAdmin: true, isSupervisor: true, staffIds: null };
  }

  // If not staff member and not admin, return empty
  if (!staffMember) {
    return { isSystemAdmin: false, isSupervisor: false, staffIds: [callerObjectId] };
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

  const roleName = (staffMember?.roleId?.roleName || staffMember?.roleId?.name || "").toLowerCase();
  const dept = (staffMember?.deparment || staffMember?.department || "").toLowerCase();
  const isDirector = dept.includes('director') || roleName.includes('director');
  const isManager = dept.includes('manager') || roleName.includes('manager');

  const staffIds = Array.from(supervisedMap.values());
  const isSupervisor = staffIds.length > 1 || isDirector || isManager;

  return {
    isSystemAdmin: false,
    isSupervisor,
    isDirector,
    isManager,
    staffIds,
    staffMember
  };
}

export default { getSupervisedStaffIds };
