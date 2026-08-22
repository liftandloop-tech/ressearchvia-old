import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import roleModel from "./app/models/roleModel.js";

async function run() {
    try {
        await mongoose.connect(process.env.DB_URL);
        const roles = await roleModel.find({});
        console.log("=== Dynamic Roles in Database ===");
        console.log(roles.map(r => ({ id: r._id, name: r.name })));
        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
run();
