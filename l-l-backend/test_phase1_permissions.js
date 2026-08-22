import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { PERMISSION_REGISTRY, isValidPermissionKey } from './app/config/permissionRegistry.js';
import permissionGroupService from './app/services/permissionGroupService.js';
import permissionGroupModel from './app/models/permissionGroupModel.js';

dotenv.config();

const runPhase1Validation = async () => {
    console.log("=========================================");
    console.log("PHASE 1: CANONICAL PERMISSIONS VALIDATION");
    console.log("=========================================\n");

    // Test 1: Registry Key Count and Validity
    const keys = Object.keys(PERMISSION_REGISTRY);
    console.log(`[1] Total Registry Keys: ${keys.length}`);
    if (keys.length !== 71) {
        throw new Error(`Expected exactly 71 canonical permission keys, found ${keys.length}`);
    }

    keys.forEach(k => {
        if (!isValidPermissionKey(k)) {
            throw new Error(`Permission key ${k} failed validity check`);
        }
        if (!k.includes('.')) {
            throw new Error(`Permission key ${k} must use dot-notation`);
        }
    });
    console.log("  ✓ All 58 keys are valid dot-notation keys.\n");

    // Test 2: Database Connection & Admin Role Seeding
    const mongoUri = process.env.DB_URL || process.env.MONGODB_URI || "mongodb://localhost:27017/res-old";
    console.log(`[2] Connecting to Database (${mongoUri.split('@').pop()})...`);
    await mongoose.connect(mongoUri);

    console.log("  Seeding default Admin Group...");
    await permissionGroupService.seedAdminGroup();

    const adminGroup = await permissionGroupModel.findOne({ name: 'admin' });
    if (!adminGroup) {
        throw new Error("Admin group was not created by seeding service");
    }

    const seededActions = [];
    adminGroup.permissions.forEach(p => {
        p.actions.forEach(a => seededActions.push(a));
    });

    console.log(`  Seeded Actions Count in Admin Group: ${seededActions.length}`);
    if (seededActions.length !== 71) {
        throw new Error(`Expected 71 seeded actions in Admin Group, found ${seededActions.length}`);
    }

    // Verify every registry key exists in adminGroup
    keys.forEach(k => {
        if (!seededActions.includes(k)) {
            throw new Error(`Seeded admin group is missing canonical key: ${k}`);
        }
    });

    console.log("  ✓ Admin group successfully seeded with all 58 canonical keys.\n");

    console.log("=========================================");
    console.log("PHASE 1 VERIFICATION COMPLETE: ALL PASSED");
    console.log("=========================================");

    await mongoose.disconnect();
    process.exit(0);
};

runPhase1Validation().catch(async (err) => {
    console.error("\n❌ PHASE 1 VALIDATION FAILED:", err.message);
    await mongoose.disconnect();
    process.exit(1);
});
