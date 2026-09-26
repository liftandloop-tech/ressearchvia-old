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

const staffService = {
  staffCreate: async ({ body, user }) => {
    try {
      console.log('staffCreate body:', body);
      if (user && (user.userType === 'Director' || user.deparment === 'Director')) {
        body.assignedDirector = user._id;
        body.assignedDirectorName = user.fullName;
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
      const username = process.env.SMS_SHORT_SERVICE_USER;;
      const apikey = process.env.SMS_SHORT_SERVICE_API_KEY;
      const sender = process.env.SMS_SHORT_SERVICE_SENDER;
      const templateID = process.env.SMS_SHORT_SERVICE_TEMPLATEID;
      const url = process.env.SMS_SHORT_SERVICE_URL
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

      // Check for allowed staff roles
      const allowedRoles = [
        'director', 'researcher', 'research analyst', 'executive', 'manager', 
        'advisory', 'compliance', 'sales', 'support', 'admin', 'quality & development', 
        'quality', 'hr', 'human resources', 'back office', 'management', 'administration'
      ];
      const deptLower = (staff.deparment || '').toLowerCase();
      const roleLower = (staff.role || '').toLowerCase();
      const isAllowed = Boolean(staff.roleId) || allowedRoles.some(r => deptLower.includes(r) || roleLower.includes(r));
      if (!isAllowed) {
        return { status: 200, message: "Access denied. Role not permitted to log in.", data: {} }
      }
      const defaultTemplate = "Your OTP for ResearchVia App is {OTP}\n\n\n\nPlease do not share OTP with anyone.\n\nhttps://researchvia.in\n\n";
      const messageText = defaultTemplate.replaceAll('{OTP}', otp);
      const message = encodeURIComponent(messageText);
      const smsUrl = `${url}username=${username}&apikey=${apikey}&apirequest=Text&sender=${sender}&mobile=${phone}&message=${message}sms&route=TRANS&TemplateID=${templateID}&format=JSON`;
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
      let { otp } = body
      let staff = await staffModel.findOne({ otp: otp })
      if (!staff) {
        return { status: 200, message: "staff not exist", data: {} }
      }
      if (staff.otp !== otp || staff.otpExpires < Date.now()) {
        return { status: 200, message: "OTP Invalid", data: {} }
      }

      // Check for allowed staff roles
      const allowedRoles = [
        'director', 'researcher', 'research analyst', 'executive', 'manager', 
        'advisory', 'compliance', 'sales', 'support', 'admin', 'quality & development', 
        'quality', 'hr', 'human resources', 'back office', 'management', 'administration'
      ];
      const deptLower = (staff.deparment || '').toLowerCase();
      const roleLower = (staff.role || '').toLowerCase();
      const isAllowed = Boolean(staff.roleId) || allowedRoles.some(r => deptLower.includes(r) || roleLower.includes(r));
      if (!isAllowed) {
        return { status: 200, message: "Access denied. Role not permitted to log in.", data: {} }
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
        process.env.JWT_TOKEN
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
      });

      if (!staff) {
        return { status: 200, message: "Staff not found", data: {} }
      }

      // Check for allowed staff roles
      const allowedRoles = [
        'director', 'researcher', 'research analyst', 'executive', 'manager', 
        'advisory', 'compliance', 'sales', 'support', 'admin', 'quality & development', 
        'quality', 'hr', 'human resources', 'back office', 'management', 'administration'
      ];
      const deptLower = (staff.deparment || '').toLowerCase();
      const roleLower = (staff.role || '').toLowerCase();
      const isAllowed = Boolean(staff.roleId) || allowedRoles.some(r => deptLower.includes(r) || roleLower.includes(r));
      if (!isAllowed) {
        return { status: 200, message: "Access denied. Role not permitted to log in.", data: {} }
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
        process.env.JWT_TOKEN
      );
      return { status: 200, message: "Login successfully", data: { token, staff } }
    } catch (error) {
      return { status: 400, message: error.message, data: {} }
    }
  },
  staffImpersonate: async ({ body, user }) => {
    try {
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
        populate: {
          path: 'permissionGroups'
        }
      });

      if (!staff) {
        return { status: 404, message: "Staff member not found", data: {} };
      }

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

      // Director Check: Only allow editing managers from their own team
      if (user && (user.userType === 'Director' || user.deparment === 'Director')) {
        const isOwnManager = staff.assignedDirector && staff.assignedDirector.toString() === user._id.toString();
        if (!isOwnManager) {
          return { status: 403, message: "Access Denied. You can only manage staff from your own team.", data: {} };
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
        staff.assignedDirector = (body.assignedDirector && body.assignedDirector !== 'unassigned' && body.assignedDirector !== 'admin') ? body.assignedDirector : null;
      }
      if (body.assignedDirectorName !== undefined) {
        staff.assignedDirectorName = (body.assignedDirector && body.assignedDirector !== 'unassigned' && body.assignedDirector !== 'admin') ? body.assignedDirectorName : (body.assignedDirector === 'admin' || body.assignedDirectorName === 'Admin' ? 'Admin' : null);
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

      // Director Check: Only allow deleting managers from their own team
      if (user && (user.userType === 'Director' || user.deparment === 'Director')) {
        const isOwnManager = staff.assignedDirector && staff.assignedDirector.toString() === user._id.toString();
        if (!isOwnManager) {
          return { status: 403, message: "Access Denied. You can only remove staff from your own team.", data: {} };
        }
      }

      await staffModel.findByIdAndDelete(id)
      return { status: 200, message: "staff cancle", data: {} }
    } catch (error) {
      return { status: 400, message: error.message, data: {} }
    }
  },
  staffList: async ({ user }) => {
    try {
      let query = {
        $or: [
          { stage: { $ne: 'Applicant' } },
          { roleId: { $ne: null } }
        ]
      };

      console.log('=== staffList called ===');
      console.log('User:', user ? { userType: user.userType, deparment: user.deparment, _id: user._id } : 'No user');

      const callerId = user?._id || user?.userId;
      let isSystemAdmin = false;
      let hasStaffViewAll = false;

      if (callerId) {
        const hierarchy = await getSupervisedStaffIds(callerId);
        isSystemAdmin = hierarchy.isSystemAdmin;

        if (hierarchy.staffMember?.roleId?.permissionGroups) {
          hasStaffViewAll = hierarchy.staffMember.roleId.permissionGroups.some(g =>
            g.permissions?.some(p => p.actions?.includes('staff.view'))
          );
        }

        if (!isSystemAdmin && !hasStaffViewAll) {
          query = {
            $or: [
              { stage: { $ne: 'Applicant' } },
              { roleId: { $ne: null } }
            ],
            _id: { $in: hierarchy.staffIds }
          };
          console.log(`Staff list scoped for ${hierarchy.staffMember?.fullName} (${hierarchy.staffIds.length} staff):`, JSON.stringify(query));
        } else {
          console.log('Admin / staff.view query (all staff):', JSON.stringify(query));
        }
      }

      const staffList = await staffModel.find(query)
        .populate({
          path: 'roleId',
          populate: [
            { path: 'permissionGroups', populate: { path: 'departmentId' } },
            { path: 'departmentId' }
          ]
        })
        .populate('departmentId')
        .lean();
      console.log(`Found ${staffList.length} staff members`);
      console.log('Staff departments:', staffList.map(s => ({ name: s.fullName, dept: s.deparment })));

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

        // Director Check: Only allow assigning managers from their own team
        if (requestingUser && (requestingUser.userType === 'Director' || requestingUser.deparment === 'Director')) {
          const isOwnManager = assignmentData.assignedDirector && assignmentData.assignedDirector.toString() === requestingUser._id.toString();
          if (!isOwnManager) {
            return { status: 403, message: "Access Denied. You can only assign managers from your own team.", data: {} };
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

      // Get all user IDs assigned to this staff (or team)
      const assignments = await staffAssigmentModel.find({ staffId: { $in: targetStaffIds } });
      const assignedUserIds = assignments.map(a => a.userId);

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
          populate: {
            path: 'permissionGroups'
          }
        });

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

      return {
        status: 200,
        message: "Staff profile retrieved successfully",
        data: staff
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

      const staff = await staffModel.findById(userId);
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
  }

}
export default staffService;