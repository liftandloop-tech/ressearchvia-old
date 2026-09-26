import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import leadModel from "./app/models/leadModel.js";
import leadPoolModel from "./app/models/leadPoolModel.js";
import staffModel from "./app/models/staffModel.js";
import roleModel from "./app/models/roleModel.js";
import { ensureDefaultFreshPool } from "./app/controller/leadPoolController.js";
import leadPoolController from "./app/controller/leadPoolController.js";
import leadPullController from "./app/controller/leadPullController.js";

async function runIsolationTest() {
    try {
        console.log("Connecting to MongoDB...");
        await mongoose.connect(process.env.DB_URL);
        console.log("Connected.");

        const companyId = "test_co_iso_" + Date.now();

        // 1. Create Roles
        let adminRole = await roleModel.findOne({ name: 'Admin' });
        if (!adminRole) {
            adminRole = await roleModel.create({ name: 'Admin', roleName: 'Admin', department: 'Admin' });
        }
        let managerRole = await roleModel.findOne({ name: 'Manager' });
        if (!managerRole) {
            managerRole = await roleModel.create({ name: 'Manager', roleName: 'Manager', department: 'Sales' });
        }
        let bdeRole = await roleModel.findOne({ name: 'BDE' });
        if (!bdeRole) {
            bdeRole = await roleModel.create({ name: 'BDE', roleName: 'BDE', department: 'Sales' });
        }

        // 2. Create Users:
        // Admin
        const adminStaff = await staffModel.create({
            staffId: "ADM-" + Date.now(),
            fullName: "System Admin",
            mobileNumber: 9990000001,
            emailAddress: `admin_${Date.now()}@test.com`,
            roleId: adminRole._id,
            role: "Admin",
            deparment: "Admin",
            stage: "Employee"
        });

        // Manager A
        const managerA = await staffModel.create({
            staffId: "MGR-A-" + Date.now(),
            fullName: "Sales Manager A",
            mobileNumber: 9990000002,
            emailAddress: `mgra_${Date.now()}@test.com`,
            roleId: managerRole._id,
            role: "Manager",
            deparment: "Sales",
            stage: "Employee",
            assignedDirector: adminStaff._id
        });

        // Staff A1 (Reports to Manager A)
        const staffA1 = await staffModel.create({
            staffId: "STF-A1-" + Date.now(),
            fullName: "Agent A1",
            mobileNumber: 9990000003,
            emailAddress: `stfa1_${Date.now()}@test.com`,
            roleId: bdeRole._id,
            role: "BDE",
            deparment: "Sales",
            stage: "Employee",
            assignedDirector: managerA._id
        });

        // Manager B
        const managerB = await staffModel.create({
            staffId: "MGR-B-" + Date.now(),
            fullName: "Sales Manager B",
            mobileNumber: 9990000004,
            emailAddress: `mgrb_${Date.now()}@test.com`,
            roleId: managerRole._id,
            role: "Manager",
            deparment: "Sales",
            stage: "Employee",
            assignedDirector: adminStaff._id
        });

        // Staff B1 (Reports to Manager B)
        const staffB1 = await staffModel.create({
            staffId: "STF-B1-" + Date.now(),
            fullName: "Agent B1",
            mobileNumber: 9990000005,
            emailAddress: `stfb1_${Date.now()}@test.com`,
            roleId: bdeRole._id,
            role: "BDE",
            deparment: "Sales",
            stage: "Employee",
            assignedDirector: managerB._id
        });

        console.log("✓ Test users & hierarchy created:");
        console.log(`  Admin: ${adminStaff._id}`);
        console.log(`  Manager A: ${managerA._id} -> Staff A1: ${staffA1._id}`);
        console.log(`  Manager B: ${managerB._id} -> Staff B1: ${staffB1._id}`);

        // Mock Express Response helper
        const mockRes = () => {
            const res = {
                statusCode: 200,
                body: null,
                status: function(c) { this.statusCode = c; return this; },
                send: function(b) { this.body = b; return this; }
            };
            return res;
        };

        console.log("\n--- TEST 1: Default Fresh Leads Auto-Creation is Global ---");
        const freshPool = await ensureDefaultFreshPool(companyId);
        if (!freshPool.isGlobal) throw new Error("Fresh Leads pool must be isGlobal: true");
        console.log("✓ Default Fresh Leads pool created with isGlobal: true");

        console.log("\n--- TEST 2: Admin Creates a Global Lead Pool ---");
        let resAdminCreate = mockRes();
        await leadPoolController.createLeadPool({
            user: { _id: adminStaff._id, companyId },
            body: {
                name: "Admin Global Inbound",
                description: "Global pool for all teams",
                pullSize: 15,
                maxPerStaff: 75
            }
        }, resAdminCreate);

        if (resAdminCreate.statusCode !== 200) throw new Error(`Admin failed to create pool: ${JSON.stringify(resAdminCreate.body)}`);
        const adminGlobalPool = resAdminCreate.body.data;
        if (!adminGlobalPool.isGlobal) throw new Error("Admin created pool should be isGlobal: true");
        console.log(`✓ Admin created global pool '${adminGlobalPool.name}' with isGlobal=true, pullSize=${adminGlobalPool.pullSize}`);

        console.log("\n--- TEST 3: Manager A Creates a Team-Specific Lead Pool ---");
        let resMgrACreate = mockRes();
        await leadPoolController.createLeadPool({
            user: { _id: managerA._id, companyId },
            body: {
                name: "Team A HNI Leads",
                description: "Private leads for Team A only",
                pullSize: 5,
                maxPerStaff: 25
            }
        }, resMgrACreate);

        if (resMgrACreate.statusCode !== 200) throw new Error(`Manager A failed to create pool: ${JSON.stringify(resMgrACreate.body)}`);
        const teamAPool = resMgrACreate.body.data;
        if (teamAPool.isGlobal !== false) throw new Error("Manager A pool must be isGlobal: false");
        if (teamAPool.createdBy.toString() !== managerA._id.toString()) throw new Error("Manager A pool creator must match Manager A");
        console.log(`✓ Manager A created team pool '${teamAPool.name}' (isGlobal=false, createdBy=${teamAPool.createdByName})`);

        console.log("\n--- TEST 4: Visibility & Isolation Testing ---");
        // A. Admin lists pools -> should see all 3 (Fresh Leads, Admin Global, Team A HNI)
        let resAdminList = mockRes();
        await leadPoolController.listLeadPools({ user: { _id: adminStaff._id, companyId } }, resAdminList);
        const adminPools = resAdminList.body.data;
        console.log(`Admin sees ${adminPools.length} pools: [${adminPools.map(p => p.name).join(', ')}]`);
        if (adminPools.length !== 3) throw new Error(`Admin expected 3 pools, got ${adminPools.length}`);

        // B. Manager A lists pools -> should see Fresh Leads, Admin Global, and Team A HNI (3 pools)
        let resMgrAList = mockRes();
        await leadPoolController.listLeadPools({ user: { _id: managerA._id, companyId } }, resMgrAList);
        const mgrAPools = resMgrAList.body.data;
        console.log(`Manager A sees ${mgrAPools.length} pools: [${mgrAPools.map(p => p.name).join(', ')}]`);
        if (mgrAPools.length !== 3) throw new Error(`Manager A expected 3 pools, got ${mgrAPools.length}`);

        // C. Staff A1 (reporting to Manager A) lists pools -> should see Fresh Leads, Admin Global, and Team A HNI (3 pools)
        let resStaffA1List = mockRes();
        await leadPoolController.listLeadPools({ user: { _id: staffA1._id, companyId } }, resStaffA1List);
        const staffA1Pools = resStaffA1List.body.data;
        console.log(`Staff A1 sees ${staffA1Pools.length} pools: [${staffA1Pools.map(p => p.name).join(', ')}]`);
        if (staffA1Pools.length !== 3) throw new Error(`Staff A1 expected 3 pools, got ${staffA1Pools.length}`);

        // D. Manager B lists pools -> should ONLY see 2 pools (Fresh Leads, Admin Global). Team A HNI MUST NOT BE VISIBLE!
        let resMgrBList = mockRes();
        await leadPoolController.listLeadPools({ user: { _id: managerB._id, companyId } }, resMgrBList);
        const mgrBPools = resMgrBList.body.data;
        console.log(`Manager B sees ${mgrBPools.length} pools: [${mgrBPools.map(p => p.name).join(', ')}]`);
        if (mgrBPools.length !== 2) throw new Error(`Manager B expected 2 pools, got ${mgrBPools.length}`);
        if (mgrBPools.some(p => p._id.toString() === teamAPool._id.toString())) {
            throw new Error("ISOLATION BREACH: Manager B can see Manager A's private team pool!");
        }
        console.log("✓ Manager B cannot see Manager A's team pool!");

        // E. Staff B1 lists pools -> should ONLY see 2 pools (Fresh Leads, Admin Global).
        let resStaffB1List = mockRes();
        await leadPoolController.listLeadPools({ user: { _id: staffB1._id, companyId } }, resStaffB1List);
        const staffB1Pools = resStaffB1List.body.data;
        console.log(`Staff B1 sees ${staffB1Pools.length} pools: [${staffB1Pools.map(p => p.name).join(', ')}]`);
        if (staffB1Pools.length !== 2) throw new Error(`Staff B1 expected 2 pools, got ${staffB1Pools.length}`);
        if (staffB1Pools.some(p => p._id.toString() === teamAPool._id.toString())) {
            throw new Error("ISOLATION BREACH: Staff B1 can see Manager A's private team pool!");
        }
        console.log("✓ Staff B1 cannot see Manager A's team pool!");

        console.log("\n--- TEST 5: Lead Pull Access Control & Quotas ---");
        // Seed 10 unassigned leads in Team A's pool
        const leads = [];
        for (let i = 1; i <= 10; i++) {
            leads.push({
                fullName: `HNI Lead ${i}`,
                mobileNumber: `98000000${i.toString().padStart(2, '0')}`,
                emailAddress: `hni${i}@test.com`,
                companyId,
                leadPoolId: teamAPool._id,
                assignedRM: null,
                stage: 'New'
            });
        }
        await leadModel.insertMany(leads);

        // Unauthorized Pull: Staff B1 tries to pull from Team A's pool
        let resStaffB1Pull = mockRes();
        await leadPullController.pullLeads({
            user: { _id: staffB1._id, companyId },
            body: { poolId: teamAPool._id }
        }, resStaffB1Pull);

        if (resStaffB1Pull.statusCode === 200 && resStaffB1Pull.body.data.pulled > 0) {
            throw new Error("SECURITY FAILURE: Staff B1 successfully pulled leads from Manager A's private pool!");
        }
        console.log(`✓ Unauthorized pull by Staff B1 was correctly rejected: status ${resStaffB1Pull.statusCode}`);

        // Authorized Pull: Staff A1 pulls from Team A's pool -> should pull 5 (teamAPool.pullSize)
        let resStaffA1Pull = mockRes();
        await leadPullController.pullLeads({
            user: { _id: staffA1._id, companyId },
            body: { poolId: teamAPool._id }
        }, resStaffA1Pull);

        if (resStaffA1Pull.statusCode !== 200) throw new Error(`Staff A1 pull failed: ${JSON.stringify(resStaffA1Pull.body)}`);
        console.log(`✓ Authorized pull by Staff A1 succeeded: pulled ${resStaffA1Pull.body.data.pulled} leads (expected batch pull size: ${teamAPool.pullSize})`);
        if (resStaffA1Pull.body.data.pulled !== 5) {
            throw new Error(`Expected pull size 5, got ${resStaffA1Pull.body.data.pulled}`);
        }

        console.log("\n--- TEST 6: Modification & Deletion Authorization ---");
        // Manager B tries to edit Manager A's pool -> Forbidden
        let resMgrBEdit = mockRes();
        await leadPoolController.updateLeadPool({
            user: { _id: managerB._id, companyId },
            params: { id: teamAPool._id },
            body: { name: "Hacked Pool" }
        }, resMgrBEdit);
        if (resMgrBEdit.statusCode !== 403) throw new Error(`Expected 403 Forbidden for Manager B edit, got ${resMgrBEdit.statusCode}`);
        console.log("✓ Manager B modification forbidden (403)");

        // Manager A edits their own pool -> Success
        let resMgrAEdit = mockRes();
        await leadPoolController.updateLeadPool({
            user: { _id: managerA._id, companyId },
            params: { id: teamAPool._id },
            body: { pullSize: 10 }
        }, resMgrAEdit);
        if (resMgrAEdit.statusCode !== 200) throw new Error(`Manager A edit failed: ${JSON.stringify(resMgrAEdit.body)}`);
        console.log(`✓ Manager A successfully updated pool pullSize to 10`);

        // Clean up test data
        await leadModel.deleteMany({ companyId });
        await leadPoolModel.deleteMany({ companyId });
        await staffModel.deleteMany({ _id: { $in: [adminStaff._id, managerA._id, staffA1._id, managerB._id, staffB1._id] } });

        console.log("\n🎉 ALL LEAD POOL ISOLATION & DISTRIBUTION TESTS PASSED SUCCESSFULLY! 🎉\n");
        process.exit(0);
    } catch (err) {
        console.error("\n❌ TEST FAILED:", err);
        process.exit(1);
    }
}

runIsolationTest();
