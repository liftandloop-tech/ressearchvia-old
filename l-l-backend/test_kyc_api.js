import mongoose from "mongoose";
import dotenv from "dotenv";
import jwt from "jsonwebtoken";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, ".env") });

async function runTest() {
    await mongoose.connect(process.env.DB_URL);
    const db = mongoose.connection.db;

    const admin = await db.collection("users").findOne({ userType: "super_admin" });
    if (!admin) {
        console.log("No admin found");
        process.exit(1);
    }

    const token = jwt.sign(
        {
            _id: admin._id,
            userObject: admin.userObject,
            fullName: admin.fullName,
            phone: admin.phone,
            userType: admin.userType,
            type: 'ACCESS'
        },
        process.env.JWT_TOKEN,
        { expiresIn: '1h' }
    );

    const testUser = await db.collection("users").findOne({ userType: "user" });

    console.log("=========================================");
    console.log("TEST DATA READY");
    console.log("Admin Token:", token);
    console.log("Test User ID:", testUser._id.toString());
    console.log("Test User Phone:", testUser.phone);
    console.log("=========================================\n");

    const baseUrl = "http://localhost:8080/api";

    async function apiCall(method, endpoint, body = null, useAuth = true) {
        const headers = { "Content-Type": "application/json" };
        if (useAuth) headers["Authorization"] = `Bearer ${token}`;

        try {
            const response = await fetch(`${baseUrl}${endpoint}`, {
                method,
                headers,
                body: body ? JSON.stringify(body) : undefined
            });
            const text = await response.text();
            let data;
            try {
                data = JSON.parse(text);
            } catch (e) {
                data = { rawText: text };
            }
            return { status: response.status, data };
        } catch (err) {
            return { status: 500, data: { error: err.message } };
        }
    }

    const userId = testUser._id.toString();

    console.log("Test 1: Reject Document Gate");
    let res = await apiCall("PUT", `/user/kyc/gate-status/${userId}`, {
        gate: "documents",
        status: "REJECTED",
        reason: "Blurry PAN card"
    });
    console.log("Result:", JSON.stringify(res.data, null, 2));

    console.log("\nTest 2: Validation Check (no reason)");
    res = await apiCall("PUT", `/user/kyc/gate-status/${userId}`, {
        gate: "documents",
        status: "REJECTED"
    });
    console.log("Result (expect 400):", res.status, res.data.message);

    console.log("\nTest 3: Get User Details (should show REJECTED + reason)");
    res = await apiCall("GET", `/user/user-details/${userId}`);
    console.log("Next Step:", res.data?.data?.nextStep);
    console.log("Reason:", res.data?.data?.rejectionReason);

    console.log("\nTest 4: Verify Documents Gate");
    res = await apiCall("PUT", `/user/kyc/gate-status/${userId}`, {
        gate: "documents",
        status: "VERIFIED"
    });
    console.log("Result:", JSON.stringify(res.data, null, 2));

    console.log("\nTest 5: Get User Details again (should move to next step)");
    res = await apiCall("GET", `/user/user-details/${userId}`);
    console.log("Next Step:", res.data?.data?.nextStep);

    console.log("\nTest 6: Verify all gates");
    await apiCall("PUT", `/user/kyc/gate-status/${userId}`, { gate: "esign", status: "VERIFIED" });
    res = await apiCall("PUT", `/user/kyc/gate-status/${userId}`, { gate: "video", status: "VERIFIED" });
    console.log("Final Overall Status:", res.data?.data?.overallKycStatus);

    console.log("\nTest 7: Final Get User Details");
    res = await apiCall("GET", `/user/user-details/${userId}`);
    console.log("Next Step:", res.data?.data?.nextStep);

    process.exit(0);
}

runTest().catch(console.error);
