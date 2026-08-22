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

      if (!body.roleId && body.deparment) {
        const trimmedDept = body.deparment.trim();
        const matchingRole = await roleModel.findOne({ name: { $regex: new RegExp(`^\\s*${trimmedDept}\\s*$`, 'i') } });
        if (matchingRole) {
          body.roleId = matchingRole._id;
          console.log(`Automatically assigned roleId ${matchingRole._id} (${matchingRole.name}) for new staff with department ${trimmedDept}`);
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
      const allowedRoles = ['Director', 'Researcher', 'Research Analyst', 'Executive', 'Manager', 'Advisory', 'Compliance', 'Sales', 'Support', 'Admin'];
      const deptLower = (staff.deparment || '').toLowerCase();
      const isAllowed = allowedRoles.some(r => r.toLowerCase() === deptLower || deptLower.includes(r.toLowerCase()));
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
      const allowedRoles = ['Director', 'Researcher', 'Research Analyst', 'Executive', 'Manager', 'Advisory', 'Compliance', 'Sales', 'Support', 'Admin'];
      const deptLower = (staff.deparment || '').toLowerCase();
      const isAllowed = allowedRoles.some(r => r.toLowerCase() === deptLower || deptLower.includes(r.toLowerCase()));
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
      staff = await staffModel.findById(staff._id).populate({
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
      const allowedRoles = ['Director', 'Researcher', 'Research Analyst', 'Executive', 'Manager', 'Advisory', 'Compliance', 'Sales', 'Support', 'Admin'];
      const deptLower = (staff.deparment || '').toLowerCase();
      const isAllowed = allowedRoles.some(r => r.toLowerCase() === deptLower || deptLower.includes(r.toLowerCase()));
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
      staff = await staffModel.findById(staff._id).populate({
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
  staffReset: async ({ query, body, user }) => {
    try {
      console.log('staffReset query:', query);
      console.log('staffReset body:', body);
      let { id } = query
      let { fullName, mobileNumber, emailAddress, deparment, designation, role, roleId } = body
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
      if (deparment) {
        const trimmedDept = deparment.trim();
        staff.deparment = trimmedDept;
        
        // Find matching role in database and update roleId
        const matchingRole = await roleModel.findOne({ name: { $regex: new RegExp(`^\\s*${trimmedDept}\\s*$`, 'i') } });
        if (matchingRole) {
          staff.roleId = matchingRole._id;
          console.log(`Automatically updated roleId to ${matchingRole._id} (${matchingRole.name}) for department ${trimmedDept}`);
        } else {
          console.log(`No matching role found in database for department "${trimmedDept}"`);
        }
      }
      if (designation) staff.designation = designation;

      if (body.gender) staff.gender = body.gender;
      if (body.dob) staff.dob = new Date(body.dob);
      if (body.experienceYears !== undefined) staff.experienceYears = Number(body.experienceYears);
      if (body.previousCompany) staff.previousCompany = body.previousCompany;
      if (body.lastCtc) staff.lastCtc = body.lastCtc;
      if (body.localAddress) staff.localAddress = body.localAddress;
      if (body.permanentAddress) staff.permanentAddress = body.permanentAddress;

      if (body.assignedDirector) {
        staff.assignedDirector = body.assignedDirector;
      }
      if (body.assignedDirectorName) {
        staff.assignedDirectorName = body.assignedDirectorName;
      }

      if (body.mpin) {
        staff.mpin = body.mpin.toString();
      }

      if (body.status) {
        staff.status = body.status;
      }

      if (roleId !== undefined) {
        staff.roleId = roleId || null;
      }

      console.log('body.isViewOnly value:', body.isViewOnly, 'type:', typeof body.isViewOnly);
      if (body.isViewOnly !== undefined) {
        staff.isViewOnly = (body.isViewOnly === true || body.isViewOnly === 'true' || body.isViewOnly === 1);
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
      let query = { stage: { $ne: 'Applicant' } };

      console.log('=== staffList called ===');
      console.log('User:', user ? { userType: user.userType, deparment: user.deparment, _id: user._id } : 'No user');

      // If user is a Director, they can only see managers assigned to them (and themselves)
      if (user && (user.userType === 'Director' || user.deparment === 'Director')) {
        query = {
          stage: { $ne: 'Applicant' },
          $or: [
            { assignedDirector: user._id },
            { _id: user._id }
          ]
        };
        console.log('Director query:', JSON.stringify(query));
      } else {
        console.log('Admin/Other query (all staff):', JSON.stringify(query));
      }

      const staffList = await staffModel.find(query).lean()
      console.log(`Found ${staffList.length} staff members`);
      console.log('Staff departments:', staffList.map(s => ({ name: s.fullName, dept: s.deparment })));

      return { status: 200, message: "staff list", data: { staffList } }
    } catch (error) {
      return { status: 400, message: error.message, data: {} }
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
      let { page, pageSize, search } = query;
      page = page ? parseInt(page) : 1;
      pageSize = pageSize ? parseInt(pageSize) : 10;

      let targetStaffIds = [staffId];

      // Check if the staff member is a Director
      const staffMember = await staffModel.findById(staffId);

      if (staffMember && staffMember.deparment === 'Director') {
        // Find all managers assigned to this director
        const managers = await staffModel.find({ assignedDirector: staffId }).select('_id');
        const managerIds = managers.map(m => m._id.toString());
        targetStaffIds = [...targetStaffIds, ...managerIds];
      }

      // Get all user IDs assigned to this staff (or team)
      const assignments = await staffAssigmentModel.find({ staffId: { $in: targetStaffIds } });
      const assignedUserIds = assignments.map(a => a.userId);

      if (assignedUserIds.length === 0) {
        return { status: 200, message: "No users assigned", data: { totalCount: 0, userData: [] } };
      }

      const aggregationPipeline = [
        {
          $match: {
            _id: { $in: assignedUserIds },
            userType: { $ne: "admin" }
          }
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

      if (search) {
        aggregationPipeline.push({
          $match: {
            $or: [
              { fullName: { $regex: search, $options: "i" } },
              { phone: { $regex: search, $options: "i" } },
              { email: { $regex: search, $options: "i" } }
            ]
          }
        });
      }

      const countPipeline = [...aggregationPipeline, { $group: { _id: null, count: { $sum: 1 } } }];
      const countResult = await userModel.aggregate(countPipeline);
      const totalCount = countResult.length > 0 ? countResult[0].count : 0;

      aggregationPipeline.push(
        { $skip: (page - 1) * pageSize },
        { $limit: pageSize }
      );

      const userData = await userModel.aggregate(aggregationPipeline);

      return { status: 200, message: "Staff assigned users", data: { totalCount, userData } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  getUserAssignedRM: async ({ userId }) => {
    try {
      console.log('getUserAssignedRM called with userId:', userId, 'type:', typeof userId);

      // Safely cast to mongoose ObjectId — handles both string and ObjectId inputs
      let userObjectId;
      try {
        userObjectId = new mongoose.Types.ObjectId(userId.toString());
      } catch (castErr) {
        console.error('Invalid userId format:', userId, castErr.message);
        return { status: 200, message: "No RM assigned", data: { rm: null } };
      }

      // Find the staff assignment for this user using the properly cast ObjectId
      const assignment = await staffAssigmentModel.findOne({ userId: userObjectId });
      console.log('Assignment found for userId', userId, ':', assignment ? `staffId=${assignment.staffId}, staffName=${assignment.staffName}` : 'NONE');

      if (!assignment) {
        console.log('No assignment found for userId:', userId.toString());
        return { status: 200, message: "No RM assigned", data: { rm: null } };
      }

      // Get full staff details using the assignment's staffId
      const staff = await staffModel.findById(assignment.staffId);
      console.log('Staff record found:', staff ? `${staff.fullName} (status=${staff.status})` : 'NONE');

      if (!staff) {
        console.log('Staff record missing for staffId:', assignment.staffId);
        return { status: 200, message: "RM not found", data: { rm: null } };
      }

      // Check if the assigned staff is still active
      const staffStatus = staff.status ? staff.status.toLowerCase() : 'active';

      if (staffStatus === 'inactive' || staffStatus === 'deactivated') {
        console.log(`Staff ${staff.fullName} is ${staff.status} — returning null RM (will fall back to default)`);
        return { status: 200, message: "RM is inactive", data: { rm: null } };
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
            staffId: staff.staffId
          }
        }
      };
    } catch (error) {
      console.error('Error in getUserAssignedRM:', error);
      return { status: 400, message: error.message, data: {} };
    }
  }

}
export default staffService;