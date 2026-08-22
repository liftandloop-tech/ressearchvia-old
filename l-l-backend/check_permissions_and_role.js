import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import staffModel from "./app/models/staffModel.js";
import roleModel from "./app/models/roleModel.js";
import permissionGroupModel from "./app/models/permissionGroupModel.js";

async function run() {
    try {
        await mongoose.connect(process.env.DB_URL);
        console.log("Connected to DB.");

        const staff = await staffModel.findOne({
            $or: [
                { mobileNumber: 9669192889 },
                { mobileNumber: 919669192889 }
            ]
        });

        if (!staff) {
            console.log("Staff ABHISHEK OJHA not found.");
            process.exit(1);
        }

        console.log("\n================ Staff Profile ================");
        console.log("Name:", staff.fullName);
        console.log("Department/Role string:", staff.deparment);
        console.log("roleId:", staff.roleId);

        if (staff.roleId) {
            const role = await roleModel.findById(staff.roleId).populate("permissionGroups");
            if (role) {
                console.log("\n================ Role Details ================");
                console.log("Role Name:", role.name);
                console.log("Description:", role.description);
                console.log("Permission Groups Count:", role.permissionGroups.length);

                for (const pg of role.permissionGroups) {
                    console.log(`\n- Permission Group: ${pg.name} (${pg.description})`);
                    console.log("Permissions:", JSON.stringify(pg.permissions, null, 2));
                }
            } else {
                console.log("Role document not found in DB for roleId:", staff.roleId);
            }
        } else {
            console.log("No roleId assigned to this staff member.");
        }

        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

run();
