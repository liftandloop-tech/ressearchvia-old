import staffModel from "../models/staffModel.js";
import staffAssigmentModel from "../models/staffAssignmentModel.js";
import userModel from "../models/userModel.js"
import axios from "axios"
import jwt from "jsonwebtoken"
import bcrypt from "bcryptjs"
import mongoose from "mongoose";
import { logManagerAssigned } from "./activityLogService.js";
import roleModel from "../models/roleModel.js";
import roleService from "./roleService.js";
import departmentModel from "../models/departmentModel.js";
import generalSettingsModel from "../models/generalSettingsModel.js";
import { getSupervisedStaffIds } from "../utils/staffHierarchy.js";
import TokenBlacklist from "../models/tokenBlacklistModel.js";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import FormData from "form-data";
import { PDFDocument, StandardFonts, rgb } from "pdf-lib";
import emailService from "./emailService.js";
import userKycService from "./userKycService.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);



/**
 * Automatically resolve role and its department.
 * Role is under department (either directly or via its permission groups).
 * Staff is assigned role only, and department is derived automatically.
 */
export async function resolveRoleAndDepartment({ roleId, roleName, fallbackDept }) {
  let role = null;
  if (roleId) {
    role = await roleModel.findById(roleId).populate({
      path: 'permissionGroups',
      populate: { path: 'departmentId' }
    }).populate('departmentId');
  }

  if (!role && roleName) {
    const trimmed = roleName.trim();
    role = await roleModel.findOne({ name: { $regex: new RegExp(`^\\s*${trimmed}\\s*$`, 'i') } }).populate({
      path: 'permissionGroups',
      populate: { path: 'departmentId' }
    }).populate('departmentId');
  }

  if (!role && fallbackDept) {
    const trimmed = fallbackDept.trim();
    role = await roleModel.findOne({ name: { $regex: new RegExp(`^\\s*${trimmed}\\s*$`, 'i') } }).populate({
      path: 'permissionGroups',
      populate: { path: 'departmentId' }
    }).populate('departmentId');
  }

  if (!role) {
    return { roleId: null, roleName: roleName || null, departmentId: null, departmentName: fallbackDept || null };
  }

  // Find department from role directly
  let deptId = role.departmentId?._id || role.departmentId || null;
  let deptName = role.departmentId?.name || null;

  // If not on role directly, derive from its permission groups (which belong to a department)
  if (!deptId && role.permissionGroups && role.permissionGroups.length > 0) {
    for (const pg of role.permissionGroups) {
      if (pg && pg.departmentId) {
        deptId = pg.departmentId._id || pg.departmentId;
        deptName = pg.departmentId.name || null;
        break;
      }
    }
  }

  // If we have deptId but no deptName, look it up in departmentModel
  if (deptId && !deptName) {
    const deptDoc = await departmentModel.findById(deptId);
    if (deptDoc) deptName = deptDoc.name;
  }

  return {
    roleId: role._id,
    roleName: role.name,
    departmentId: deptId,
    departmentName: deptName
  };
}

export async function populateStaffHierarchy(staffDoc) {
  if (!staffDoc) return staffDoc;
  const staffObj = staffDoc.toObject ? staffDoc.toObject() : staffDoc;

  // Fallback departmentId from roleId if staff.departmentId is null
  if (!staffObj.departmentId && staffObj.roleId && staffObj.roleId.departmentId) {
    staffObj.departmentId = staffObj.roleId.departmentId;
  }
  if (!staffObj.departmentId && (staffObj.deparment || staffObj.department)) {
    const deptName = (staffObj.deparment || staffObj.department).trim();
    const deptDoc = await departmentModel.findOne({
      name: { $regex: new RegExp(`^${deptName}$`, 'i') }
    }).lean();
    if (deptDoc) {
      staffObj.departmentId = deptDoc;
    }
  }

  // Hierarchy Inheritance:
  // If staff has a role with level > 1 and belongs to a department,
  // inherit permission groups from all lower-level roles in the same department
  if (staffObj.roleId && staffObj.roleId.level > 1 && staffObj.roleId.departmentId) {
    const deptId = staffObj.roleId.departmentId._id || staffObj.roleId.departmentId;
    const lowerRoles = await roleModel.find({
      departmentId: deptId,
      level: { $lt: staffObj.roleId.level },
      isActive: true
    }).populate({
      path: 'permissionGroups',
      populate: { path: 'departmentId' }
    }).lean();

    const existingPgIds = new Set((staffObj.roleId.permissionGroups || []).map(g => (g._id || g).toString()));
    const mergedGroups = [...(staffObj.roleId.permissionGroups || [])];

    for (const lr of lowerRoles) {
      for (const pg of (lr.permissionGroups || [])) {
        const pgIdStr = (pg._id || pg).toString();
        if (!existingPgIds.has(pgIdStr)) {
          existingPgIds.add(pgIdStr);
          mergedGroups.push(pg);
        }
      }
    }
    staffObj.roleId.permissionGroups = mergedGroups;
  }

  return staffObj;
}

const staffService = {
  staffCreate: async ({ body, user }) => {
    try {
      console.log('staffCreate body:', body);
      const callerId = user?._id || user?.userId || user?.id;
      if (callerId) {
        const hierarchy = await getSupervisedStaffIds(callerId);
        if (!hierarchy.isSystemAdmin) {
          body.assignedDirector = callerId;
          body.assignedDirectorName = user.fullName;
        }
      }

      if (!body.staffId) {
        // Generate a unique staff ID if not provided
        const count = await staffModel.countDocuments();
        const randomSuffix = Math.floor(1000 + Math.random() * 9000);
        body.staffId = `STF${String(count + 1).padStart(3, '0')}${randomSuffix}`;
      }

      // Admin-created staff should default to 'Employee' stage, not 'Applicant'
      body.stage = body.stage || 'Employee';

      if (body.mpin) {
        body.mpin = body.mpin.toString();
      }

      // Seed default Admin role and group
      await roleService.seedAdminRole();

      // Automatically resolve Role and Department (Department is derived from Role)
      const resolved = await resolveRoleAndDepartment({
        roleId: body.roleId,
        roleName: body.role,
        fallbackDept: body.deparment || body.department
      });

      if (resolved.roleId) {
        body.roleId = resolved.roleId;
        body.role = resolved.roleName;
      }
      if (resolved.departmentId) {
        body.departmentId = resolved.departmentId;
        body.deparment = resolved.departmentName;
      } else if (body.departmentId) {
        const dept = await departmentModel.findById(body.departmentId);
        if (dept && !body.deparment) {
          body.deparment = dept.name;
        }
      }

      let staff = await staffModel.findOne({ staffId: body.staffId })
      if (!staff) {
        console.log('Creating staff member. body.isViewOnly:', body.isViewOnly, 'type:', typeof body.isViewOnly);
        if (body.isViewOnly !== undefined) {
          body.isViewOnly = (body.isViewOnly === true || body.isViewOnly === 'true' || body.isViewOnly === 1);
        }
        console.log('Creating staff with processed isViewOnly:', body.isViewOnly);
        staff = await staffModel.create(body)
        return { status: 200, message: "staff", data: { staff } }
      } else {
        return { status: 200, message: "staff already exist", data: {} }
      }
    } catch (error) {
      return { status: 400, message: error.message, data: {} }
    }
  },

  staffLogin: async ({ body }) => {
    try {
      let { phone } = body
      const otp = Math.floor(1000 + Math.random() * 9000).toString();
      const username = process.env.SMS_SHORT_SERVICE_USER || 'ResearchVia';
      const apikey = process.env.SMS_SHORT_SERVICE_API_KEY || 'DA15E-A0C79';
      const sender = process.env.SMS_SHORT_SERVICE_SENDER || 'REGISR';
      const templateID = process.env.SMS_SHORT_SERVICE_TEMPLATEID || '1607100000000327862';
      const url = process.env.SMS_SHORT_SERVICE_URL || 'http://sms.shortmsgservice.com/sms-panel/api/http/index.php?';
      const cleanPhone = phone ? phone.toString().replace(/[^0-9]/g, '') : '';
      const last10 = cleanPhone.slice(-10);

      const staff = await staffModel.findOne({
        $or: [
          { mobileNumber: phone },
          { mobileNumber: cleanPhone },
          { mobileNumber: last10 },
          { mobileNumber: parseInt(last10) },
          { mobileNumber: `91${last10}` },
          { mobileNumber: `+91${last10}` }
        ]
      });
      if (!staff) {
        return { status: 200, message: "staff not found", data: {} }
      }

      if (staff.status && (staff.status.toLowerCase() === 'inactive' || staff.status.toLowerCase() === 'deactivated')) {
        return { status: 403, message: "Access denied. Account is inactive. Please contact Admin.", data: {} };
      }
      const defaultTemplate = "Your OTP for ResearchVia App is {OTP}\n\n\n\nPlease do not share OTP with anyone.\n\nhttps://researchvia.in\n\n";
      const messageText = defaultTemplate.replaceAll('{OTP}', otp);
      const message = encodeURIComponent(messageText);
      const smsUrl = `${url}username=${username}&apikey=${apikey}&apirequest=Text&sender=${sender}&mobile=91${last10}&message=${message}sms&route=TRANS&TemplateID=${templateID}&format=JSON`;
      const response = await axios.get(smsUrl);
      if (response.status == 200) {
        staff.otp = otp;
        staff.otpExpires = Date.now() + 5 * 60 * 1000;
        await staff.save();
        return { status: 200, message: "OTP send your phone ", data: {} }
      }
    } catch (error) {
      return { status: 400, message: error.message, data: {} }

    }
  },
  staffOtpVerify: async ({ body }) => {
    try {
      let { otp, phone, email, staffId } = body;
      if (!otp) {
        return { status: 400, message: "OTP is required", data: {} };
      }

      let staff = null;
      if (phone || email || staffId) {
        const queryOr = [];
        if (phone) {
          const raw = phone.toString().replace(/\D/g, '').slice(-10);
          queryOr.push({ mobileNumber: raw });
          queryOr.push({ mobileNumber: Number(raw) });
        }
        if (email) queryOr.push({ emailAddress: email.trim().toLowerCase() });
        if (staffId) queryOr.push({ staffId: staffId.trim() });
        staff = await staffModel.findOne({ $or: queryOr }).select('+otp +otpExpires');
      }
      if (!staff) {
        staff = await staffModel.findOne({ otp: Number(otp) }).select('+otp +otpExpires');
      }

      if (!staff) {
        return { status: 404, message: "Staff not found", data: {} };
      }

      const isOtpValid = (staff.otp !== null && staff.otp !== undefined) &&
        (staff.otp.toString() === otp.toString().trim()) &&
        (!staff.otpExpires || staff.otpExpires >= Date.now());

      if (!isOtpValid) {
        return { status: 400, message: "OTP Invalid or expired", data: {} };
      }

      if (staff.status && (staff.status.toLowerCase() === 'inactive' || staff.status.toLowerCase() === 'deactivated')) {
        return { status: 403, message: "Access denied. Account is inactive. Please contact Admin.", data: {} };
      }
      staff.otp = null;
      staff.otpExpires = null;
      await staff.save();

      // Seed default Admin role and group
      await roleService.seedAdminRole();

      // Auto-assign Admin role to Admin department if not present
      if (!staff.roleId && (staff.deparment || "").toLowerCase() === 'admin') {
        const adminRole = await roleModel.findOne({ name: 'Admin' });
        if (adminRole) {
          staff.roleId = adminRole._id;
          await staff.save();
        }
      }

      // Populate role details for response
      staff = await staffModel.findById(staff._id)
        .populate('departmentId')
        .populate({
          path: 'roleId',
          populate: {
            path: 'permissionGroups'
          }
        });

      let token = jwt.sign(
        {
          _id: staff._id.toString(),
          fullName: staff.fullName,
          phone: staff.mobileNumber,
          userType: staff.deparment,
          isViewOnly: staff.isViewOnly || false
        },
        process.env.JWT_TOKEN,
        { expiresIn: '8h' }
      );
      return { status: 200, message: "Login successfully", data: { token, staff } }
    } catch (error) {
      return { status: 400, message: error.message, data: {} }
    }
  },
  staffMpinLogin: async ({ body }) => {
    try {
      console.log('staffMpinLogin body:', body);
      let { phone, mpin } = body;
      const cleanPhone = phone ? phone.toString().replace(/[^0-9]/g, '') : '';
      const last10 = cleanPhone.slice(-10);

      let staff = await staffModel.findOne({
        $or: [
          { mobileNumber: phone },
          { mobileNumber: cleanPhone },
          { mobileNumber: last10 },
          { mobileNumber: parseInt(last10) },
          { mobileNumber: `91${last10}` },
          { mobileNumber: `+91${last10}` }
        ]
      }).select('+mpin');

      if (!staff) {
        return { status: 200, message: "Staff not found", data: {} }
      }

      if (staff.status && (staff.status.toLowerCase() === 'inactive' || staff.status.toLowerCase() === 'deactivated')) {
        return { status: 403, message: "Access denied. Account is inactive. Please contact Admin.", data: {} };
      }

      if (!staff.mpin) {
        return { status: 200, message: "MPIN not set for this staff member. Please contact Admin.", data: {} }
      }

      const isMatch = mpin.toString() === staff.mpin;

      if (!isMatch) {
        return { status: 200, message: "Invalid MPIN", data: {} }
      }

      // Seed default Admin role and group
      await roleService.seedAdminRole();

      // Auto-assign Admin role to Admin department if not present
      if (!staff.roleId && (staff.deparment || "").toLowerCase() === 'admin') {
        const adminRole = await roleModel.findOne({ name: 'Admin' });
        if (adminRole) {
          staff.roleId = adminRole._id;
          await staff.save();
        }
      }

      // Populate role details for response
      staff = await staffModel.findById(staff._id)
        .populate('departmentId')
        .populate({
          path: 'roleId',
          populate: [
            { path: 'permissionGroups' },
            { path: 'departmentId' }
          ]
        });

      staff = await populateStaffHierarchy(staff);

      let token = jwt.sign(
        {
          _id: staff._id.toString(),
          fullName: staff.fullName,
          phone: staff.mobileNumber,
          userType: staff.deparment,
          isViewOnly: staff.isViewOnly || false
        },
        process.env.JWT_TOKEN,
        { expiresIn: '8h' }
      );
      return { status: 200, message: "Login successfully", data: { token, staff } }
    } catch (error) {
      return { status: 400, message: error.message, data: {} }
    }
  },
  staffImpersonate: async ({ body, user }) => {
    try {
      if (!user) {
        return { status: 403, message: "Authentication required to login as staff.", data: {} };
      }

      const { staffId } = body;
      if (!staffId) {
        return { status: 400, message: "Staff ID is required", data: {} };
      }

      let staff = await staffModel.findOne({
        $or: [
          { _id: mongoose.isValidObjectId(staffId) ? staffId : null },
          { staffId: staffId }
        ].filter(Boolean)
      })
      .populate('departmentId')
      .populate({
        path: 'roleId',
        populate: [
          { path: 'permissionGroups' },
          { path: 'departmentId' }
        ]
      });

      if (!staff) {
        return { status: 404, message: "Staff member not found", data: {} };
      }

      staff = await populateStaffHierarchy(staff);

      // Generate staff token for admin impersonation (valid for 2 hours)
      const token = jwt.sign(
        {
          _id: staff._id.toString(),
          fullName: staff.fullName,
          phone: staff.mobileNumber,
          userType: staff.deparment || 'Staff',
          isViewOnly: staff.isViewOnly || false,
          isImpersonated: true
        },
        process.env.JWT_TOKEN,
        { expiresIn: '2h' }
      );

      return {
        status: 200,
        message: "Staff impersonation token generated successfully",
        data: {
          token,
          staff,
          impersonatedBy: user ? user.fullName : 'Admin'
        }
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  staffReset: async ({ query, body, user }) => {
    try {
      console.log('staffReset query:', query);
      console.log('staffReset body:', body);
      let { id } = query
      let { fullName, mobileNumber, emailAddress, deparment, departmentId, designation, role, roleId } = body
      const staff = await staffModel.findOne({ _id: id })
      if (!staff || staff == null) {
        return { status: 200, message: "staff not exist", data: {} }
      }

      // Ensure stage is set to 'Employee' for active staff updates (prevents schema default demoting them to Applicant)
      staff.stage = 'Employee';

      // Hierarchy Check: Non-admins can only manage staff from their own team/hierarchy
      const callerId = user?._id || user?.userId || user?.id;
      const isSuper = user?.userType === 'admin' || user?.userType === 'super_admin' || user?.role === 'Admin' || user?.role === 'admin';
      if (!isSuper && callerId) {
        const hierarchy = await getSupervisedStaffIds(callerId);
        if (!hierarchy.isSystemAdmin) {
          const isSupervised = hierarchy.staffIds?.some(id => id.toString() === staff._id.toString());
          if (!isSupervised) {
            return { status: 403, message: "Access Denied. You can only manage staff from your own team.", data: {} };
          }
        }
      }
      if (fullName) staff.fullName = fullName;
      if (mobileNumber) staff.mobileNumber = mobileNumber;
      if (emailAddress) staff.emailAddress = emailAddress;

      const targetRoleId = roleId !== undefined ? roleId : body.roleId;
      const targetRoleName = role || body.role;

      if (targetRoleId || targetRoleName || deparment || departmentId) {
        const resolved = await resolveRoleAndDepartment({
          roleId: targetRoleId,
          roleName: targetRoleName,
          fallbackDept: deparment
        });

        if (resolved.roleId) {
          staff.roleId = resolved.roleId;
          staff.role = resolved.roleName;
        } else if (targetRoleId === null) {
          staff.roleId = null;
          staff.role = null;
        }

        if (resolved.departmentId) {
          staff.departmentId = resolved.departmentId;
          staff.deparment = resolved.departmentName;
        } else if (departmentId !== undefined) {
          if (departmentId) {
            const dept = await departmentModel.findById(departmentId);
            staff.departmentId = dept ? dept._id : null;
            if (dept && !deparment) staff.deparment = dept.name;
          } else {
            staff.departmentId = null;
          }
        } else if (deparment) {
          staff.deparment = deparment.trim();
        }
      }
      if (designation) staff.designation = designation;

      if (body.gender) staff.gender = body.gender;
      if (body.dob) staff.dob = new Date(body.dob);
      if (body.experienceYears !== undefined) staff.experienceYears = Number(body.experienceYears);
      if (body.previousCompany) staff.previousCompany = body.previousCompany;
      if (body.lastCtc) staff.lastCtc = body.lastCtc;
      if (body.localAddress) staff.localAddress = body.localAddress;
      if (body.emergencyContact !== undefined) {
        if (!body.emergencyContact || (!body.emergencyContact.name && !body.emergencyContact.phone)) {
          staff.emergencyContact = null;
        } else {
          staff.emergencyContact = body.emergencyContact;
        }
      }

      if (body.assignedDirector !== undefined) {
        const rawDir = body.assignedDirector;
        if (!rawDir || rawDir === 'unassigned' || rawDir === 'admin' || !mongoose.isValidObjectId(rawDir)) {
          staff.assignedDirector = null;
        } else {
          staff.assignedDirector = new mongoose.Types.ObjectId(rawDir.toString());
        }
      }
      if (body.assignedDirectorName !== undefined) {
        staff.assignedDirectorName = staff.assignedDirector 
          ? (body.assignedDirectorName || null) 
          : ((body.assignedDirector === 'admin' || body.assignedDirectorName === 'Admin') ? 'Admin' : null);
      }

      if (body.mpin) {
        staff.mpin = body.mpin.toString();
      }

      if (body.status) {
        staff.status = body.status;
      }

      console.log('body.isViewOnly value:', body.isViewOnly, 'type:', typeof body.isViewOnly);
      if (body.isViewOnly !== undefined) {
        staff.isViewOnly = (body.isViewOnly === true || body.isViewOnly === 'true' || body.isViewOnly === 1);
      }

      if (body.walkInForm !== undefined) {
        staff.walkInForm = body.walkInForm;
        staff.markModified('walkInForm');
      }

      console.log('Final staff object before save (isViewOnly):', staff.isViewOnly);
      await staff.save()
      console.log('Staff saved successfully. DB state isViewOnly:', staff.isViewOnly);
      return { status: 200, message: "staff", data: { staff } }

    } catch (error) {
      return { status: 400, message: error.message, data: {} }
    }
  },
  cancleStaff: async ({ params, user }) => {
    try {
      let { id } = params
      const staff = await staffModel.findOne({ _id: id })
      if (!staff) return { status: 200, message: "staff not exist", data: {} }

      // Hierarchy Check: Non-admins can only remove staff from their own team/hierarchy
      const callerId = user?._id || user?.userId || user?.id;
      if (callerId) {
        const hierarchy = await getSupervisedStaffIds(callerId);
        if (!hierarchy.isSystemAdmin) {
          const isSupervised = hierarchy.staffIds?.some(id => id.toString() === staff._id.toString());
          if (!isSupervised) {
            return { status: 403, message: "Access Denied. You can only remove staff from your own team.", data: {} };
          }
        }
      }

      await staffModel.findByIdAndDelete(id)
      return { status: 200, message: "staff cancle", data: {} }
    } catch (error) {
      return { status: 400, message: error.message, data: {} }
    }
  },
  staffList: async ({ query = {}, user }) => {
    try {
      let mongoQuery = {
        stage: { $ne: 'Applicant' }
      };

      // Status filtering: Default to Active only unless explicitly requested
      const statusParam = (query?.status || '').toString().trim();
      if (statusParam.toUpperCase() === 'ALL') {
        // Return all staff members regardless of status
      } else if (statusParam.toUpperCase() === 'INACTIVE') {
        // Return inactive / deactivated staff
        mongoQuery.status = { $in: ['Inactive', 'Deactivated', 'inactive', 'deactivated'] };
      } else if (statusParam) {
        mongoQuery.status = { $regex: new RegExp(`^${statusParam}$`, 'i') };
      } else {
        // DEFAULT: Show only active staff
        mongoQuery.status = { $in: ['Active', 'active'] };
      }

      console.log('=== staffList called ===');
      console.log('User:', user ? { userType: user.userType, deparment: user.deparment, _id: user._id } : 'No user');

      const callerId = user?._id || user?.userId;
      let isSystemAdmin = false;
      let hasGlobalStaffAccess = false;

      if (callerId) {
        const hierarchy = await getSupervisedStaffIds(callerId);
        isSystemAdmin = hierarchy.isSystemAdmin;

        const deptName = (hierarchy.staffMember?.deparment || hierarchy.staffMember?.departmentId?.name || "").toLowerCase().trim();
        const isHRorAdminDept = deptName === 'admin' || deptName === 'administration & management' || deptName === 'hr';

        if (isHRorAdminDept && hierarchy.staffMember?.roleId?.permissionGroups) {
          hasGlobalStaffAccess = hierarchy.staffMember.roleId.permissionGroups.some(g =>
            g.permissions?.some(p => p.actions?.includes('staff.view'))
          );
        }

        const forceScoped = query?.scoped === 'true' || query?.scoped === true;
        const isDirector = hierarchy.isDirector || /director/i.test(deptName) || /director/i.test(hierarchy.staffMember?.role || "");
        if (!isSystemAdmin && (!hasGlobalStaffAccess || forceScoped || isDirector)) {
          mongoQuery._id = { $in: hierarchy.staffIds };
          console.log(`Staff list scoped for ${hierarchy.staffMember?.fullName} (${hierarchy.staffIds?.length || 0} staff):`, JSON.stringify(mongoQuery));
        } else {
          console.log('Admin / global staff access query (all staff):', JSON.stringify(mongoQuery));
        }
      }

      const staffList = await staffModel.find(mongoQuery)
        .populate({
          path: 'roleId',
          populate: [
            { path: 'permissionGroups', populate: { path: 'departmentId' } },
            { path: 'departmentId' }
          ]
        })
        .populate('departmentId')
        .lean();
      console.log(`Found ${staffList.length} staff members (statusFilter=${statusParam || 'Active(default)'})`);
      console.log('Staff departments:', staffList.map(s => ({ name: s.fullName, dept: s.deparment, status: s.status })));

      return { status: 200, message: "staff list", data: { staffList } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  StaffAssignment: async ({ body, user: requestingUser, req }) => {
    try {
      let userDoc = await userModel.findOne({ _id: body.userId })
      if (userDoc) {
        let assignment = await staffAssigmentModel.findOne({ userId: body.userId })
        let assignmentData = await staffModel.findOne({ _id: body.staffId })
        if (!assignmentData) {
          return { status: 200, message: "staff not exist", data: {} }
        }
        if (assignmentData.status && assignmentData.status.toLowerCase() !== 'active') {
          return { status: 400, message: "Cannot assign an inactive staff member", data: {} };
        }

        // Hierarchy Check: Non-admins can only assign staff from their own team/hierarchy
        const requestingId = requestingUser?._id || requestingUser?.userId || requestingUser?.id;
        if (requestingId) {
          const hierarchy = await getSupervisedStaffIds(requestingId);
          if (!hierarchy.isSystemAdmin) {
            const isSupervised = hierarchy.staffIds?.some(id => id.toString() === assignmentData._id.toString());
            if (!isSupervised) {
              return { status: 403, message: "Access Denied. You can only assign staff from your own team.", data: {} };
            }
          }
        }

        console.log("assignmentData=====", assignmentData.fullName)
        body.staffName = assignmentData.fullName

        if (!assignment) {
          assignment = await staffAssigmentModel.create(body)
        } else {
          // Update existing assignment
          assignment.staffId = body.staffId;
          assignment.staffName = body.staffName;
          await assignment.save();
        }

        // --- COMPLIANCE LOG: MANAGER ASSIGNED ---
        logManagerAssigned({
          userId: body.userId,
          manager: {
            id: assignmentData._id.toString(),
            name: assignmentData.fullName,
            staffId: assignmentData.staffId
          },
          performedBy: {
            id: requestingUser?._id?.toString() || null,
            name: requestingUser?.fullName || 'Admin',
            role: requestingUser?.userType || 'ADMIN'
          },
          req
        });

        return { status: 200, message: "staff assignment", data: { assignment } }
      } else {
        return { status: 200, message: "user not exist", data: {} }
      }
    } catch (error) {
      return { status: 400, message: error.message, data: {} }

    }
  },

  getStaffAssignedUsers: async ({ staffId, user, query }) => {
    try {
      let page = Math.max(1, parseInt(query.page) || 1);
      let pageSize = Math.min(100, Math.max(1, parseInt(query.pageSize) || 10));
      let search = query.search ? query.search.trim() : "";

      let targetStaffIds = [staffId];
      const hierarchy = await getSupervisedStaffIds(staffId);
      if (!hierarchy.isSystemAdmin && hierarchy.staffIds) {
        targetStaffIds = hierarchy.staffIds;
      }

      const staffObjIds = targetStaffIds
        .filter(sid => sid && mongoose.isValidObjectId(sid))
        .map(sid => new mongoose.Types.ObjectId(sid.toString()));
      const staffStrIds = targetStaffIds.filter(Boolean).map(sid => sid.toString());
      const allTargetStaffIds = [...new Set([...staffObjIds, ...staffStrIds])];

      // Get all user IDs assigned to this staff (or team)
      const assignments = await staffAssigmentModel.find({ staffId: { $in: allTargetStaffIds } }).select('userId');
      const assignedUserIds = assignments
        .map(a => a.userId)
        .filter(id => id && mongoose.isValidObjectId(id))
        .map(id => new mongoose.Types.ObjectId(id.toString()));

      if (assignedUserIds.length === 0) {
        return { status: 200, message: "No users assigned", data: { totalCount: 0, userData: [] } };
      }

      const baseMatch = {
        _id: { $in: assignedUserIds },
        userType: { $ne: "admin" }
      };

      if (search) {
        baseMatch.$or = [
          { fullName: { $regex: search, $options: "i" } },
          { phone: { $regex: search, $options: "i" } },
          { email: { $regex: search, $options: "i" } }
        ];
      }

      const [totalCount, pageDocs] = await Promise.all([
        userModel.countDocuments(baseMatch),
        userModel.find(baseMatch)
          .sort({ createdAt: -1 })
          .skip((page - 1) * pageSize)
          .limit(pageSize)
          .select('_id')
          .lean()
      ]);

      const pageIds = pageDocs.map(d => d._id);
      if (pageIds.length === 0) {
        return { status: 200, message: "Staff assigned users", data: { totalCount, userData: [] } };
      }

      const aggregationPipeline = [
        {
          $match: { _id: { $in: pageIds } }
        },
        {
          $lookup: {
            from: "entitlements",
            let: { userId: "$_id" },
            pipeline: [
              {
                $match: {
                  $expr: {
                    $and: [
                      { $eq: ["$userId", "$$userId"] },
                      { $eq: ["$type", "PLAN"] },
                      { $eq: ["$status", "ACTIVE"] }
                    ]
                  }
                }
              },
              {
                $lookup: {
                  from: "segmentsplans",
                  localField: "resourceId",
                  foreignField: "_id",
                  as: "planDetails"
                }
              },
              { $unwind: "$planDetails" },
              {
                $project: {
                  packageName: { $concat: ["$planDetails.segmentsName", " - ", "$planDetails.planName"] },
                  endDate: 1,
                  startDate: 1
                }
              }
            ],
            as: "activeEntitlements"
          }
        },
        {
          $lookup: {
            from: "planpurchases",
            let: { userId: "$_id" },
            pipeline: [
              {
                $match: {
                  $expr: { $eq: ["$userId", "$$userId"] },
                  status: "active"
                }
              }
            ],
            as: "planpurchasesData"
          }
        },
        {
          $lookup: {
            from: "staffassigments",
            let: { userId: "$_id" },
            pipeline: [
              {
                $match: {
                  $expr: { $eq: ["$userId", "$$userId"] },
                },
              },
            ],
            as: "assignmentData",
          },
        },
        {
          $unwind: {
            path: "$assignmentData",
            preserveNullAndEmptyArrays: true,
          },
        },
        {
          $project: {
            fullName: 1,
            phone: 1,
            email: 1,
            userId: 1,
            userStatus: 1,
            kycStatus: 1,
            registrationStatus: 1,
            registrationType: 1,
            registrationSource: 1,
            planSource: 1,
            ManagerId: "$assignmentData.staffId",
            Manager: "$assignmentData.staffName",
            subscriptionEndDate: {
              $cond: {
                if: { $gt: [{ $size: "$activeEntitlements" }, 0] },
                then: { $max: "$activeEntitlements.endDate" },
                else: { $max: "$planpurchasesData.endDate" }
              }
            },
            packageName: {
              $ifNull: [
                { $arrayElemAt: ["$activeEntitlements.packageName", 0] },
                { $arrayElemAt: ["$planpurchasesData.packageName", 0] },
                "N/A"
              ]
            },
            activePlans: {
              $cond: {
                if: { $gt: [{ $size: "$activeEntitlements" }, 0] },
                then: "$activeEntitlements",
                else: "$planpurchasesData"
              }
            },
            createdAt: 1,
            updatedAt: 1
          }
        },
        { $sort: { createdAt: -1 } }
      ];

      const userData = await userModel.aggregate(aggregationPipeline);

      return { status: 200, message: "Staff assigned users", data: { totalCount, userData } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  getUserAssignedRM: async ({ userId }) => {
    try {
      console.log('getUserAssignedRM called with userId:', userId, 'type:', typeof userId);

      // Helper to fetch the configured default RM from admin settings
      const getDefaultRMResponse = async () => {
        try {
          const defaultRmSetting = await generalSettingsModel.findOne({ key: 'default_rm' });
          let defaultRm = defaultRmSetting?.value;

          if (!defaultRm || (!defaultRm.fullName && !defaultRm.staffId)) {
            defaultRm = {
              fullName: 'Jaya Verma',
              mobileNumber: '+91 9755016839',
              emailAddress: 'info@researchvia.in',
              department: 'Relationship Manager',
              staffId: ''
            };
          } else if (defaultRm.staffId) {
            try {
              const query = mongoose.Types.ObjectId.isValid(defaultRm.staffId)
                ? { $or: [{ _id: defaultRm.staffId }, { staffId: defaultRm.staffId }] }
                : { staffId: defaultRm.staffId };
              const freshStaff = await staffModel.findOne(query).lean();
              if (freshStaff && freshStaff.status?.toLowerCase() === 'active') {
                defaultRm = {
                  id: freshStaff._id,
                  fullName: freshStaff.fullName || freshStaff.name || defaultRm.fullName,
                  mobileNumber: freshStaff.mobileNumber || freshStaff.mobile || defaultRm.mobileNumber,
                  emailAddress: freshStaff.emailAddress || freshStaff.email || defaultRm.emailAddress,
                  department: freshStaff.deparment || freshStaff.department || defaultRm.department || 'Relationship Manager',
                  staffId: freshStaff.staffId,
                };
              }
            } catch (_) {}
          }

          return {
            status: 200,
            message: "Default RM details fetched successfully",
            data: {
              rm: {
                id: defaultRm.id || defaultRm.staffId || 'default_rm',
                fullName: defaultRm.fullName || 'Relationship Manager',
                mobileNumber: defaultRm.mobileNumber || '+91 9755016839',
                emailAddress: defaultRm.emailAddress || 'info@researchvia.in',
                department: defaultRm.department || 'Relationship Manager',
                staffId: defaultRm.staffId || '',
                isDefault: true
              }
            }
          };
        } catch (e) {
          console.error('Error fetching default RM setting:', e);
          return { status: 200, message: "No RM assigned", data: { rm: null } };
        }
      };

      // Safely cast to mongoose ObjectId — handles both string and ObjectId inputs
      let userObjectId;
      try {
        userObjectId = new mongoose.Types.ObjectId(userId.toString());
      } catch (castErr) {
        console.error('Invalid userId format:', userId, castErr.message);
        return await getDefaultRMResponse();
      }

      // Find the staff assignment for this user using the properly cast ObjectId
      const assignment = await staffAssigmentModel.findOne({ userId: userObjectId });
      console.log('Assignment found for userId', userId, ':', assignment ? `staffId=${assignment.staffId}, staffName=${assignment.staffName}` : 'NONE');

      if (!assignment) {
        console.log('No assignment found for userId:', userId.toString(), '— returning default RM');
        return await getDefaultRMResponse();
      }

      // Get full staff details using the assignment's staffId
      const staff = await staffModel.findById(assignment.staffId);
      console.log('Staff record found:', staff ? `${staff.fullName} (status=${staff.status})` : 'NONE');

      if (!staff) {
        console.log('Staff record missing for staffId:', assignment.staffId, '— returning default RM');
        return await getDefaultRMResponse();
      }

      // Check if the assigned staff is still active
      const staffStatus = staff.status ? staff.status.toLowerCase() : 'active';

      if (staffStatus === 'inactive' || staffStatus === 'deactivated') {
        console.log(`Staff ${staff.fullName} is ${staff.status} — returning default RM`);
        return await getDefaultRMResponse();
      }

      console.log(`Returning assigned RM: ${staff.fullName} (${staff.mobileNumber})`);
      return {
        status: 200,
        message: "RM details fetched successfully",
        data: {
          rm: {
            id: staff._id,
            fullName: staff.fullName,
            mobileNumber: staff.mobileNumber,
            emailAddress: staff.emailAddress,
            department: staff.deparment,
            staffId: staff.staffId,
            isDefault: false
          }
        }
      };
    } catch (error) {
      console.error('Error in getUserAssignedRM:', error);
      return { status: 400, message: error.message, data: {} };
    }
  },

  getPublicStaffVerification: async (staffId) => {
    try {
      let query = {};
      if (mongoose.Types.ObjectId.isValid(staffId)) {
        query = { $or: [{ _id: staffId }, { staffId: staffId }] };
      } else {
        query = { staffId: staffId };
      }

      const staff = await staffModel.findOne(query).select('fullName name staffId role deparment status photoUrl createdAt joiningDate onboardingStatus').lean();
      if (!staff) {
        return { status: 404, message: "Staff member not found or invalid ID", data: null };
      }

      return {
        status: 200,
        message: "Staff verification record found",
        data: {
          id: staff._id,
          staffId: staff.staffId,
          name: staff.fullName || staff.name,
          role: staff.role || staff.deparment,
          department: staff.deparment || staff.role,
          status: staff.status,
          photoUrl: staff.photoUrl,
          joiningDate: staff.joiningDate || staff.createdAt,
          verified: staff.status === 'Active',
          organization: 'SP ResearchVia Pvt. Ltd.',
          sebiReg: 'INH000015808 (SEBI Registered Research Analyst)',
          cin: 'U73200MP2023PTC069041',
          bseEnlistment: '6120',
          quickConnect: '+91 9755016839',
          address: '129 A, Kalani Bagh, AB Road, Dewas, MP - 455001',
        }
      };
    } catch (error) {
      return { status: 500, message: error.message, data: null };
    }
  },

  getStaffProfileMe: async ({ user }) => {
    try {
      const userId = user._id || user.userId;
      if (!userId) {
        return { status: 401, message: "User not authenticated", data: null };
      }

      let staff = await staffModel.findById(userId)
        .populate('departmentId')
        .populate({
          path: 'roleId',
          populate: [
            { path: 'permissionGroups' },
            { path: 'departmentId' }
          ]
        });

      if (staff) {
        staff = await populateStaffHierarchy(staff);
      }

      if (!staff) {
        // Fallback: check if admin in userModel
        const adminUser = await userModel.findById(userId);
        if (adminUser) {
          return {
            status: 200,
            message: "Admin profile retrieved",
            data: {
              _id: adminUser._id,
              staffId: "ADMIN-001",
              fullName: adminUser.fullName || adminUser.name || "Administrator",
              emailAddress: adminUser.emailAddress || adminUser.email || "",
              mobileNumber: adminUser.mobileNumber || adminUser.phone || "",
              deparment: "Administration",
              role: adminUser.userType || "Super Admin",
              stage: "Employee",
              status: "Active",
              photoUrl: adminUser.profileImage || null,
              joiningDate: adminUser.createdAt,
              isAdmin: true,
              permissions: ['*']
            }
          };
        }
        return { status: 404, message: "Profile not found", data: null };
      }

      const staffObj = staff.toObject ? staff.toObject() : staff;
      staffObj.serviceAgreementDocUrl = staffObj.agreementPdfUrl || `/api/staff/agreement/document/${staffObj._id}`;
      return {
        status: 200,
        message: "Staff profile retrieved successfully",
        data: staffObj
      };
    } catch (error) {
      return { status: 500, message: error.message, data: null };
    }
  },

  updateStaffProfileMe: async ({ user, body }) => {
    try {
      const userId = user._id || user.userId;
      if (!userId) {
        return { status: 401, message: "User not authenticated", data: null };
      }

      let staff = await staffModel.findById(userId);
      if (!staff) {
        const adminUser = await userModel.findById(userId);
        if (adminUser) {
          if (body.fullName) adminUser.fullName = body.fullName;
          if (body.emailAddress) adminUser.emailAddress = body.emailAddress;
          if (body.photoUrl !== undefined) adminUser.profileImage = body.photoUrl;
          await adminUser.save();
          return { status: 200, message: "Admin profile updated successfully", data: adminUser };
        }
        return { status: 404, message: "Staff record not found", data: null };
      }

      // Allow staff to update only personal/contact info (not role, department, salary, or stage)
      const allowedFields = [
        'fullName',
        'emailAddress',
        'mobileNumber',
        'localAddress',
        'currentAddress',
        'permanentAddress',
        'emergencyContact',
        'gender',
        'dob',
        'photoUrl',
        'walkInForm'
      ];

      allowedFields.forEach(field => {
        if (body[field] !== undefined) {
          staff[field] = body[field];
        }
      });
      if (body.walkInForm !== undefined) {
        staff.markModified('walkInForm');
      }
      if (body.localAddress && !body.currentAddress) {
        staff.currentAddress = body.localAddress;
      }

      await staff.save();

      const updated = await staffModel.findById(userId)
        .populate('departmentId')
        .populate({
          path: 'roleId',
          populate: {
            path: 'permissionGroups'
          }
        });

      return {
        status: 200,
        message: "Profile updated successfully",
        data: updated
      };
    } catch (error) {
      return { status: 500, message: error.message, data: null };
    }
  },

  changeStaffMpinMe: async ({ user, body }) => {
    try {
      const userId = user._id || user.userId;
      if (!userId) {
        return { status: 401, message: "User not authenticated", data: null };
      }

      const { oldMpin, newMpin } = body;
      if (!newMpin || newMpin.toString().trim().length < 4 || newMpin.toString().trim().length > 6) {
        return { status: 400, message: "New MPIN must be between 4 and 6 digits", data: null };
      }

      const staff = await staffModel.findById(userId).select('+mpin');
      if (!staff) {
        return { status: 404, message: "Staff member not found", data: null };
      }

      // If user already has an MPIN set, verify oldMpin
      if (staff.mpin && staff.mpin.trim().length > 0) {
        if (!oldMpin || oldMpin.toString().trim() !== staff.mpin.trim()) {
          return { status: 400, message: "Current MPIN is incorrect", data: null };
        }
      }

      staff.mpin = newMpin.toString().trim();
      await staff.save();

      return {
        status: 200,
        message: "MPIN changed successfully",
        data: { success: true }
      };
    } catch (error) {
      return { status: 500, message: error.message, data: null };
    }
  },

  logoutStaff: async ({ headers, user, token }) => {
    try {
      const rawHeader = headers?.authorization || headers?.Authorization;
      const rawToken = token || (rawHeader?.startsWith('Bearer ') ? rawHeader.substring(7) : rawHeader);

      if (rawToken) {
        try {
          const decoded = jwt.decode(rawToken);
          const expiresAt = decoded?.exp ? new Date(decoded.exp * 1000) : new Date(Date.now() + 8 * 3600 * 1000);
          await TokenBlacklist.findOneAndUpdate(
            { token: rawToken },
            {
              $setOnInsert: {
                token: rawToken,
                userId: user?._id?.toString() || null,
                userType: 'Staff',
                expiresAt,
                reason: 'STAFF_LOGOUT'
              }
            },
            { upsert: true }
          );
        } catch (tokErr) {
          console.error('[Staff Logout] Error blacklisting token:', tokErr.message);
        }
      }
      return { status: 200, message: "Staff logged out successfully", data: {} };
    } catch (error) {
      return { status: 500, message: error.message, data: {} };
    }
  },

  signAgreement: async ({ user, body, req }) => {
    try {
      const staffId = user?._id || user?.userId;
      if (!staffId) {
        return { status: 401, message: "Unauthorized. Staff context required.", data: {} };
      }

      const { signature, version } = body || {};
      if (!signature || !signature.toString().trim()) {
        return { status: 400, message: "Digital signature is required to sign the agreement.", data: {} };
      }

      const staff = await staffModel.findById(staffId);
      if (!staff) {
        return { status: 404, message: "Staff member not found.", data: {} };
      }

      const clientIp = req?.headers?.['x-forwarded-for']?.split(',')[0]?.trim() || req?.socket?.remoteAddress || req?.ip || 'N/A';

      staff.hasSignedAgreement = true;
      staff.agreementSignedAt = new Date();
      staff.agreementSignature = signature.toString().trim();
      staff.agreementIp = clientIp;
      staff.agreementVersion = version || '1.0';
      await staff.save();

      const updatedStaff = await staffModel.findById(staff._id)
        .populate('departmentId')
        .populate({
          path: 'roleId',
          populate: [
            { path: 'permissionGroups' },
            { path: 'departmentId' }
          ]
        });

      return {
        status: 200,
        message: "Job terms agreement signed successfully.",
        data: { staff: updatedStaff }
      };
    } catch (error) {
      return { status: 500, message: error.message, data: {} };
    }
  },

  /**
   * Generates a personalized Staff Joining Agreement PDF using the official
   * template and embedding the employee's name at verified coordinates.
   */
  generateStaffAgreementPdf: async (staff) => {
    const templatePath = path.join(__dirname, '../serviceAgreement/staff_disclaimer_terms_agreement.pdf');
    if (!fs.existsSync(templatePath)) {
      throw new Error(`Staff agreement template not found at: ${templatePath}`);
    }
    const templateBytes = fs.readFileSync(templatePath);
    const pdfDoc = await PDFDocument.load(templateBytes);

    const page1 = pdfDoc.getPage(0);
    const page11 = pdfDoc.getPage(10);

    const font = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
    const black = rgb(0, 0, 0);
    const employeeName = (staff.fullName || 'EMPLOYEE').toUpperCase().trim();

    // Page 1, Line 1: 'I, ______' blank line (verified alignment)
    page1.drawText(employeeName, {
      x: 86,
      y: 678,
      size: 11,
      font,
      color: black
    });

    // Page 1, Last line: 'Employee\'s Name & Signature ______.' (verified alignment)
    page1.drawText(employeeName, {
      x: 218,
      y: 245,
      size: 11,
      font,
      color: black
    });

    // Page 11: To the right of 'NAME' label (verified alignment)
    page11.drawText(employeeName, {
      x: 120,
      y: 221.9,
      size: 11,
      font,
      color: black
    });

    const safeName = employeeName.replace(/[^a-zA-Z0-9]/g, '_');
    const outputFilePath = path.join(__dirname, `../serviceAgreement/staff_agreement_${staff._id || safeName}.pdf`);
    const pdfBytes = await pdfDoc.save();
    fs.writeFileSync(outputFilePath, pdfBytes);

    return {
      outputFilePath,
      fileName: `SP_Staff_Agreement_${safeName}.pdf`,
      employeeName
    };
  },

  /**
   * Initiates Aadhaar E-Sign on Digio for the staff joining agreement.
   * Signature is placed on ALL pages at the default position.
   */
  initiateStaffDigioAgreement: async (staffIdOrUser, customRedirectUrl) => {
    try {
      const id = staffIdOrUser?._id || staffIdOrUser;
      const staff = await staffModel.findById(id);
      if (!staff) {
        return { status: 404, message: "Staff member not found", data: {} };
      }

      if (staff.hasSignedAgreement && staff.agreementStatus === 'VERIFIED') {
        return {
          status: 200,
          message: "Agreement already verified",
          data: { staff, isSigned: true, hasSignedAgreement: true }
        };
      }

      // Determine return redirect URL to bring staff back to webapp after signing
      let redirectUrl = customRedirectUrl;
      if (!redirectUrl) {
        const frontendBase = (process.env.FRONTEND_URL || "https://spadmin.researchvia.in").replace(/\/+$/, "");
        redirectUrl = `${frontendBase}/job-terms-agreement?signed=true`;
      }

      // Generate customized PDF with employee name on pages 1 & 11
      const { outputFilePath, fileName } = await staffService.generateStaffAgreementPdf(staff);

      const rawDigioBase = (process.env.DIGIO_API_BASE_URL || "https://api.digio.in").trim().replace(/\/+$/, "");
      const apiBaseUrl = rawDigioBase.includes("/v2/client/document/upload")
        ? rawDigioBase
        : `${rawDigioBase}/v2/client/document/upload`;
      const CLIENT_ID = (process.env.DIGIO_CLIENT_ID || "").trim();
      const CLIENT_SECRET = (process.env.DIGIO_CLIENT_SECRET_ID || "").trim();

      if (!CLIENT_ID || !CLIENT_SECRET) {
        return {
          status: 400,
          message: "Digio API credentials (DIGIO_CLIENT_ID / DIGIO_CLIENT_SECRET_ID) are missing or not configured on the server.",
          data: {}
        };
      }

      // Check if email has a valid deliverable / public domain (not a fake or test domain)
      const isPublicEmail = (email) => {
        if (!email || typeof email !== 'string') return false;
        const trimmed = email.trim().toLowerCase();
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) return false;
        const domain = trimmed.split('@')[1];
        const blockedDomains = ['test.com', 'example.com', 'sample.com', 'fake.com', 'dummy.com', 'invalid.com', 'test.in', 'localhost'];
        return !blockedDomains.includes(domain);
      };

      const cleanMobile = staff.mobileNumber ? String(staff.mobileNumber).replace(/\D/g, '').slice(-10) : null;
      let signerIdentifier = null;

      // Keep EMAIL PRIMARY, then MOBILE NUMBER SECONDARY
      if (staff.emailAddress && staff.emailAddress.trim().length > 0) {
        signerIdentifier = staff.emailAddress.trim();
      } else if (cleanMobile && cleanMobile.length === 10) {
        signerIdentifier = cleanMobile;
      }

      if (!signerIdentifier) {
        return { status: 400, message: "A valid 10-digit mobile number or email is required for Digio Aadhaar signing", data: {} };
      }

      const authHeader = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString("base64");
      const requestData = {
        signers: [
          {
            identifier: signerIdentifier,
            name: staff.fullName,
            sign_type: "Aadhaar",
            reason: "Staff Joining Agreement"
          }
        ],
        expire_in_days: 15,
        display_on_page: "ALL", // Aadhaar e-sign stamp on all pages at default position
        notify_signers: true,
        send_sign_link: true,
        file_name: fileName,
        will_self_sign: false,
        generate_access_token: true,
        redirect_url: redirectUrl
      };

      const formData = new FormData();
      formData.append("file", fs.createReadStream(outputFilePath), { filename: fileName });
      formData.append("request", JSON.stringify(requestData));

      console.log(`[Staff Digio] Uploading agreement to Digio for ${staff.fullName} (${signerIdentifier}), redirect_url: ${redirectUrl}...`);

      const response = await axios.post(apiBaseUrl, formData, {
        headers: {
          Authorization: `Basic ${authHeader}`,
          Accept: "application/json",
          ...formData.getHeaders(),
        },
        maxContentLength: Infinity,
        maxBodyLength: Infinity,
      });

      console.log("[Staff Digio] Upload successful, status:", response.status, "Doc ID:", response.data?.id);

      if (response.status >= 200 && response.status < 300) {
        const docId = response.data.id || response.data.document_id;
        const accessToken = response.data.access_token?.id || null;

        staff.digioDocId = docId;
        staff.digioObject = response.data;
        staff.digioStatus = 'pending';
        staff.agreementStatus = 'PENDING_SIGNATURE';
        staff.agreementPdfUrl = outputFilePath;
        await staff.save();

        const gatewayBase = apiBaseUrl.includes("ext.digio.in") ? "https://ext.digio.in" : "https://app.digio.in";
        const signingUrl = accessToken
          ? `${gatewayBase}/#/gateway/login/${docId}/${accessToken}/${encodeURIComponent(signerIdentifier)}?redirect_url=${encodeURIComponent(redirectUrl)}`
          : `${gatewayBase}/#/gateway/login/${docId}/null/${encodeURIComponent(signerIdentifier)}?redirect_url=${encodeURIComponent(redirectUrl)}`;

        // Send branded ResearchVia email with signing link and PDF attachment
        if (staff.emailAddress && isPublicEmail(staff.emailAddress)) {
          try {
            await emailService.sendEmail({
              to: staff.emailAddress,
              subject: "Action Required: Sign Your ResearchVia Employment Agreement",
              htmlContent: `
                <h2>Welcome to the Team, ${staff.fullName}!</h2>
                <p>Your employment joining agreement is prepared and ready for Aadhaar E-Sign.</p>
                <p>Please review and sign your agreement by clicking the button below:</p>
                <p><a href="${signingUrl}" class="button" style="display:inline-block;padding:12px 24px;background-color:#163174;color:#ffffff;text-decoration:none;border-radius:6px;font-weight:bold;">Sign Employment Agreement</a></p>
                <p>Or open this link directly in your browser: <br/><a href="${signingUrl}">${signingUrl}</a></p>
                <p><strong>Important Note:</strong> You will need your Aadhaar-linked mobile number to complete OTP verification on Digio.</p>
                <p>After you complete e-signing, the HR and Compliance team will verify your agreement to fully activate your workspace.</p>
                <br/>
                <p>Best regards,<br/>HR & Compliance Team<br/>ResearchVia</p>
              `,
              attachments: fs.existsSync(outputFilePath) ? [{
                filename: fileName,
                path: outputFilePath
              }] : []
            });
            console.log(`[Staff Digio Email] Branded agreement email sent to ${staff.emailAddress}`);
          } catch (mailErr) {
            console.warn("[Staff Digio Email Error]:", mailErr.message);
          }
        }

        return {
          status: 200,
          message: "Staff agreement initialized on Digio successfully and email dispatched",
          data: {
            docId,
            tokenId: accessToken,
            signingUrl,
            digio: response.data,
            staff
          }
        };
      } else {
        return {
          status: 400,
          message: "Digio document initialization failed",
          data: { digio: response.data }
        };
      }
    } catch (error) {
      console.error("[Staff Digio Error]:", error.response?.data || error.message);
      return {
        status: 500,
        message: error.response?.data?.message || error.message,
        data: { error: error.response?.data || error.message }
      };
    }
  },

  /**
   * Checks current agreement status for a staff member and syncs with Digio if pending.
   */
  getStaffAgreementStatus: async (staffIdOrUser, customRedirectUrl) => {
    try {
      const id = staffIdOrUser?._id || staffIdOrUser;
      const staff = await staffModel.findById(id);
      if (!staff) {
        return { status: 404, message: "Staff member not found", data: {} };
      }

      // If document is pending on Digio, query Digio directly to sync
      if (staff.digioDocId && !staff.hasSignedAgreement) {
        try {
          const CLIENT_ID = process.env.DIGIO_CLIENT_ID;
          const CLIENT_SECRET = process.env.DIGIO_CLIENT_SECRET_ID;
          const authHeader = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString("base64");
          const checkUrl = `https://api.digio.in/v2/client/document/${staff.digioDocId}`;
          const res = await axios.get(checkUrl, {
            headers: { Authorization: `Basic ${authHeader}` }
          });
          if (res.data) {
            const agreementStatus = (res.data.agreement_status || res.data.status || '').toLowerCase();
            if (agreementStatus.includes('signed') || agreementStatus === 'completed') {
              staff.hasSignedAgreement = true;
              staff.agreementSignedAt = new Date();
              staff.agreementSignature = 'Digio Aadhaar E-Sign';
              staff.digioStatus = 'verified';
              if (!staff.agreementStatus || staff.agreementStatus === 'PENDING_SIGNATURE') {
                staff.agreementStatus = 'PENDING_ADMIN_VERIFICATION';
              }
              staff.digioObject = res.data;
              await staff.save();
            }
          }
        } catch (syncErr) {
          console.warn("[Staff Digio Status Sync] Warning:", syncErr.message);
        }
      }

      let redirectUrl = customRedirectUrl;
      if (!redirectUrl) {
        const frontendBase = (process.env.FRONTEND_URL || "https://spadmin.researchvia.in").replace(/\/+$/, "");
        redirectUrl = `${frontendBase}/job-terms-agreement?signed=true`;
      }

      const cleanMobile = staff.mobileNumber ? String(staff.mobileNumber).replace(/\D/g, '').slice(-10) : '';
      const signerIdentifier = (staff.emailAddress && staff.emailAddress.trim().length > 0)
        ? staff.emailAddress.trim()
        : cleanMobile;
      const accessToken = staff.digioObject?.access_token?.id || null;
      const signingUrl = staff.digioDocId
        ? `https://app.digio.in/#/gateway/login/${staff.digioDocId}/${accessToken}/${encodeURIComponent(signerIdentifier)}?redirect_url=${encodeURIComponent(redirectUrl)}`
        : null;

      return {
        status: 200,
        message: "Staff agreement status fetched successfully",
        data: {
          hasSignedAgreement: staff.hasSignedAgreement,
          agreementStatus: staff.agreementStatus || (staff.hasSignedAgreement ? 'VERIFIED' : 'PENDING_SIGNATURE'),
          agreementSignedAt: staff.agreementSignedAt,
          agreementRejectionReason: staff.agreementRejectionReason,
          digioStatus: staff.digioStatus,
          digioDocId: staff.digioDocId,
          signingUrl,
          staff
        }
      };
    } catch (error) {
      return { status: 500, message: error.message, data: {} };
    }
  },

  /**
   * Admin verifies the signed employment agreement
   */
  verifyStaffAgreement: async (staffId, adminUser) => {
    try {
      const staff = await staffModel.findById(staffId);
      if (!staff) {
        return { status: 404, message: "Staff member not found", data: {} };
      }

      const updatedStaff = await staffModel.findByIdAndUpdate(
        staffId,
        {
          $set: {
            agreementStatus: 'VERIFIED',
            hasSignedAgreement: true,
            agreementVerifiedAt: new Date(),
            agreementVerifiedBy: adminUser?._id || null,
            agreementRejectionReason: null
          }
        },
        { new: true }
      );

      // Send email notification to employee confirming verification
      if (staff.emailAddress) {
        try {
          await emailService.sendEmail({
            to: staff.emailAddress,
            subject: "ResearchVia: Employment Agreement Verified & Approved",
            htmlContent: `
              <h2>Congratulations, ${staff.fullName}!</h2>
              <p>Your employment agreement has been reviewed, verified, and approved by the Administration.</p>
              <p>Your employee workspace and dashboard access are now fully activated.</p>
              <br/>
              <p>Welcome aboard!<br/>ResearchVia Team</p>
            `
          });
        } catch (mailErr) {
          console.warn("[Agreement Verify Email Error]:", mailErr.message);
        }
      }

      return {
        status: 200,
        message: "Employment agreement verified successfully",
        data: { staff: updatedStaff }
      };
    } catch (error) {
      return { status: 500, message: error.message, data: {} };
    }
  },

  /**
   * Admin rejects the signed employment agreement with mandatory reason
   */
  rejectStaffAgreement: async (staffId, adminUser, reason) => {
    try {
      if (!reason || reason.trim().length < 3) {
        return { status: 400, message: "A valid rejection reason is required", data: {} };
      }

      const staff = await staffModel.findById(staffId);
      if (!staff) {
        return { status: 404, message: "Staff member not found", data: {} };
      }

      const updatedStaff = await staffModel.findByIdAndUpdate(
        staffId,
        {
          $set: {
            agreementStatus: 'REJECTED',
            hasSignedAgreement: false,
            agreementRejectionReason: reason.trim(),
            agreementRejectedAt: new Date()
          }
        },
        { new: true }
      );

      // Send rejection notification email to employee
      if (staff.emailAddress) {
        try {
          await emailService.sendEmail({
            to: staff.emailAddress,
            subject: "Action Required: Employment Agreement Needs Revision",
            htmlContent: `
              <h2>Notice Regarding Your Employment Agreement</h2>
              <p>Hello ${staff.fullName},</p>
              <p>Your submitted employment agreement was reviewed by the Administration and could not be verified.</p>
              <div style="background-color: #fef2f2; border-left: 4px solid #ef4444; padding: 12px; margin: 16px 0;">
                <p style="margin: 0; color: #991b1b; font-weight: bold;">Reason for Rejection:</p>
                <p style="margin: 4px 0 0 0; color: #7f1d1d;">${reason.trim()}</p>
              </div>
              <p>Please log in to your employee portal, review and correct the required details, and e-sign the updated agreement.</p>
              <br/>
              <p>Regards,<br/>HR & Compliance Team<br/>ResearchVia</p>
            `
          });
        } catch (mailErr) {
          console.warn("[Agreement Reject Email Error]:", mailErr.message);
        }
      }

      return {
        status: 200,
        message: "Employment agreement rejected. Employee notified to update and re-sign.",
        data: { staff: updatedStaff }
      };
    } catch (error) {
      return { status: 500, message: error.message, data: {} };
    }
  },

  /**
   * Streams or downloads the agreement PDF for preview
   */
  downloadStaffAgreementDocument: async (staffId) => {
    try {
      const staff = await staffModel.findById(staffId);
      if (!staff) {
        return { status: 404, message: "Staff member not found" };
      }

      if (staff.digioDocId) {
        const digioDoc = await userKycService.downloadDigioDocument(staff.digioDocId);
        if (digioDoc.status === 200 && digioDoc.data) {
          return { status: 200, data: digioDoc.data, contentType: 'application/pdf', filename: `Agreement_${staff.staffId || staffId}.pdf` };
        }
      }

      if (staff.agreementPdfUrl && fs.existsSync(staff.agreementPdfUrl)) {
        const fileBytes = fs.readFileSync(staff.agreementPdfUrl);
        return { status: 200, data: fileBytes, contentType: 'application/pdf', filename: `Agreement_${staff.staffId || staffId}.pdf` };
      }

      // Generate on the fly if not exists
      const { outputFilePath, fileName } = await staffService.generateStaffAgreementPdf(staff);
      const fileBytes = fs.readFileSync(outputFilePath);
      return { status: 200, data: fileBytes, contentType: 'application/pdf', filename: fileName };
    } catch (error) {
      return { status: 500, message: error.message };
    }
  }

}
export default staffService;