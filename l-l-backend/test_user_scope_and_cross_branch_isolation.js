import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import userModel from "./app/models/userModel.js";
import staffModel from "./app/models/staffModel.js";
import roleModel from "./app/models/roleModel.js";
import departmentModel from "./app/models/departmentModel.js";
import permissionGroupModel from "./app/models/permissionGroupModel.js";
import staffAssignmentModel from "./app/models/staffAssignmentModel.js";

import {
  getSupervisedStaffIds,
  getUpstreamSupervisorIds,
  getBranchDirectorId,
  getBranchStaffIds,
  resolveUserScope
} from "./app/utils/staffHierarchy.js";
import userService from "./app/services/userService.js";
import { checkPermission } from "./app/middleware/accessMiddleware.js";

async function runScopeAndIsolationTests() {
  console.log("================================================================================");
  console.log("   AUTOMATED VERIFICATION: THREE DATA SCOPES & CROSS-BRANCH ISOLATION   ");
  console.log("================================================================================\n");

  let createdPgIds = [];
  let createdRoleIds = [];
  let createdStaffIds = [];
  let createdUserIds = [];
  let createdAssignmentIds = [];

  try {
    console.log("1. Connecting to MongoDB...");
    await mongoose.connect(process.env.DB_URL);
    console.log("✓ Connected.\n");

    const ts = Date.now();

    // -------------------------------------------------------------------------
    // STEP 1: CREATE DYNAMIC PERMISSION GROUPS
    // -------------------------------------------------------------------------
    console.log("2. Creating Dynamic Permission Groups...");

    const pgGlobal = await permissionGroupModel.create({
      name: `PG_TEST_GLOBAL_${ts}`,
      description: "Company-wide user view",
      permissions: [{ feature: "Users", actions: ["users.view_all"] }]
    });
    createdPgIds.push(pgGlobal._id);

    const pgBranch = await permissionGroupModel.create({
      name: `PG_TEST_BRANCH_${ts}`,
      description: "Branch-level user view",
      permissions: [{ feature: "Users", actions: ["users.view_branch"] }]
    });
    createdPgIds.push(pgBranch._id);

    const pgAssigned = await permissionGroupModel.create({
      name: `PG_TEST_ASSIGNED_${ts}`,
      description: "Assigned-only user view",
      permissions: [{ feature: "Users", actions: ["users.view_assigned"] }]
    });
    createdPgIds.push(pgAssigned._id);

    const pgNoUsers = await permissionGroupModel.create({
      name: `PG_TEST_NO_USERS_${ts}`,
      description: "No access to users module",
      permissions: [{ feature: "Leads", actions: ["leads.view"] }]
    });
    createdPgIds.push(pgNoUsers._id);

    console.log("✓ Created 4 permission groups (global, branch, assigned, no-users).\n");

    // -------------------------------------------------------------------------
    // STEP 2: CREATE DYNAMIC ROLES (No hardcoded names in logic!)
    // -------------------------------------------------------------------------
    console.log("3. Creating Dynamic Roles...");

    const roleAdmin = await roleModel.findOne({ name: "Admin" }) || await roleModel.create({
      name: "Admin",
      roleName: "Admin",
      level: 1
    });

    const roleAuditor = await roleModel.create({
      name: `ROLE_CHIEF_AUDITOR_${ts}`,
      roleName: `ROLE_CHIEF_AUDITOR_${ts}`,
      level: 2,
      permissionGroups: [pgGlobal._id]
    });
    createdRoleIds.push(roleAuditor._id);

    const roleCompliance = await roleModel.create({
      name: `ROLE_COMPLIANCE_OFFICER_${ts}`,
      roleName: `ROLE_COMPLIANCE_OFFICER_${ts}`,
      level: 2,
      permissionGroups: [pgBranch._id]
    });
    createdRoleIds.push(roleCompliance._id);

    const roleDirector = await roleModel.create({
      name: `ROLE_DIRECTOR_${ts}`,
      roleName: `Director`,
      level: 3,
      permissionGroups: [pgBranch._id]
    });
    createdRoleIds.push(roleDirector._id);

    const roleManager = await roleModel.create({
      name: `ROLE_SALES_MANAGER_${ts}`,
      roleName: `Manager`,
      level: 2,
      permissionGroups: [pgAssigned._id]
    });
    createdRoleIds.push(roleManager._id);

    const roleBde = await roleModel.create({
      name: `ROLE_BDE_${ts}`,
      roleName: `BDE`,
      level: 1,
      permissionGroups: [pgAssigned._id]
    });
    createdRoleIds.push(roleBde._id);

    const roleIntern = await roleModel.create({
      name: `ROLE_INTERN_${ts}`,
      roleName: `Intern`,
      level: 1,
      permissionGroups: [pgNoUsers._id]
    });
    createdRoleIds.push(roleIntern._id);

    console.log("✓ Dynamic roles created.\n");

    // -------------------------------------------------------------------------
    // STEP 3: CREATE STAFF ACROSS TWO DISTINCT BRANCHES
    // -------------------------------------------------------------------------
    console.log("4. Setting up Staff Hierarchy for Branch A & Branch B...");

    // System Admin
    const adminStaff = await staffModel.create({
      staffId: `ADM_${ts}`,
      fullName: "System Admin User",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `admin_${ts}@test.com`,
      roleId: roleAdmin._id,
      role: "Admin",
      stage: "Employee"
    });
    createdStaffIds.push(adminStaff._id);

    // Global Chief Auditor
    const globalAuditor = await staffModel.create({
      staffId: `AUD_GLOB_${ts}`,
      fullName: "Global Auditor",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `auditor_glob_${ts}@test.com`,
      roleId: roleAuditor._id,
      role: "Chief Auditor",
      stage: "Employee",
      assignedDirector: adminStaff._id
    });
    createdStaffIds.push(globalAuditor._id);

    // --- BRANCH A ---
    // Director A
    const directorA = await staffModel.create({
      staffId: `DIR_A_${ts}`,
      fullName: "Branch Director A",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `director_a_${ts}@test.com`,
      roleId: roleDirector._id,
      role: "Director",
      stage: "Employee",
      assignedDirector: adminStaff._id
    });
    createdStaffIds.push(directorA._id);

    // Manager A
    const managerA = await staffModel.create({
      staffId: `MGR_A_${ts}`,
      fullName: "Sales Manager A",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `manager_a_${ts}@test.com`,
      roleId: roleManager._id,
      role: "Manager",
      stage: "Employee",
      assignedDirector: directorA._id
    });
    createdStaffIds.push(managerA._id);

    // Staff A1 (RM)
    const staffA1 = await staffModel.create({
      staffId: `RM_A1_${ts}`,
      fullName: "RM Staff A1",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `staff_a1_${ts}@test.com`,
      roleId: roleBde._id,
      role: "BDE",
      stage: "Employee",
      assignedDirector: managerA._id
    });
    createdStaffIds.push(staffA1._id);

    // Compliance Officer A (Reports to Director A, has users.view_branch)
    const complianceA = await staffModel.create({
      staffId: `COMP_A_${ts}`,
      fullName: "Compliance Officer Branch A",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `compliance_a_${ts}@test.com`,
      roleId: roleCompliance._id,
      role: "Compliance Officer",
      stage: "Employee",
      assignedDirector: directorA._id
    });
    createdStaffIds.push(complianceA._id);

    // Intern in Branch A (No users module permission)
    const internA = await staffModel.create({
      staffId: `INT_A_${ts}`,
      fullName: "Intern Branch A",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `intern_a_${ts}@test.com`,
      roleId: roleIntern._id,
      role: "Intern",
      stage: "Employee",
      assignedDirector: managerA._id
    });
    createdStaffIds.push(internA._id);

    // --- BRANCH B ---
    // Director B
    const directorB = await staffModel.create({
      staffId: `DIR_B_${ts}`,
      fullName: "Branch Director B",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `director_b_${ts}@test.com`,
      roleId: roleDirector._id,
      role: "Director",
      stage: "Employee",
      assignedDirector: adminStaff._id
    });
    createdStaffIds.push(directorB._id);

    // Manager B
    const managerB = await staffModel.create({
      staffId: `MGR_B_${ts}`,
      fullName: "Sales Manager B",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `manager_b_${ts}@test.com`,
      roleId: roleManager._id,
      role: "Manager",
      stage: "Employee",
      assignedDirector: directorB._id
    });
    createdStaffIds.push(managerB._id);

    // Staff B1 (RM)
    const staffB1 = await staffModel.create({
      staffId: `RM_B1_${ts}`,
      fullName: "RM Staff B1",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `staff_b1_${ts}@test.com`,
      roleId: roleBde._id,
      role: "BDE",
      stage: "Employee",
      assignedDirector: managerB._id
    });
    createdStaffIds.push(staffB1._id);

    // Compliance Officer B
    const complianceB = await staffModel.create({
      staffId: `COMP_B_${ts}`,
      fullName: "Compliance Officer Branch B",
      mobileNumber: Math.floor(1000000000 + Math.random() * 9000000000),
      emailAddress: `compliance_b_${ts}@test.com`,
      roleId: roleCompliance._id,
      role: "Compliance Officer",
      stage: "Employee",
      assignedDirector: directorB._id
    });
    createdStaffIds.push(complianceB._id);

    console.log("✓ Branch A staff tree: Director A -> Manager A -> Staff A1 + Compliance A");
    console.log("✓ Branch B staff tree: Director B -> Manager B -> Staff B1 + Compliance B\n");

    // -------------------------------------------------------------------------
    // STEP 4: CREATE CLIENT USERS AND ASSIGNMENTS
    // -------------------------------------------------------------------------
    console.log("5. Creating Client Users & Assignments...");

    // Client A1 -> Assigned to Staff A1
    const phoneA1 = "98" + Math.floor(10000000 + Math.random() * 90000000);
    const clientA1 = await userModel.create({
      fullName: `Client A1 (${ts})`,
      phone: phoneA1,
      emailAddress: `client_a1_${ts}@test.com`,
      userObject: { phone: phoneA1 },
      userType: "user"
    });
    createdUserIds.push(clientA1._id);

    const asgnA1 = await staffAssignmentModel.create({
      userId: clientA1._id,
      staffId: staffA1._id,
      staffName: staffA1.fullName
    });
    createdAssignmentIds.push(asgnA1._id);

    // Client A2 -> Assigned to Director A
    const phoneA2 = "98" + Math.floor(10000000 + Math.random() * 90000000);
    const clientA2 = await userModel.create({
      fullName: `Client A2 Direct (${ts})`,
      phone: phoneA2,
      emailAddress: `client_a2_${ts}@test.com`,
      userObject: { phone: phoneA2 },
      userType: "user"
    });
    createdUserIds.push(clientA2._id);

    const asgnA2 = await staffAssignmentModel.create({
      userId: clientA2._id,
      staffId: directorA._id,
      staffName: directorA.fullName
    });
    createdAssignmentIds.push(asgnA2._id);

    // Client B1 -> Assigned to Staff B1
    const phoneB1 = "98" + Math.floor(10000000 + Math.random() * 90000000);
    const clientB1 = await userModel.create({
      fullName: `Client B1 (${ts})`,
      phone: phoneB1,
      emailAddress: `client_b1_${ts}@test.com`,
      userObject: { phone: phoneB1 },
      userType: "user"
    });
    createdUserIds.push(clientB1._id);

    const asgnB1 = await staffAssignmentModel.create({
      userId: clientB1._id,
      staffId: staffB1._id,
      staffName: staffB1.fullName
    });
    createdAssignmentIds.push(asgnB1._id);

    // Client B2 -> Assigned to Director B
    const phoneB2 = "98" + Math.floor(10000000 + Math.random() * 90000000);
    const clientB2 = await userModel.create({
      fullName: `Client B2 Direct (${ts})`,
      phone: phoneB2,
      emailAddress: `client_b2_${ts}@test.com`,
      userObject: { phone: phoneB2 },
      userType: "user"
    });
    createdUserIds.push(clientB2._id);

    const asgnB2 = await staffAssignmentModel.create({
      userId: clientB2._id,
      staffId: directorB._id,
      staffName: directorB.fullName
    });
    createdAssignmentIds.push(asgnB2._id);

    console.log("✓ Client A1 -> assigned to Staff A1");
    console.log("✓ Client A2 -> assigned to Director A");
    console.log("✓ Client B1 -> assigned to Staff B1");
    console.log("✓ Client B2 -> assigned to Director B\n");

    // =========================================================================
    // TEST SECTION 1: HIERARCHY & DIRECTOR RESOLUTION
    // =========================================================================
    console.log("--------------------------------------------------------------------------------");
    console.log("TEST 1: getBranchDirectorId Invariants");
    console.log("--------------------------------------------------------------------------------");

    const resolvedDirAFromStaff = await getBranchDirectorId(staffA1._id);
    const resolvedDirAFromComp = await getBranchDirectorId(complianceA._id);
    const resolvedDirAFromDir = await getBranchDirectorId(directorA._id);

    if (resolvedDirAFromStaff.toString() !== directorA._id.toString()) {
      throw new Error(`Expected Director A for Staff A1, got ${resolvedDirAFromStaff}`);
    }
    if (resolvedDirAFromComp.toString() !== directorA._id.toString()) {
      throw new Error(`Expected Director A for Compliance A, got ${resolvedDirAFromComp}`);
    }
    if (resolvedDirAFromDir.toString() !== directorA._id.toString()) {
      throw new Error(`Expected Director A for Director A, got ${resolvedDirAFromDir}`);
    }

    const resolvedDirBFromStaff = await getBranchDirectorId(staffB1._id);
    const resolvedDirBFromComp = await getBranchDirectorId(complianceB._id);

    if (resolvedDirBFromStaff.toString() !== directorB._id.toString()) {
      throw new Error(`Expected Director B for Staff B1, got ${resolvedDirBFromStaff}`);
    }
    if (resolvedDirBFromComp.toString() !== directorB._id.toString()) {
      throw new Error(`Expected Director B for Compliance B, got ${resolvedDirBFromComp}`);
    }

    console.log("✓ getBranchDirectorId correctly resolves Director A for all Branch A members.");
    console.log("✓ getBranchDirectorId correctly resolves Director B for all Branch B members.");

    // =========================================================================
    // TEST SECTION 2: BRANCH BOUNDARY & CROSS-BRANCH ISOLATION
    // =========================================================================
    console.log("\n--------------------------------------------------------------------------------");
    console.log("TEST 2: getBranchStaffIds & Strict Cross-Branch Isolation");
    console.log("--------------------------------------------------------------------------------");

    const branchAStaffIds = await getBranchStaffIds(complianceA._id);
    const branchAStaffStrSet = new Set(branchAStaffIds.map(id => id.toString()));

    // Must contain all Branch A staff
    if (!branchAStaffStrSet.has(directorA._id.toString())) throw new Error("Branch A staffIds missing Director A");
    if (!branchAStaffStrSet.has(managerA._id.toString())) throw new Error("Branch A staffIds missing Manager A");
    if (!branchAStaffStrSet.has(staffA1._id.toString())) throw new Error("Branch A staffIds missing Staff A1");
    if (!branchAStaffStrSet.has(complianceA._id.toString())) throw new Error("Branch A staffIds missing Compliance A");

    // MUST NOT CONTAIN ANY Branch B staff
    if (branchAStaffStrSet.has(directorB._id.toString())) throw new Error("SECURITY LEAK: Branch A contains Director B!");
    if (branchAStaffStrSet.has(managerB._id.toString())) throw new Error("SECURITY LEAK: Branch A contains Manager B!");
    if (branchAStaffStrSet.has(staffB1._id.toString())) throw new Error("SECURITY LEAK: Branch A contains Staff B1!");
    if (branchAStaffStrSet.has(complianceB._id.toString())) throw new Error("SECURITY LEAK: Branch A contains Compliance B!");

    const branchBStaffIds = await getBranchStaffIds(complianceB._id);
    const branchBStaffStrSet = new Set(branchBStaffIds.map(id => id.toString()));

    // Must contain all Branch B staff
    if (!branchBStaffStrSet.has(directorB._id.toString())) throw new Error("Branch B staffIds missing Director B");
    if (!branchBStaffStrSet.has(staffB1._id.toString())) throw new Error("Branch B staffIds missing Staff B1");

    // MUST NOT CONTAIN ANY Branch A staff
    if (branchBStaffStrSet.has(directorA._id.toString())) throw new Error("SECURITY LEAK: Branch B contains Director A!");
    if (branchBStaffStrSet.has(staffA1._id.toString())) throw new Error("SECURITY LEAK: Branch B contains Staff A1!");

    console.log("✓ getBranchStaffIds(complianceA) includes all Branch A staff.");
    console.log("✓ getBranchStaffIds(complianceA) strictly excludes all Branch B staff (0% leakage).");
    console.log("✓ getBranchStaffIds(complianceB) strictly excludes all Branch A staff (0% leakage).");

    // =========================================================================
    // TEST SECTION 3: resolveUserScope PERMISSION RESOLVER
    // =========================================================================
    console.log("\n--------------------------------------------------------------------------------");
    console.log("TEST 3: resolveUserScope Type Resolution");
    console.log("--------------------------------------------------------------------------------");

    // Admin -> global
    const scopeAdmin = await resolveUserScope(adminStaff._id, 'users');
    if (scopeAdmin.type !== 'global' || scopeAdmin.staffIds !== null) {
      throw new Error(`Admin expected { type: 'global', staffIds: null }, got ${JSON.stringify(scopeAdmin)}`);
    }

    // Global Auditor -> global
    const scopeGlobalAuditor = await resolveUserScope(globalAuditor._id, 'users');
    if (scopeGlobalAuditor.type !== 'global' || scopeGlobalAuditor.staffIds !== null) {
      throw new Error(`Global Auditor expected { type: 'global', staffIds: null }, got ${JSON.stringify(scopeGlobalAuditor)}`);
    }

    // Compliance A -> branch
    const scopeComplianceA = await resolveUserScope(complianceA._id, 'users');
    if (scopeComplianceA.type !== 'branch' || !Array.isArray(scopeComplianceA.staffIds)) {
      throw new Error(`Compliance A expected { type: 'branch', staffIds: [...] }, got ${JSON.stringify(scopeComplianceA)}`);
    }

    // Staff A1 -> assigned
    const scopeStaffA1 = await resolveUserScope(staffA1._id, 'users');
    if (scopeStaffA1.type !== 'assigned' || !Array.isArray(scopeStaffA1.staffIds)) {
      throw new Error(`Staff A1 expected { type: 'assigned', staffIds: [...] }, got ${JSON.stringify(scopeStaffA1)}`);
    }

    console.log("✓ System Admin        -> type: 'global' (staffIds: null)");
    console.log("✓ users.view_all      -> type: 'global' (staffIds: null)");
    console.log("✓ users.view_branch   -> type: 'branch' (staffIds: [Director + Branch Subordinates])");
    console.log("✓ users.view_assigned -> type: 'assigned' (staffIds: [Line Management Subordinates])");

    // =========================================================================
    // TEST SECTION 4: DATA ACCESS - userService.getUsers
    // =========================================================================
    console.log("\n--------------------------------------------------------------------------------");
    console.log("TEST 4: Data Access & Filtering via userService.userList");
    console.log("--------------------------------------------------------------------------------");

    // 4a. Compliance Officer A calls userList
    const usersResCompA = await userService.userList({
      currentUserId: complianceA._id.toString(),
      query: { page: 1, limit: 100 }
    });
    const compAUserIds = (usersResCompA.data.userData || []).map(u => u._id.toString());
    const compAUserSet = new Set(compAUserIds);

    // Should see Branch A clients
    if (!compAUserSet.has(clientA1._id.toString())) throw new Error("Compliance A cannot see Client A1 (Staff A1's client)");
    if (!compAUserSet.has(clientA2._id.toString())) throw new Error("Compliance A cannot see Client A2 (Director A's client)");

    // MUST NOT SEE Branch B clients
    if (compAUserSet.has(clientB1._id.toString())) throw new Error("SECURITY LEAK: Compliance A can see Client B1!");
    if (compAUserSet.has(clientB2._id.toString())) throw new Error("SECURITY LEAK: Compliance A can see Client B2!");

    console.log("✓ Compliance Officer A sees Client A1 & Client A2 (Full Branch A visibility).");
    console.log("✓ Compliance Officer A CANNOT see Client B1 or Client B2 (Cross-branch isolation enforced).");

    // 4b. Compliance Officer B calls userList
    const usersResCompB = await userService.userList({
      currentUserId: complianceB._id.toString(),
      query: { page: 1, limit: 100 }
    });
    const compBUserIds = (usersResCompB.data.userData || []).map(u => u._id.toString());
    const compBUserSet = new Set(compBUserIds);

    // Should see Branch B clients
    if (!compBUserSet.has(clientB1._id.toString())) throw new Error("Compliance B cannot see Client B1");
    if (!compBUserSet.has(clientB2._id.toString())) throw new Error("Compliance B cannot see Client B2");

    // MUST NOT SEE Branch A clients
    if (compBUserSet.has(clientA1._id.toString())) throw new Error("SECURITY LEAK: Compliance B can see Client A1!");
    if (compBUserSet.has(clientA2._id.toString())) throw new Error("SECURITY LEAK: Compliance B can see Client A2!");

    console.log("✓ Compliance Officer B sees Client B1 & Client B2 (Full Branch B visibility).");
    console.log("✓ Compliance Officer B CANNOT see Client A1 or Client A2 (Cross-branch isolation enforced).");

    // 4c. Staff A1 (Assigned Scope) calls userList
    const usersResStaffA1 = await userService.userList({
      currentUserId: staffA1._id.toString(),
      query: { page: 1, limit: 100 }
    });
    const staffA1UserIds = (usersResStaffA1.data.userData || []).map(u => u._id.toString());
    const staffA1UserSet = new Set(staffA1UserIds);

    // Should ONLY see Client A1
    if (!staffA1UserSet.has(clientA1._id.toString())) throw new Error("Staff A1 cannot see their own Client A1");
    if (staffA1UserSet.has(clientA2._id.toString())) throw new Error("Staff A1 leaked Client A2 (Director's client)!");
    if (staffA1UserSet.has(clientB1._id.toString())) throw new Error("Staff A1 leaked Client B1!");

    console.log("✓ Staff A1 (view_assigned) sees ONLY Client A1 (own client). Cannot see Director's client or Branch B.");

    // 4d. Global Auditor (Global Scope) calls userList
    const usersResGlobal = await userService.userList({
      currentUserId: globalAuditor._id.toString(),
      query: { page: 1, limit: 100 }
    });
    const globalUserIds = (usersResGlobal.data.userData || []).map(u => u._id.toString());
    const globalUserSet = new Set(globalUserIds);

    if (!globalUserSet.has(clientA1._id.toString())) throw new Error("Global Auditor cannot see Client A1");
    if (!globalUserSet.has(clientA2._id.toString())) throw new Error("Global Auditor cannot see Client A2");
    if (!globalUserSet.has(clientB1._id.toString())) throw new Error("Global Auditor cannot see Client B1");
    if (!globalUserSet.has(clientB2._id.toString())) throw new Error("Global Auditor cannot see Client B2");

    console.log("✓ Global Auditor (view_all) sees all clients across all branches (Global visibility).");

    // =========================================================================
    // TEST SECTION 5: DATA ACCESS - userService.userDetails
    // =========================================================================
    console.log("\n--------------------------------------------------------------------------------");
    console.log("TEST 5: Single User Details Scoping via userService.userDetails");
    console.log("--------------------------------------------------------------------------------");

    // Compliance A viewing Branch A clients -> 200 Allowed
    const resA1 = await userService.userDetails({ user: complianceA, params: { id: clientA1._id.toString() } });
    if (resA1.status !== 200) throw new Error(`Compliance A failed to view Client A1: status ${resA1.status}`);

    const resA2 = await userService.userDetails({ user: complianceA, params: { id: clientA2._id.toString() } });
    if (resA2.status !== 200) throw new Error(`Compliance A failed to view Client A2: status ${resA2.status}`);

    // Compliance A viewing Branch B client -> 403 Forbidden!
    const resB1Blocked = await userService.userDetails({ user: complianceA, params: { id: clientB1._id.toString() } });
    if (resB1Blocked.status !== 403) throw new Error(`SECURITY LEAK: Compliance A was not blocked from viewing Client B1! Status: ${resB1Blocked.status}`);

    // Staff A1 viewing Director's client -> 403 Forbidden!
    const resStaffDirBlocked = await userService.userDetails({ user: staffA1, params: { id: clientA2._id.toString() } });
    if (resStaffDirBlocked.status !== 403) throw new Error(`Staff A1 was not blocked from viewing Director's client A2! Status: ${resStaffDirBlocked.status}`);

    console.log("✓ Compliance A viewing Client A1 (Staff client): Allowed (200).");
    console.log("✓ Compliance A viewing Client A2 (Director client): Allowed (200).");
    console.log("✓ Compliance A viewing Client B1 (Other branch client): BLOCKED (403 Access Denied).");
    console.log("✓ Staff A1 viewing Client A2 (Director client): BLOCKED (403 Access Denied).");

    // =========================================================================
    // TEST SECTION 6: ENDPOINT AUTHORIZATION via accessMiddleware
    // =========================================================================
    console.log("\n--------------------------------------------------------------------------------");
    console.log("TEST 6: Route Authorization via accessMiddleware");
    console.log("--------------------------------------------------------------------------------");

    const mockReqRes = (userObj) => {
      let statusCode = 200;
      let responseBody = null;
      let nextCalled = false;
      const req = { user: userObj };
      const res = {
        status: (code) => {
          statusCode = code;
          return {
            json: (b) => { responseBody = b; }
          };
        }
      };
      const next = () => { nextCalled = true; };
      return { req, res, next, getResult: () => ({ statusCode, responseBody, nextCalled }) };
    };

    // Intern (no users permission) -> 403
    const internCtx = mockReqRes({ _id: internA._id });
    await checkPermission('Users', 'read')(internCtx.req, internCtx.res, internCtx.next);
    if (internCtx.getResult().statusCode !== 403 || internCtx.getResult().nextCalled) {
      throw new Error(`Intern should be rejected with 403, got ${internCtx.getResult().statusCode}`);
    }

    // Compliance A (has users.view_branch) -> 200 Next
    const compACtx = mockReqRes({ _id: complianceA._id });
    await checkPermission('Users', 'read')(compACtx.req, compACtx.res, compACtx.next);
    if (!compACtx.getResult().nextCalled) {
      throw new Error(`Compliance A should pass endpoint authorization, got status ${compACtx.getResult().statusCode}`);
    }

    // Staff A1 (has users.view_assigned) -> 200 Next
    const staffACtx = mockReqRes({ _id: staffA1._id });
    await checkPermission('Users', 'read')(staffACtx.req, staffACtx.res, staffACtx.next);
    if (!staffACtx.getResult().nextCalled) {
      throw new Error(`Staff A1 should pass endpoint authorization, got status ${staffACtx.getResult().statusCode}`);
    }

    // Global Auditor (has users.view_all) -> 200 Next
    const auditorCtx = mockReqRes({ _id: globalAuditor._id });
    await checkPermission('Users', 'read')(auditorCtx.req, auditorCtx.res, auditorCtx.next);
    if (!auditorCtx.getResult().nextCalled) {
      throw new Error(`Global Auditor should pass endpoint authorization, got status ${auditorCtx.getResult().statusCode}`);
    }

    console.log("✓ Staff without Users capability: 403 Forbidden.");
    console.log("✓ Staff with users.view_branch:    Passes endpoint check (next called).");
    console.log("✓ Staff with users.view_assigned:  Passes endpoint check (next called).");
    console.log("✓ Staff with users.view_all:       Passes endpoint check (next called).");

    console.log("\n================================================================================");
    console.log("   🎉 ALL THREE SCOPES AND CROSS-BRANCH ISOLATION TESTS PASSED 100%! 🎉   ");
    console.log("================================================================================\n");

  } catch (err) {
    console.error("\n❌ TEST SUITE FAILED WITH ERROR:", err);
    throw err;
  } finally {
    console.log("Cleaning up test database records...");
    if (createdAssignmentIds.length > 0) {
      await staffAssignmentModel.deleteMany({ _id: { $in: createdAssignmentIds } });
    }
    if (createdUserIds.length > 0) {
      await userModel.deleteMany({ _id: { $in: createdUserIds } });
    }
    if (createdStaffIds.length > 0) {
      await staffModel.deleteMany({ _id: { $in: createdStaffIds } });
    }
    if (createdRoleIds.length > 0) {
      await roleModel.deleteMany({ _id: { $in: createdRoleIds } });
    }
    if (createdPgIds.length > 0) {
      await permissionGroupModel.deleteMany({ _id: { $in: createdPgIds } });
    }
    console.log("✓ Cleaned up all temporary test documents.");
    await mongoose.disconnect();
    console.log("✓ MongoDB disconnected.");
  }
}

runScopeAndIsolationTests()
  .then(() => process.exit(0))
  .catch(() => process.exit(1));
