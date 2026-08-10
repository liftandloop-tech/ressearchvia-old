import mongoose from "mongoose";
import xlsx from "xlsx";
import fs from "fs";
import * as dotenv from "dotenv";
dotenv.config();

import importService from "./app/services/importService.js";
import importJobModel from "./app/models/importJobModel.js";
import leadModel from "./app/models/leadModel.js";
import staffModel from "./app/models/staffModel.js";
import leadPoolModel from "./app/models/leadPoolModel.js";
import importController from "./app/controller/importController.js";

async function run() {
    console.log("Running integration test with Company Isolation...");
    
    // Connect to database
    await mongoose.connect(process.env.DB_URL);
    console.log("Connected to MongoDB.");

    // Drop legacy unique index if it exists in MongoDB
    try {
        await mongoose.connection.collection("leadpools").dropIndex("name_1");
        console.log("✓ Dropped legacy name_1 unique index.");
    } catch (e) {
        // Ignore if index doesn't exist
    }

    // Clean up test leads and pools
    await leadModel.deleteMany({ mobileNumber: { $in: ['9876543210', '9876543211', '9876543212'] } });
    await leadPoolModel.deleteMany({ name: { $in: ["Isolated Pool", "Company B Pool", "Test Integration Pool"] } });

    const mockStaff = await staffModel.findOne();
    if (!mockStaff) {
        console.error("No staff found in DB. Test cannot proceed.");
        process.exit(1);
    }

    let results = {
        sameNameDifferentCompanies: false,
        crossCompanyPoolProtection: false,
        importWithoutPool: false,
        importWithPool: false,
        duplicateUpdateWithPool: false,
        duplicateUpdateWithoutPool: false
    };

    try {
        // --- 1. SAME NAME, DIFFERENT COMPANIES ---
        console.log("\nTesting same name creation across different companies...");
        const poolA = await leadPoolModel.create({
            companyId: "company_a",
            name: "Isolated Pool",
            description: "Belongs to Company A"
        });
        const poolB = await leadPoolModel.create({
            companyId: "company_b",
            name: "Isolated Pool",
            description: "Belongs to Company B"
        });

        if (poolA && poolB) {
            results.sameNameDifferentCompanies = true;
            console.log("✓ Same name, different companies: PASS");
        } else {
            console.log("✗ Same name, different companies: FAIL");
        }

        // --- 2. CROSS-COMPANY POOL ATTACK PROTECTION ---
        console.log("\nTesting cross-company pool selection attack protection...");
        // Mock a request from Company A trying to start import using Company B's pool
        const reqMock = {
            params: { importId: "some_mock_id" },
            body: {
                mapping: { fullName: 1, mobileNumber: 2 },
                importOptions: {
                    leadPoolId: poolB._id.toString() // Company B's pool ID
                }
            },
            user: {
                _id: mockStaff._id,
                companyId: "company_a" // User belongs to Company A
            }
        };

        const resMock = {
            status: function(code) {
                this.statusCode = code;
                return this;
            },
            send: function(payload) {
                this.sentPayload = payload;
                return this;
            }
        };

        // Create import job record for Company A
        const jobAttack = await importJobModel.create({
            userId: mockStaff._id,
            companyId: "company_a",
            fileName: "leads.xlsx",
            filePath: "./leads.xlsx",
            status: "mapping_required"
        });

        reqMock.params.importId = jobAttack._id.toString();

        await importController.startImport(reqMock, resMock);
        console.log("Cross company startImport response code:", resMock.statusCode);
        console.log("Response message:", resMock.sentPayload?.message);

        if (resMock.statusCode === 400 && resMock.sentPayload?.message.includes("belongs to another company")) {
            results.crossCompanyPoolProtection = true;
            console.log("✓ Cross-company pool attack protection: PASS");
        } else {
            console.log("✗ Cross-company pool attack protection: FAIL");
        }

        // Clean up attack job
        await importJobModel.findByIdAndDelete(jobAttack._id);

        // --- 3. IMPORT WITHOUT POOL / WITH POOL ---
        console.log("\nTesting import assignment (with and without pool)...");
        const fileAPath = "./test_excel_a.xlsx";
        const dataA = [
            ["Name", "Mobile Number", "Email Address", "Company", "City"],
            ["Rahul PoolA", "9876543210", "rahul@test.com", "ABC Ltd", "Indore"],
            ["Amit NoPool", "9876543211", "amit@test.com", "XYZ Ltd", "Bhopal"]
        ];
        
        const wbA = xlsx.utils.book_new();
        const wsA = xlsx.utils.aoa_to_sheet(dataA);
        xlsx.utils.book_append_sheet(wbA, wsA, "Leads Sheet");
        xlsx.writeFile(wbA, fileAPath);

        // Run Import with Pool A for Rahul
        const jobRahul = await importJobModel.create({
            userId: mockStaff._id,
            companyId: "company_a",
            fileName: "test_excel_a.xlsx",
            filePath: fileAPath,
            status: "mapping_required",
            mapping: { fullName: 1, mobileNumber: 2, emailAddress: 3, city: 5 },
            importOptions: {
                duplicateHandling: "skip",
                stage: "New",
                leadPoolId: poolA._id
            }
        });

        await importService.runImportJob(jobRahul._id);

        const leadRahul = await leadModel.findOne({ mobileNumber: "9876543210", companyId: "company_a" });
        if (leadRahul && leadRahul.leadPoolId?.toString() === poolA._id.toString()) {
            results.importWithPool = true;
            console.log("✓ Import with pool assignment: PASS");
        } else {
            console.log("✗ Import with pool assignment: FAIL");
        }

        // Run Import without Pool for Amit (file containing Amit)
        // Set filePath again since runImportJob unlinks it
        xlsx.writeFile(wbA, fileAPath);
        await leadModel.deleteMany({ mobileNumber: { $in: ['9876543210', '9876543211'] } });
        const jobAmit = await importJobModel.create({
            userId: mockStaff._id,
            companyId: "company_a",
            fileName: "test_excel_a.xlsx",
            filePath: fileAPath,
            status: "mapping_required",
            mapping: { fullName: 1, mobileNumber: 2, emailAddress: 3, city: 5 },
            importOptions: {
                duplicateHandling: "skip",
                stage: "New",
                leadPoolId: null
            }
        });

        await importService.runImportJob(jobAmit._id);

        const leadAmit = await leadModel.findOne({ mobileNumber: "9876543211", companyId: "company_a" });
        if (leadAmit && leadAmit.leadPoolId === null) {
            results.importWithoutPool = true;
            console.log("✓ Import without pool assignment: PASS");
        } else {
            console.log("✗ Import without pool assignment: FAIL");
        }

        // --- 4. DUPLICATE UPDATE WITH POOL / WITHOUT POOL ---
        console.log("\nTesting Duplicate handling update behaviors...");
        // Pre-create lead with PoolA
        const leadDupTest = await leadModel.findOne({ mobileNumber: "9876543210" }); // Rahul (PoolA)
        
        // Case A: Update duplicate with Pool B
        const fileBPath = "./test_excel_b.xlsx";
        const dataB = [
            ["Name", "Mobile Number"],
            ["Rahul Updated PoolB", "9876543210"]
        ];
        const wbB = xlsx.utils.book_new();
        const wsB = xlsx.utils.aoa_to_sheet(dataB);
        xlsx.utils.book_append_sheet(wbB, wsB, "Leads Sheet");
        xlsx.writeFile(wbB, fileBPath);

        const jobDupWithPool = await importJobModel.create({
            userId: mockStaff._id,
            companyId: "company_a",
            fileName: "test_excel_b.xlsx",
            filePath: fileBPath,
            status: "mapping_required",
            mapping: { fullName: 1, mobileNumber: 2 },
            importOptions: {
                duplicateHandling: "update",
                stage: "New",
                leadPoolId: poolB._id // Try updating lead pool to Pool B
            }
        });

        await importService.runImportJob(jobDupWithPool._id);

        const updatedRahulB = await leadModel.findOne({ mobileNumber: "9876543210", companyId: "company_a" });
        if (updatedRahulB && updatedRahulB.fullName === "Rahul Updated PoolB" && updatedRahulB.leadPoolId?.toString() === poolB._id.toString()) {
            results.duplicateUpdateWithPool = true;
            console.log("✓ Duplicate update with pool: PASS");
        } else {
            console.log("✗ Duplicate update with pool: FAIL");
        }

        // Case B: Update duplicate without Pool (leadPoolId is null in import options)
        // Existing lead now has Pool B. Import should NOT overwrite Pool B back to null.
        xlsx.writeFile(wbB, fileBPath);
        const jobDupWithoutPool = await importJobModel.create({
            userId: mockStaff._id,
            companyId: "company_a",
            fileName: "test_excel_b.xlsx",
            filePath: fileBPath,
            status: "mapping_required",
            mapping: { fullName: 1, mobileNumber: 2 },
            importOptions: {
                duplicateHandling: "update",
                stage: "New",
                leadPoolId: null // No pool selected
            }
        });

        await importService.runImportJob(jobDupWithoutPool._id);

        const updatedRahulNoPoolChange = await leadModel.findOne({ mobileNumber: "9876543210", companyId: "company_a" });
        if (updatedRahulNoPoolChange && updatedRahulNoPoolChange.leadPoolId?.toString() === poolB._id.toString()) {
            results.duplicateUpdateWithoutPool = true;
            console.log("✓ Duplicate update without pool (retains original pool): PASS");
        } else {
            console.log("✗ Duplicate update without pool: FAIL");
        }

        // Clean up files and database
        if (fs.existsSync(fileAPath)) fs.unlinkSync(fileAPath);
        if (fs.existsSync(fileBPath)) fs.unlinkSync(fileBPath);
        await leadPoolModel.deleteMany({ name: "Isolated Pool" });
        await leadModel.deleteMany({ mobileNumber: { $in: ["9876543210", "9876543211"] } });
        await importJobModel.deleteMany({ userId: mockStaff._id });

        console.log("\n=================== INTEGRATION TEST SUMMARY ===================");
        console.log(`Same Name, Diff Companies:  ${results.sameNameDifferentCompanies ? "PASS" : "FAIL"}`);
        console.log(`Cross Company Protection:   ${results.crossCompanyPoolProtection ? "PASS" : "FAIL"}`);
        console.log(`Import Without Pool:        ${results.importWithoutPool ? "PASS" : "FAIL"}`);
        console.log(`Import With Pool:           ${results.importWithPool ? "PASS" : "FAIL"}`);
        console.log(`Duplicate Update With Pool: ${results.duplicateUpdateWithPool ? "PASS" : "FAIL"}`);
        console.log(`Duplicate Update No Pool:   ${results.duplicateUpdateWithoutPool ? "PASS" : "FAIL"}`);
        console.log("================================================================");

        const allPassed = Object.values(results).every(v => v === true);
        if (allPassed) {
            console.log("\nALL LEAD POOL TENANT ISOLATION TESTS PASSED!");
            process.exit(0);
        } else {
            console.log("\nSOME LEAD POOL TESTS FAILED!");
            process.exit(1);
        }
    } catch (error) {
        console.error("\n❌ LEAD POOL TEST ERROR:", error);
        process.exit(1);
    }
}

run();
