import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import staffModel from "./app/models/staffModel.js";
import roleModel from "./app/models/roleModel.js";

async function run() {
    try {
        console.log("Connecting to database...");
        await mongoose.connect(process.env.DB_URL);
        console.log("Connected.");

        // 1. Restore demoted staff
        const candidates = await staffModel.find({
            stage: 'Applicant',
            $or: [
                { mpin: { $ne: null } },
                { joiningDate: { $ne: null } },
                { roleId: { $ne: null } }
            ]
        });

        console.log(`Found ${candidates.length} staff members eligible for restoration.`);
        for (const staff of candidates) {
            console.log(`Restoring staff member: ${staff.fullName} (ID: ${staff.staffId}) to 'Employee' stage...`);
            staff.stage = 'Employee';
            await staff.save();
            console.log(`✓ Restored.`);
        }

        // 2. Synchronize roleId based on department string
        const allStaff = await staffModel.find({});
        console.log(`\nSyncing roleId for ${allStaff.length} staff members...`);
        for (const staff of allStaff) {
            if (staff.deparment) {
                const trimmedDept = staff.deparment.trim();
                
                // If department is trimmed, save the trimmed version back to DB
                if (staff.deparment !== trimmedDept) {
                    staff.deparment = trimmedDept;
                }

                const matchingRole = await roleModel.findOne({ name: { $regex: new RegExp(`^\\s*${trimmedDept}\\s*$`, 'i') } });
                if (matchingRole) {
                    if (!staff.roleId || staff.roleId.toString() !== matchingRole._id.toString()) {
                        staff.roleId = matchingRole._id;
                        await staff.save();
                        console.log(`✓ Updated roleId for ${staff.fullName} to: ${matchingRole.name} (${matchingRole._id})`);
                    } else {
                        console.log(`- ${staff.fullName} already has correct roleId for department: ${trimmedDept}`);
                    }
                } else {
                    console.log(`x No matching role found for ${staff.fullName}'s department: "${trimmedDept}"`);
                }
            } else {
                console.log(`x ${staff.fullName} has no department assigned.`);
            }
        }

        console.log("\nDatabase update and role synchronization complete.");
        process.exit(0);
    } catch (error) {
        console.error("Error during restoration:", error);
        process.exit(1);
    }
}

run();
