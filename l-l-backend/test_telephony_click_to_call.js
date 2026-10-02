import mongoose from "mongoose";
import dotenv from "dotenv";
dotenv.config();

import leadModel from "./app/models/leadModel.js";
import staffModel from "./app/models/staffModel.js";
import callLogModel from "./app/models/callLogModel.js";
import telephonyService from "./app/services/telephonyService.js";

async function runTest() {
    console.log("=== Testing Click-to-Call Telephony Integration ===");
    const mongoUri = process.env.DB_URL || "mongodb://localhost:27017/researchvia";
    await mongoose.connect(mongoUri);
    console.log("Connected to MongoDB");

    try {
        // 1. Create or find dummy lead & staff
        let staff = await staffModel.findOne({ status: 'Active' });
        if (!staff) {
            staff = await staffModel.create({
                staffId: "STF_TEST_01",
                fullName: "Agent Test",
                mobileNumber: 9876543210,
                emailAddress: "agent.test@example.com",
                telephonyExtension: "101"
            });
        } else if (!staff.telephonyExtension) {
            staff.telephonyExtension = "101";
            await staff.save();
        }

        let lead = await leadModel.findOne();
        if (!lead) {
            lead = await leadModel.create({
                fullName: "Customer Lead Test",
                mobileNumber: "9876500001",
                emailAddress: "lead.test@example.com",
                assignedRM: staff._id
            });
        }

        console.log(`Using Staff: ${staff.fullName} (Ext: ${staff.telephonyExtension})`);
        console.log(`Using Lead: ${lead.fullName} (Phone: ${lead.mobileNumber})`);

        // 2. Test initiateClickToDial
        const callResult = await telephonyService.initiateClickToDial({
            fromDestination: staff.telephonyExtension,
            fromType: 'extension',
            toDestination: lead.mobileNumber,
            leadId: lead._id,
            staffId: staff._id
        });

        console.log("✓ initiateClickToDial succeeded:");
        console.log(`  Call ID: ${callResult.callId}`);
        console.log(`  Initial Status: ${callResult.callLog.status}`);

        // 3. Test getCallStatus
        const statusResult = await telephonyService.getCallStatus(callResult.callId);
        console.log(`✓ getCallStatus: ${statusResult.status}`);

        // 4. Test terminateCall
        const hangupResult = await telephonyService.terminateCall(callResult.callId);
        console.log(`✓ terminateCall: ${hangupResult.status}, duration: ${hangupResult.durationSeconds}s`);

        // 5. Test logFollowUpFromCall
        const followUpResult = await telephonyService.logFollowUpFromCall(callResult.callLog._id, {
            notes: "Lead is interested in Nifty Options strategy. Call duration: 45s.",
            status: "Completed",
            stage: "Interested",
            nextFollowUpDate: new Date(Date.now() + 86400000 * 2)
        });

        console.log("✓ logFollowUpFromCall succeeded:");
        console.log(`  Lead stage updated to: ${followUpResult.lead.stage}`);
        console.log(`  Follow-ups count: ${followUpResult.lead.followUps.length}`);
        const lastFollowUp = followUpResult.lead.followUps[followUpResult.lead.followUps.length - 1];
        console.log(`  Last follow-up type: ${lastFollowUp.followUpType}, notes: ${lastFollowUp.notes}`);

        // Clean up test callLog
        await callLogModel.findByIdAndDelete(callResult.callLog._id);
        console.log("✓ Cleanup finished. Telephony tests PASSED!");
    } catch (err) {
        console.error("Test failed:", err);
    } finally {
        await mongoose.disconnect();
    }
}

runTest();
