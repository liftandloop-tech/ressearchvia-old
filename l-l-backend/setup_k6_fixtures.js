import 'dotenv/config';
import fs from 'fs';
import jwt from 'jsonwebtoken';
import MONGO_CLIENT from './app/config/db.config.js';
import User from './app/models/userModel.js';
import SegmentsPlan from './app/models/segmentsPlansModel.js';
import segmentsModel from './app/models/segmentsModel.js';
import PaymentIntent from './app/models/paymentIntentModel.js';
import Entitlement from './app/models/entitlementModel.js';

const PREFIX = 'K6_SIM_' + Date.now();

async function main() {
    const isTeardown = process.argv.includes('teardown');
    await MONGO_CLIENT();

    if (isTeardown) {
        console.log("Cleaning up k6 fixtures...");
        if (fs.existsSync('k6_fixtures.json')) {
            const data = JSON.parse(fs.readFileSync('k6_fixtures.json', 'utf8'));
            if (data.userIds && data.userIds.length > 0) {
                await User.deleteMany({ _id: { $in: data.userIds } });
            }
            if (data.planIds && data.planIds.length > 0) {
                await SegmentsPlan.deleteMany({ _id: { $in: data.planIds } });
            }
            if (data.segmentIds && data.segmentIds.length > 0) {
                await segmentsModel.deleteMany({ _id: { $in: data.segmentIds } });
            }
            if (data.intentIds && data.intentIds.length > 0) {
                await PaymentIntent.deleteMany({ _id: { $in: data.intentIds } });
            }
            if (data.entitlementIds && data.entitlementIds.length > 0) {
                await Entitlement.deleteMany({ _id: { $in: data.entitlementIds } });
            }
            fs.unlinkSync('k6_fixtures.json');
        }
        console.log("Teardown complete.");
        process.exit(0);
    }

    console.log("Setting up k6 simulation fixtures...");

    const userIds = [];
    const planIds = [];
    const segmentIds = [];
    const intentIds = [];
    const entitlementIds = [];

    // 1. Segments
    const segActive = await segmentsModel.create({
        segmentName: `${PREFIX}_ACTIVE_SEG`,
        segmentStatus: 'active'
    });
    segmentIds.push(segActive._id);

    const segInactive = await segmentsModel.create({
        segmentName: `${PREFIX}_INACTIVE_SEG`,
        segmentStatus: 'inactive'
    });
    segmentIds.push(segInactive._id);

    // 2. Plans
    const planActive = await SegmentsPlan.create({
        planName: `${PREFIX}_ACTIVE_PLAN`,
        duration: '30',
        day: '30',
        price: 5000,
        perDayCharge: 166.6,
        planStatus: 'active',
        discription: 'Test Active Plan',
        planFeatures: 'Features',
        isHni: false
    });
    planIds.push(planActive._id);

    const planInactive = await SegmentsPlan.create({
        planName: `${PREFIX}_INACTIVE_PLAN`,
        duration: '30',
        day: '30',
        price: 5000,
        perDayCharge: 166.6,
        planStatus: 'inactive',
        discription: 'Test Inactive Plan',
        planFeatures: 'Features',
        isHni: false
    });
    planIds.push(planInactive._id);

    const planHni = await SegmentsPlan.create({
        planName: `${PREFIX}_HNI_PLAN`,
        duration: '30',
        day: '30',
        price: 50000,
        perDayCharge: 1666.6,
        planStatus: 'active',
        discription: 'Test HNI Plan',
        planFeatures: 'HNI Features',
        isHni: true
    });
    planIds.push(planHni._id);

    // 3. Helper to create user with token
    const createTestUser = async (name, kycStatus, regStatus, feePaid, phoneSuffix) => {
        const user = await User.create({
            fullName: `${PREFIX}_${name}`,
            phone: `992${Date.now().toString().slice(-4)}${phoneSuffix}`,
            account_type: 'SELF_REGISTERED',
            registrationStatus: regStatus,
            registrationFeePaid: feePaid,
            kycStatus: kycStatus
        });
        userIds.push(user._id);

        const token = jwt.sign(
            { _id: user._id, userType: 'user', userId: user.userId },
            process.env.JWT_TOKEN,
            { expiresIn: '2h' }
        );

        return { user, token };
    };

    const userKycRejected = await createTestUser('KycRejected', 'REJECTED', 'ACTIVE', true, '01');
    const userKycProgress = await createTestUser('KycProgress', 'IN_PROGRESS', 'ACTIVE', true, '02');
    const userKycReview = await createTestUser('KycReview', 'WAITING_FOR_REVIEW', 'ACTIVE', true, '03');
    const userKycNotStarted = await createTestUser('KycNotStarted', 'NOT_STARTED', 'ACTIVE', true, '04');
    const userKycVerified = await createTestUser('KycVerified', 'VERIFIED', 'ACTIVE', true, '05');
    const userUnpaidReg = await createTestUser('UnpaidReg', 'VERIFIED', 'PENDING', false, '06');

    // User with active plan
    const userActivePlan = await createTestUser('ActivePlan', 'VERIFIED', 'ACTIVE', true, '07');
    const ent = await Entitlement.create({
        userId: userActivePlan.user._id,
        type: 'PLAN',
        resourceId: planActive._id,
        segmentId: segActive._id,
        status: 'ACTIVE',
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        grantedBy: 'SYSTEM',
        grantReason: 'ONLINE_PAYMENT'
    });
    entitlementIds.push(ent._id);

    // Victim and Attacker users
    const victim = await createTestUser('Victim', 'VERIFIED', 'ACTIVE', true, '08');
    const attacker = await createTestUser('Attacker', 'VERIFIED', 'ACTIVE', true, '09');

    // Intent belonging to victim
    const victimIntent = await PaymentIntent.create({
        userId: victim.user._id,
        purchaseType: 'PLAN',
        planId: planActive._id,
        baseAmount: 5000,
        gstAmount: 900,
        totalAmount: 5900,
        razorpayOrderId: `BANK_${PREFIX}_victim`,
        status: 'PENDING_BANK_TRANSFER',
        paymentMethod: 'BANK_TRANSFER'
    });
    intentIds.push(victimIntent._id);

    // Write fixtures out
    const output = {
        userIds,
        planIds,
        segmentIds,
        intentIds,
        entitlementIds,
        fixtures: {
            activeSegmentId: segActive._id.toString(),
            inactiveSegmentId: segInactive._id.toString(),
            activePlanId: planActive._id.toString(),
            inactivePlanId: planInactive._id.toString(),
            hniPlanId: planHni._id.toString(),
            victimIntentId: victimIntent._id.toString(),
            tokens: {
                kycRejected: userKycRejected.token,
                kycProgress: userKycProgress.token,
                kycReview: userKycReview.token,
                kycNotStarted: userKycNotStarted.token,
                kycVerified: userKycVerified.token,
                unpaidReg: userUnpaidReg.token,
                activePlanUser: userActivePlan.token,
                victim: victim.token,
                attacker: attacker.token
            },
            userIdsMap: {
                kycRejected: userKycRejected.user._id.toString(),
                kycVerified: userKycVerified.user._id.toString(),
                victim: victim.user._id.toString(),
                attacker: attacker.user._id.toString()
            }
        }
    };

    fs.writeFileSync('k6_fixtures.json', JSON.stringify(output, null, 2));
    console.log("k6_fixtures.json successfully created!");
    process.exit(0);
}

main().catch(err => {
    console.error("Fixture setup failed:", err);
    process.exit(1);
});
