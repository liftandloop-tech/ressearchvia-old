import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import permissionGroupModel from "./app/models/permissionGroupModel.js";
import roleModel from "./app/models/roleModel.js";
import staffModel from "./app/models/staffModel.js";
import roleService from "./app/services/roleService.js";
import permissionGroupService from "./app/services/permissionGroupService.js";

async function run() {
    try {
        console.log("Connecting to database...");
        await mongoose.connect(process.env.DB_URL);
        console.log("Connected.");

        // 1. Test Seeding
        console.log("\n--- Testing default seeding ---");
        await roleService.seedAdminRole();

        // 2. Validate Default Admin Group
        const adminGroup = await permissionGroupModel.findOne({ name: 'admin' });
        if (!adminGroup) {
            throw new Error("Seeding failed: 'admin' group not found.");
        }
        console.log("✓ Default 'admin' permission group exists.");
        console.log(`  Permissions count: ${adminGroup.permissions.length}`);

        // Validate Actions
        const allFeatures = ['Leads', 'Reports', 'Users', 'Staff', 'KYC', 'Payments', 'Notifications', 'Settings'];
        for (const feature of allFeatures) {
            const match = adminGroup.permissions.find(p => p.feature === feature);
            if (!match || match.actions.length !== 4) {
                throw new Error(`Seeding validation failed: '${feature}' does not have full CRUD permissions.`);
            }
        }
        console.log("✓ All features in 'admin' group have full CRUD actions.");

        // 3. Validate Default Admin Role
        const adminRole = await roleModel.findOne({ name: 'Admin' }).populate('permissionGroups');
        if (!adminRole) {
            throw new Error("Seeding failed: 'Admin' role not found.");
        }
        console.log("✓ Default 'Admin' role exists.");
        if (adminRole.permissionGroups.length === 0 || adminRole.permissionGroups[0].name !== 'admin') {
            throw new Error("Seeding validation failed: Admin role is not associated with 'admin' group.");
        }
        console.log("✓ Admin role matches 'admin' permission group.");

        // 4. Create custom group and role
        console.log("\n--- Testing Custom Role/Group creation ---");
        // Ensure clean test state
        await roleModel.deleteOne({ name: 'TEST_Role_Viewer' });
        await permissionGroupModel.deleteOne({ name: 'TEST_PG_Lead_Reader' });

        const customGroupRes = await permissionGroupService.createPermissionGroup({
            body: {
                name: 'TEST_PG_Lead_Reader',
                description: 'Allows reading leads only',
                permissions: [
                    { feature: 'Leads', actions: ['read'] }
                ]
            }
        });

        if (customGroupRes.status !== 200) {
            throw new Error(`Failed to create custom permission group: ${customGroupRes.message}`);
        }
        console.log("✓ Custom permission group created successfully.");

        const customRoleRes = await roleService.createRole({
            body: {
                name: 'TEST_Role_Viewer',
                description: 'Viewer role with limited permissions',
                permissionGroups: [customGroupRes.data._id]
            }
        });

        if (customRoleRes.status !== 200) {
            throw new Error(`Failed to create custom role: ${customRoleRes.message}`);
        }
        console.log("✓ Custom role created successfully.");

        // 5. Test mock authorization checks
        console.log("\n--- Simulating Authorization checks ---");

        // Helper function simulating the logic inside checkPermission middleware
        const evaluatePermission = (populatedRole, feature, action) => {
            if (!populatedRole) return false;
            return populatedRole.permissionGroups.some(group => {
                return group.permissions.some(perm => {
                    return perm.feature.toLowerCase() === feature.toLowerCase() &&
                           perm.actions.some(act => act.toLowerCase() === action.toLowerCase());
                });
            });
        };

        const populatedAdminRole = await roleModel.findById(adminRole._id).populate('permissionGroups');
        const populatedCustomRole = await roleModel.findById(customRoleRes.data._id).populate('permissionGroups');

        // Test 1: Admin should have access to everything
        const adminHasLeadRead = evaluatePermission(populatedAdminRole, 'Leads', 'read');
        const adminHasReportsDelete = evaluatePermission(populatedAdminRole, 'Reports', 'delete');
        console.log(`  Admin access to Leads:read -> Expected: true, Actual: ${adminHasLeadRead}`);
        console.log(`  Admin access to Reports:delete -> Expected: true, Actual: ${adminHasReportsDelete}`);

        if (!adminHasLeadRead || !adminHasReportsDelete) {
            throw new Error("Auth check failed: Admin role lacks permissions.");
        }
        console.log("✓ Admin role simulation passed.");

        // Test 2: Custom role (Leads:read)
        const customHasLeadRead = evaluatePermission(populatedCustomRole, 'Leads', 'read');
        const customHasLeadCreate = evaluatePermission(populatedCustomRole, 'Leads', 'create');
        const customHasReportsRead = evaluatePermission(populatedCustomRole, 'Reports', 'read');

        console.log(`  Custom role access to Leads:read -> Expected: true, Actual: ${customHasLeadRead}`);
        console.log(`  Custom role access to Leads:create -> Expected: false, Actual: ${customHasLeadCreate}`);
        console.log(`  Custom role access to Reports:read -> Expected: false, Actual: ${customHasReportsRead}`);

        if (!customHasLeadRead || customHasLeadCreate || customHasReportsRead) {
            throw new Error("Auth check failed: Custom role permissions resolved incorrectly.");
        }
        console.log("✓ Custom role simulation passed.");

        // Clean up test data
        await roleModel.deleteOne({ name: 'TEST_Role_Viewer' });
        await permissionGroupModel.deleteOne({ name: 'TEST_PG_Lead_Reader' });
        console.log("\n✓ Cleaned up test roles and groups.");

        console.log("\nALL TESTS PASSED SUCCESSFULLY!");
        process.exit(0);
    } catch (error) {
        console.error("\n❌ TEST FAILED:", error);
        process.exit(1);
    }
}

run();
