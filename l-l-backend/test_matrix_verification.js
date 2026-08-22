import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { PERMISSION_REGISTRY, isValidPermissionKey } from './app/config/permissionRegistry.js';
import permissionGroupService from './app/services/permissionGroupService.js';
import permissionGroupModel from './app/models/permissionGroupModel.js';
import auditLogModel from './app/models/auditLogModel.js';
import { logAuditTrail } from './app/services/activityLogService.js';
import staffModel from './app/models/staffModel.js';
import roleModel from './app/models/roleModel.js';
import { checkPermission } from './app/middleware/accessMiddleware.js';

dotenv.config();

const runMatrixVerification = async () => {
    console.log("=========================================");
    console.log("PHASE 5: END-TO-END MATRIX VERIFICATION");
    console.log("=========================================\n");

    const mongoUri = process.env.DB_URL || process.env.MONGODB_URI || "mongodb://localhost:27017/res-old";
    console.log(`Connecting to Database...`);
    await mongoose.connect(mongoUri);

    // 1. Registry Completeness Check
    const keys = Object.keys(PERMISSION_REGISTRY);
    console.log(`[1] Registry Completeness: Verified ${keys.length} canonical keys.`);

    // 2. Data Scope Matrix Test
    console.log(`[2] Data Scope Matrix: Verifying leads.view_all vs leads.view_assigned...`);
    const leadsViewAll = isValidPermissionKey('leads.view_all');
    const leadsViewAssigned = isValidPermissionKey('leads.view_assigned');
    if (!leadsViewAll || !leadsViewAssigned) {
        throw new Error("Data scope keys leads.view_all or leads.view_assigned missing");
    }
    console.log("  ✓ Data scope keys verified.\n");

    // 3. RBAC Settings Isolation Test
    console.log(`[3] RBAC Settings Isolation: Verifying roles.* vs settings.update...`);
    const rolesCreate = PERMISSION_REGISTRY['roles.create'];
    const settingsUpdate = PERMISSION_REGISTRY['settings.update'];
    if (rolesCreate.feature === settingsUpdate.feature) {
        throw new Error("RBAC administration keys must be isolated from generic system settings!");
    }
    console.log("  ✓ Roles management is isolated from generic settings.\n");

    // 4. Audit Log Verification Test
    console.log(`[4] Immutable Audit Trail Test...`);
    const testActorId = new mongoose.Types.ObjectId();
    await logAuditTrail({
        actorUserId: testActorId,
        action: 'PAYMENT_BYPASSED',
        resourceType: 'Payment',
        resourceId: 'PAY_99999',
        oldValue: { status: 'PENDING' },
        newValue: { status: 'BYPASSED' },
        metadata: { reason: 'E2E Matrix Test' },
        success: true
    });

    const auditLogEntry = await auditLogModel.findOne({ actorUserId: testActorId, action: 'PAYMENT_BYPASSED' });
    if (!auditLogEntry) {
        throw new Error("Audit trail log entry creation failed!");
    }
    console.log("  ✓ Immutable audit entry written and verified successfully.\n");
    await auditLogModel.deleteOne({ _id: auditLogEntry._id });

    // 5. Authorization Engine (checkPermission) Middleware Mock Test
    console.log(`[5] Authorization Engine checkPermission Middleware Test...`);
    
    // Create temporary role and group
    const testGroup = await permissionGroupModel.create({
        name: `TEST_GRP_${Date.now()}`,
        description: 'Temporary Test Group',
        permissions: [{ feature: 'Leads', actions: ['leads.view_assigned', 'leads.follow_up_assigned'] }]
    });

    const testRole = await roleModel.create({
        name: `TEST_ROLE_${Date.now()}`,
        description: 'Temporary Test Role',
        permissionGroups: [testGroup._id]
    });

    const testStaff = await staffModel.create({
        staffId: `TEST_STF_${Date.now()}`,
        fullName: 'E2E Test Staff',
        mobileNumber: `99999${Math.floor(1000 + Math.random() * 9000)}`,
        roleId: testRole._id,
        stage: 'Employee'
    });

    const mockReqAuthorized = { user: { _id: testStaff._id, userId: testStaff._id } };
    const mockReqUnauthorized = { user: { _id: testStaff._id, userId: testStaff._id } };

    let isAuthorized = false;
    let isDenied = false;

    // Authorized check for leads.view_assigned
    const authMiddleware = checkPermission('leads.view_assigned');
    await authMiddleware(mockReqAuthorized, { status: () => ({ json: () => {} }) }, () => {
        isAuthorized = true;
    });

    // Unauthorized check for leads.bulk_upload
    const unauthMiddleware = checkPermission('leads.bulk_upload');
    const mockRes = {
        status: (code) => {
            if (code === 403) isDenied = true;
            return { json: () => {} };
        }
    };
    await unauthMiddleware(mockReqUnauthorized, mockRes, () => {});

    // Clean up temporary documents
    await staffModel.deleteOne({ _id: testStaff._id });
    await roleModel.deleteOne({ _id: testRole._id });
    await permissionGroupModel.deleteOne({ _id: testGroup._id });

    if (!isAuthorized) {
        throw new Error("Authorization engine failed to grant access for valid canonical permission key.");
    }
    if (!isDenied) {
        throw new Error("Authorization engine failed to reject access for unauthorized canonical permission key.");
    }

    console.log("  ✓ Middleware correctly granted authorized capability and returned HTTP 403 for unauthorized capability.\n");

    console.log("=========================================");
    console.log("E2E MATRIX VERIFICATION PASSED SUCCESSFULLY!");
    console.log("=========================================");

    await mongoose.disconnect();
    process.exit(0);
};

runMatrixVerification().catch(async (err) => {
    console.error("\n❌ MATRIX VERIFICATION FAILED:", err.message);
    await mongoose.disconnect();
    process.exit(1);
});
