import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import roleModel from "./app/models/roleModel.js";
import staffModel from "./app/models/staffModel.js";

const rolesToSeed = [
    'Director',
    'Researcher',
    'Research Analyst',
    'Executive',
    'Manager',
    'Advisory',
    'Compliance',
    'Sales',
    'Support'
];

async function run() {
    try {
        console.log("Connecting to database...");
        await mongoose.connect(process.env.DB_URL);
        console.log("Connected.");

        // 1. Clean up legacy 'director ' role name trailing space if it exists
        const legacyDirectorRole = await roleModel.findOne({ name: 'director ' });
        if (legacyDirectorRole) {
            console.log("Found legacy 'director ' role. Renaming to 'Director'...");
            legacyDirectorRole.name = 'Director';
            await legacyDirectorRole.save();
            console.log("✓ Renamed.");
        }

        // 2. Seed all other standard roles
        for (const roleName of rolesToSeed) {
            const existing = await roleModel.findOne({ name: { $regex: new RegExp(`^\\s*${roleName}\\s*$`, 'i') } });
            if (!existing) {
                console.log(`Creating missing role: '${roleName}'...`);
                await roleModel.create({
                    name: roleName,
                    description: `Default ${roleName} Role`,
                    permissionGroups: []
                });
                console.log(`✓ Created.`);
            } else {
                console.log(`- Role '${roleName}' already exists.`);
            }
        }

        // 3. Sync roleId database-wide for all staff
        const allStaff = await staffModel.find({});
        console.log(`\nSyncing roleId for all ${allStaff.length} staff members...`);
        for (const staff of allStaff) {
            if (staff.deparment) {
                const trimmedDept = staff.deparment.trim();
                
                // Save trimmed department name
                if (staff.deparment !== trimmedDept) {
                    staff.deparment = trimmedDept;
                }

                const matchingRole = await roleModel.findOne({ name: { $regex: new RegExp(`^\\s*${trimmedDept}\\s*$`, 'i') } });
                if (matchingRole) {
                    staff.roleId = matchingRole._id;
                    staff.stage = 'Employee';
                    await staff.save();
                    console.log(`✓ Synced ${staff.fullName} to Role: ${matchingRole.name} (${matchingRole._id})`);
                } else {
                    console.log(`x No matching role found for ${staff.fullName}'s department: "${trimmedDept}"`);
                }
            } else {
                console.log(`x ${staff.fullName} has no department assigned.`);
            }
        }

        console.log("\nAll roles successfully seeded and staff records synced.");
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

run();
