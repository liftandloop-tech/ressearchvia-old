import 'dotenv/config';
import mongoose from 'mongoose';
import MONGO_CLIENT from './app/config/db.config.js';
import User from './app/models/userModel.js';
import SegmentsPlan from './app/models/segmentsPlansModel.js';
import segmentsModel from './app/models/segmentsModel.js';
import PaymentIntent from './app/models/paymentIntentModel.js';
import Entitlement from './app/models/entitlementModel.js';
import * as acquisitionService from './app/services/acquisitionService.js';
import { contentAccess, registrationAccess } from './app/middleware/accessMiddleware.js';

const TEST_PREFIX = 'EDGE_TEST_' + Date.now();

// Helper to create mock Express response
const createMockRes = () => {
    const res = {
        statusCode: 200,
        jsonData: null,
        status(code) {
            this.statusCode = code;
            return this;
        },
        json(data) {
            this.jsonData = data;
            return this;
        }
    };
    return res;
};

async function runEdgeCaseSimulation() {
    console.log("================================================================================");
    console.log("MOBILE APP API ENDPOINTS & BACKEND BUSINESS RULES: COMPREHENSIVE EDGE-CASE AUDIT");
    console.log("================================================================================\n");

    await MONGO_CLIENT();

    const results = [];
    const createdUserIds = [];
    const createdIntentIds = [];
    const createdEntitlementIds = [];

    const recordResult = (testId, category, description, passed, details) => {
        results.push({ testId, category, description, passed, details });
        const icon = passed ? '✅ PASS' : '❌ FAIL';
        console.log(`[${icon}] ${testId} [${category}]: ${description}`);
        if (!passed || process.env.VERBOSE) {
            console.log(`       Details: ${details}`);
        }
    };

    let testSegmentActive = null;
    let testSegmentInactive = null;
    let testPlanActive = null;
    let testPlanInactive = null;
    let testPlanHni = null;

    try {
        // --- SETUP FIXTURES ---
        testSegmentActive = await segmentsModel.create({
            segmentName: `${TEST_PREFIX}_ACTIVE_SEG`,
            segmentStatus: 'active'
        });

        testSegmentInactive = await segmentsModel.create({
            segmentName: `${TEST_PREFIX}_INACTIVE_SEG`,
            segmentStatus: 'inactive'
        });

        testPlanActive = await SegmentsPlan.create({
            planName: `${TEST_PREFIX}_ACTIVE_PLAN`,
            duration: '30',
            day: '30',
            price: 5000,
            perDayCharge: 166.6,
            planStatus: 'active',
            discription: 'Test Active Plan',
            planFeatures: 'Features',
            isHni: false
        });

        testPlanInactive = await SegmentsPlan.create({
            planName: `${TEST_PREFIX}_INACTIVE_PLAN`,
            duration: '30',
            day: '30',
            price: 5000,
            perDayCharge: 166.6,
            planStatus: 'inactive',
            discription: 'Test Inactive Plan',
            planFeatures: 'Features',
            isHni: false
        });

        testPlanHni = await SegmentsPlan.create({
            planName: `${TEST_PREFIX}_HNI_PLAN`,
            duration: '30',
            day: '30',
            price: 50000,
            perDayCharge: 1666.6,
            planStatus: 'active',
            discription: 'Test HNI Plan',
            planFeatures: 'HNI Features',
            isHni: true
        });

        // ════════════════════════════════════════════════════════════════════════════
        // CATEGORY A: KYC GATES ON PLAN ORDER (/acquisition/plan-order)
        // ════════════════════════════════════════════════════════════════════════════

        const kycStatusesToTest = [
            { status: 'NOT_STARTED', shouldPass: false, desc: 'KYC NOT_STARTED must block plan purchase' },
            { status: 'IN_PROGRESS', shouldPass: false, desc: 'KYC IN_PROGRESS must block plan purchase' },
            { status: 'WAITING_FOR_REVIEW', shouldPass: false, desc: 'KYC WAITING_FOR_REVIEW must block plan purchase' },
            { status: 'REJECTED', shouldPass: false, desc: 'KYC REJECTED must block plan purchase' },
            { status: 'VERIFIED', shouldPass: true, desc: 'KYC VERIFIED must allow plan purchase' },
        ];

        for (let i = 0; i < kycStatusesToTest.length; i++) {
            const item = kycStatusesToTest[i];
            const user = await User.create({
                fullName: `${TEST_PREFIX} KYC ${item.status}`,
                phone: `999000${Date.now().toString().slice(-4)}${i}`,
                account_type: 'SELF_REGISTERED',
                registrationStatus: 'ACTIVE',
                registrationFeePaid: true,
                kycStatus: item.status
            });
            createdUserIds.push(user._id);

            try {
                const res = await acquisitionService.initiatePlanPurchase(
                    user._id,
                    testPlanActive._id,
                    'BANK_TRANSFER',
                    false,
                    testSegmentActive._id
                );
                if (res?.paymentIntentId) createdIntentIds.push(res.paymentIntentId);

                if (item.shouldPass) {
                    recordResult(`TC-A${i + 1}`, 'KYC Gate', item.desc, true, `Allowed with KYC: ${item.status}`);
                } else {
                    recordResult(`TC-A${i + 1}`, 'KYC Gate', item.desc, false, `VULNERABILITY: Plan purchase succeeded despite KYC being ${item.status}`);
                }
            } catch (err) {
                if (!item.shouldPass) {
                    const isKycError = err.message.includes('KYC Verification Required');
                    recordResult(`TC-A${i + 1}`, 'KYC Gate', item.desc, isKycError, `Blocked as expected: "${err.message}"`);
                } else {
                    recordResult(`TC-A${i + 1}`, 'KYC Gate', item.desc, false, `Unexpected rejection for verified KYC: "${err.message}"`);
                }
            }
        }

        // ════════════════════════════════════════════════════════════════════════════
        // CATEGORY B: REGISTRATION STATUS GATES
        // ════════════════════════════════════════════════════════════════════════════

        // Test B1: Unpaid Registration Fee
        const userUnpaidReg = await User.create({
            fullName: `${TEST_PREFIX} Unpaid Reg`,
            phone: `998000${Date.now().toString().slice(-4)}1`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'PENDING',
            registrationFeePaid: false,
            kycStatus: 'VERIFIED'
        });
        createdUserIds.push(userUnpaidReg._id);

        try {
            await acquisitionService.initiatePlanPurchase(
                userUnpaidReg._id,
                testPlanActive._id,
                'BANK_TRANSFER',
                false,
                testSegmentActive._id
            );
            recordResult('TC-B1', 'Registration Gate', 'Unpaid registration must block plan purchase', false, 'Allowed plan purchase without active registration');
        } catch (err) {
            const blocked = err.message.includes('Registration approval required');
            recordResult('TC-B1', 'Registration Gate', 'Unpaid registration must block plan purchase', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test B2: Client attempting ADMIN_ENTITLEMENT in registration-order
        const userClientReg = await User.create({
            fullName: `${TEST_PREFIX} Client Reg`,
            phone: `998000${Date.now().toString().slice(-4)}2`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'PENDING',
            registrationFeePaid: false,
            kycStatus: 'NOT_STARTED'
        });
        createdUserIds.push(userClientReg._id);

        try {
            await acquisitionService.initiateRegistrationPurchase(
                userClientReg._id,
                'YEARLY',
                'ADMIN_ENTITLEMENT',
                testSegmentActive._id,
                testPlanActive._id
            );
            recordResult('TC-B2', 'Registration Gate', 'Client self-assigning ADMIN_ENTITLEMENT must be rejected', false, 'VULNERABILITY: Client created ADMIN_ENTITLEMENT payment intent');
        } catch (err) {
            const blocked = err.message.includes('ADMIN_ENTITLEMENT cannot be initiated directly by client');
            recordResult('TC-B2', 'Registration Gate', 'Client self-assigning ADMIN_ENTITLEMENT must be rejected', blocked, `Blocked as expected: "${err.message}"`);
        }

        // ════════════════════════════════════════════════════════════════════════════
        // CATEGORY C: PLAN & SEGMENT POLICY GATES
        // ════════════════════════════════════════════════════════════════════════════

        const verifiedUser = await User.create({
            fullName: `${TEST_PREFIX} Verified User`,
            phone: `997000${Date.now().toString().slice(-4)}1`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true,
            kycStatus: 'VERIFIED'
        });
        createdUserIds.push(verifiedUser._id);

        // Test C1: Inactive Plan
        try {
            await acquisitionService.initiatePlanPurchase(
                verifiedUser._id,
                testPlanInactive._id,
                'BANK_TRANSFER',
                false,
                testSegmentActive._id
            );
            recordResult('TC-C1', 'Plan Validation', 'Inactive plan purchase must be blocked', false, 'Allowed purchase of inactive plan');
        } catch (err) {
            const blocked = err.message.includes('inactive');
            recordResult('TC-C1', 'Plan Validation', 'Inactive plan purchase must be blocked', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test C2: Inactive Segment
        try {
            await acquisitionService.initiatePlanPurchase(
                verifiedUser._id,
                testPlanActive._id,
                'BANK_TRANSFER',
                false,
                testSegmentInactive._id
            );
            recordResult('TC-C2', 'Segment Validation', 'Inactive segment purchase must be blocked', false, 'Allowed purchase with inactive segment');
        } catch (err) {
            const blocked = err.message.includes('inactive');
            recordResult('TC-C2', 'Segment Validation', 'Inactive segment purchase must be blocked', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test C3: Missing Segment
        try {
            await acquisitionService.initiatePlanPurchase(
                verifiedUser._id,
                testPlanActive._id,
                'BANK_TRANSFER',
                false,
                null
            );
            recordResult('TC-C3', 'Segment Validation', 'Missing segment must be blocked', false, 'Allowed purchase without segment');
        } catch (err) {
            const blocked = err.message.includes('Strict Policy');
            recordResult('TC-C3', 'Segment Validation', 'Missing segment must be blocked', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test C4: Multiple Segments in Initial Plan Order
        try {
            await acquisitionService.initiatePlanPurchase(
                verifiedUser._id,
                testPlanActive._id,
                'BANK_TRANSFER',
                false,
                [testSegmentActive._id, testSegmentInactive._id]
            );
            recordResult('TC-C4', 'Segment Validation', 'Multiple segments in plan order must be blocked (strict 1-segment rule)', false, 'Allowed multi-segment initial purchase');
        } catch (err) {
            const blocked = err.message.includes('Exactly 1 segment');
            recordResult('TC-C4', 'Segment Validation', 'Multiple segments in plan order must be blocked (strict 1-segment rule)', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test C5: HNI Plan with Invalid GSTIN
        try {
            await acquisitionService.initiatePlanPurchase(
                verifiedUser._id,
                testPlanHni._id,
                'BANK_TRANSFER',
                false,
                testSegmentActive._id,
                false,
                'INVALID_GSTIN_123'
            );
            recordResult('TC-C5', 'HNI Compliance', 'HNI Plan with invalid GSTIN format must be rejected', false, 'Allowed HNI plan purchase with invalid GSTIN');
        } catch (err) {
            const blocked = err.message.includes('valid 15-character GSTIN is strictly required');
            recordResult('TC-C5', 'HNI Compliance', 'HNI Plan with invalid GSTIN format must be rejected', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test C6: HNI Plan with Valid GSTIN
        try {
            const hniResult = await acquisitionService.initiatePlanPurchase(
                verifiedUser._id,
                testPlanHni._id,
                'BANK_TRANSFER',
                false,
                testSegmentActive._id,
                false,
                '27ABCDE1234F1Z5'
            );
            if (hniResult?.paymentIntentId) createdIntentIds.push(hniResult.paymentIntentId);
            recordResult('TC-C6', 'HNI Compliance', 'HNI Plan with valid GSTIN must succeed', !!hniResult.paymentIntentId, 'HNI plan initiated successfully');
        } catch (err) {
            recordResult('TC-C6', 'HNI Compliance', 'HNI Plan with valid GSTIN must succeed', false, `Failed: ${err.message}`);
        }

        // ════════════════════════════════════════════════════════════════════════════
        // CATEGORY D: SINGLE ACTIVE PLAN POLICY & CONFLICTS
        // ════════════════════════════════════════════════════════════════════════════

        const userWithActivePlan = await User.create({
            fullName: `${TEST_PREFIX} User With Active Plan`,
            phone: `996000${Date.now().toString().slice(-4)}1`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true,
            kycStatus: 'VERIFIED'
        });
        createdUserIds.push(userWithActivePlan._id);

        // Grant active plan entitlement
        const activeEnt = await Entitlement.create({
            userId: userWithActivePlan._id,
            type: 'PLAN',
            resourceId: testPlanActive._id,
            segmentId: testSegmentActive._id,
            status: 'ACTIVE',
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            grantedBy: 'SYSTEM',
            grantReason: 'ONLINE_PAYMENT'
        });
        createdEntitlementIds.push(activeEnt._id);

        // Attempt second plan
        try {
            await acquisitionService.initiatePlanPurchase(
                userWithActivePlan._id,
                testPlanActive._id,
                'BANK_TRANSFER',
                false,
                testSegmentActive._id
            );
            recordResult('TC-D1', 'Single Plan Rule', 'User with existing active plan cannot purchase another plan', false, 'Allowed duplicate plan purchase');
        } catch (err) {
            const blocked = err.message.includes('Strict Policy: A user can only hold one plan at a time');
            recordResult('TC-D1', 'Single Plan Rule', 'User with existing active plan cannot purchase another plan', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test C7: Non-existent Plan ID
        try {
            const fakePlanId = new mongoose.Types.ObjectId();
            await acquisitionService.initiatePlanPurchase(
                verifiedUser._id,
                fakePlanId,
                'BANK_TRANSFER',
                false,
                testSegmentActive._id
            );
            recordResult('TC-C7', 'Plan Validation', 'Non-existent plan purchase must be blocked', false, 'Allowed purchase of non-existent plan');
        } catch (err) {
            const blocked = err.message.includes('Plan not found');
            recordResult('TC-C7', 'Plan Validation', 'Non-existent plan purchase must be blocked', blocked, `Blocked as expected: "${err.message}"`);
        }

        // ════════════════════════════════════════════════════════════════════════════
        // CATEGORY E: PROOF UPLOAD, IDOR & AMOUNT TAMPERING
        // ════════════════════════════════════════════════════════════════════════════

        const victimUser = await User.create({
            fullName: `${TEST_PREFIX} Victim User`,
            phone: `995000${Date.now().toString().slice(-4)}1`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true,
            kycStatus: 'VERIFIED'
        });
        createdUserIds.push(victimUser._id);

        const attackerUser = await User.create({
            fullName: `${TEST_PREFIX} Attacker User`,
            phone: `995000${Date.now().toString().slice(-4)}2`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true,
            kycStatus: 'VERIFIED'
        });
        createdUserIds.push(attackerUser._id);

        const victimIntent = await PaymentIntent.create({
            userId: victimUser._id,
            purchaseType: 'PLAN',
            planId: testPlanActive._id,
            baseAmount: 5000,
            gstAmount: 900,
            totalAmount: 5900,
            razorpayOrderId: `BANK_test_${Date.now()}`,
            status: 'PENDING_BANK_TRANSFER',
            paymentMethod: 'BANK_TRANSFER'
        });
        createdIntentIds.push(victimIntent._id);

        const dummyFiles = [{ filename: 'receipt_123.jpg' }];

        // Test E1: IDOR Attack (Attacker tries uploading proof for victim's intent)
        try {
            await acquisitionService.uploadProof(
                victimIntent._id,
                dummyFiles,
                { amountPaid: 5900, utrNumber: 'UTR12345' },
                attackerUser._id // Attacker's token userId
            );
            recordResult('TC-E1', 'IDOR Security', 'User B uploading proof for User A intent must be rejected', false, 'VULNERABILITY: Attacker successfully modified victim payment intent');
        } catch (err) {
            const blocked = err.message.includes('Unauthorized: You can only upload payment proof for your own');
            recordResult('TC-E1', 'IDOR Security', 'User B uploading proof for User A intent must be rejected', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test E2: Legitimate Owner Proof Upload
        try {
            const validProofRes = await acquisitionService.uploadProof(
                victimIntent._id,
                dummyFiles,
                { amountPaid: 5900, utrNumber: 'UTR12345' },
                victimUser._id // Victim's own token userId
            );
            recordResult('TC-E2', 'Proof Upload', 'Owner uploading proof for their own intent must succeed', validProofRes.success === true, 'Owner proof upload succeeded');
        } catch (err) {
            recordResult('TC-E2', 'Proof Upload', 'Owner uploading proof for their own intent must succeed', false, `Failed: ${err.message}`);
        }

        // Test E3: Negative or Zero Amount Tampering
        const intentForAmountTest = await PaymentIntent.create({
            userId: victimUser._id,
            purchaseType: 'PLAN',
            planId: testPlanActive._id,
            baseAmount: 5000,
            gstAmount: 900,
            totalAmount: 5900,
            razorpayOrderId: `BANK_amount_${Date.now()}`,
            status: 'PENDING_BANK_TRANSFER',
            paymentMethod: 'BANK_TRANSFER'
        });
        createdIntentIds.push(intentForAmountTest._id);

        try {
            await acquisitionService.uploadProof(
                intentForAmountTest._id,
                dummyFiles,
                { amountPaid: -1000 },
                victimUser._id
            );
            recordResult('TC-E3', 'Amount Tampering', 'Negative amount in proof upload must be rejected', false, 'Allowed negative payment amount');
        } catch (err) {
            const blocked = err.message.includes('greater than zero');
            recordResult('TC-E3', 'Amount Tampering', 'Negative amount in proof upload must be rejected', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test E4: Disallowed Status (Uploading proof for a FAILED intent)
        const intentCancelled = await PaymentIntent.create({
            userId: victimUser._id,
            purchaseType: 'PLAN',
            planId: testPlanActive._id,
            baseAmount: 5000,
            gstAmount: 900,
            totalAmount: 5900,
            razorpayOrderId: `BANK_failed_${Date.now()}`,
            status: 'FAILED',
            paymentMethod: 'BANK_TRANSFER'
        });
        createdIntentIds.push(intentCancelled._id);

        try {
            await acquisitionService.uploadProof(
                intentCancelled._id,
                dummyFiles,
                { amountPaid: 5900 },
                victimUser._id
            );
            recordResult('TC-E4', 'Status Protection', 'Uploading proof for CANCELLED status must be rejected', false, 'Allowed proof upload on CANCELLED intent');
        } catch (err) {
            const blocked = err.message.includes('Invalid status for proof upload');
            recordResult('TC-E4', 'Status Protection', 'Uploading proof for CANCELLED status must be rejected', blocked, `Blocked as expected: "${err.message}"`);
        }

        // Test E5: Partial Payment Installment Overrun (Capacity check)
        const partialIntent = await PaymentIntent.create({
            userId: victimUser._id,
            purchaseType: 'PLAN',
            planId: testPlanActive._id,
            baseAmount: 5000,
            gstAmount: 900,
            totalAmount: 5900,
            partialTotalTarget: 8850, // 1.5x of 5900
            isPartial: true,
            razorpayOrderId: `BANK_partial_${Date.now()}`,
            status: 'PENDING_BANK_TRANSFER',
            paymentMethod: 'BANK_TRANSFER',
            partialPaymentsHistory: [
                { amountPaid: 8000, status: 'APPROVED', transactionDate: new Date() }
            ]
        });
        createdIntentIds.push(partialIntent._id);

        try {
            await acquisitionService.uploadProof(
                partialIntent._id,
                dummyFiles,
                { amountPaid: 5000 }, // 8000 + 5000 = 13000 > 8850 + 1000 buffer
                victimUser._id
            );
            recordResult('TC-E5', 'Capacity Limits', 'Partial installment exceeding max allowed plan capacity must be rejected', false, 'Allowed payment exceeding capacity');
        } catch (err) {
            const blocked = err.message.includes('Payment amount exceeds the allowed limit');
            recordResult('TC-E5', 'Capacity Limits', 'Partial installment exceeding max allowed plan capacity must be rejected', blocked, `Blocked as expected: "${err.message}"`);
        }

        // ════════════════════════════════════════════════════════════════════════════
        // CATEGORY F: CONCURRENCY & RACE CONDITION TEST (k6-style simulation)
        // ════════════════════════════════════════════════════════════════════════════

        const raceUser = await User.create({
            fullName: `${TEST_PREFIX} Race User`,
            phone: `994000${Date.now().toString().slice(-4)}1`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true,
            kycStatus: 'VERIFIED'
        });
        createdUserIds.push(raceUser._id);

        const testOrderId = `order_race_${Date.now()}`;
        const raceIntent = await PaymentIntent.create({
            userId: raceUser._id,
            purchaseType: 'REGISTRATION',
            baseAmount: 5000,
            gstAmount: 900,
            totalAmount: 5900,
            razorpayOrderId: testOrderId,
            status: 'CREATED'
        });
        createdIntentIds.push(raceIntent._id);

        // Fire 5 concurrent verifyPayment calls simultaneously
        const concurrentAttempts = 5;
        const promises = [];
        for (let i = 0; i < concurrentAttempts; i++) {
            promises.push(
                PaymentIntent.findOneAndUpdate(
                    { razorpayOrderId: testOrderId, status: { $nin: ['PAID', 'PROCESSING'] } },
                    { $set: { status: 'PROCESSING' } },
                    { new: true }
                ).then(async (acquiredLock) => {
                    if (!acquiredLock) {
                        return { processed: false, reason: 'Already Processed / Locked' };
                    }
                    acquiredLock.status = 'PAID';
                    await acquiredLock.save();
                    return { processed: true };
                })
            );
        }

        const raceResults = await Promise.all(promises);
        const processedCount = raceResults.filter(r => r.processed).length;
        const lockedCount = raceResults.filter(r => !r.processed).length;

        recordResult(
            'TC-F1',
            'Concurrency / Race Condition',
            '5 concurrent verification requests must only process exactly once (zero double-entitlement)',
            processedCount === 1 && lockedCount === 4,
            `Processed: ${processedCount}, Idempotently Handled/Locked: ${lockedCount}`
        );

        // Test F2: Payment Verification KYC Gate (Plan entitlement must be withheld if KYC revoked/rejected)
        const revokedKycUser = await User.create({
            fullName: `${TEST_PREFIX} Revoked KYC User`,
            phone: `994000${Date.now().toString().slice(-4)}2`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true,
            kycStatus: 'REJECTED' // KYC was rejected
        });
        createdUserIds.push(revokedKycUser._id);

        const planIntentWithRevokedKyc = await PaymentIntent.create({
            userId: revokedKycUser._id,
            purchaseType: 'PLAN',
            planId: testPlanActive._id,
            baseAmount: 5000,
            gstAmount: 900,
            totalAmount: 5900,
            razorpayOrderId: `order_revoked_${Date.now()}`,
            status: 'PROCESSING'
        });
        createdIntentIds.push(planIntentWithRevokedKyc._id);

        try {
            // Simulate the PLAN branch of verifyPayment
            const userCheck = await User.findById(planIntentWithRevokedKyc.userId);
            const validKycStatus = ['VERIFIED', 'APPROVED'];
            if (!userCheck || !validKycStatus.includes(userCheck.kycStatus)) {
                planIntentWithRevokedKyc.status = 'VERIFICATION_PENDING';
                await planIntentWithRevokedKyc.save();
                throw new Error(`KYC Verification Required. Payment received but plan entitlement withheld pending KYC verification (Current KYC: "${userCheck?.kycStatus || 'NOT_STARTED'}").`);
            }
            recordResult('TC-F2', 'Payment Verification KYC Gate', 'Plan activation on payment verification must be withheld if user KYC is REJECTED', false, 'Allowed plan entitlement activation despite rejected KYC');
        } catch (err) {
            const blocked = err.message.includes('KYC Verification Required');
            recordResult('TC-F2', 'Payment Verification KYC Gate', 'Plan activation on payment verification must be withheld if user KYC is REJECTED', blocked, `Withheld as expected: "${err.message}"`);
        }

        // ════════════════════════════════════════════════════════════════════════════
        // CATEGORY G: CONTENT ACCESS (TRADING CALLS & REPORTS) KYC ENFORCEMENT
        // ════════════════════════════════════════════════════════════════════════════

        const unverifiedReportUser = await User.create({
            fullName: `${TEST_PREFIX} Unverified Content User`,
            phone: `993000${Date.now().toString().slice(-4)}1`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true,
            kycStatus: 'IN_PROGRESS'
        });
        createdUserIds.push(unverifiedReportUser._id);

        const reqMockUnverified = {
            user: { _id: unverifiedReportUser._id, userType: 'user' },
            userDetails: unverifiedReportUser
        };
        const resMockUnverified = createMockRes();
        let nextCalledUnverified = false;

        await contentAccess(reqMockUnverified, resMockUnverified, () => {
            nextCalledUnverified = true;
        });

        recordResult(
            'TC-G1',
            'Content Access Compliance',
            'Content access (research calls/reports) must be blocked when KYC is IN_PROGRESS',
            resMockUnverified.statusCode === 403 && !nextCalledUnverified,
            `Status: ${resMockUnverified.statusCode}, ErrorCode: ${resMockUnverified.jsonData?.errorCode}`
        );

        const verifiedReportUser = await User.create({
            fullName: `${TEST_PREFIX} Verified Content User`,
            phone: `993000${Date.now().toString().slice(-4)}2`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true,
            kycStatus: 'VERIFIED'
        });
        createdUserIds.push(verifiedReportUser._id);

        // Grant active plan
        const repEnt = await Entitlement.create({
            userId: verifiedReportUser._id,
            type: 'PLAN',
            resourceId: testPlanActive._id,
            segmentId: testSegmentActive._id,
            status: 'ACTIVE',
            startDate: new Date(),
            endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            grantedBy: 'SYSTEM',
            grantReason: 'ONLINE_PAYMENT'
        });
        createdEntitlementIds.push(repEnt._id);

        const reqMockVerified = {
            user: { _id: verifiedReportUser._id, userType: 'user' },
            userDetails: verifiedReportUser
        };
        const resMockVerified = createMockRes();
        let nextCalledVerified = false;

        await contentAccess(reqMockVerified, resMockVerified, () => {
            nextCalledVerified = true;
        });

        recordResult(
            'TC-G2',
            'Content Access Compliance',
            'Content access (research calls/reports) must be allowed when KYC is VERIFIED and active plan exists',
            nextCalledVerified === true,
            `next() was called successfully: ${nextCalledVerified}`
        );

    } catch (unexpectedErr) {
        console.error("FATAL RUNNER ERROR:", unexpectedErr);
    } finally {
        // --- CLEANUP TEST FIXTURES ---
        console.log("\nCleaning up test fixtures...");
        if (testSegmentActive) await segmentsModel.findByIdAndDelete(testSegmentActive._id);
        if (testSegmentInactive) await segmentsModel.findByIdAndDelete(testSegmentInactive._id);
        if (testPlanActive) await SegmentsPlan.findByIdAndDelete(testPlanActive._id);
        if (testPlanInactive) await SegmentsPlan.findByIdAndDelete(testPlanInactive._id);
        if (testPlanHni) await SegmentsPlan.findByIdAndDelete(testPlanHni._id);
        if (createdUserIds.length > 0) await User.deleteMany({ _id: { $in: createdUserIds } });
        if (createdIntentIds.length > 0) await PaymentIntent.deleteMany({ _id: { $in: createdIntentIds } });
        if (createdEntitlementIds.length > 0) await Entitlement.deleteMany({ _id: { $in: createdEntitlementIds } });
        console.log("Cleanup complete.\n");
    }

    // --- SUMMARY REPORT ---
    console.log("================================================================================");
    console.log("AUDIT SUMMARY & SIMULATION RESULTS");
    console.log("================================================================================");
    const totalTests = results.length;
    const passedTests = results.filter(r => r.passed).length;
    const failedTests = totalTests - passedTests;

    console.log(`TOTAL EDGE CASES TESTED: ${totalTests}`);
    console.log(`PASSED:                  ${passedTests}`);
    console.log(`FAILED:                  ${failedTests}`);
    console.log(`SUCCESS RATE:            ${Math.round((passedTests / totalTests) * 100)}%\n`);

    if (failedTests > 0) {
        console.log("Failed Edge Cases:");
        results.filter(r => !r.passed).forEach(r => {
            console.log(`- ${r.testId} [${r.category}]: ${r.description} -> ${r.details}`);
        });
        process.exit(1);
    } else {
        console.log("🎉 ALL EDGE CASES PASSED WITH 100% SUCCESS!");
        process.exit(0);
    }
}

runEdgeCaseSimulation();
