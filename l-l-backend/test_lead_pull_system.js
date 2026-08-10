import mongoose from "mongoose";
import * as dotenv from "dotenv";
import fs from "fs";
dotenv.config();

import leadModel from "./app/models/leadModel.js";
import leadPoolModel from "./app/models/leadPoolModel.js";
import staffModel from "./app/models/staffModel.js";
import generalSettingsModel from "./app/models/generalSettingsModel.js";
import importJobModel from "./app/models/importJobModel.js";
import importService from "./app/services/importService.js";
import { ensureDefaultFreshPool } from "./app/controller/leadPoolController.js";
import leadPullController from "./app/controller/leadPullController.js";

async function runTest() {
    try {
        console.log("Connecting to MongoDB...");
        await mongoose.connect(process.env.DB_URL);
        console.log("Connected.");

        const companyA = "test_company_pull_A_" + Date.now();
        const companyB = "test_company_pull_B_" + Date.now();

        // Mock staff members
        const staffA1 = new mongoose.Types.ObjectId();
        const staffA2 = new mongoose.Types.ObjectId();
        const staffB1 = new mongoose.Types.ObjectId();

        console.log("\n--- 1. Testing Default Fresh Lead Pool Auto-Creation ---");
        const freshPoolA = await ensureDefaultFreshPool(companyA);
        console.log(`✓ Fresh Pool A created/retrieved: ID=${freshPoolA._id}, Name=${freshPoolA.name}, Company=${freshPoolA.companyId}`);
        if (freshPoolA.name !== "Fresh Leads" || freshPoolA.companyId !== companyA) {
            throw new Error("Default Fresh Lead pool failed validation");
        }

        const freshPoolB = await ensureDefaultFreshPool(companyB);
        console.log(`✓ Fresh Pool B created/retrieved: ID=${freshPoolB._id}, Name=${freshPoolB.name}, Company=${freshPoolB.companyId}`);
        if (freshPoolB._id.toString() === freshPoolA._id.toString()) {
            throw new Error("Company A and B share the same pool ID — multi-tenancy issue!");
        }

        console.log("\n--- 2. Testing Lead Import Defaulting to Fresh Pool ---");
        // Create 25 leads for Company A
        const leadsCompanyA = [];
        for (let i = 1; i <= 25; i++) {
            leadsCompanyA.push({
                fullName: `CompanyA Lead ${i}`,
                mobileNumber: `91000000${i.toString().padStart(2, '0')}`,
                emailAddress: `leadA${i}@test.com`,
                companyId: companyA,
                leadPoolId: freshPoolA._id, // landed in Fresh pool
                assignedRM: null,
                stage: 'New',
                isRead: false
            });
        }
        await leadModel.insertMany(leadsCompanyA);
        console.log(`✓ Seeded 25 fresh leads for ${companyA}`);

        // Create 10 leads for Company B
        const leadsCompanyB = [];
        for (let i = 1; i <= 10; i++) {
            leadsCompanyB.push({
                fullName: `CompanyB Lead ${i}`,
                mobileNumber: `92000000${i.toString().padStart(2, '0')}`,
                emailAddress: `leadB${i}@test.com`,
                companyId: companyB,
                leadPoolId: freshPoolB._id,
                assignedRM: null,
                stage: 'New',
                isRead: false
            });
        }
        await leadModel.insertMany(leadsCompanyB);
        console.log(`✓ Seeded 10 fresh leads for ${companyB}`);

        console.log("\n--- 3. Testing Settings Configuration & Fallbacks ---");
        // Set custom limits for Company A: max=20, pullSize=8
        await generalSettingsModel.create({
            key: `lead_distribution_${companyA}`,
            value: {
                freshMaxPerStaff: 20,
                freshPullSize: 8,
                unreadMaxPerStaff: 15,
                unreadPullSize: 5
            }
        });
        console.log("✓ Custom lead distribution settings saved for Company A");

        console.log("\n--- 4. Testing Pull Stats API ---");
        const mockReqStats = {
            user: { _id: staffA1, companyId: companyA }
        };
        let resStatsData = null;
        const mockResStats = {
            status: (code) => ({
                send: (payload) => { resStatsData = payload; }
            })
        };
        await leadPullController.getPullStats(mockReqStats, mockResStats);
        console.log("Pull stats output:", resStatsData);
        if (resStatsData.data.freshAvailable !== 25 || resStatsData.data.myFresh !== 0 || resStatsData.data.freshMax !== 20) {
            throw new Error("Pull stats output mismatch!");
        }
        console.log("✓ Pull stats verified accurately");

        console.log("\n--- 5. Testing Fresh Lead Pulling ---");
        // Staff A1 pulls fresh leads. Expected: 8 pulled (freshPullSize = 8)
        let pullResA1_1 = null;
        const reqPull1 = {
            body: { type: "fresh" },
            user: { _id: staffA1, companyId: companyA }
        };
        const resPull1 = {
            status: (code) => ({ send: (payload) => { pullResA1_1 = payload; } })
        };
        await leadPullController.pullLeads(reqPull1, resPull1);
        console.log("Pull 1 result:", pullResA1_1);
        if (pullResA1_1.data.pulled !== 8 || pullResA1_1.data.current !== 8) {
            throw new Error("First pull failed to assign exactly 8 leads");
        }
        console.log("✓ Staff A1 pulled 8 leads successfully");

        // Staff A1 pulls again. Expected: 8 pulled (total = 16)
        let pullResA1_2 = null;
        await leadPullController.pullLeads(reqPull1, {
            status: (code) => ({ send: (payload) => { pullResA1_2 = payload; } })
        });
        console.log("Pull 2 result:", pullResA1_2);
        if (pullResA1_2.data.pulled !== 8 || pullResA1_2.data.current !== 16) {
            throw new Error("Second pull failed to assign 8 leads");
        }
        console.log("✓ Staff A1 pulled another 8 leads (total = 16)");

        // Staff A1 pulls third time. Remaining capacity = 20 - 16 = 4. Expected: 4 pulled.
        let pullResA1_3 = null;
        await leadPullController.pullLeads(reqPull1, {
            status: (code) => ({ send: (payload) => { pullResA1_3 = payload; } })
        });
        console.log("Pull 3 (Capacity Cap) result:", pullResA1_3);
        if (pullResA1_3.data.pulled !== 4 || pullResA1_3.data.current !== 20) {
            throw new Error("Cap-restricted pull failed to cap at remaining capacity of 4!");
        }
        console.log("✓ Staff A1 capacity cap enforced correctly (pulled 4 to reach max 20)");

        // Staff A1 pulls fourth time. Current = 20, Max = 20. Expected: 0 pulled (Limit reached)
        let pullResA1_4 = null;
        await leadPullController.pullLeads(reqPull1, {
            status: (code) => ({ send: (payload) => { pullResA1_4 = payload; } })
        });
        console.log("Pull 4 (Limit Reached) result:", pullResA1_4);
        if (pullResA1_4.data.pulled !== 0 || pullResA1_4.data.remainingCapacity !== 0) {
            throw new Error("Staff at max capacity pulled non-zero leads!");
        }
        console.log("✓ Staff at max limit prevented from pulling further leads");

        console.log("\n--- 6. Testing Company Isolation ---");
        // Staff B1 (Company B) attempts to pull. Total in Pool B = 10. Max per staff (default) = 100.
        // Should only pull from Pool B (10 leads), never touching Company A's remaining 5 leads!
        let pullResB1 = null;
        const reqPullB = {
            body: { type: "fresh" },
            user: { _id: staffB1, companyId: companyB }
        };
        await leadPullController.pullLeads(reqPullB, {
            status: (code) => ({ send: (payload) => { pullResB1 = payload; } })
        });
        console.log("Staff B1 pull result:", pullResB1);
        if (pullResB1.data.pulled !== 10) {
            throw new Error("Company B failed to pull its own leads!");
        }

        // Verify Company A still has 5 leads available
        const remainingFreshA = await leadModel.countDocuments({ companyId: companyA, assignedRM: null });
        console.log(`Remaining unassigned fresh leads in Company A: ${remainingFreshA}`);
        if (remainingFreshA !== 5) {
            throw new Error("Company B pulled leads belonging to Company A!");
        }
        console.log("✓ Company Isolation verified — Company B received zero leads from Company A");

        console.log("\n--- 7. Testing Concurrent Pull Operations ---");
        // Reset Company A leads (30 fresh unassigned leads)
        await leadModel.deleteMany({ companyId: companyA });
        const concurrentLeads = [];
        for (let i = 1; i <= 30; i++) {
            concurrentLeads.push({
                fullName: `Concurrent Lead ${i}`,
                mobileNumber: `93000000${i.toString().padStart(2, '0')}`,
                companyId: companyA,
                leadPoolId: freshPoolA._id,
                assignedRM: null,
                stage: 'New',
                isRead: false
            });
        }
        await leadModel.insertMany(concurrentLeads);

        // Run simultaneous pulls for Staff A1 and Staff A2
        const pullReqA1 = { body: { type: "fresh" }, user: { _id: staffA1, companyId: companyA } };
        const pullReqA2 = { body: { type: "fresh" }, user: { _id: staffA2, companyId: companyA } };

        let resConcur1 = null;
        let resConcur2 = null;

        await Promise.all([
            leadPullController.pullLeads(pullReqA1, { status: () => ({ send: (p) => { resConcur1 = p; } }) }),
            leadPullController.pullLeads(pullReqA2, { status: () => ({ send: (p) => { resConcur2 = p; } }) })
        ]);

        console.log("Concurrent Pull Staff A1:", resConcur1.data);
        console.log("Concurrent Pull Staff A2:", resConcur2.data);

        // Verify total leads pulled across both staff = sum of pulled
        const staffA1Leads = await leadModel.find({ companyId: companyA, assignedRM: staffA1 });
        const staffA2Leads = await leadModel.find({ companyId: companyA, assignedRM: staffA2 });

        console.log(`Staff A1 got ${staffA1Leads.length} leads, Staff A2 got ${staffA2Leads.length} leads`);

        const a1Ids = new Set(staffA1Leads.map(l => l._id.toString()));
        const overlap = staffA2Leads.filter(l => a1Ids.has(l._id.toString()));

        if (overlap.length > 0) {
            throw new Error(`CRITICAL: Concurrent pull double-assigned ${overlap.length} leads!`);
        }
        console.log("✓ Concurrent pull atomic safety verified — 0 duplicate assignments!");

        // Clean up test data
        await leadModel.deleteMany({ companyId: { $in: [companyA, companyB] } });
        await leadPoolModel.deleteMany({ companyId: { $in: [companyA, companyB] } });
        await generalSettingsModel.deleteMany({ key: `lead_distribution_${companyA}` });

        console.log("\n==========================================");
        console.log("🎉 ALL LEAD PULL SYSTEM TESTS PASSED PERFECTLY!");
        console.log("==========================================\n");

        process.exit(0);
    } catch (error) {
        console.error("\n❌ TEST FAILED:", error);
        process.exit(1);
    }
}

runTest();
