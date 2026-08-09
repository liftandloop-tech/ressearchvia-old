import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import reportModel from "./app/models/reportsModel.js";

async function run() {
    await mongoose.connect(process.env.DB_URL);
    const reports = await reportModel.find({ segment: { $exists: true, $not: {$size: 0} } }).select('title segment planArray').limit(10).lean();
    console.log("Sample Reports:", JSON.stringify(reports, null, 2));
    process.exit(0);
}
run();
