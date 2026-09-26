import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import departmentService from "./app/services/departmentService.js";
import departmentModel from "./app/models/departmentModel.js";
import permissionGroupModel from "./app/models/permissionGroupModel.js";
import roleModel from "./app/models/roleModel.js";
import staffModel from "./app/models/staffModel.js";

async function main() {
    try {
        await mongoose.connect(process.env.DB_URL);
        console.log("Connected to MongoDB for department seeding.");

        // 1. Seed standard departments
        await departmentService.seedDefaultDepartments();

        const adminDept = await departmentModel.findOne({ code: 'ADMIN' });
        const researchDept = await departmentModel.findOne({ code: 'RESEARCH' });
        const salesDept = await departmentModel.findOne({ code: 'SALES' });
        const opsDept = await departmentModel.findOne({ code: 'OPERATIONS' });

        console.log("Departments found:", {
            admin: adminDept?._id,
            research: researchDept?._id,
            sales: salesDept?._id,
            ops: opsDept?._id
        });

        // 2. Link existing permission groups if unassigned
        if (adminDept) {
            await permissionGroupModel.updateMany(
                { name: { $regex: /^admin$/i }, departmentId: null },
                { $set: { departmentId: adminDept._id } }
            );
            await roleModel.updateMany(
                { name: { $regex: /^admin$/i }, departmentId: null },
                { $set: { departmentId: adminDept._id } }
            );
        }

        if (researchDept) {
            await permissionGroupModel.updateMany(
                { name: { $regex: /research/i }, departmentId: null },
                { $set: { departmentId: researchDept._id } }
            );
            await roleModel.updateMany(
                { name: { $regex: /research/i }, departmentId: null },
                { $set: { departmentId: researchDept._id } }
            );
        }

        if (salesDept) {
            await permissionGroupModel.updateMany(
                { name: { $regex: /(sales|manager|director|rm|caller)/i }, departmentId: null },
                { $set: { departmentId: salesDept._id } }
            );
            await roleModel.updateMany(
                { name: { $regex: /(sales|manager|director|rm|caller)/i }, departmentId: null },
                { $set: { departmentId: salesDept._id } }
            );
        }

        // 3. Link existing staff members by matching deparment string to department name
        const departments = await departmentModel.find({});
        for (const dept of departments) {
            const regex = new RegExp(`^\\s*${dept.name}\\s*$`, 'i');
            const codeRegex = new RegExp(`^\\s*${dept.code}\\s*$`, 'i');
            await staffModel.updateMany(
                {
                    departmentId: null,
                    $or: [
                        { deparment: { $regex: regex } },
                        { deparment: { $regex: codeRegex } }
                    ]
                },
                { $set: { departmentId: dept._id } }
            );
        }

        // Handle common staff department strings like "Researcher" -> "Research & Advisory"
        if (researchDept) {
            await staffModel.updateMany(
                { departmentId: null, deparment: { $regex: /research/i } },
                { $set: { departmentId: researchDept._id } }
            );
        }
        if (salesDept) {
            await staffModel.updateMany(
                { departmentId: null, deparment: { $regex: /(sales|manager|director)/i } },
                { $set: { departmentId: salesDept._id } }
            );
        }
        if (adminDept) {
            await staffModel.updateMany(
                { departmentId: null, deparment: { $regex: /admin/i } },
                { $set: { departmentId: adminDept._id } }
            );
        }

        console.log("Seeding & migration completed successfully.");
        process.exit(0);
    } catch (err) {
        console.error("Seeding error:", err);
        process.exit(1);
    }
}

main();
