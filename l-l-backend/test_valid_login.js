import mongoose from "mongoose";
import axios from "axios";
import * as dotenv from "dotenv";
dotenv.config();

import staffModel from "./app/models/staffModel.js";

async function run() {
    try {
        await mongoose.connect(process.env.DB_URL);
        const staff = await staffModel.findOne({
            $or: [
                { mobileNumber: 9669192889 },
                { mobileNumber: 919669192889 }
            ]
        });
        if (!staff) {
            console.log("Staff member not found in database.");
            process.exit(1);
        }
        console.log(`Found staff member: ${staff.fullName}, MPIN: ${staff.mpin}`);

        console.log("Attempting API login with phone: '919669192889'...");
        try {
            const response = await axios.post("http://localhost:8080/api/staff/staff-mpin-login", {
                phone: "919669192889",
                mpin: staff.mpin
            });
            console.log("API Response Status:", response.status);
            console.log("API Response Body:", response.data);
        } catch (apiError) {
            console.error("API Request Failed!");
            console.error("Status:", apiError.response?.status);
            console.error("Body:", apiError.response?.data);
        }

        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}
run();
