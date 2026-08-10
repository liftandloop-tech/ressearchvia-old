import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import importService from "./app/services/importService.js";
import importJobModel from "./app/models/importJobModel.js";
import leadModel from "./app/models/leadModel.js";
import staffModel from "./app/models/staffModel.js";

async function run() {
    try {
        console.log("Connecting to database...");
        await mongoose.connect(process.env.DB_URL);
        console.log("Connected.");

        // Clean up previous test leads
        await leadModel.deleteMany({ mobileNumber: { $in: ['9876543210', '9876543211', '9876543212'] } });

        // 1. Fetch Dynamic Lead Fields
        console.log("\n--- Testing dynamic fields metadata ---");
        const fields = importService.LEAD_IMPORT_FIELDS;
        console.log(`✓ Fields retrieved: ${fields.map(f => f.key).join(", ")}`);

        // 2. Validate Suggestions Matching Engine
        console.log("\n--- Testing matching suggestion logic ---");
        const mockColumns = [
            { index: 1, letter: "A", header: "Customer Name", sampleValues: ["Rahul"] },
            { index: 2, letter: "B", header: "Mobile Number", sampleValues: ["9876543210"] },
            { index: 3, letter: "C", header: "E-mail Address", sampleValues: ["rahul@gmail.com"] },
            { index: 4, letter: "D", header: "City Name", sampleValues: ["Indore"] }
        ];

        const suggestions = importService.calculateSuggestions(mockColumns);
        console.log("Suggestions computed:", JSON.stringify(suggestions, null, 2));

        if (suggestions.fullName?.columnIndex !== 1 || suggestions.mobileNumber?.columnIndex !== 2) {
            throw new Error("Suggestions logic is incorrect.");
        }
        console.log("✓ Correct suggestions resolved with high confidence.");

        // 3. Setup mock import file data
        console.log("\n--- Setting up import job context ---");
        const mockStaff = await staffModel.findOne();
        if (!mockStaff) {
            throw new Error("Need at least one staff record in DB to run test.");
        }

        // Create a fake CSV file for testing
        const tempFilePath = "./scratch_leads_test.csv";
        const csvData = "Name,Mobile,Email,City,State\nRahul,9876543210,rahul@gmail.com,Indore,MP\nAmit,9876543211,amit@gmail.com,Bhopal,MP\nInvalidRow,,invalid-email,,\nDuplicateRahul,9876543210,rahul.new@gmail.com,Indore,MP\n";
        fs.writeFileSync(tempFilePath, csvData);

        const { sheetNames, previewRows, columnPreview } = await importService.parseUploadedFile(tempFilePath, 'csv');
        console.log("✓ Parsed file metadata.");
        console.log(`  Sheets: ${sheetNames}`);
        console.log(`  Columns found: ${columnPreview.map(c => c.header).join(", ")}`);

        const job = await importJobModel.create({
            userId: mockStaff._id,
            fileName: "scratch_leads_test.csv",
            filePath: tempFilePath,
            status: 'mapping_required',
            sheetNames,
            columnPreview,
            previewRows
        });

        // Set mapping config
        const resolvedMappings = {};
        for (const field of fields) {
            const match = columnPreview.find(c => {
                const h = c.header.toLowerCase();
                return h.includes(field.key.toLowerCase()) || 
                       h.includes(field.label.toLowerCase()) ||
                       (field.key === 'fullName' && h === 'name') ||
                       (field.key === 'mobileNumber' && h === 'mobile');
            });
            if (match) {
                resolvedMappings[field.key] = match.index;
            }
        }

        job.mapping = resolvedMappings;
        job.importOptions = {
            duplicateHandling: 'skip',
            stage: 'New'
        };
        await job.save();

        // 4. Run Import Processor
        console.log("\n--- Running background Import processor ---");
        await importService.runImportJob(job._id);

        const finishedJob = await importJobModel.findById(job._id);
        console.log(`Import status: ${finishedJob.status}`);
        console.log(`Total rows: ${finishedJob.totalRows}`);
        console.log(`Successful: ${finishedJob.successfulRows}`);
        console.log(`Failed: ${finishedJob.failedRows}`);
        console.log(`Duplicates skipped/updated: ${finishedJob.duplicateRows}`);
        console.log("Errors logged:", JSON.stringify(finishedJob.errors, null, 2));

        if (finishedJob.successfulRows !== 2 || finishedJob.failedRows !== 1 || finishedJob.duplicateRows !== 1) {
            throw new Error("Import job processed rows incorrectly.");
        }
        console.log("✓ Dynamic batch validation & deduplication rules working correctly.");

        // Check DB documents
        const rahul = await leadModel.findOne({ mobileNumber: '9876543210' });
        if (!rahul || rahul.fullName !== 'Rahul' || rahul.personalDetails?.city !== 'Indore') {
            throw new Error("Lead doc structure is corrupted or not created.");
        }
        console.log("✓ Lead records correctly normalized and saved to standard Mongoose Lead model.");

        // Clean up
        if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
        await importJobModel.findByIdAndDelete(job._id);
        await leadModel.deleteMany({ mobileNumber: { $in: ['9876543210', '9876543211'] } });

        console.log("\nALL BACKEND IMPORT TESTS PASSED SUCCESSFULLY!");
        process.exit(0);
    } catch (error) {
        console.error("\n❌ IMPORT TEST FAILED:", error);
        process.exit(1);
    }
}

import fs from "fs";
run();
