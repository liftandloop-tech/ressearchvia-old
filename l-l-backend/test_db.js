import mongoose from "mongoose";
import * as dotenv from "dotenv";
dotenv.config();

import segmentsPlanModel from "./app/models/segmentsPlansModel.js";

async function run() {
    await mongoose.connect(process.env.DB_URL);
    const plans = await segmentsPlanModel.find().lean().limit(1);
    console.log(JSON.stringify(plans, null, 2));
    process.exit(0);
}
run();
