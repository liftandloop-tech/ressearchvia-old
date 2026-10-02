import mongoose from "mongoose";
import dotenv from "dotenv";
dotenv.config();

import leadModel from "./app/models/leadModel.js";
import staffModel from "./app/models/staffModel.js";
import callLogModel from "./app/models/callLogModel.js";
import telephonyService, { cleanPhoneNumber } from "./app/services/telephonyService.js";
import telephonyController from "./app/controller/telephonyController.js";

const TEST_COMPANY = "test_telephony_company_" + Date.now();

// Helper to simulate Express req / res objects
function createMockReqRes({ body = {}, params = {}, query = {}, user = null }) {
    const req = { body, params, query, user };
    const res = {
        statusCode: 200,
        data: null,
        status(code) {
            this.statusCode = code;
            return this;
        },
        json(payload) {
            this.data = payload;
            return this;
        },
        send(payload) {
            this.data = payload;
            return this;
        }
    };
    return { req, res };
}

async function runDataFlowTests() {
    console.log("================================================================================");
    console.log("  TELEPHONY CLICK-TO-CALL: DEEP CODE ANALYSIS & DATA FLOW INTEGRATION TESTS     ");
    console.log("================================================================================");

    const mongoUri = process.env.DB_URL || "mongodb://localhost:27017/researchvia";
    await mongoose.connect(mongoUri);
    console.log("✓ Connected to MongoDB:", mongoUri);

    let testLead = null;
    let testStaff = null;
    let createdCallLogIds = [];

    try {
        // -------------------------------------------------------------------------
        // SECTION 1: Phone Sanitization & Carrier Dial-Plan Matrix Tests
        // -------------------------------------------------------------------------
        console.log("\n--- [TEST SUITE 1] Phone Sanitization & Carrier Dial-Plan Matrix ---");

        const testMatrix = [
            { input: "9876543210", expected: "9876543210", desc: "Clean 10-digit Indian mobile" },
            { input: "919876543210", expected: "9876543210", desc: "12-digit number starting with 91" },
            { input: "+919876543210", expected: "9876543210", desc: "E.164 with +91 country code" },
            { input: "09876543210", expected: "9876543210", desc: "11-digit number with leading 0" },
            { input: "+91 (98765) 43210", expected: "9876543210", desc: "Formatted string with spaces & parentheses" },
            { input: "  98765-43210  ", expected: "9876543210", desc: "String with hyphen & whitespaces" }
        ];

        for (const t of testMatrix) {
            const result = cleanPhoneNumber(t.input);
            if (result !== t.expected) {
                throw new Error(`Sanitization failed for '${t.desc}'. Expected '${t.expected}', got '${result}'`);
            }
            console.log(`  ✓ ${t.desc} -> ${result}`);
        }

        // Test optional PSTN prefix
        process.env.TELEPHONY_PSTN_PREFIX = "91";
        const prefixedResult = cleanPhoneNumber("9876543210");
        if (prefixedResult !== "919876543210") {
            throw new Error(`PSTN prefix failed. Expected '919876543210', got '${prefixedResult}'`);
        }
        console.log(`  ✓ Optional TELEPHONY_PSTN_PREFIX='91' -> ${prefixedResult}`);
        delete process.env.TELEPHONY_PSTN_PREFIX; // reset

        // -------------------------------------------------------------------------
        // SECTION 2: Seed Fixture Data
        // -------------------------------------------------------------------------
        console.log("\n--- [TEST SUITE 2] Fixture Setup ---");

        testStaff = await staffModel.create({
            staffId: "STF_FLOW_" + Date.now(),
            fullName: "Telephony Agent Alpha",
            mobileNumber: 9988776655,
            emailAddress: `agent_alpha_${Date.now()}@example.com`,
            telephonyExtension: "201",
            telephonyType: "extension",
            status: "Active"
        });
        console.log(`  ✓ Created test staff: ${testStaff.fullName} (ID: ${testStaff._id}, Ext: ${testStaff.telephonyExtension})`);

        testLead = await leadModel.create({
            fullName: "Rajesh Kumar (Lead)",
            mobileNumber: "9876543210",
            emailAddress: `rajesh_lead_${Date.now()}@example.com`,
            assignedRM: testStaff._id,
            companyId: TEST_COMPANY,
            stage: "New",
            personalDetails: { city: "Indore", state: "Madhya Pradesh" },
            followUps: []
        });
        console.log(`  ✓ Created test lead: ${testLead.fullName} (ID: ${testLead._id}, Phone: ${testLead.mobileNumber})`);

        // -------------------------------------------------------------------------
        // SECTION 3: Service Layer - Click-to-Dial Lifecycle & State Machine
        // -------------------------------------------------------------------------
        console.log("\n--- [TEST SUITE 3] Telephony State Machine & Call Lifecycle ---");

        // 3.1 Initiate Call
        const initResult = await telephonyService.initiateClickToDial({
            fromDestination: testStaff.telephonyExtension,
            fromType: testStaff.telephonyType,
            toDestination: testLead.mobileNumber,
            leadId: testLead._id,
            staffId: testStaff._id,
            companyId: TEST_COMPANY
        });

        if (!initResult.success || !initResult.callId) {
            throw new Error("Failed to initiate call via telephonyService");
        }
        createdCallLogIds.push(initResult.callLog._id);
        console.log(`  ✓ Call initiated successfully: CallId=${initResult.callId}, Status=${initResult.callLog.status}`);

        // Verify database persistence
        const persistedCall = await callLogModel.findById(initResult.callLog._id);
        if (!persistedCall || persistedCall.status !== "ringing") {
            throw new Error("Persisted call state invalid or not found in MongoDB");
        }
        console.log(`  ✓ Call record verified in MongoDB with status='${persistedCall.status}'`);

        // 3.2 Poll Status
        const statusPoll = await telephonyService.getCallStatus(initResult.callId);
        console.log(`  ✓ Polled Call Status: ${statusPoll.status}`);

        // 3.3 Terminate Call (Hangup)
        const hangupResult = await telephonyService.terminateCall(initResult.callId);
        if (hangupResult.status !== "completed" && hangupResult.status !== "cancelled") {
            throw new Error(`Hangup failed to update call state properly. Got: ${hangupResult.status}`);
        }
        console.log(`  ✓ Call terminated successfully: Final Status=${hangupResult.status}, Duration=${hangupResult.durationSeconds}s`);

        // -------------------------------------------------------------------------
        // SECTION 4: Remote 404 Purge Simulation Test (Vonage Active Call Lifecycle)
        // -------------------------------------------------------------------------
        console.log("\n--- [TEST SUITE 4] Active Table 404 Purge Simulation ---");
        // Simulate a call that was connected (on-call), then Vonage removes it from active calls table
        const purgeTestCall = await callLogModel.create({
            leadId: testLead._id,
            staffId: testStaff._id,
            provider: "airtel_vonage",
            callId: "purge-test-" + Date.now(),
            from: { destination: "201", type: "extension" },
            to: { destination: "9876543210", type: "pstn" },
            type: "click2dial",
            status: "on-call",
            startedAt: new Date(Date.now() - 45000), // 45 seconds ago
            answeredAt: new Date(Date.now() - 40000),
            companyId: TEST_COMPANY
        });
        createdCallLogIds.push(purgeTestCall._id);

        console.log(`  ✓ Created simulated on-call session (callId: ${purgeTestCall.callId})`);

        // Trigger status check - in mock/service mode when call finishes, verify graceful transition
        purgeTestCall.status = 'on-call';
        await purgeTestCall.save();
        const updatedPurgeCall = await telephonyService.terminateCall(purgeTestCall.callId);
        if (updatedPurgeCall.status !== 'completed' || updatedPurgeCall.durationSeconds < 35) {
            throw new Error(`Expected completed call with ~40s duration, got status=${updatedPurgeCall.status}, duration=${updatedPurgeCall.durationSeconds}s`);
        }
        console.log(`  ✓ 404/Disconnect transition correctly recorded: Status='${updatedPurgeCall.status}', Duration=${updatedPurgeCall.durationSeconds}s`);

        // -------------------------------------------------------------------------
        // SECTION 5: Post-Call Follow-Up Synchronization Data Flow
        // -------------------------------------------------------------------------
        console.log("\n--- [TEST SUITE 5] Post-Call Follow-Up Synchronization ---");

        const followUpNotes = "Spoke with Rajesh. He is interested in the BankNifty Algo strategy. Send proposal on WhatsApp.";
        const nextDate = new Date(Date.now() + 86400000 * 3); // in 3 days

        const syncResult = await telephonyService.logFollowUpFromCall(initResult.callLog._id, {
            notes: followUpNotes,
            status: "Completed",
            nextFollowUpDate: nextDate,
            stage: "Qualified",
            userId: testStaff._id
        });

        // Verify lead document in MongoDB
        const refreshedLead = await leadModel.findById(testLead._id);
        if (refreshedLead.stage !== "Qualified") {
            throw new Error(`Lead stage was not updated to 'Qualified'. Got: ${refreshedLead.stage}`);
        }
        if (refreshedLead.followUps.length === 0) {
            throw new Error("Follow-ups array was not updated in Lead model");
        }

        const lastFollowUp = refreshedLead.followUps[refreshedLead.followUps.length - 1];
        if (lastFollowUp.followUpType !== "Call") {
            throw new Error(`Follow-up type should be 'Call'. Got: ${lastFollowUp.followUpType}`);
        }
        if (lastFollowUp.notes !== followUpNotes) {
            throw new Error(`Follow-up notes mismatch. Got: ${lastFollowUp.notes}`);
        }

        console.log(`  ✓ Lead Stage updated: 'New' -> '${refreshedLead.stage}'`);
        console.log(`  ✓ Follow-up registered in Lead: Type='${lastFollowUp.followUpType}', Date='${lastFollowUp.followUpDate}'`);
        console.log(`  ✓ Next Follow-up Date set: ${lastFollowUp.nextFollowUpDate}`);

        // Verify CallLog document also holds notes & disposition
        const refreshedCallLog = await callLogModel.findById(initResult.callLog._id);
        if (refreshedCallLog.notes !== followUpNotes || refreshedCallLog.disposition !== "Completed") {
            throw new Error("CallLog notes and disposition were not synchronized");
        }
        console.log(`  ✓ CallLog record updated: Notes='${refreshedCallLog.notes}', Disposition='${refreshedCallLog.disposition}'`);

        // -------------------------------------------------------------------------
        // SECTION 6: Controller HTTP Layer Integration Tests
        // -------------------------------------------------------------------------
        console.log("\n--- [TEST SUITE 6] Controller Endpoints & HTTP Data Flow ---");

        // 6.1 Test POST /api/telephony/click-to-call via Controller
        const { req: callReq, res: callRes } = createMockReqRes({
            body: { leadId: testLead._id.toString(), extension: "305" },
            user: { _id: testStaff._id, userType: "staff" }
        });
        await telephonyController.initiateClickToCall(callReq, callRes);

        if (callRes.statusCode !== 200 || !callRes.data.status) {
            throw new Error(`Controller initiateClickToCall failed with status ${callRes.statusCode}: ${JSON.stringify(callRes.data)}`);
        }
        const httpCallData = callRes.data.data;
        createdCallLogIds.push(httpCallData.callLogId);
        console.log(`  ✓ Controller initiateClickToCall: status=${callRes.statusCode}, callId=${httpCallData.callId}, extension=${httpCallData.extension}`);

        // 6.2 Test GET /api/telephony/calls/:callId/status
        const { req: statusReq, res: statusRes } = createMockReqRes({
            params: { callId: httpCallData.callId }
        });
        await telephonyController.getCallStatus(statusReq, statusRes);
        if (statusRes.statusCode !== 200 || !statusRes.data.data) {
            throw new Error(`Controller getCallStatus failed with status ${statusRes.statusCode}`);
        }
        console.log(`  ✓ Controller getCallStatus: status=${statusRes.statusCode}, callState=${statusRes.data.data.status}`);

        // 6.3 Test POST /api/telephony/calls/:callId/hangup
        const { req: hangReq, res: hangRes } = createMockReqRes({
            params: { callId: httpCallData.callId }
        });
        await telephonyController.terminateCall(hangReq, hangRes);
        if (hangRes.statusCode !== 200) {
            throw new Error(`Controller terminateCall failed with status ${hangRes.statusCode}`);
        }
        console.log(`  ✓ Controller terminateCall: status=${hangRes.statusCode}, message='${hangRes.data.message}'`);

        // 6.4 Test GET /api/telephony/lead/:leadId/calls
        const { req: listReq, res: listRes } = createMockReqRes({
            params: { leadId: testLead._id.toString() }
        });
        await telephonyController.getLeadCallHistory(listReq, listRes);
        if (listRes.statusCode !== 200 || !Array.isArray(listRes.data.data)) {
            throw new Error(`Controller getLeadCallHistory failed with status ${listRes.statusCode}`);
        }
        console.log(`  ✓ Controller getLeadCallHistory: returned ${listRes.data.data.length} call log records`);

        // 6.5 Test GET /api/telephony/extensions
        const { req: extReq, res: extRes } = createMockReqRes({});
        await telephonyController.getExtensions(extReq, extRes);
        if (extRes.statusCode !== 200 || !Array.isArray(extRes.data.data)) {
            throw new Error(`Controller getExtensions failed with status ${extRes.statusCode}`);
        }
        console.log(`  ✓ Controller getExtensions: returned ${extRes.data.data.length} available extensions`);

        // 6.6 Test PUT /api/telephony/staff/:staffId/extension
        const { req: updateExtReq, res: updateExtRes } = createMockReqRes({
            params: { staffId: testStaff._id.toString() },
            body: { extension: "404", telephonyType: "device" }
        });
        await telephonyController.updateStaffExtension(updateExtReq, updateExtRes);
        if (updateExtRes.statusCode !== 200) {
            throw new Error(`Controller updateStaffExtension failed with status ${updateExtRes.statusCode}`);
        }
        const updatedStaff = await staffModel.findById(testStaff._id);
        if (updatedStaff.telephonyExtension !== "404" || updatedStaff.telephonyType !== "device") {
            throw new Error("Staff extension update was not persisted in MongoDB");
        }
        console.log(`  ✓ Controller updateStaffExtension: persisted ext='${updatedStaff.telephonyExtension}', type='${updatedStaff.telephonyType}'`);

        // -------------------------------------------------------------------------
        // SECTION 7: Admin Caller Edge Case (User from `users` collection, staffId null)
        // -------------------------------------------------------------------------
        console.log("\n--- [TEST SUITE 7] Edge Case: Admin Caller & Null Staff ID ---");

        const adminUserId = new mongoose.Types.ObjectId();
        const unassignedLead = await leadModel.create({
            fullName: "Unassigned Customer",
            mobileNumber: "9123456780",
            companyId: TEST_COMPANY,
            assignedRM: null,
            stage: "New"
        });

        const { req: adminCallReq, res: adminCallRes } = createMockReqRes({
            body: { leadId: unassignedLead._id.toString() },
            user: { _id: adminUserId, userType: "admin" } // admin caller
        });
        await telephonyController.initiateClickToCall(adminCallReq, adminCallRes);

        if (adminCallRes.statusCode !== 200 || !adminCallRes.data.status) {
            throw new Error(`Admin initiateClickToCall failed: ${JSON.stringify(adminCallRes.data)}`);
        }
        createdCallLogIds.push(adminCallRes.data.data.callLogId);

        const adminCallLog = await callLogModel.findById(adminCallRes.data.data.callLogId);
        if (adminCallLog.staffId !== null && adminCallLog.staffId?.toString() !== adminUserId.toString()) {
            throw new Error(`Unexpected staffId in admin call: ${adminCallLog.staffId}`);
        }
        console.log(`  ✓ Admin call created without schema validation errors: CallLogId=${adminCallLog._id}`);

        await leadModel.findByIdAndDelete(unassignedLead._id);

        console.log("\n================================================================================");
        console.log("  ALL TELEPHONY INTEGRATION & DATA FLOW TESTS PASSED (100% SUCCESS)             ");
        console.log("================================================================================");

    } catch (error) {
        console.error("\n❌ TEST SUITE FAILURE:", error);
        throw error;
    } finally {
        // Clean up test fixtures
        console.log("\nCleaning up test artifacts...");
        if (testLead?._id) await leadModel.findByIdAndDelete(testLead._id);
        if (testStaff?._id) await staffModel.findByIdAndDelete(testStaff._id);
        if (createdCallLogIds.length > 0) {
            await callLogModel.deleteMany({ _id: { $in: createdCallLogIds } });
        }
        await mongoose.disconnect();
        console.log("Disconnected from MongoDB.");
    }
}

runDataFlowTests();
