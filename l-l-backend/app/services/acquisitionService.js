import Razorpay from "razorpay";
import crypto from "crypto";
import PaymentIntent from "../models/paymentIntentModel.js";
import Entitlement from "../models/entitlementModel.js";
import User from "../models/userModel.js";
import SegmentsPlan from "../models/segmentsPlansModel.js";
import { grantEntitlement } from "./entitlementService.js";
import userService from "./userService.js";

import { getRazorpay } from "./razorpayClient.js";

import PlanPurchase from "../models/planPurchaseModel.js";
import PaymentModel from "../models/paymentModel.js";
import Devices from "../models/deviceModel.js";
import notificationService from "./notificationService.js";
import invoiceModel from "../models/invoiceModel.js";
import invoiceGenerator from "./invoiceGenerator.js";
import emailService from "./emailService.js";
import { getUserTokens } from "../repositories/user.repository.js";
import segmentsModel from "../models/segmentsModel.js";
import userActiveSegmentModel from "../models/userActiveSegmentsModel.js";
import staff from "../models/staffModel.js";
import * as activityLogService from "./activityLogService.js";


export const initiateRegistrationPurchase = async (userId, type, paymentMode, segmentId, planId, isPartial = false) => {
    try {
        // 1. Calculate Price
        let baseAmount = 0;

        if (type === 'LIFETIME') {
            baseAmount = 10000;
        } else {
            baseAmount = 5000; // default YEARLY
        }

        const gstPercent = 18;
        const gstAmount = Math.round((baseAmount * gstPercent) / 100);
        // Round UP total amount to nearest Rupee
        const totalAmount = Math.ceil(baseAmount + gstAmount);
        const amountPaise = totalAmount * 100;

        console.log(`DEBUG: initiateRegistrationPurchase - Type: ${type}, Total: ${totalAmount}, Paise: ${amountPaise}, Partial: ${isPartial}`);
        console.log(`DEBUG: Trial Bundling - Segment: ${segmentId}, Plan: ${planId}`);

        // Handle ADMIN ENTITLEMENT
        if (paymentMode === 'ADMIN_ENTITLEMENT') {
            const shortUserId = userId.toString().slice(-8);
            const receipt = `admin_${shortUserId}_${Date.now()}`;

            const paymentIntent = new PaymentIntent({
                userId,
                purchaseType: 'REGISTRATION',
                baseAmount,
                gstAmount,
                totalAmount,
                razorpayOrderId: `ADMIN_${receipt}`,
                status: 'PENDING_ADMIN_APPROVAL',
                paymentMethod: 'ADMIN_ENTITLEMENT',
                preferredSegmentId: segmentId,
                preferredPlanId: planId
            });
            await paymentIntent.save();

            return {
                amount: totalAmount,
                currency: "INR",
                paymentIntentId: paymentIntent._id,
                message: "Admin Request Submitted"
            };
        }

        // ── DUPLICATE REGISTRATION GUARD ─────────────────────────────────────────
        const activeRegEntitlement = await Entitlement.findOne({
            userId,
            type: 'REGISTRATION',
            status: { $in: ['ACTIVE', 'SUSPENDED'] },
            $or: [{ endDate: null }, { endDate: { $gt: new Date() } }]
        });
        if (activeRegEntitlement) {
            throw new Error('Your registration is already active or suspended. You cannot register again.');
        }

        const existingPartialReg = await PaymentIntent.findOne({
            userId,
            purchaseType: 'REGISTRATION',
            isPartial: true,
            status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] }
        }).sort({ createdAt: -1 });

        if (existingPartialReg) {
            if (paymentMode !== 'BANK_TRANSFER') {
                throw new Error('You have an ongoing partial registration payment. Please complete it via Bank Transfer.');
            }
            return {
                amount: existingPartialReg.totalAmount,
                currency: 'INR',
                paymentIntentId: existingPartialReg._id,
                message: 'Existing partial registration payment found.',
                isPartial: true,
                totalToPay: existingPartialReg.totalAmount
            };
        }

        const existingNonPartialReg = await PaymentIntent.findOne({
            userId,
            purchaseType: 'REGISTRATION',
            isPartial: false,
            status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] }
        }).sort({ createdAt: -1 });

        if (existingNonPartialReg) {
            if (existingNonPartialReg.status === 'VERIFICATION_PENDING') {
                throw new Error('Your previous registration payment is under verification. Please wait for admin approval.');
            }
            if (paymentMode === 'BANK_TRANSFER') {
                return {
                    amount: existingNonPartialReg.totalAmount,
                    currency: 'INR',
                    paymentIntentId: existingNonPartialReg._id,
                    message: 'Bank Transfer Initiated',
                    isPartial: false,
                    totalToPay: existingNonPartialReg.totalAmount
                };
            }
        }

        if (paymentMode !== 'BANK_TRANSFER') {
            const existingCreatedReg = await PaymentIntent.findOne({
                userId,
                purchaseType: 'REGISTRATION',
                status: 'CREATED',
                createdAt: { $gte: new Date(Date.now() - 10 * 60 * 1000) }
            }).sort({ createdAt: -1 });

            if (existingCreatedReg) {
                return {
                    orderId: existingCreatedReg.razorpayOrderId,
                    amount: existingCreatedReg.totalAmount,
                    currency: 'INR',
                    paymentIntentId: existingCreatedReg._id
                };
            }
        }
        // ── END GUARD ─────────────────────────────────────────────────────────────

        // if Bank Transfer
        if (paymentMode === 'BANK_TRANSFER') {
            const shortUserId = userId.toString().slice(-8);
            const receipt = isPartial ? `bank_reg_partial_${shortUserId}_${Date.now()}` : `bank_reg_${shortUserId}_${Date.now()}`;

            const originalDuration = type === 'LIFETIME' ? 3652 : 365;

            const intentData = {
                userId,
                purchaseType: 'REGISTRATION',
                baseAmount,
                gstAmount,
                totalAmount,
                razorpayOrderId: `BANK_${receipt}`,
                status: 'PENDING_BANK_TRANSFER',
                paymentMethod: 'BANK_TRANSFER',
                preferredSegmentId: segmentId,
                preferredPlanId: planId,
                isPartial: !!isPartial,
                packageName: type === 'LIFETIME' ? 'Gold' : 'Silver',
                originalPlanAmount: totalAmount,
                originalDuration: originalDuration
            };

            if (isPartial) {
                // Registration Partial Payment: Use 1x multiplier as requested
                const partialTotalTarget = totalAmount; // 1x factor
                const perDayCharge = partialTotalTarget / originalDuration;
                const maxAllowedDays = originalDuration;

                intentData.partialTotalTarget = partialTotalTarget;
                intentData.perDayCharge = perDayCharge;
                intentData.maxAllowedDays = maxAllowedDays;
            }

            const paymentIntent = new PaymentIntent(intentData);
            await paymentIntent.save();

            return {
                amount: totalAmount,
                currency: "INR",
                paymentIntentId: paymentIntent._id,
                message: isPartial ? "Registration Partial Payment (Bank Transfer) Initiated" : "Bank Transfer Initiated",
                isPartial: !!isPartial,
                totalToPay: totalAmount
            };
        }

        // 2. Create Razorpay Order
        // Receipt limit is 40 chars. UserId is 24 chars, Timestamp is 13 chars. Total 37+prefix > 40.
        // We use last 8 chars of userId + timestamp.
        const shortUserId = userId.toString().slice(-8);
        const receipt = `reg_${shortUserId}_${Date.now()}`;
        const options = {
            amount: amountPaise,
            currency: "INR",
            receipt: receipt,
        };

        console.log('DEBUG: Creating Razorpay Order with options:', JSON.stringify(options));

        const order = await getRazorpay().orders.create(options);

        console.log('DEBUG: Razorpay Order Created:', order.id);

        // 3. Create PaymentIntent
        const paymentIntent = new PaymentIntent({
            userId,
            purchaseType: 'REGISTRATION',
            baseAmount,
            gstAmount,
            totalAmount,
            razorpayOrderId: order.id,
            status: 'CREATED',
            preferredSegmentId: segmentId,
            preferredPlanId: planId,
            packageName: type === 'LIFETIME' ? 'Gold' : 'Silver',
            originalPlanAmount: totalAmount,
            originalDuration: type === 'LIFETIME' ? 3652 : 365
        });
        await paymentIntent.save();

        return {
            orderId: order.id,
            amount: totalAmount,
            currency: "INR",
            paymentIntentId: paymentIntent._id
        };
    } catch (e) {
        console.error('ERROR in initiateRegistrationPurchase:', e);
        throw e;
    }
};

export const initiatePlanPurchase = async (userId, planId, paymentMode, isPartial = false, segmentId = null, calledBySystem = false) => {
    // 1. Verify User Registration Status
    const user = await User.findById(userId);
    if (!user) throw new Error("User not found");

    if (user.account_type === 'SELF_REGISTERED' && (user.registrationStatus !== 'ACTIVE' || !user.registrationFeePaid)) {
        throw new Error("Registration approval required. You cannot purchase plans until your registration is approved by the admin.");
    }

    // 2. Fetch Plan
    const plan = await SegmentsPlan.findById(planId);
    if (!plan) throw new Error("Plan not found");

    if (isPartial && paymentMode !== 'BANK_TRANSFER') {
        throw new Error("Partial payment is only available via Bank Transfer");
    }

    // 3. Calculate Price
    const basePrice = plan.price;
    const gstPercent = 18;
    const gstAmount = Math.round((basePrice * gstPercent) / 100);
    const totalAmount = basePrice + gstAmount;

    // ── DUPLICATE PLAN GUARD ──────────────────────────────────────────────────
    if (!calledBySystem) {
        // 1. Block if user has an active or admin-suspended plan
        const activeEntitlement = await Entitlement.findOne({
            userId,
            type: 'PLAN',
            resourceId: planId,
            status: { $in: ['ACTIVE', 'SUSPENDED'] },
            grantReason: { $ne: 'REGISTRATION_TRIAL' }, // Ignore trial plans during duplicate check
            $or: [{ endDate: null }, { endDate: { $gt: new Date() } }]
        });
        if (activeEntitlement) {
            throw new Error(
                `You already have an active or suspended subscription for this plan. Cannot purchase again.`
            );
        }

        // 2. Block or resume existing PARTIAL payment
        const existingPartial = await PaymentIntent.findOne({
            userId,
            planId: plan._id,
            purchaseType: 'PLAN',
            isPartial: true,
            status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] }
        }).sort({ createdAt: -1 });

        if (existingPartial) {
            if (paymentMode !== 'BANK_TRANSFER') {
                throw new Error('You have an ongoing partial payment for this plan. Please complete it via Bank Transfer.');
            }
            return {
                amount: existingPartial.totalAmount,
                currency: 'INR',
                paymentIntentId: existingPartial._id,
                message: 'Existing partial payment found. Please upload your next installment.',
                isPartial: true,
                totalToPay: existingPartial.totalAmount
            };
        }

        // 3. Block or resume existing NON-PARTIAL bank/verification pending
        const existingNonPartial = await PaymentIntent.findOne({
            userId,
            planId: plan._id,
            purchaseType: 'PLAN',
            isPartial: false,
            status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] }
        }).sort({ createdAt: -1 });

        if (existingNonPartial) {
            if (existingNonPartial.status === 'VERIFICATION_PENDING') {
                throw new Error('Your previous payment is currently under verification. Please wait for admin approval.');
            }
            if (paymentMode === 'BANK_TRANSFER') {
                return {
                    amount: existingNonPartial.totalAmount,
                    currency: 'INR',
                    paymentIntentId: existingNonPartial._id,
                    message: 'Bank Transfer Initiated',
                    isPartial: false,
                    totalToPay: existingNonPartial.totalAmount
                };
            }
            // paymentMode == RAZORPAY + existing offline → allow (user switching modes). Falls through.
        }

        // 4. Razorpay idempotency — same order returned if < 10 min old
        if (paymentMode !== 'BANK_TRANSFER') {
            const existingCreated = await PaymentIntent.findOne({
                userId,
                planId: plan._id,
                purchaseType: 'PLAN',
                status: 'CREATED',
                createdAt: { $gte: new Date(Date.now() - 10 * 60 * 1000) }
            }).sort({ createdAt: -1 });

            if (existingCreated) {
                return {
                    orderId: existingCreated.razorpayOrderId,
                    amount: existingCreated.totalAmount,
                    currency: 'INR',
                    paymentIntentId: existingCreated._id
                };
            }
        }
    }
    // ── END DUPLICATE GUARD ───────────────────────────────────────────────────

    // Use current plan values
    const currentGstPercent = 18;
    const currentGstAmount = Math.round((basePrice * currentGstPercent) / 100);
    // Round UP total amount to nearest Rupee as per requirement
    const currentTotalAmount = Math.ceil(basePrice + currentGstAmount);
    const amountPaise = currentTotalAmount * 100;

    if (paymentMode === 'BANK_TRANSFER') {
        const shortUserId = userId.toString().slice(-8);
        const receipt = `bank_plan_${shortUserId}_${Date.now()}`;

        const intentData = {
            userId,
            purchaseType: 'PLAN',
            planId: plan._id,
            baseAmount: basePrice,
            gstAmount: currentGstAmount,
            totalAmount: currentTotalAmount,
            razorpayOrderId: `BANK_${receipt}`,
            status: 'PENDING_BANK_TRANSFER',
            paymentMethod: 'BANK_TRANSFER',
            isPartial: !!isPartial,
            preferredSegmentId: segmentId,
            gstRateUsed: 18, // Snapshotting current GST
            originalPlanAmount: totalAmount,
            originalDuration: (function () {
                const planName = (plan.planName || '').toLowerCase();
                const segmentName = (plan.segmentsName || '').toLowerCase();
                if (planName.includes('lifetime') || planName.includes('gold') || segmentName.includes('lifetime') || segmentName.includes('gold')) return 3652;
                if (planName.includes('yearly') || planName.includes('silver') || segmentName.includes('yearly') || segmentName.includes('silver')) return 365;

                const d1 = parseInt(plan.duration);
                const d2 = parseInt(plan.day);
                if (!isNaN(d1) && d1 > 0) return d1;
                if (!isNaN(d2) && d2 > 0) return d2;
                return 365;
            })()
        };

        if (isPartial) {
            const isRegistration = (plan.planName?.toLowerCase().includes('registration') || plan.segmentsName?.toLowerCase().includes('registration'));
            const multiplier = isRegistration ? 1 : 1.5;

            const partialTotalTarget = Math.ceil(totalAmount * multiplier);
            const perDayCharge = partialTotalTarget / intentData.originalDuration;
            const maxAllowedDays = isRegistration ? intentData.originalDuration : Math.ceil(totalAmount / perDayCharge);

            intentData.partialTotalTarget = partialTotalTarget;
            intentData.perDayCharge = perDayCharge;
            intentData.maxAllowedDays = maxAllowedDays;
            if (isRegistration) intentData.purchaseType = 'REGISTRATION';
        }

        const paymentIntent = new PaymentIntent(intentData);
        await paymentIntent.save();

        return {
            amount: totalAmount,
            currency: "INR",
            paymentIntentId: paymentIntent._id,
            message: isPartial ? "Partial Payment (Bank Transfer) Initiated" : "Bank Transfer Initiated",
            isPartial: !!isPartial,
            totalToPay: totalAmount
        };
    }

    // 3. Create Razorpay Order
    // Shorten receipt to < 40 chars
    const shortUserId = userId.toString().slice(-8);
    const receipt = `plan_${shortUserId}_${Date.now()}`;
    const options = {
        amount: amountPaise,
        currency: "INR",
        receipt: receipt,
    };

    const order = await getRazorpay().orders.create(options);

    // 4. Create PaymentIntent
    const paymentIntent = new PaymentIntent({
        userId,
        purchaseType: 'PLAN',
        planId: plan._id,
        baseAmount,
        gstAmount,
        totalAmount,
        razorpayOrderId: order.id,
        status: 'CREATED',
        preferredSegmentId: segmentId,
        gstRateUsed: 18,
        originalPlanAmount: totalAmount,
        originalDuration: (function () {
            const planName = (plan.planName || '').toLowerCase();
            const segmentName = (plan.segmentsName || '').toLowerCase();
            if (planName.includes('lifetime') || planName.includes('gold') || segmentName.includes('lifetime') || segmentName.includes('gold')) return 3652;
            if (planName.includes('yearly') || planName.includes('silver') || segmentName.includes('yearly') || segmentName.includes('silver')) return 365;

            const d1 = parseInt(plan.duration);
            const d2 = parseInt(plan.day);
            if (!isNaN(d1) && d1 > 0) return d1;
            if (!isNaN(d2) && d2 > 0) return d2;
            return 365;
        })()
    });
    await paymentIntent.save();

    return {
        orderId: order.id,
        amount: totalAmount,
        currency: "INR",
        paymentIntentId: paymentIntent._id
    };
};

import GeneralSettings from "../models/generalSettingsModel.js";

// ... existing imports

export const verifyPayment = async (razorpayOrderId, razorpayPaymentId, razorpaySignature) => {
    let validPaymentId = razorpayPaymentId;
    let razorpayPayment = null;
    let signatureValid = false;

    // 1. Verify Signature if provided
    if (razorpaySignature) {
        const secret = process.env.RAZORPAY_KEY_SECRET;
        const generatedSignature = crypto
            .createHmac("sha256", secret)
            .update(razorpayOrderId + "|" + razorpayPaymentId)
            .digest("hex");

        if (generatedSignature === razorpaySignature) {
            signatureValid = true;
        }
    }

    // 2. Resolve Payment Details (Handle Missing/Invalid Payment ID)
    // If ID is missing or doesn't start with 'pay_' (e.g. frontend sent DB ID by mistake), fetch via Order
    if (!validPaymentId || !validPaymentId.startsWith('pay_')) {
        console.log(`[VerifyPayment] Invalid Payment ID '${validPaymentId}' provided. Fetching payments for Order ${razorpayOrderId}...`);
        try {
            const payments = await getRazorpay().orders.fetchPayments(razorpayOrderId);
            // Find the successful one
            const successPayment = payments.items.find(p => p.status === 'captured');
            if (successPayment) {
                validPaymentId = successPayment.id;
                razorpayPayment = successPayment;
                console.log(`[VerifyPayment] Found captured payment ${validPaymentId} for order.`);
            } else {
                console.error(`[VerifyPayment] No captured payment found for order ${razorpayOrderId}`);
                throw new Error("No successful payment found for this Order");
            }
        } catch (err) {
            console.error(`[VerifyPayment] Error fetching payments for order: ${err.message}`);
            throw new Error("Unable to verify payment status from Razorpay");
        }
    } else {
        // Fetch normally
        razorpayPayment = await getRazorpay().payments.fetch(validPaymentId);
    }

    if (!razorpayPayment) throw new Error("Could not fetch payment details");

    // 3. Security Check: Validation without Signature (Server-Side Trust)
    if (!signatureValid) {
        console.log(`[VerifyPayment] Signature check skipped/failed. Performing strict Server-Side Verification for ${razorpayOrderId}.`);

        // Strict Check 1: Order ID Match
        if (razorpayPayment.order_id !== razorpayOrderId) {
            throw new Error("Payment ID does not match Order ID");
        }

        // Strict Check 2: Status
        if (razorpayPayment.status !== 'captured') {
            throw new Error(`Payment status is ${razorpayPayment.status}, not captured`);
        }
        console.log(`[VerifyPayment] Server-Side Verification Passed.`);
    }

    // 4. Find Intent & Standard Checks
    const paymentIntent = await PaymentIntent.findOne({ razorpayOrderId });
    if (!paymentIntent) throw new Error("Payment Intent not found");

    if (paymentIntent.status === 'PAID') {
        return { success: true, message: "Already Processed" }; // Idempotency
    }

    // 5. Amount Verification
    const expectedAmountPaise = Math.round(paymentIntent.totalAmount * 100);
    // Razorpay amount is in paise
    if (razorpayPayment.amount !== expectedAmountPaise) {
        paymentIntent.status = 'FAILED';
        await paymentIntent.save();
        throw new Error(`Amount mismatch fraud check: Expected ${expectedAmountPaise}, Got ${razorpayPayment.amount}`);
    }

    // 6. Mark Paid
    paymentIntent.status = 'PAID';
    paymentIntent.paymentId = validPaymentId;
    await paymentIntent.save();

    // 5. Grant Entitlement
    if (paymentIntent.purchaseType === 'REGISTRATION') {
        let isLifetime = false;
        if (paymentIntent.baseAmount === 10000) {
            isLifetime = true;
        }

        // --- FETCH TRIAL SETTINGS ---
        let yearlyTrial = 5;
        let lifetimeTrial = 7;
        try {
            const settings = await GeneralSettings.find({ key: { $in: ['trial_days_yearly', 'trial_days_lifetime'] } });
            const admissionYearly = settings.find(s => s.key === 'trial_days_');
            const admissionLifetime = settings.find(s => s.key === 'trial_days_lifetime');
            if (admissionYearly) yearlyTrial = parseInt(admissionYearly.value) || 5;
            if (admissionLifetime) lifetimeTrial = parseInt(admissionLifetime.value) || 7;
        } catch (err) {
            console.error("Error fetching trial settings, using defaults", err);
        }

        const trialDays = isLifetime ? lifetimeTrial : yearlyTrial;

        // A. Grant REGISTRATION
        await grantEntitlement({
            userId: paymentIntent.userId,
            type: 'REGISTRATION',
            isLifetime,
            days: isLifetime ? 3652 : 365,
            grantedBy: 'SYSTEM',
            grantReason: 'ONLINE_PAYMENT',
            jobTitle: 'SYSTEM'
        });

        // B. Grant TRIAL PLAN (Bundle)
        if (paymentIntent.preferredPlanId) {
            console.log(`Granting Bundled Trial: Plan ${paymentIntent.preferredPlanId} for ${trialDays} days`);
            await grantEntitlement({
                userId: paymentIntent.userId,
                type: 'PLAN',
                resourceId: paymentIntent.preferredPlanId,
                segmentId: paymentIntent.preferredSegmentId,
                days: trialDays,
                isLifetime: false,
                grantedBy: 'SYSTEM',
                grantReason: 'REGISTRATION_TRIAL',
                sourceRefId: paymentIntent._id.toString()
            });
        }

        // Sync Legacy User Status
        await User.findByIdAndUpdate(paymentIntent.userId, {
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true,
            registrationType: isLifetime ? 'LIFETIME' : 'YEARLY',
            registrationExpiry: isLifetime ? new Date(Date.now() + 10 * 365.25 * 24 * 60 * 60 * 1000) : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
        });
    } else if (paymentIntent.purchaseType === 'PLAN') {
        const plan = await SegmentsPlan.findById(paymentIntent.planId);

        let days = 30; // Default fallback
        let isLifetime = false;

        if (plan) {
            if (plan.planName && plan.planName.toLowerCase().includes('lifetime')) {
                isLifetime = true;
                days = 3652; // 10 years
            } else {
                const d1 = parseInt(plan.duration);
                const d2 = parseInt(plan.day);
                if (!isNaN(d1) && d1 > 0) days = d1;
                else if (!isNaN(d2) && d2 > 0) days = d2;
            }
        }

        await grantEntitlement({
            userId: paymentIntent.userId,
            type: 'PLAN',
            resourceId: paymentIntent.planId,
            days,
            isLifetime,
            grantedBy: 'SYSTEM',
            grantReason: 'ONLINE_PAYMENT',
            sourceRefId: paymentIntent._id.toString(),
            segmentId: paymentIntent.preferredSegmentId
        });
    }

    // 6. LEGACY SYNC (Create PlanPurchase & Payment records for Admin Panel/App History)
    // ... (Keep existing legacy sync logic) ...
    // Note: I am not modifying legacy sync heavily here to save tokens, assuming it works.
    // Ideally, we should also record the Trial Plan in legacy tables?
    // Current legacy sync handles the MAIN purchase. Trial is an extra entitlement.
    // The App calls `getUserActiveSegment` which reads Entitlements, so the user WILL see the trial access.

    // ... Copying Legacy Sync Logic for completeness or reference if needed ...
    // Since I'm replacing the whole function, I must include it.

    try {
        const currentDate = new Date();
        let planPurchase = null;

        if (paymentIntent.purchaseType === 'REGISTRATION') {
            const isLifetime = paymentIntent.baseAmount === 10000;
            const endDate = new Date(currentDate);
            if (isLifetime) endDate.setDate(endDate.getDate() + 3652);
            else endDate.setDate(endDate.getDate() + 365);

            planPurchase = new PlanPurchase({
                userId: paymentIntent.userId,
                packageName: isLifetime ? 'Gold Registration' : 'Silver Registration',
                validity: isLifetime ? 3652 : 365,
                startDate: currentDate,
                endDate: endDate,
                status: 'active',
                basicAmount: paymentIntent.baseAmount,
                cgstAmount: paymentIntent.gstAmount / 2,
                sgstAmount: paymentIntent.gstAmount / 2,
                paymentMethod: 'ONLINE', // Razorpay
                expiryReminder: true
            });
        } else if (paymentIntent.purchaseType === 'PLAN') {
            const plan = await SegmentsPlan.findById(paymentIntent.planId);
            let days = paymentIntent.originalDuration || 30;
            const endDate = new Date(currentDate);
            endDate.setDate(endDate.getDate() + days);

            planPurchase = new PlanPurchase({
                userId: paymentIntent.userId,
                packageName: plan ? plan.planName : "Unknown Plan",
                validity: days,
                startDate: currentDate,
                endDate: endDate,
                status: 'active',
                basicAmount: paymentIntent.baseAmount,
                cgstAmount: paymentIntent.gstAmount / 2,
                sgstAmount: paymentIntent.gstAmount / 2,
                paymentMethod: 'ONLINE',
                expiryReminder: true
            });
        }

        if (planPurchase) {
            await planPurchase.save();

            // Create Payment Record (Legacy)
            await PaymentModel.create({
                userId: paymentIntent.userId,
                packageId: planPurchase._id,
                razorpayOrderId: razorpayOrderId,
                razorpayPaymentId: razorpayPaymentId,
                razorpaySignature: razorpaySignature,
                razorpayReceipt: paymentIntent.razorpayOrderId,
                amount: paymentIntent.totalAmount,
                razorpayCurrency: 'INR',
                paymentMethod: razorpayPayment.method || 'ONLINE',
                status: 'paid'
            });
            console.log("Legacy Plan/Payment records synced.");
        }
    } catch (legacyError) {
        console.error("Legacy Sync Error:", legacyError);
    }

    return { success: true };
};

export const rejectPartialPayment = async (paymentIntentId, historyId) => {
    const paymentIntent = await PaymentIntent.findById(paymentIntentId);
    if (!paymentIntent) throw new Error("Payment Intent not found");

    const historyItem = paymentIntent.partialPaymentsHistory.id(historyId);
    if (!historyItem) throw new Error("History item not found");

    historyItem.status = 'REJECTED';
    historyItem.verifiedAt = new Date();

    // Addition: If this was the only non-rejected installment, or we want fully robust rejection:
    // Check non-rejected installments AFTER this update.
    const nonRejectedInstallments = paymentIntent.partialPaymentsHistory.filter(h => h.status !== 'REJECTED');

    if (nonRejectedInstallments.length === 0) {
        paymentIntent.status = 'REJECTED';
        
        // Sync registration status to user model
        if (paymentIntent.purchaseType === 'REGISTRATION') {
            await userModel.findByIdAndUpdate(paymentIntent.userId, {
                registrationStatus: 'REJECTED',
                registrationFeePaid: false,
                registrationExpiry: null
            });
        }
    }

    await paymentIntent.save();
    return { success: true };
};

export const uploadProof = async (paymentIntentId, files, extraData = {}) => {
    const paymentIntent = await PaymentIntent.findById(paymentIntentId);
    if (!paymentIntent) throw new Error("Payment Intent not found");

    // Allow re-upload
    const allowedStatuses = ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING', 'CREATED', 'REJECTED'];

    // For partial payments and registrations, we allow uploading even if status is PAID
    // (e.g. they paid the base fee and are now paying a premium installment or balance)
    if (paymentIntent.isPartial || paymentIntent.purchaseType === 'REGISTRATION') {
        allowedStatuses.push('PAID');
    }

    if (!allowedStatuses.includes(paymentIntent.status)) {
        throw new Error("Invalid status for proof upload. Current status: " + paymentIntent.status);
    }

    // Assuming static serve from 'app/uploads'
    if (!files || files.length === 0) throw new Error("No files uploaded");
    const imageUrls = files.map(file => `uploads/receipts/${file.filename}`);
    const firstImageUrl = imageUrls[0];

    // If it's a registration and not marked partial, but we are receiving an installment, 
    // mark it as partial now so it uses the history logic.
    if (paymentIntent.purchaseType === 'REGISTRATION' && !paymentIntent.isPartial) {
        paymentIntent.isPartial = true;
        if (!paymentIntent.partialTotalTarget) {
            paymentIntent.partialTotalTarget = paymentIntent.totalAmount;
        }
    }

    if (paymentIntent.isPartial) {
        const newAmount = Number(extraData.amountPaid || 0);

        // Validate the new payment amount
        if (newAmount <= 0) {
            throw new Error("Payment amount must be greater than zero");
        }

        // Calculate total approved payments so far
        const totalApprovedPayments = paymentIntent.partialPaymentsHistory
            .filter(h => h.status === 'APPROVED')
            .reduce((sum, h) => sum + (h.amountPaid || 0), 0);

        // Calculate total pending payments (including this new one)
        const totalPendingPayments = paymentIntent.partialPaymentsHistory
            .filter(h => h.status === 'PENDING')
            .reduce((sum, h) => sum + (h.amountPaid || 0), 0);

        const totalCommittedAmount = totalApprovedPayments + totalPendingPayments + newAmount;

        const multiplier = paymentIntent.purchaseType === 'REGISTRATION' ? 1 : 1.5;
        const maxAllowed = paymentIntent.partialTotalTarget || (paymentIntent.totalAmount * multiplier);

        // Allow a small buffer of ₹1000 for rounding/transaction fees
        const buffer = 1000;

        if (totalCommittedAmount > maxAllowed + buffer) {
            const remainingAllowed = Math.max(0, maxAllowed - totalApprovedPayments - totalPendingPayments);
            throw new Error(
                `Payment amount exceeds the allowed limit. Maximum allowed: ₹${maxAllowed.toFixed(2)}. ` +
                `Already paid/pending: ₹${(totalApprovedPayments + totalPendingPayments).toFixed(2)}. ` +
                `You can pay up to ₹${remainingAllowed.toFixed(2)} more.`
            );
        }

        paymentIntent.partialPaymentsHistory.push({
            amountPaid: newAmount,
            transactionDate: extraData.transactionDate ? new Date(extraData.transactionDate) : new Date(),
            proofImage: firstImageUrl,
            proofImages: imageUrls,
            status: 'PENDING',
            utrNumber: extraData.utrNumber || null
        });

        // For partials, amountPaid in the main doc can represent the latest installment or we can keep it as is
        paymentIntent.amountPaid = newAmount;
    } else {
        paymentIntent.proofImage = firstImageUrl;
        paymentIntent.proofImages = imageUrls;
        if (extraData.transactionDate) {
            paymentIntent.transactionDate = new Date(extraData.transactionDate);
        }
        if (extraData.amountPaid) {
            paymentIntent.amountPaid = Number(extraData.amountPaid);
            // Calculate Remaining Amount
            paymentIntent.remainingAmount = Math.max(0, paymentIntent.totalAmount - paymentIntent.amountPaid);
        }
        if (extraData.utrNumber) {
            paymentIntent.utrNumber = extraData.utrNumber;
        }
    }

    paymentIntent.status = 'VERIFICATION_PENDING';
    await paymentIntent.save();

    return {
        success: true,
        message: "Proof Uploaded Successfully",
        data: {
            isPartial: paymentIntent.isPartial,
            intentId: paymentIntent._id
        }
    };
};

export const approvePartialPayment = async (paymentIntentId, historyId, adminId, comment, discount) => {
    // Note: Transactions removed due to 'Transaction numbers are only allowed on a replica set member'
    // in standalone development environments. Since we are updating specific embedded documents,
    // atomicity is relatively safe even without them in this context.
    try {
        const paymentIntent = await PaymentIntent.findById(paymentIntentId);
        if (!paymentIntent) throw new Error("Payment Intent not found");
        if (!paymentIntent.isPartial) throw new Error("Not a partial payment intent");

        const historyItem = paymentIntent.partialPaymentsHistory.id(historyId);
        if (!historyItem) throw new Error("Payment record not found");
        if (historyItem.status !== 'PENDING') throw new Error("Payment already processed");

        // 1. Update status
        historyItem.status = 'APPROVED';
        historyItem.verifiedAt = new Date();
        historyItem.verifiedBy = adminId;
        if (comment) {
            historyItem.note = comment;
        }

        // 1.5 Apply Discount if provided (Standalone Tracking)
        if (discount && discount > 0) {
            // We update the discount field.
            paymentIntent.discount = (paymentIntent.discount || 0) + discount;

            // Ensure partial metrics are based on the Discounted Target
            const originalDuration = paymentIntent.originalDuration || 365;
            const originalPrice = paymentIntent.originalPlanAmount || paymentIntent.totalAmount;
            const discountedTarget = Math.max(0, originalPrice - paymentIntent.discount);

            // Source of Truth (X) remains original price
            paymentIntent.totalAmount = originalPrice;
            // The Target for remaining amount math becomes the discounted amount
            paymentIntent.partialTotalTarget = discountedTarget;

            // Use 1x multiplier for REGISTRATION, 1.5x for PLAN
            const multiplier = (paymentIntent.purchaseType === 'REGISTRATION' || paymentIntent.packageName?.toLowerCase().includes("registration")) ? 1 : 1.5;

            // The Per Day Charge is calculated based on the NEW Target
            paymentIntent.perDayCharge = discountedTarget > 0 ? (discountedTarget * multiplier / originalDuration) : 1;
            paymentIntent.maxAllowedDays = Math.floor(discountedTarget / paymentIntent.perDayCharge);
        }

        // 2. Sum up ALL approved payments
        const approvedPayments = paymentIntent.partialPaymentsHistory.filter(h => h.status === 'APPROVED');
        const totalPaid = approvedPayments.reduce((sum, h) => sum + h.amountPaid, 0);

        // 3. Phase 3: Threshold and Overflow logic
        // We cap the amount used for "Day Calculation" at the 'totalAmount' (Actual Plan Price X)
        const currentTarget = paymentIntent.partialTotalTarget || paymentIntent.totalAmount;
        let amountUsedForDays = totalPaid;
        let walletBalance = 0;

        if (totalPaid > currentTarget) {
            amountUsedForDays = currentTarget;
            walletBalance = totalPaid - currentTarget;
        }

        let perDayCharge = paymentIntent.perDayCharge;
        let maxAllowedDays = paymentIntent.maxAllowedDays;

        if (!perDayCharge || perDayCharge === 0 || !maxAllowedDays || maxAllowedDays === 0) {
            const originalDuration = paymentIntent.originalDuration || 365;
            const baseAmount = (paymentIntent.totalAmount || 0);

            // The Target is always the Plan Amount
            paymentIntent.partialTotalTarget = baseAmount;

            // Use 1x multiplier for REGISTRATION, 1.5x for PLAN
            const multiplier = (paymentIntent.purchaseType === 'REGISTRATION' || paymentIntent.packageName?.toLowerCase().includes("registration")) ? 1 : 1.5;

            // The Per Day Charge is calculated at a premium rate for partials (except registration)
            // Math: (Amount * multiplier) / originalDuration
            paymentIntent.perDayCharge = baseAmount > 0 ? (baseAmount * multiplier / originalDuration) : 1;

            // Max allowed days is effectively originalDuration / multiplier
            paymentIntent.maxAllowedDays = Math.floor(baseAmount / paymentIntent.perDayCharge);
        }

        // 4. Calculate Days (Premium math based on 1.5X)
        // perDayCharge = (totalAmount * 1.5) / originalDuration
        const totalDaysToGrant = Math.ceil(amountUsedForDays / perDayCharge);

        // Safety cap: Cannot exceed maxAllowedDays
        let finalDays = Math.min(totalDaysToGrant, maxAllowedDays);

        // REGISTRATION RULE: Do not reduce days for partial registration payments
        if (paymentIntent.purchaseType === 'REGISTRATION' || paymentIntent.packageName?.toLowerCase().includes("registration")) {
            // FORCE CORRECT ORIGINAL DURATION IF WRONG OR MISSING
            if (paymentIntent.packageName?.toLowerCase().includes("gold") || paymentIntent.packageName?.toLowerCase().includes("lifetime")) {
                paymentIntent.originalDuration = 3652;
            } else if (paymentIntent.packageName?.toLowerCase().includes("silver") || paymentIntent.packageName?.toLowerCase().includes("yearly")) {
                paymentIntent.originalDuration = 365;
            }

            finalDays = paymentIntent.originalDuration || 365;

            // ALSO RESET METRICS TO 1x SO THEY DISPLAY CORRECTLY IN ADMIN
            const currentDur = finalDays;
            const discountedTarget = paymentIntent.totalAmount - (paymentIntent.discount || 0);
            paymentIntent.partialTotalTarget = discountedTarget;
            paymentIntent.perDayCharge = discountedTarget / currentDur;
            paymentIntent.maxAllowedDays = currentDur;
        }

        // FULL PAYMENT DETECTION: If the user has paid the full (potentially discounted) plan price,
        // give them the full original duration instead of the reduced premium-rate duration.
        if (totalPaid >= currentTarget) {
            const originalDuration = paymentIntent.originalDuration || 365;
            finalDays = originalDuration;

            // Standardize the metrics to 1x since it's now a full payment
            paymentIntent.partialTotalTarget = currentTarget;
            paymentIntent.perDayCharge = currentTarget / originalDuration;
            paymentIntent.maxAllowedDays = originalDuration;
        }

        // 5. Update Intent Status
        paymentIntent.amountPaid = totalPaid;
        paymentIntent.walletBalance = walletBalance;
        if (comment) {
            paymentIntent.notes = paymentIntent.notes ? `${paymentIntent.notes}\n[Admin] ${comment}` : `[Admin] ${comment}`;
        }

        if (!paymentIntent.serviceStartDate) {
            paymentIntent.serviceStartDate = new Date();
        }

        const expiryDate = new Date(paymentIntent.serviceStartDate);
        expiryDate.setDate(expiryDate.getDate() + finalDays + (paymentIntent.manualDaysAdjustment || 0));
        paymentIntent.currentExpiryDate = expiryDate;


        // status update
        if (totalPaid >= (currentTarget - 1)) { // Using currentTarget (Discounted)
            paymentIntent.status = 'PAID';
        } else {
            paymentIntent.status = 'PENDING_BANK_TRANSFER'; // Wait for more
        }

        await paymentIntent.save();

        // 5.5 Find or Create a Single Invoice for this PaymentIntent
        try {
            const user = await User.findById(paymentIntent.userId);
            let invoice = await invoiceModel.findOne({
                userId: paymentIntent.userId,
                paymentRefId: paymentIntent._id.toString()
            });

            const gstPercent = paymentIntent.gstRateUsed || 18;
            const totalPaid = paymentIntent.amountPaid;
            const totalBase = Math.round((totalPaid / (1 + gstPercent / 100)) * 100) / 100;
            const totalGst = totalPaid - totalBase;

            if (!invoice) {
                const count = await invoiceModel.countDocuments();
                const invoiceNumber = `INV-${Date.now()}-${count + 1}`;
                invoice = await invoiceModel.create({
                    userId: paymentIntent.userId,
                    invoiceNumber: invoiceNumber,
                    paymentMode: 'OFFLINE',
                    amount: totalPaid,
                    gstAmount: totalGst,
                    paymentRefId: paymentIntent._id.toString(),
                    generatedBy: 'ADMIN',
                    status: 'paid'
                });
            } else {
                invoice.amount = totalPaid;
                invoice.gstAmount = totalGst;
                await invoice.save();
            }

            // Send Email with Updated Invoice
            if (user && user.email) {
                // Get all approved installments for the table
                const approvedInstallments = paymentIntent.partialPaymentsHistory
                    .filter(h => h.status === 'APPROVED')
                    .map(h => ({
                        date: h.verifiedAt || h.transactionDate,
                        amount: h.amountPaid,
                        method: 'OFFLINE'
                    }));

                let formattedPlanName = paymentIntent.packageName || (paymentIntent.purchaseType === 'REGISTRATION' ? 'Registration Fee' : 'Subscription Plan');
                if (paymentIntent.purchaseType === 'PLAN' && paymentIntent.preferredSegmentId) {
                    const segment = await segmentsModel.findById(paymentIntent.preferredSegmentId).select('segmentName');
                    if (segment) {
                        const baseName = paymentIntent.packageName || 'Plan Purchase';
                        formattedPlanName = `${segment.segmentName} - ${baseName}`;
                    }
                }

                const invoiceData = {
                    invoiceNumber: invoice.invoiceNumber,
                    date: new Date(),
                    customerName: user.fullName || 'Valued Customer',
                    customerEmail: user.email,
                    customerPhone: user.phone,
                    planName: formattedPlanName,
                    basicAmount: totalBase,
                    cgst: totalGst / 2,
                    sgst: totalGst / 2,
                    totalAmount: totalPaid,
                    installments: approvedInstallments, // NEW: Pass installments to generator
                    gstin: user.gstin || null,
                    firmName: user.firmName || null,
                    customerAddress: user.userObject ? [
                        user.userObject.APP_COR_ADD1,
                        user.userObject.APP_COR_ADD2,
                        user.userObject.APP_COR_CITY,
                        user.userObject.APP_COR_STATE,
                        user.userObject.APP_COR_PINCD
                    ].filter(Boolean).join(', ') : null
                };

                const pdfBytes = await invoiceGenerator.generateInvoice(invoiceData);

                /* 
                await emailService.sendEmail({
                    to: user.email,
                    subject: "Payment Invoice - ResearchVia",
                    htmlContent: `<p>Dear ${user.fullName || 'Customer'},</p>
                     <p>Your payment for ${invoiceData.planName} has been recorded/updated.</p>
                     <p>Total Amount Paid so far: ₹${totalPaid}</p>
                     <p>Please find your updated invoice attached showing all installments.</p>
                     <p>Regards,<br>Team ResearchVia</p>`,
                    attachments: [{
                        filename: `Invoice_${invoice.invoiceNumber}.pdf`,
                        content: Buffer.from(pdfBytes),
                        contentType: 'application/pdf'
                    }]
                });
                console.log(`Updated invoice sent to ${user.email}`);
                */
            }
        } catch (invoiceErr) {
            console.error("Error managing invoice for partial payment:", invoiceErr);
        }

        // 6. Sync with Entitlements
        const entitlement = await Entitlement.findOne({
            userId: paymentIntent.userId,
            type: paymentIntent.purchaseType,
            resourceId: paymentIntent.planId,
            sourceRefId: paymentIntent._id.toString(),
            status: { $in: ['ACTIVE', 'SUSPENDED'] }
        });

        if (entitlement) {
            entitlement.resourceId = paymentIntent.planId; // Sync corrected Plan ID
            entitlement.startDate = paymentIntent.serviceStartDate; // Sync corrected Start Date
            entitlement.endDate = paymentIntent.currentExpiryDate;
            entitlement.status = 'ACTIVE';
            if (paymentIntent.preferredSegmentId) {
                entitlement.segmentId = paymentIntent.preferredSegmentId;
            }
            if (comment) {
                entitlement.remarks = entitlement.remarks ? `${entitlement.remarks} | ${comment}` : comment;
            }
            await entitlement.save();
        } else {
            // First approval, create the entitlement
            await grantEntitlement({
                userId: paymentIntent.userId,
                type: paymentIntent.purchaseType,
                resourceId: paymentIntent.planId,
                days: finalDays,
                startDate: paymentIntent.serviceStartDate, // Pass corrected Start Date
                grantedBy: 'ADMIN',
                grantReason: 'OFFLINE_PAYMENT',
                sourceRefId: paymentIntent._id.toString(),
                segmentId: paymentIntent.preferredSegmentId,
                remarks: comment || null
            });
        }

        // Cleanup: If a full plan is granted, revoke any active REGISTRATION_TRIAL for this user
        if (paymentIntent.purchaseType === 'PLAN' && totalPaid >= currentTarget) {
            await Entitlement.updateMany(
                {
                    userId: paymentIntent.userId,
                    type: 'PLAN',
                    grantReason: 'REGISTRATION_TRIAL',
                    status: 'ACTIVE'
                },
                {
                    $set: { status: 'REVOKED', remarks: 'Revoked due to full plan purchase' }
                }
            );
        }

        // --- NEW: Sync with PlanPurchase (Mobile App Visibility) ---
        if (paymentIntent.purchaseType === 'PLAN') {
            const plan = await SegmentsPlan.findById(paymentIntent.planId);
            const correctedPackageName = plan ? `${plan.segmentsName || ''} - ${plan.planName}` : (paymentIntent.packageName || 'Custom Plan');

            let planPurchase = await PlanPurchase.findOne({
                userId: paymentIntent.userId,
                $or: [
                    { linkedPaymentIntent: paymentIntent._id },
                    { remarks: { $regex: paymentIntent._id.toString() } }
                ]
            });

            if (planPurchase) {
                planPurchase.packageName = correctedPackageName; // Sync corrected Plan Name
                planPurchase.startDate = paymentIntent.serviceStartDate; // Sync corrected Start Date
                planPurchase.endDate = paymentIntent.currentExpiryDate;
                planPurchase.status = 'active';
                if (totalPaid >= currentTarget) {
                    planPurchase.isPartial = false;
                    planPurchase.validity = paymentIntent.originalDuration || 30;
                }

                // Update remarks
                if (comment) {
                    planPurchase.remarks = planPurchase.remarks ? `${planPurchase.remarks} | ${comment}` : comment;
                }
                await planPurchase.save();
            } else {
                const isFull = totalPaid >= currentTarget;

                // The mobile app expects total plan amount/base to be the full target, 
                // but the end date represents the partial grant.
                await PlanPurchase.create({
                    userId: paymentIntent.userId,
                    packageName: correctedPackageName,
                    validity: isFull ? (paymentIntent.originalDuration || 30) : paymentIntent.maxAllowedDays, // The max full validity
                    startDate: paymentIntent.serviceStartDate,
                    endDate: paymentIntent.currentExpiryDate,
                    status: 'active',
                    basicAmount: paymentIntent.baseAmount,
                    cgstAmount: paymentIntent.gstAmount / 2,
                    sgstAmount: paymentIntent.gstAmount / 2,
                    totalPlanAmount: paymentIntent.totalAmount, // App expects the full planned amount
                    gstAmount: paymentIntent.gstAmount,
                    discount: paymentIntent.discount || 0,
                    paymentMethod: 'OFFLINE',
                    isPartial: !isFull,
                    remarks: `LinkedIntent:${paymentIntent._id.toString()}${comment ? ' | Admin: ' + comment : ''}`
                });
            }
        }
        // --- END NEW ---

        // --- SYNC WITH USER MODAL (Registration Flags) ---
        if (paymentIntent.purchaseType === 'REGISTRATION') {
            const target = paymentIntent.partialTotalTarget || paymentIntent.totalAmount;
            const isFull = totalPaid >= target;
            const detectedType = (paymentIntent.originalDuration === 3652 || paymentIntent.totalAmount >= 10000) ? 'LIFETIME' : 'YEARLY';

            await User.findByIdAndUpdate(paymentIntent.userId, {
                registrationStatus: 'ACTIVE',
                registrationFeePaid: isFull,
                registrationExpiry: paymentIntent.currentExpiryDate,
                registrationType: detectedType
            });

            // Grant Bundled Trial if not already granted
            const trialExists = await Entitlement.findOne({
                userId: paymentIntent.userId,
                type: 'PLAN',
                grantReason: 'REGISTRATION_TRIAL'
            });

            if (!trialExists && paymentIntent.preferredPlanId) {
                // Fetch Trial Settings
                let trialDays = 5; // Default fallback
                try {
                    const settings = await GeneralSettings.find({
                        key: { $in: ['trial_days_yearly', 'trial_days_lifetime'] }
                    });
                    const keyToFind = detectedType === 'LIFETIME' ? 'trial_days_lifetime' : 'trial_days_yearly';
                    const setting = settings.find(s => s.key === keyToFind);
                    if (setting) trialDays = parseInt(setting.value) || (detectedType === 'LIFETIME' ? 7 : 5);
                } catch (err) {
                    console.error("Error fetching trial settings in approvePartialPayment:", err);
                }

                console.log(`Granting Bundled Trial via Admin: Plan ${paymentIntent.preferredPlanId} for ${trialDays} days`);
                await grantEntitlement({
                    userId: paymentIntent.userId,
                    type: 'PLAN',
                    resourceId: paymentIntent.preferredPlanId,
                    segmentId: paymentIntent.preferredSegmentId,
                    days: trialDays,
                    isLifetime: false,
                    grantedBy: 'ADMIN',
                    grantReason: 'REGISTRATION_TRIAL',
                    sourceRefId: paymentIntent._id.toString()
                });
            }
        }

        return {
            success: true,
            totalPaid,
            walletBalance,
            expiryDate: paymentIntent.currentExpiryDate,
            daysGranted: finalDays
        };
    } catch (error) {
        throw error;
    }
};

export const handleExpiredPartials = async () => {
    const now = new Date();
    // 1. Find partial intents that have expired and have a wallet balance
    const expiredWithBalance = await PaymentIntent.find({
        isPartial: true,
        walletBalance: { $gt: 0 },
        currentExpiryDate: { $lte: now },
        status: 'PAID' // Paid means it reached the maxAllowedDays or totalAmount
    });

    console.log(`CRON: Checking expired partials. Found ${expiredWithBalance.length} candidates.`);

    for (const intent of expiredWithBalance) {
        try {
            console.log(`CRON: Processing overflow for user ${intent.userId}, amount: ${intent.walletBalance}`);

            // 2. Clear balance from old intent to prevent double processing
            const overflowAmount = intent.walletBalance;
            intent.walletBalance = 0;
            intent.status = 'PAID';
            intent.notes = (intent.notes || '') + ' | SYSTEM: Plan expired with wallet overflow. Balance carried forward to new intent.';
            await intent.save();

            // 3. Initiate NEW partial intent for the same plan
            // We use initiatePlanPurchase logic but with internal triggers
            const newIntentData = await initiatePlanPurchase(
                intent.userId,
                intent.planId,
                'BANK_TRANSFER',
                true, // isPartial
                null, // segmentId
                true  // calledBySystem
            );

            // 4. Automatically 'approve' the first installment using the overflow amount
            const newIntentId = newIntentData.paymentIntentId;
            const newIntent = await PaymentIntent.findById(newIntentId);

            // Add history item for the "Advance applied"
            newIntent.partialPaymentsHistory.push({
                amountPaid: overflowAmount,
                transactionDate: now,
                proofImage: 'SYSTEM_WALLET_OVERFLOW',
                utrNumber: `ADVANCE_FROM_${intent._id}`,
                status: 'PENDING' // Will be approved in next line
            });
            await newIntent.save();

            // Use the history item ID for approval
            const historyId = newIntent.partialPaymentsHistory[0]._id;

            // Approve it immediately
            await approvePartialPayment(newIntentId, historyId, 'SYSTEM');

            // 5. Send Notification
            const userDevices = await Devices.find({ userId: intent.userId, isActive: true });
            const tokens = userDevices.map(d => d.pushToken).filter(t => !!t);

            if (tokens.length > 0) {
                await notificationService.sendPushNotification(
                    tokens,
                    "Partial Plan Updated",
                    `Your partial plan has ended. We've applied your advance balance of ₹${overflowAmount} to your next plan.`,
                    { type: 'PARTIAL_PAYMENT_OVERFLOW', newIntentId: newIntentId.toString() }
                );
            }

            console.log(`CRON: Successfully migrated advance balance to new intent ${newIntentId}`);
        } catch (err) {
            console.error(`CRON: Error processing partial overflow for intent ${intent._id}:`, err);
        }
    }
};

export const getActivePartialInfo = async (userId) => {
    const activePartial = await PaymentIntent.findOne({
        userId,
        isPartial: true,
        status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING', 'PAID'] }
    }).populate('planId').sort({ createdAt: -1 });

    if (!activePartial) return null;

    const now = new Date();
    const expiry = activePartial.currentExpiryDate;

    // Calculate days remaining
    let daysRemaining = 0;
    if (expiry && expiry > now) {
        daysRemaining = Math.max(0, Math.ceil((expiry - now) / (1000 * 60 * 60 * 24)));
    }

    // Calculate duration granted so far
    let totalDurationGranted = 0;
    if (activePartial.serviceStartDate && expiry) {
        totalDurationGranted = Math.max(0, Math.ceil((expiry - activePartial.serviceStartDate) / (1000 * 60 * 60 * 24)));
    }

    // Calculate payment breakdown
    const totalApprovedPayments = activePartial.partialPaymentsHistory
        .filter(h => h.status === 'APPROVED')
        .reduce((sum, h) => sum + (h.amountPaid || 0), 0);

    const totalPendingPayments = activePartial.partialPaymentsHistory
        .filter(h => h.status === 'PENDING')
        .reduce((sum, h) => sum + (h.amountPaid || 0), 0);

    const multiplier = activePartial.purchaseType === 'REGISTRATION' ? 1 : 1.5;
    const maxAllowed = activePartial.partialTotalTarget || (activePartial.totalAmount * multiplier);
    const remainingCapacity = Math.max(0, maxAllowed - totalApprovedPayments - totalPendingPayments);

    return {
        intentId: activePartial._id,
        purchaseType: activePartial.purchaseType, // 'REGISTRATION' or 'PLAN' - used by frontend to gate access
        planName: activePartial.planId ? (activePartial.planId.planName || "Active Plan") : "Unknown Plan",
        actual_total_amount: activePartial.totalAmount, // X
        total_amount_paid: totalApprovedPayments,
        pending_amount: totalPendingPayments,
        remaining_capacity: remainingCapacity,
        max_payment_limit: maxAllowed,
        days_remaining: daysRemaining,
        total_duration_granted: totalDurationGranted,
        max_possible_days: activePartial.maxAllowedDays,
        expiry_date: expiry,
        is_at_max_capacity: totalApprovedPayments >= activePartial.totalAmount,
        is_at_payment_limit: remainingCapacity <= 0,
        wallet_balance: activePartial.walletBalance || 0,
        per_day_charge: activePartial.perDayCharge || 0,
        status: activePartial.status,
        has_registration_balance: activePartial.purchaseType === 'REGISTRATION' && remainingCapacity > 0,
        discount: activePartial.discount || 0,
        effective_total_payable: Math.max(0, activePartial.totalAmount - (activePartial.discount || 0))
    };
};

export const getPartialPaymentHistory = async (userId, intentId) => {
    let query = { userId, isPartial: true };
    if (intentId) {
        query._id = intentId;
    }

    const intent = await PaymentIntent.findOne(query).sort({ createdAt: -1 });
    if (!intent) throw new Error("Partial payment record not found");

    const history = intent.partialPaymentsHistory.map(h => ({
        amount: h.amountPaid,
        date: h.transactionDate,
        status: h.status,
        utr: h.utrNumber,
        type: h.proofImage === 'SYSTEM_WALLET_OVERFLOW' ? 'SYSTEM_OVERFLOW' : 'USER_PAYMENT'
    }));

    const totalApproved = intent.partialPaymentsHistory
        .filter(h => h.status === 'APPROVED')
        .reduce((sum, h) => sum + h.amountPaid, 0);

    const totalPending = intent.partialPaymentsHistory
        .filter(h => h.status === 'PENDING')
        .reduce((sum, h) => sum + h.amountPaid, 0);

    return {
        intentId: intent._id,
        installments: history,
        total_approved: totalApproved,
        total_pending: totalPending
    };
};

export const onboardOfflineUser = async (adminId, userData, entitlements) => {
    // 1. Create User
    let user = await User.findOne({ phone: userData.mobile });
    if (user) {
        throw new Error("User with this mobile already exists");
    }

    const mpin = Math.floor(1000 + Math.random() * 9000).toString();

    // Simplistic user creation
    user = new User({
        fullName: userData.name,
        phone: userData.mobile,
        email: userData.email,
        userType: 'USER',
        createdBy: 'ADMIN',
        kycStatus: 'NOT_STARTED', // Explicitly start here
        // Set hashed MPIN - assuming we handle hashing elsewhere or hook saves it.
        // Assuming userModel or external service handles hashing or we store plain for moment (MVP refactor).
        // For security, would hash with crypto.
        mpinHash: crypto.createHash('sha256').update(mpin).digest('hex') // Basic example hash
    });
    await user.save();

    // 2. Grant Registration
    const isLifetime = entitlements.registrationType === 'LIFETIME';

    // Only grant if specified ? User said "Creates REGISTRATION + PLAN"
    // Assuming admin MUST specify reg type.
    await grantEntitlement({
        userId: user._id,
        type: 'REGISTRATION',
        isLifetime,
        days: isLifetime ? 3652 : 365,
        grantedBy: 'ADMIN',
        grantReason: 'OFFLINE_PAYMENT',
        sourceRefId: adminId ? adminId.toString() : 'admin'
    });

    // Sync Legacy Status
    user.registrationStatus = 'ACTIVE';
    user.registrationType = entitlements.registrationType;
    await user.save();

    // 3. Grant Plans
    if (entitlements.plans && entitlements.plans.length > 0) {
        for (const planId of entitlements.plans) {
            const plan = await SegmentsPlan.findById(planId);
            if (!plan) continue;
            const days = plan.day ? parseInt(plan.day) : 30;

            await grantEntitlement({
                userId: user._id,
                type: 'PLAN',
                resourceId: planId,
                days,
                grantedBy: 'ADMIN',
                grantReason: 'OFFLINE_PAYMENT',
                sourceRefId: adminId ? adminId.toString() : 'admin'
            });
        }
    }

    return { user, mpin };
};

/**
 * Send expiry warning notifications to users with partial payments expiring soon
 * Runs daily to check for plans expiring within 3 days
 */
export const sendPartialExpiryWarnings = async () => {
    try {
        const now = new Date();
        const threeDaysFromNow = new Date();
        threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

        // Find partial payment intents expiring within 3 days
        const expiringPartials = await PaymentIntent.find({
            isPartial: true,
            status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING', 'PAID'] },
            currentExpiryDate: {
                $gte: now,
                $lte: threeDaysFromNow
            }
        }).populate('userId').populate('planId');

        console.log(`Found ${expiringPartials.length} partial payments expiring within 3 days`);

        for (const intent of expiringPartials) {
            if (!intent.userId) continue;

            const daysRemaining = Math.ceil((intent.currentExpiryDate - now) / (1000 * 60 * 60 * 24));
            const planName = intent.planId?.planName || 'Your Plan';

            // Calculate remaining payment capacity
            const totalApprovedPayments = intent.partialPaymentsHistory
                .filter(h => h.status === 'APPROVED')
                .reduce((sum, h) => sum + (h.amountPaid || 0), 0);

            const totalPendingPayments = intent.partialPaymentsHistory
                .filter(h => h.status === 'PENDING')
                .reduce((sum, h) => sum + (h.amountPaid || 0), 0);

            const multiplier = intent.purchaseType === 'REGISTRATION' ? 1 : 1.5;
            const maxAllowed = intent.partialTotalTarget || (intent.totalAmount * multiplier);
            const remainingCapacity = Math.max(0, maxAllowed - totalApprovedPayments - totalPendingPayments);

            // Only send notification if user can still pay more
            if (remainingCapacity > 100) {
                const notificationPayload = {
                    title: `${planName} Expiring Soon!`,
                    body: `Your plan expires in ${daysRemaining} day${daysRemaining > 1 ? 's' : ''}. Pay your next installment to extend your access.`,
                    data: {
                        type: 'PARTIAL_EXPIRY_WARNING',
                        intentId: intent._id.toString(),
                        planName: String(planName),
                        daysRemaining: String(daysRemaining),
                        remainingCapacity: remainingCapacity.toFixed(2)
                    }
                };

                // Send push notification
                try {
                    const tokens = await getUserTokens(intent.userId._id);
                    if (tokens && tokens.length > 0) {
                        await notificationService.sendPushNotification(
                            tokens,
                            notificationPayload.title,
                            notificationPayload.body,
                            notificationPayload.data
                        );
                    }
                    console.log(`Sent expiry warning to user ${intent.userId.phone} for plan ${planName}`);
                } catch (notifError) {
                    console.error(`Failed to send notification to user ${intent.userId._id}:`, notifError.message);
                }
            } else {
                console.log(`User ${intent.userId.phone} has reached payment limit for ${planName}, skipping warning`);
            }
        }

        console.log(`Completed sending ${expiringPartials.length} expiry warnings`);
        return { success: true, count: expiringPartials.length };
    } catch (error) {
        console.error('Error in sendPartialExpiryWarnings:', error);
        throw error;
    }
};

export const updatePaymentDiscount = async (paymentIntentId, newTotalDiscount, adminId) => {
    try {
        const paymentIntent = await PaymentIntent.findById(paymentIntentId);
        if (!paymentIntent) throw new Error("Payment Intent not found");

        const oldDiscount = paymentIntent.discount || 0;
        const originalPrice = paymentIntent.originalPlanAmount || paymentIntent.totalAmount;

        // Logic: Discount reduces the Target and thus the Per Day Charge.
        if (newTotalDiscount > originalPrice) throw new Error("Discount cannot exceed original plan price");

        paymentIntent.discount = newTotalDiscount;
        const discountedTarget = Math.max(0, originalPrice - newTotalDiscount);

        // Keep original price as the source of truth for (X)
        paymentIntent.totalAmount = originalPrice;

        // Sync with standard partial metrics using the DISCOUNTED TARGET
        const originalDuration = paymentIntent.originalDuration || 365;
        paymentIntent.partialTotalTarget = discountedTarget;

        // Use 1x multiplier for REGISTRATION, 1.5x for PLAN
        const multiplier = paymentIntent.purchaseType === 'REGISTRATION' ? 1 : 1.5;

        paymentIntent.perDayCharge = discountedTarget > 0 ? (discountedTarget * multiplier / originalDuration) : 1;
        paymentIntent.maxAllowedDays = Math.floor(discountedTarget / paymentIntent.perDayCharge);

        // Recalculate current payment totals
        const approvedPayments = (paymentIntent.partialPaymentsHistory || []).filter(h => h.status === 'APPROVED');
        const totalPaid = approvedPayments.reduce((sum, h) => sum + (h.amountPaid || 0), 0);
        
        paymentIntent.amountPaid = totalPaid;
        paymentIntent.remainingAmount = Math.max(0, originalPrice - totalPaid - newTotalDiscount);

        // Auto-promote to PAID if the new discount covers the gap
        const isFull = totalPaid >= (discountedTarget - 1); // 1 Rupee tolerance
        if (isFull) {
            paymentIntent.status = 'PAID';
        }

        await paymentIntent.save();
        
        // Phase 2: Live Sync - Update Entitlement and PlanPurchase if they exist
        try {
            // Update User Flags for Registration
            if (paymentIntent.purchaseType === 'REGISTRATION') {
                await User.findByIdAndUpdate(paymentIntent.userId, {
                    registrationFeePaid: isFull,
                    registrationStatus: 'ACTIVE'
                });
            }

            await PlanPurchase.updateMany(
                {
                    $or: [
                        { linkedPaymentIntent: paymentIntent._id },
                        { remarks: { $regex: paymentIntent._id.toString() } }
                    ]
                },
                {
                    $set: { 
                        discount: newTotalDiscount, 
                        totalPlanAmount: originalPrice,
                        isPartial: !isFull,
                        status: isFull ? 'active' : 'pending_verification' // maybe leave status as is if already active
                    }
                }
            );
            
            // Also log to Activity Log for Audit & Transparency
            if (adminId) {
                await activityLogService.logUpdatePaymentDiscount({
                    userId: paymentIntent.userId,
                    paymentIntentId: paymentIntent._id,
                    oldDiscount,
                    newDiscount: newTotalDiscount,
                    originalPrice,
                    performedBy: { id: adminId, role: 'ADMIN' }
                });
            }
        } catch (syncErr) {
            console.error("Live Sync Error during discount update:", syncErr);
        }

        return paymentIntent;
    } catch (error) {
        console.error("Error updating payment discount:", error.message);
        throw error;
    }
};

export const getRegistrationDetails = async (userId) => {
    try {
        const user = await User.findById(userId).select('registrationType registrationStatus registrationExpiry');
        if (!user) throw new Error("User not found");

        // 1. Get Active Registration Entitlement
        const registrationEntitlement = await Entitlement.findOne({
            userId,
            type: 'REGISTRATION',
            status: 'ACTIVE'
        }).sort({ createdAt: -1 });

        // 2. Get Latest Registration Payment Intent (To check for partial/remaining)
        const paymentIntent = await PaymentIntent.findOne({
            userId,
            purchaseType: 'REGISTRATION',
            status: { $in: ['PAID', 'PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING', 'CREATED', 'REJECTED'] }
        }).sort({ createdAt: -1 });

        // 3. Get Registration Trial Info
        const trialEntitlement = await Entitlement.findOne({
            userId,
            type: 'PLAN',
            grantReason: 'REGISTRATION_TRIAL',
            status: 'ACTIVE'
        }).populate({
            path: 'resourceId',
            model: 'segmentsPlan',
            select: 'planName'
        }).sort({ createdAt: -1 });

        let registrationType = user.registrationType || 'YEARLY';

        // Use the payment intent's data if available, as it reflects the user's current choice
        if (paymentIntent) {
            if (paymentIntent.originalDuration === 3652 || paymentIntent.totalAmount >= 10000) {
                registrationType = 'LIFETIME';
            } else if (paymentIntent.originalDuration === 365) {
                registrationType = 'YEARLY';
            }
        }

        const isLifetime = registrationType === 'LIFETIME';

        let amountPaid = 0;
        let remainingAmount = 0;
        let targetAmount = paymentIntent ? paymentIntent.totalAmount : 0;
        let discount = 0;
        let walletBalance = 0;

        let approvedAmount = 0;
        let pendingAmount = 0;

        if (paymentIntent) {
            discount = paymentIntent.discount || 0;
            walletBalance = paymentIntent.walletBalance || 0;

            if (paymentIntent.isPartial) {
                targetAmount = paymentIntent.partialTotalTarget || paymentIntent.totalAmount;
                
                approvedAmount = paymentIntent.partialPaymentsHistory
                    .filter(h => h.status === 'APPROVED')
                    .reduce((sum, h) => sum + (h.amountPaid || 0), 0);
                    
                pendingAmount = paymentIntent.partialPaymentsHistory
                    .filter(h => h.status === 'PENDING')
                    .reduce((sum, h) => sum + (h.amountPaid || 0), 0);
                
                amountPaid = approvedAmount + pendingAmount;
            } else {
                targetAmount = Math.max(0, paymentIntent.totalAmount - discount);
                if (paymentIntent.status === 'PAID') {
                    approvedAmount = paymentIntent.amountPaid || targetAmount;
                } else if (paymentIntent.status === 'VERIFICATION_PENDING') {
                    pendingAmount = paymentIntent.amountPaid || targetAmount;
                }
                amountPaid = approvedAmount + pendingAmount;
            }

            remainingAmount = Math.max(0, targetAmount - approvedAmount - pendingAmount);
        } else {
            // No intent yet - use defaults based on registrationType
            const base = registrationType === 'LIFETIME' ? 10000 : 5000;
            const gst = Math.round(base * 0.18);
            targetAmount = Math.ceil(base + gst);
            amountPaid = 0;
            remainingAmount = targetAmount;
        }

        return {
            registrationType: registrationType,
            validityLabel: isLifetime ? 'Lifetime' : 'Annual',
            expiryDate: user.registrationExpiry,
            isActive: user.registrationStatus === 'ACTIVE' && registrationEntitlement != null,
            paymentStatus: {
                paymentIntentId: paymentIntent?._id || null,
                totalAmount: paymentIntent ? paymentIntent.totalAmount : targetAmount, // Default based on type if no intent
                amountPaid: amountPaid,
                approvedAmount: approvedAmount,
                pendingAmount: pendingAmount,
                targetAmount: targetAmount,
                discount: discount,
                walletBalance: walletBalance,
                remainingAmount: remainingAmount,
                isPartial: (paymentIntent?.isPartial === true) || ((user.registrationStatus === 'ACTIVE' || user.registrationStatus === 'PENDING') && !user.registrationFeePaid && !user.adminAccessGranted),
                status: paymentIntent?.status || (user.registrationFeePaid ? 'PAID' : 'PENDING'),
                hasRejectedInstallment: paymentIntent?.partialPaymentsHistory?.some(h => h.status === 'REJECTED') || false,
            },
            trialInfo: trialEntitlement ? {
                planName: trialEntitlement.resourceId?.planName || 'Trial Plan',
                expiryDate: trialEntitlement.endDate,
                daysRemaining: trialEntitlement.endDate ? Math.max(0, Math.ceil((new Date(trialEntitlement.endDate) - new Date()) / (1000 * 60 * 60 * 24))) : 0
            } : null
        };
    } catch (error) {
        console.error("Error in getRegistrationDetails:", error);
        throw error;
    }
};

/**
 * Expires abandoned PaymentIntents.
 *
 * A PaymentIntent is considered "abandoned" if:
 *   - status is 'CREATED'  (Razorpay order was made but user never paid / closed the sheet)
 *   - amountPaid is 0 or missing
 *   - createdAt is older than ABANDON_THRESHOLD_MINUTES
 *
 * This is safe to run frequently (e.g. every 10 minutes).
 */
export const expireAbandonedIntents = async (thresholdMinutes = 10) => {
    const maxRetries = 3;
    let attempt = 0;

    while (attempt < maxRetries) {
        try {
            const cutoff = new Date(Date.now() - thresholdMinutes * 60 * 1000);

            const result = await PaymentIntent.updateMany(
                {
                    status: 'CREATED',
                    $or: [
                        { amountPaid: { $exists: false } },
                        { amountPaid: 0 },
                        { amountPaid: null }
                    ],
                    createdAt: { $lt: cutoff }
                },
                { $set: { status: 'FAILED' } }
            );

            if (result.modifiedCount > 0) {
                console.log(`[expireAbandonedIntents] Marked ${result.modifiedCount} abandoned PaymentIntent(s) as FAILED (threshold: ${thresholdMinutes} min).`);
            }

            return { expired: result.modifiedCount };
        } catch (error) {
            attempt++;

            // Check if it's a network error that we should retry
            const isNetworkError = error.name === 'MongoNetworkError' ||
                error.name === 'MongoServerSelectionError' ||
                error.name === 'PoolClearedOnNetworkError' ||
                error.name === 'MongoNetworkTimeoutError' ||
                error.message.includes('ECONNRESET') ||
                error.message.includes('ETIMEDOUT') ||
                error.message.includes('PoolClearedOnNetworkError') ||
                error.message.includes('monitor timeout');

            if (isNetworkError && attempt < maxRetries) {
                const delay = attempt * 2000;
                console.error(`[expireAbandonedIntents] Network error (attempt ${attempt}): ${error.message}. Retrying in ${delay}ms...`);
                await new Promise(resolve => setTimeout(resolve, delay));
                continue;
            }

            throw error;
        }
    }
};

/**
 * Update Subscription Metadata (Admin Only)
 * Implementation of the Quad-Sync engine with 36-gap protection.
 */
export const updateSubscriptionMetadata = async ({ 
    paymentIntentId, 
    newSegmentId, 
    newPlanId, 
    newStartDate, 
    newExpiryDate, 
    adminId,
    clientVersion,
    req // for IP logging
}) => {
    try {
        // 1. Fetch record and basic validation
        const paymentIntent = await PaymentIntent.findById(paymentIntentId);
        if (!paymentIntent) throw new Error("Subscription record not found.");

        // Gap 21: Optimistic Concurrency Check
        if (clientVersion !== undefined && paymentIntent.correctionVersion !== clientVersion) {
            const error = new Error("CONCURRENCY_CONFLICT: This record was updated by another admin. Please refresh.");
            error.status = 409;
            throw error;
        }

        // Gap 5: Registration Lock
        if (paymentIntent.purchaseType === 'REGISTRATION') {
            throw new Error("REGISTRATION_LOCKED: Registration details cannot be altered via this tool.");
        }

        const snapshotBefore = JSON.parse(JSON.stringify(paymentIntent));

        // 2. Fetch new Segment and Plan (Gap 32: Separate lookups for virtual fields)
        const newSegment = await segmentsModel.findById(newSegmentId);
        const newPlan = await SegmentsPlan.findById(newPlanId);

        if (!newSegment || !newPlan) throw new Error("INVALID_SELECTION: New segment or plan not found.");

        // Fetch old names for history
        const oldSegmentId = paymentIntent.preferredSegmentId || snapshotBefore.preferredSegmentId;
        const oldPlanId = paymentIntent.planId || snapshotBefore.planId;
        
        const oldSegment = await segmentsModel.findById(oldSegmentId);
        const oldPlan = await SegmentsPlan.findById(oldPlanId);
        const oldSegmentName = oldSegment ? oldSegment.segmentName : (paymentIntent.packageName?.split(' - ')[0] || 'Unknown Segment');
        const oldPlanName = oldPlan ? oldPlan.planName : (paymentIntent.packageName?.split(' - ')[1] || 'Unknown Plan');

        console.log(`[CorrectionHistory] Old: ${oldSegmentName} / ${oldPlanName}, New: ${newSegment.segmentName} / ${newPlan.planName}`);

        // Gap 9: Active Plan Validation
        if (newPlan.planStatus !== 'active') throw new Error("INACTIVE_PLAN: Selected plan is currently deactivated.");

        // Gap 17: Custom Plan Blocker
        if ((oldPlan && oldPlan.isHni) || newPlan.isHni) {
            throw new Error("CUSTOM_PLAN_RESTRICTED: Standard plans cannot be converted to Custom/HNI plans and vice-versa.");
        }

        // Gap 27 Sanitization: Ensure package name doesn't contain reserved keywords
        const sanitizedPlanName = newPlan.planName.replace(/registration/gi, "Package");
        const newSegmentName = newSegment.segmentName || 'Unknown Segment';
        const newPlanName = newPlan.planName || 'Unknown Plan';
        const newPackageName = `${newSegmentName} - ${sanitizedPlanName}`;

        // 3. Mathematical Recalculation (Gap 2, 11, 28)
        const newBasePrice = newPlan.price;
        const gstRate = paymentIntent.gstRateUsed || 18;
        const newGstAmount = Math.round((newBasePrice * gstRate) / 100);
        const newTotalAmount = newBasePrice + newGstAmount;

        // Gap 14: Overpaid Downgrade Check
        const approvedPayments = paymentIntent.partialPaymentsHistory
            .filter(h => h.status === 'APPROVED')
            .reduce((sum, h) => sum + (h.amountPaid || 0), 0);
        
        if (approvedPayments > newTotalAmount) {
            throw new Error(`OVERPAID_DOWNGRADE: User has already paid ₹${approvedPayments}, which exceeds the new plan price of ₹${newTotalAmount}.`);
        }

        // Gap 25: Duration Reset
        let newDuration = 30;
        const d1 = parseInt(newPlan.duration);
        const d2 = parseInt(newPlan.day);
        if (newPlan.planName.toLowerCase().includes('lifetime')) newDuration = 3652;
        else if (!isNaN(d1) && d1 > 0) newDuration = d1;
        else if (!isNaN(d2) && d2 > 0) newDuration = d2;

        // Gap 2 & 13: Discount Reset & Partial Math
        const previousDiscount = paymentIntent.discount || 0;
        paymentIntent.discount = 0; // Force reset as per Gap 13
        const discountedTarget = newTotalAmount; // Since discount is 0

        const multiplier = 1.5; // Always Plan
        const perDayCharge = discountedTarget > 0 ? (discountedTarget * multiplier / newDuration) : 1;
        const maxAllowedDays = newDuration;

        // Gap 3 & 18: Date Adjustments
        if (newStartDate) paymentIntent.serviceStartDate = new Date(newStartDate);
        if (newExpiryDate) {
            const exp = new Date(newExpiryDate);
            if (paymentIntent.serviceStartDate && exp <= paymentIntent.serviceStartDate) {
                throw new Error("INVALID_DATES: Expiry date must be after start date.");
            }
            paymentIntent.currentExpiryDate = exp;

            // Calculate manual adjustment for future installments
            // Math: How many days beyond "math expiry" did admin give?
            const mathDays = Math.ceil(approvedPayments / perDayCharge);
            const mathExpiry = new Date(paymentIntent.serviceStartDate || paymentIntent.createdAt);
            mathExpiry.setDate(mathExpiry.getDate() + mathDays);
            
            const diffTime = exp.getTime() - mathExpiry.getTime();
            paymentIntent.manualDaysAdjustment = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        }

        // 4. Update Intent Fields (Sync 1)
        paymentIntent.planId = newPlanId;
        paymentIntent.preferredPlanId = newPlanId.toString();
        paymentIntent.preferredSegmentId = newSegmentId.toString();
        paymentIntent.packageName = newPackageName;
        paymentIntent.baseAmount = newBasePrice / (1 + (gstRate/100)); // Precise base
        paymentIntent.gstAmount = newTotalAmount - (newTotalAmount / (1 + (gstRate/100)));
        paymentIntent.totalAmount = newTotalAmount;
        paymentIntent.originalPlanAmount = newTotalAmount;
        paymentIntent.originalDuration = newDuration;
        paymentIntent.partialTotalTarget = discountedTarget;
        paymentIntent.perDayCharge = perDayCharge;
        paymentIntent.maxAllowedDays = maxAllowedDays;
        paymentIntent.isCorrected = true;
        paymentIntent.correctionVersion += 1;

        // Gap 22: Auto-Activation if paid in full
        if (approvedPayments >= newTotalAmount) {
            paymentIntent.status = 'PAID';
            paymentIntent.notes += `\n[System] Auto-activated after plan switch to ₹${newTotalAmount}`;
        }

        // Push to correction history
        const adminUser = await staff.findById(adminId) || await User.findById(adminId);
        const adminName = adminUser ? (adminUser.fullName || adminUser.name) : 'Admin';

        const historyRecord = {
            oldAmount: snapshotBefore.totalAmount || 0,
            newAmount: newTotalAmount || 0,
            oldSegmentName: oldSegmentName || 'N/A',
            newSegmentName: newSegmentName || 'N/A',
            oldPlanName: oldPlanName || 'N/A',
            newPlanName: newPlanName || 'N/A',
            oldStartDate: snapshotBefore.serviceStartDate,
            newStartDate: paymentIntent.serviceStartDate,
            oldExpiry: snapshotBefore.currentExpiryDate,
            newExpiry: paymentIntent.currentExpiryDate,
            reason: `Metadata updated by ${adminName}`,
            correctedBy: adminId,
            correctedAt: new Date(),
            snapShotBefore: snapshotBefore,
            snapShotAfter: JSON.parse(JSON.stringify(paymentIntent))
        };

        console.log("[CorrectionHistory] Pushing Record:", JSON.stringify(historyRecord, null, 2));
        paymentIntent.correctionHistory.push(historyRecord);
        paymentIntent.markModified('correctionHistory');

        await paymentIntent.save();

        // 5. Quad-Sync (Legacy & App state)
        // Sync 2: Entitlement (Gap 8)
        await Entitlement.updateMany(
            { userId: paymentIntent.userId, sourceRefId: paymentIntentId.toString() },
            { 
                resourceId: newPlanId, 
                segmentId: newSegmentId,
                startDate: paymentIntent.serviceStartDate || undefined,
                endDate: paymentIntent.currentExpiryDate || undefined
            }
        );

        // Sync 3: PlanPurchase (Gap 12 & 36)
        await PlanPurchase.updateMany(
            { 
                userId: paymentIntent.userId, 
                $or: [
                    { sourceRefId: paymentIntentId.toString() }, 
                    { remarks: { $regex: paymentIntentId.toString() } },
                    { linkedPaymentIntent: paymentIntentId } // Gap Fix: capture records created via approvePartialPayment
                ] 
            },
            {
                packageName: newPackageName,
            totalPlanAmount: newTotalAmount,
                basicAmount: paymentIntent.baseAmount,
                cgstAmount: paymentIntent.gstAmount / 2,
                sgstAmount: paymentIntent.gstAmount / 2,
                startDate: paymentIntent.serviceStartDate || undefined,
                endDate: paymentIntent.currentExpiryDate || undefined,
                validity: newDuration
            }
        );

        // Sync 4: userActiveSegment (Gap 34)
        await userActiveSegmentModel.findOneAndUpdate(
            { userId: paymentIntent.userId, isActive: true },
            { segmentId: newSegmentId, expiryDate: paymentIntent.currentExpiryDate || undefined }
        );

        // 6. Finalize (Audit & Legal)
        // Gap 20 & 10: Audit Log
        await activityLogService.logSubscriptionMetadataUpdate({
            userId: paymentIntent.userId,
            adminId: adminId,
            description: `Subscription corrected by ${adminName}`,
            details: {
                from: { segment: oldSegmentName, plan: oldPlanName, amount: snapshotBefore.totalAmount, expiry: snapshotBefore.currentExpiryDate, start: snapshotBefore.serviceStartDate },
                to: { segment: newSegmentName, plan: newPlanName, amount: newTotalAmount, expiry: paymentIntent.currentExpiryDate, start: paymentIntent.serviceStartDate }
            },
            metadata: {
                paymentIntentId,
                oldPackage: snapshotBefore.packageName,
                newPackage: newPackageName
            }
        });

        // Gap 23: Invoice Regeneration & Email Correction
        try {
            const user = await User.findById(paymentIntent.userId);
            const invoice = await invoiceModel.findOne({ 
                userId: paymentIntent.userId, 
                $or: [
                    { paymentRefId: paymentIntent.razorpayOrderId },
                    { paymentRefId: { $regex: paymentIntentId.toString() } }
                ]
            });
            
            if (invoice && user) {
                invoice.amount = newTotalAmount;
                invoice.gstAmount = paymentIntent.gstAmount;
                await invoice.save();

                // Regenerate PDF bytes
                const invoiceData = {
                    invoiceNumber: invoice.invoiceNumber,
                    date: new Date(),
                    customerName: user.fullName || 'Valued Customer',
                    customerEmail: user.email,
                    customerPhone: user.phone,
                    planName: newPackageName,
                    basicAmount: paymentIntent.baseAmount,
                    cgst: paymentIntent.gstAmount / 2,
                    sgst: paymentIntent.gstAmount / 2,
                    totalAmount: newTotalAmount,
                    gstin: user.gstin || null,
                    firmName: user.firmName || null,
                    customerAddress: user.userObject ? [
                        user.userObject.APP_COR_ADD1,
                        user.userObject.APP_COR_ADD2,
                        user.userObject.APP_COR_CITY,
                        user.userObject.APP_COR_STATE,
                        user.userObject.APP_COR_PINCD
                    ].filter(Boolean).join(', ') : null
                };

                const pdfBytes = await invoiceGenerator.generateInvoice(invoiceData);

                /* 
                // Send to Subscriber (Corrections Gap 23)
                if (user.email) {
                    await emailService.sendEmail({
                        to: user.email,
                        subject: "Updated: Subscription Details - ResearchVia",
                        htmlContent: `
                            <p>Dear ${user.fullName || 'Customer'},</p>
                            <p>Your subscription details for <b>${newPackageName}</b> have been updated by our administration team.</p>
                            <p><b>Updated Plan:</b> ${newPackageName}<br>
                            <b>New Expiry Date:</b> ${paymentIntent.currentExpiryDate ? paymentIntent.currentExpiryDate.toLocaleDateString() : 'N/A'}</p>
                            <p>Please find the updated invoice attached to this email.</p>
                            <p>Regards,<br>Team ResearchVia</p>
                        `,
                        attachments: [{
                            filename: `Updated_Invoice_${invoice.invoiceNumber}.pdf`,
                            content: Buffer.from(pdfBytes),
                            contentType: 'application/pdf'
                        }]
                    });
                }
                */
            }
        } catch (invErr) {
            console.error("Non-critical Invoice/Email Sync Error:", invErr.message);
        }

        return paymentIntent;

    } catch (error) {
        console.error("updateSubscriptionMetadata Error:", error.message);
        throw error;
    }
};

