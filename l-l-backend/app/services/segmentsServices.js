import segmentsModel from "../models/segmentsModel.js";
import segmentsPlanModel from "../models/segmentsPlansModel.js";
import userModel from "../models/userModel.js";
import segmentsPaymentModel from "../models/segmentsPaymentModel.js";
import Razorpay from "razorpay";
import crypto from "crypto";
import userActiveSegmentModel from "../models/userActiveSegmentsModel.js";
import invoiceModel from "../models/invoiceModel.js";
import segments from "../models/segmentsModel.js";
import { grantEntitlement } from "./entitlementService.js"; // CHUNK 7 Integration
import Entitlement from "../models/entitlementModel.js"; // CHUNK 9 Audit Fix
import PaymentIntent from "../models/paymentIntentModel.js";
import planPurchaseModel from "../models/planPurchaseModel.js";
import GeneralSettings from "../models/generalSettingsModel.js";
import HniRequest from "../models/hniRequestModel.js";
import AdminAuditLog from "../models/adminAuditLogModel.js";
import { approvePartialPayment } from "./acquisitionService.js";
import mongoose from "mongoose";
import staffModel from "../models/staffModel.js";
import staffAssigmentModel from "../models/staffAssignmentModel.js";

const segmentsService = {
  createSegments: async ({ body }) => {
    try {
      const payload = { ...body };
      const segment = new segmentsModel(payload);
      await segment.save();
      return { status: 201, message: "segments created", data: { segment } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  updateSegments: async ({ query, body }) => {
    try {
      let { segmentId } = query;
      let { segmentName, segmentDiscription } = body;
      const segments = await segmentsModel.findOne({ _id: segmentId });
      if (!segments) {
        return { status: 200, message: "segments not found", data: {} };
      } else {
        segments.segmentName = segmentName;
        segments.segmentDiscription = segmentDiscription;
        segments.save();
      }
      return { status: 201, message: "segments updated", data: { segments } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  segmentsDelete: async ({ query }) => {
    try {
      let { segmentId } = query;
      const result = await segmentsModel.deleteOne({ _id: segmentId });
      return { status: 201, message: "segments deleted", data: {} };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  userSegmentsPlansList: async ({ query }) => {
    try {
      // Plans are now universal. We return all active plans.
      let segmentsPlans = await segmentsPlanModel.find({ planStatus: 'active' }).sort({ price: 1 });

      // Deduplicate by _id (in case of data corruption)
      const uniquePlans = [];
      const seenIds = new Set();
      for (const plan of segmentsPlans) {
        const idStr = plan._id.toString();
        if (!seenIds.has(idStr)) {
          seenIds.add(idStr);
          uniquePlans.push(plan);
        }
      }

      return { status: 200, message: "success", data: { segmentsPlans: uniquePlans } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  segmentsDropDownList: async ({ }) => {
    try {
      let segmentsDataRaw = await segmentsModel.find({}).select({ _id: 1, segmentName: 1, segmentStatus: 1 });

      // Calculate user counts using Entitlement model which is the current source of truth for access
      const segmentsData = await Promise.all(segmentsDataRaw.map(async (segment) => {
        const userCount = await Entitlement.countDocuments({
          segmentId: segment._id,
          type: "PLAN",
          status: "ACTIVE",
          $or: [
            { endDate: null }, // Lifetime access
            { endDate: { $gt: new Date() } } // Current access
          ]
        });
        return {
          _id: segment._id,
          segmentName: segment.segmentName,
          segmentStatus: segment.segmentStatus || 'active',
          userCount: userCount
        };
      }));

      // Sort by userCount descending, then segmentName ascending
      segmentsData.sort((a, b) => {
        if (b.userCount !== a.userCount) {
          return b.userCount - a.userCount;
        }
        return a.segmentName.localeCompare(b.segmentName);
      });

      return { status: 200, message: "success", data: { segmentsData } };
    } catch (error) {
      console.error("Error in segmentsDropDownList:", error);
      let segmentsData = await segmentsModel.find({}).select({ _id: 1, segmentName: 1, segmentStatus: 1 });
      return { status: 200, message: "success (fallback)", data: { segmentsData } };
    }
  },
  segmentsPurchase: async ({ body }) => {
    try {
      let { userId, segmentId, segmentPlanId, paymentMode, paymentProof } = body;

      const receipt = `receipt${Date.now()}`;
      let currency = process.env.CURRENCY || "INR";

      const user = await userModel.findOne({ _id: userId });
      if (!user) {
        return { status: 404, message: "user not found", data: {} };
      }

      // CHUNK 3: KYC Gate
      const validKycStatus = ['VERIFIED', 'APPROVED'];
      if (!validKycStatus.includes(user.kycStatus)) {
        return {
          status: 403,
          message: "KYC Verification Required. Please complete KYC checks.",
          data: {}
        };
      }
      // CHUNK 4: Platform Access Gate
      if (user.account_type === 'SELF_REGISTERED' && user.registrationStatus !== 'ACTIVE' && user.registrationStatus !== 'COMPLETE') {
        return {
          status: 403,
          message: "Platform Access Fee Required. Please pay registration fee first.",
          data: {}
        };
      }

      const segment = await segmentsModel.findOne({ _id: segmentId });
      if (!segment) {
        return { status: 404, message: "segment not found", data: {} };
      }

      // HNI Plan Request Check
      if (segmentPlanId) {
        const plan = await segmentsPlanModel.findById(segmentPlanId);
        if (plan && plan.isHni) {
          const existingRequest = await HniRequest.findOne({ userId, planId: segmentPlanId, status: 'PENDING' });
          if (existingRequest) {
            return { status: 200, message: "Request already submitted. Our team will contact you.", data: {} };
          }
          await HniRequest.create({
            userId,
            segmentId,
            planId: segmentPlanId
          });
          return { status: 200, message: "HNI Custom Plan requested successfully. Our team will contact you shortly.", data: {} };
        }
      }

      // Fetch Plan (Source of Truth)
      if (!segmentPlanId) {
        return { status: 400, message: "Plan ID is required", data: {} };
      }
      const plan = await segmentsPlanModel.findById(segmentPlanId);
      if (!plan) {
        return { status: 404, message: "Plan not found", data: {} };
      }

      // ── DUPLICATE PLAN GUARD (Legacy Flow) ───────────────────────────────────
      // 1. Active or suspended entitlement
      const activeEntitlement = await Entitlement.findOne({
        userId,
        type: 'PLAN',
        resourceId: segmentPlanId,
        status: { $in: ['ACTIVE', 'SUSPENDED'] },
        $or: [{ endDate: null }, { endDate: { $gt: new Date() } }]
      });
      if (activeEntitlement) {
        return { status: 409, success: false, message: 'You already have an active or suspended subscription for this plan.', data: {} };
      }

      // 2. Existing partial
      const existingPartialIntent = await PaymentIntent.findOne({
        userId,
        planId: segmentPlanId,
        purchaseType: 'PLAN',
        isPartial: true,
        status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] }
      }).sort({ createdAt: -1 });

      if (existingPartialIntent) {
        if (paymentMode !== 'BANK_TRANSFER') {
          return { status: 400, success: false, message: 'Ongoing partial payment exists. Complete via Bank Transfer.', data: {} };
        }
        return {
          status: 201,
          message: 'Bank transfer request initiated',
          data: {
            segmentsPayment: { _id: existingPartialIntent._id, amount: existingPartialIntent.totalAmount },
            paymentIntentId: existingPartialIntent._id,
            isExistingIntent: true,
            isPartial: true
          }
        };
      }

      // 3. Existing non-partial
      const existingNonPartialIntent = await PaymentIntent.findOne({
        userId,
        planId: segmentPlanId,
        purchaseType: 'PLAN',
        isPartial: false,
        status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] }
      }).sort({ createdAt: -1 });

      if (existingNonPartialIntent) {
        if (existingNonPartialIntent.status === 'VERIFICATION_PENDING') {
          return { status: 400, success: false, message: 'Previous payment under verification. Wait for admin approval.', data: {} };
        }
        if (paymentMode === 'BANK_TRANSFER') {
          return {
            status: 201,
            message: 'Bank transfer request initiated',
            data: {
              segmentsPayment: { _id: existingNonPartialIntent._id, amount: existingNonPartialIntent.totalAmount },
              paymentIntentId: existingNonPartialIntent._id,
              isExistingIntent: true,
              isPartial: false
            }
          };
        }
      }

      // 4. Razorpay idempotency (razorpayOrderId does not start with BANK_ for Razorpay orders)
      if (paymentMode !== 'BANK_TRANSFER') {
        const tenMinsAgo = new Date(Date.now() - 10 * 60 * 1000);
        const existingLegacyRazorpay = await segmentsPaymentModel.findOne({
          userId,
          segmentPlanId,
          paymentStatus: 'pending',            // lowercase — as per schema enum
          razorpayOrderId: { $not: /^BANK_/ }, // Excludes bank transfer records
          createdAt: { $gte: tenMinsAgo }
        }).sort({ createdAt: -1 });

        if (existingLegacyRazorpay) {
          return {
            status: 201,
            message: 'segments puchased', // INTENTIONAL: match legacy endpoint typo exactly
            data: { segmentsPayment: existingLegacyRazorpay }
          };
        }
      }
      // ── END GUARD ─────────────────────────────────────────────────────────────

      // Calculate Price
      const basePrice = plan.price;
      const gstPercent = 18;
      const gstAmount = Math.round((basePrice * gstPercent) / 100);
      const totalAmount = basePrice + gstAmount;

      const amountPaise = Math.round(totalAmount * 100);

      if (paymentMode === 'BANK_TRANSFER') {
        const segmentsPayment = await segmentsPaymentModel.create({
          userId: userId,
          segmentId: segmentId,
          segmentPlanId: segmentPlanId,
          razorpayOrderId: `BANK_${receipt}`, // Placeholder
          razorpayCurrency: currency,
          razorpayReceipt: receipt,
          amount: totalAmount,
          gstAmount: gstAmount,
          paymentStatus: 'pending',
          paymentMethod: 'BANK_TRANSFER',
          paymentProof: paymentProof
        });
        await segmentsPayment.save();

        // Create PaymentIntent for compatibility with new Admin Panel
        try {
          const paymentIntent = await PaymentIntent.create({
            userId: userId,
            purchaseType: 'PLAN',
            planId: segmentPlanId,
            baseAmount: basePrice,
            gstAmount: gstAmount,
            totalAmount: totalAmount,
            razorpayOrderId: `BANK_${receipt}`,
            status: paymentProof ? 'VERIFICATION_PENDING' : 'PENDING_BANK_TRANSFER',
            paymentMethod: 'BANK_TRANSFER',
            proofImage: paymentProof,
            preferredSegmentId: segmentId,
            preferredPlanId: segmentPlanId
          });
          console.log(`[segmentsPurchase] Created PaymentIntent ${paymentIntent._id} for legacy bank transfer`);
        } catch (piError) {
          console.error('[segmentsPurchase] Failed to create PaymentIntent:', piError);
        }

        return {
          status: 201,
          message: "Bank transfer request initiated",
          data: { segmentsPayment },
        };
      }

      const razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
      });

      const options = {
        amount: amountPaise,
        currency: currency,
        receipt: receipt,
      };

      const order = await razorpay.orders.create(options);

      const segmentsPayment = await segmentsPaymentModel.create({
        userId: userId,
        segmentId: segmentId,
        segmentPlanId: segmentPlanId,
        razorpayOrderId: order.id,
        razorpayCurrency: currency,
        razorpayReceipt: receipt,
        amount: totalAmount,
        gstAmount: gstAmount,
      });
      await segmentsPayment.save();

      return {
        status: 201,
        message: "segments puchased",
        data: { segmentsPayment },
      };
    } catch (error) {
      console.error("Segments Purchase Error:", error);
      return { status: 400, message: error.message, data: {} };
    }
  },

  adminGrantSegment: async ({ body, user }) => {
    try {
      const { userId, segmentPlanId, paymentMode, paymentRefId, amount, isPartial, comment, discount } = body;
      const adminId = user ? user._id : null;

      // 1. Check for PaymentIntent (New Flow)
      // We use paymentRefId which currently holds razorpayOrderId passed from frontend for pending transfers
      const intent = await PaymentIntent.findOne({ razorpayOrderId: paymentRefId });

      if (intent) {
        // Verify User
        if (intent.userId.toString() !== userId) {
          return { status: 400, message: "User Mismatch for this Payment Intent", data: {} };
        }

        // Mark Paid
        intent.status = 'PAID';
        intent.paymentId = `MANUAL_ADMIN_${adminId || 'System'}`;
        if (discount && discount > 0) {
          intent.discount = discount;
          // Recalculate partial metrics just in case (to keep everything synced)
          const originalPrice = intent.originalPlanAmount || intent.totalAmount;
          intent.partialTotalTarget = Math.max(0, originalPrice - discount);
          const originalDuration = intent.originalDuration || 365;

          // Identify if it's registration
          const isRegistration = intent.purchaseType === 'REGISTRATION';
          const multiplier = isRegistration ? 1 : 1.5;

          intent.perDayCharge = intent.partialTotalTarget > 0 ? (intent.partialTotalTarget * multiplier / originalDuration) : 1;
          intent.maxAllowedDays = Math.floor(intent.partialTotalTarget / intent.perDayCharge);
        }
        if (comment) {
          intent.notes = intent.notes ? `${intent.notes}\n[Admin] ${comment}` : `[Admin] ${comment}`;
        }
        await intent.save();

        if (intent.purchaseType === 'REGISTRATION') {
          const isLifetime = intent.baseAmount === 10000;

          // --- FETCH TRIAL SETTINGS ---
          let yearlyTrial = 5;
          let lifetimeTrial = 7;
          try {
            const settings = await GeneralSettings.find({ key: { $in: ['trial_days_yearly', 'trial_days_lifetime'] } });
            const admissionYearly = settings.find(s => s.key === 'trial_days_yearly');
            const admissionLifetime = settings.find(s => s.key === 'trial_days_lifetime');
            if (admissionYearly) yearlyTrial = parseInt(admissionYearly.value) || 5;
            if (admissionLifetime) lifetimeTrial = parseInt(admissionLifetime.value) || 7;
          } catch (err) {
            console.error("Error fetching trial settings, using defaults", err);
          }

          const trialDays = isLifetime ? lifetimeTrial : yearlyTrial;

          const regEntitlement = await grantEntitlement({
            userId: userId,
            type: 'REGISTRATION',
            isLifetime,
            days: isLifetime ? 3652 : 365,
            startDate: intent.serviceStartDate, // Gap 33 Fix
            grantedBy: 'ADMIN',
            grantReason: 'OFFLINE_PAYMENT',
            sourceRefId: intent._id,
            remarks: comment || null
          });

          // Gap 3 & 12 Force Sync
          if (!isLifetime && intent.currentExpiryDate) {
            regEntitlement.endDate = intent.currentExpiryDate;
            await regEntitlement.save();
          }

          // Grant TRIAL PLAN (Bundle)
          // Grant TRIAL PLAN (Bundle)
          let bundlePlanId = intent.preferredPlanId;

          // AUTO-FIX: Fallback if planId is missing in intent (Legacy/Error case)
          if (!bundlePlanId) {
            console.log("(Admin) preferredPlanId missing, attempting to find default Equity/Spark plan...");
            const defaultPlan = await segmentsPlanModel.findOne({
              $or: [
                { planName: { $regex: 'Equity', $options: 'i' } },
                { planName: { $regex: 'Spark', $options: 'i' } }
              ]
            });
            if (defaultPlan) {
              bundlePlanId = defaultPlan._id;
              console.log(`(Admin) Found default fallback plan: ${defaultPlan.planName}`);
            }
          }

          if (bundlePlanId) {
            console.log(`(Admin) Granting Bundled Trial: Plan ${bundlePlanId} for ${trialDays} days`);
            await grantEntitlement({
              userId: intent.userId,
              type: 'PLAN',
              resourceId: bundlePlanId,
              days: trialDays,
              isLifetime: false,
              grantedBy: 'ADMIN',
              grantReason: 'REGISTRATION_TRIAL',
              sourceRefId: intent._id.toString(),
              remarks: comment || null
            });
          } else {
            console.warn("(Admin) Could not grant trial: No preferred plan and no default plan found.");
          }

          // Sync Legacy User Status
          await userModel.findByIdAndUpdate(userId, {
            registrationStatus: 'ACTIVE',
            registrationFeePaid: true, // AUTO-FIX: Set fee paid
            registrationType: isLifetime ? 'LIFETIME' : 'YEARLY',
            registrationExpiry: isLifetime ? new Date(Date.now() + 10 * 365.25 * 24 * 60 * 60 * 1000) : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
          });

        } else if (intent.purchaseType === 'PLAN') {
          const plan = await segmentsPlanModel.findById(intent.planId);
          if (!plan) {
            return {
              status: 404, message: "Plan not found", data: {}
            };
          }

          let days = 30;
          let isLifetime = false;

          if (plan.planName && plan.planName.toLowerCase().includes('lifetime')) {
            isLifetime = true;
            days = 3652;
          } else {
            const d1 = parseInt(plan.duration);
            const d2 = parseInt(plan.day);
            if (!isNaN(d1) && d1 > 0) days = d1;
            else if (!isNaN(d2) && d2 > 0) days = d2;
          }
          // Get segmentId from intent's preferredSegmentId or extract from plan
          let segmentId = intent.preferredSegmentId;

          // If not in intent, we need a segmentId - this is required for legacy models
          if (!segmentId) {
            console.warn('[adminGrantSegment] No preferredSegmentId in intent, using first available segment as fallback');
            const firstSegment = await segmentsModel.findOne({});
            if (firstSegment) {
              segmentId = firstSegment._id;
            } else {
              return { status: 400, message: "No segment found. Cannot activate plan without a segment.", data: {} };
            }
          }

          // Create legacy payment record
          const segmentsPayment = await segmentsPaymentModel.create({
            userId: userId,
            segmentId: segmentId,
            segmentPlanId: intent.planId,
            razorpayOrderId: intent.razorpayOrderId,
            razorpayPaymentId: intent.paymentId || `ADMIN_${Date.now()}`,
            razorpaySignature: 'ADMIN_APPROVED',
            razorpayCurrency: 'INR',
            amount: intent.totalAmount,
            gstAmount: intent.gstAmount,
            paymentStatus: 'paid',
            paymentMethod: intent.paymentMethod || 'BANK_TRANSFER',
            purchaseDate: intent.serviceStartDate || new Date(),
            expiryDate: intent.currentExpiryDate || new Date(Date.now() + (days * 24 * 60 * 60 * 1000))
          });


          // Create user active segment
          const userActiveSegment = await userActiveSegmentModel.create({
            userId: userId,
            segmentId: segmentId,
            isActive: true,
            purchaseDate: intent.serviceStartDate || new Date(),
            expiryDate: intent.currentExpiryDate || new Date(Date.now() + (days * 24 * 60 * 60 * 1000)),
          });


          // Grant entitlement
          const planEntitlement = await grantEntitlement({
            userId: userId,
            type: 'PLAN',
            resourceId: intent.planId,
            segmentId: segmentId,
            days,
            isLifetime,
            startDate: intent.serviceStartDate, // Gap 33 Fix
            grantedBy: 'ADMIN',
            grantReason: 'OFFLINE_PAYMENT',
            sourceRefId: segmentsPayment._id,
            remarks: comment || null
          });

          // Gap 3 & 12 Force Sync: Ensure Entitlement exactly matches intent's re-valued expiry (Manual Adjustment)
          if (!isLifetime && intent.currentExpiryDate) {
            planEntitlement.endDate = intent.currentExpiryDate;
            await planEntitlement.save();
          }

          // Create plan purchase record for app visibility
          await planPurchaseModel.create({
            userId: userId,
            packageName: `${plan.segmentsName || ''} - ${plan.planName}`,
            validity: days,
            startDate: intent.serviceStartDate || new Date(),
            endDate: intent.currentExpiryDate || new Date(Date.now() + (days * 24 * 60 * 60 * 1000)),

            status: "active",
            basicAmount: intent.baseAmount,
            cgstAmount: intent.gstAmount / 2, // Approximate
            sgstAmount: intent.gstAmount / 2, // Approximate
            paymentMethod: "OFFLINE",
            expiryReminder: true,
            remarks: comment || null,
            totalPlanAmount: intent.totalAmount,
            gstAmount: intent.gstAmount
          });

          // Create invoice
          const year = new Date().getFullYear();
          const count = await invoiceModel.countDocuments();
          const seq = String(count + 1).padStart(3, "0");
          const invoiceNumber = `RV/${year}/${seq}`;

          await invoiceModel.create({
            userId: userId,
            segmentId: segmentId,
            invoiceNumber: invoiceNumber,
            paymentMode: intent.paymentMethod || 'BANK_TRANSFER',
            status: "paid",
            amount: segmentsPayment.amount,
            gstAmount: segmentsPayment.gstAmount,
            paymentRefId: intent.razorpayOrderId,
            userActiveSegmentsId: userActiveSegment._id,
            generatedBy: "Admin",
          });
        }

        return { status: 200, message: "Payment Approved & Entitlement Granted", data: { intent } };
      }

      // 2. Fallback: Manual Grant (Legacy or Direct Admin Action without Intent)
      if (segmentPlanId === 'REGISTRATION') {
        // Admin trying to grant reg manually without intent? Rare but possible via API.
        await grantEntitlement({
          userId: userId,
          type: 'REGISTRATION',
          isLifetime: false, // Default
          days: 365,
          grantedBy: 'ADMIN',
          grantReason: 'MANUAL',
          sourceRefId: `MANUAL_${Date.now()}`,
          remarks: comment || null
        });
        await userModel.findByIdAndUpdate(userId, {
          registrationStatus: 'ACTIVE',
          registrationFeePaid: true, // AUTO-FIX: Set fee paid
          registrationType: 'YEARLY',
          registrationExpiry: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
        });
        return { status: 200, message: "Registration Granted Manually", data: {} };
      }

      const plan = await segmentsPlanModel.findById(segmentPlanId);
      if (!plan) return { status: 404, message: "Plan not found", data: {} };

      // AUTO-DETECT REGISTRATION PLAN
      if (plan.planName.toLowerCase().includes('registration') ||
        (plan.segmentsName && plan.segmentsName.toLowerCase().includes('registration'))) {

        const isLifetime = plan.planName.toLowerCase().includes('lifetime');

        // Grant Registration Entitlement
        await grantEntitlement({
          userId,
          type: 'REGISTRATION',
          isLifetime,
          days: isLifetime ? 3652 : 365,
          grantedBy: 'ADMIN',
          grantReason: 'MANUAL',
          sourceRefId: paymentRefId || `MANUAL_${Date.now()}`,
          remarks: comment || null
        });
        // Update User Status
        await userModel.findByIdAndUpdate(userId, {
          registrationStatus: 'ACTIVE',
          registrationFeePaid: true,
          registrationType: isLifetime ? 'LIFETIME' : 'YEARLY',
          registrationExpiry: isLifetime ? new Date(Date.now() + 10 * 365.25 * 24 * 60 * 60 * 1000) : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
        });
      }

      // segmentId should be provided in body for manual grant
      if (!segmentId) {
        return { status: 400, message: "segmentId is required for manual grant", data: {} };
      }

      // --- MANUAL PARTIAL PAYMENT GRANT ---
      if (isPartial) {
        // 1. Calculate Pricing
        const baseAmount = plan.price || 0;
        const gstPercent = 18;
        const gstAmount = Math.round((baseAmount * gstPercent) / 100);
        const totalAmount = Math.ceil(baseAmount + gstAmount);

        // Partial Calculation
        // Identify if it's a registration plan
        const isRegistration = (plan.planName.toLowerCase().includes('registration') ||
          (plan.segmentsName && plan.segmentsName.toLowerCase().includes('registration')));
        const multiplier = isRegistration ? 1 : 1.5;

        const partialTotalTarget = Math.ceil(totalAmount * multiplier);
        let originalDuration = 30;
        const d1 = parseInt(plan.duration);
        const d2 = parseInt(plan.day);
        if (isRegistration && plan.planName.toLowerCase().includes('lifetime')) originalDuration = 3652;
        else if (isRegistration) originalDuration = 365;
        else if (!isNaN(d1) && d1 > 0) originalDuration = d1;
        else if (!isNaN(d2) && d2 > 0) originalDuration = d2;

        const perDayCharge = partialTotalTarget / originalDuration;
        const maxAllowedDays = Math.ceil(totalAmount / perDayCharge);

        // 2. Validate Amount Paid
        const paidAmount = Number(amount || 0);
        if (paidAmount <= 0) {
          return { status: 400, message: "Paid amount must be greater than 0 for partial payment", data: {} };
        }

        // 3. Create Intent (Already Approved)
        const receipt = `manual_partial_${userId.toString().slice(-8)}_${Date.now()}`;

        // Calculate Days Granted
        let amountUsedForDays = paidAmount;
        let walletBalance = 0;
        if (paidAmount > totalAmount) {
          amountUsedForDays = totalAmount;
          walletBalance = paidAmount - totalAmount;
        }

        const daysGranted = Math.min(Math.ceil(amountUsedForDays / perDayCharge), maxAllowedDays);

        const serviceStartDate = new Date();
        const expiryDate = new Date(serviceStartDate);
        expiryDate.setDate(expiryDate.getDate() + daysGranted);

        let status = 'PENDING_BANK_TRANSFER'; // Default if not fully paid
        if (paidAmount >= totalAmount) {
          status = 'PAID';
        }

        const paymentIntent = await PaymentIntent.create({
          userId,
          purchaseType: isRegistration ? 'REGISTRATION' : 'PLAN',
          planId: plan._id,
          baseAmount,
          gstAmount,
          totalAmount,
          razorpayOrderId: `MANUAL_${receipt}`,
          status: status, // Manual grant implies verified/approved
          paymentMethod: paymentMode || 'MANUAL',
          isPartial: true,
          partialTotalTarget,
          perDayCharge,
          maxAllowedDays,
          amountPaid: paidAmount, // Total paid so far
          walletBalance: walletBalance,
          serviceStartDate: serviceStartDate,
          currentExpiryDate: expiryDate,
          preferredSegmentId: segmentId,
          partialPaymentsHistory: [{
            amountPaid: paidAmount,
            transactionDate: new Date(),
            status: 'APPROVED',
            verifiedBy: adminId || null,
            verifiedAt: new Date(),
            utrNumber: paymentRefId || `MANUAL_${Date.now()}`,
            proofImage: 'MANUAL_GRANT'
          }]
        });

        // 4. Grant Entitlement
        await grantEntitlement({
          userId: userId,
          type: 'PLAN',
          resourceId: plan._id,
          segmentId: segmentId,
          days: daysGranted,
          grantedBy: 'ADMIN',
          grantReason: 'MANUAL_PARTIAL',
          sourceRefId: paymentIntent._id.toString(),
          remarks: comment || null
        });

        return {
          status: 200,
          message: `Partial Plan Granted. ${daysGranted} days access given.`,
          data: {
            daysGranted,
            expiryDate
          }
        };
      }

      const segmentsPayment = await segmentsPaymentModel.create({
        userId: userId,
        segmentId: segmentId,
        segmentPlanId: segmentPlanId,
        razorpayOrderId: `ADMIN_${Date.now()}`,
        razorpayPaymentId: paymentRefId || `MANUAL_${Date.now()}`,
        razorpaySignature: 'MANUAL_GRANT',
        razorpayCurrency: 'INR',
        amount: amount || (plan.price * 1.18),
        gstAmount: amount ? (amount - (amount / 1.18)) : (plan.price * 0.18),
        paymentStatus: 'paid',
        paymentMethod: paymentMode || 'BANK_TRANSFER',
        purchaseDate: new Date(),
        expiryDate: new Date(Date.now() + (parseInt(plan.duration) * 24 * 60 * 60 * 1000))
      });

      const purchaseDate = new Date();
      const duration = parseInt(plan.duration) || 30;
      const expiryDate = new Date();
      expiryDate.setDate(expiryDate.getDate() + duration);

      const userActiveSegment = await userActiveSegmentModel.create({
        userId: userId,
        segmentId: segmentId,
        isActive: true,
        purchaseDate: purchaseDate,
        expiryDate: expiryDate,
      });

      await grantEntitlement({
        userId: userId,
        type: 'PLAN',
        resourceId: segmentPlanId,
        segmentId: segmentId,
        days: duration,
        grantedBy: 'ADMIN',
        grantReason: 'MANUAL',
        sourceRefId: segmentsPayment._id,
        remarks: comment || null
      });

      // Create plan purchase record for app visibility (Fallback path)
      await planPurchaseModel.create({
        userId: userId,
        packageName: `${plan.segmentsName || ''} - ${plan.planName}`,
        validity: duration,
        startDate: purchaseDate,
        endDate: expiryDate,
        status: "active",
        basicAmount: segmentsPayment.amount - segmentsPayment.gstAmount,
        cgstAmount: segmentsPayment.gstAmount / 2,
        sgstAmount: segmentsPayment.gstAmount / 2,
        paymentMethod: "OFFLINE",
        expiryReminder: true,
        remarks: comment || null,
        totalPlanAmount: (segmentsPayment.amount - segmentsPayment.gstAmount),
        gstAmount: segmentsPayment.gstAmount
      });

      const year = new Date().getFullYear();
      const count = await invoiceModel.countDocuments();
      const seq = String(count + 1).padStart(3, "0");
      const invoiceNumber = `RV/${year}/${seq}`;

      await invoiceModel.create({
        userId: userId,
        segmentId: segmentId,
        invoiceNumber: invoiceNumber,
        paymentMode: paymentMode || 'BANK_TRANSFER',
        status: "paid",
        amount: segmentsPayment.amount,
        gstAmount: segmentsPayment.gstAmount,
        paymentRefId: paymentRefId || "MANUAL",
        userActiveSegmentsId: userActiveSegment._id,
        generatedBy: "Admin",
      });

      return { status: 200, message: "Segment granted successfully", data: { segmentsPayment } };

    } catch (e) {
      return { status: 400, message: e.message, data: {} };
    }
  },

  rejectBankTransfer: async ({ body }) => {
    try {
      const { paymentId } = body;

      console.log('[rejectBankTransfer] Called with paymentId:', paymentId);

      // First, find the document to confirm it exists
      const existing = await PaymentIntent.findById(paymentId);
      console.log('[rejectBankTransfer] Found PaymentIntent:', existing ? `status=${existing.status}` : 'NOT FOUND');

      if (!existing) {
        return { status: 404, message: "Payment Intent not found", data: {} };
      }

      // Update status to REJECTED (no status restriction - allow rejecting any non-PAID intent)
      existing.status = 'REJECTED';
      
      // SYNC REGISTRATION STATUS TO USER MODEL
      if (existing.purchaseType === 'REGISTRATION') {
          await userModel.findByIdAndUpdate(existing.userId, {
              registrationStatus: 'REJECTED',
              registrationFeePaid: false,
              registrationExpiry: null
          });
      }

      await existing.save();

      console.log('[rejectBankTransfer] Successfully updated status to REJECTED for:', paymentId);
      return { status: 200, message: "Bank transfer rejected", data: {} };
    } catch (error) {
      console.error('[rejectBankTransfer] Error:', error);
      return { status: 400, message: error.message, data: {} };
    }
  },

  getPendingBankTransfers: async ({ query, user }) => {
    try {
      console.log('[getPendingBankTransfers] Called with query:', query);

      // --- SYNC LEGACY PAYMENTS START ---
      try {
        const legacyPending = await segmentsPaymentModel.find({
          paymentStatus: 'pending',
          paymentMethod: 'BANK_TRANSFER'
        });

        for (const lp of legacyPending) {
          // Determine consistent unique ID
          const uniqueId = (lp.razorpayOrderId && lp.razorpayOrderId.length > 5)
            ? lp.razorpayOrderId
            : `LEGACY_${lp._id}`;

          // Check if already synced to PaymentIntent
          const exists = await PaymentIntent.findOne({ razorpayOrderId: uniqueId });

          if (!exists) {
            console.log(`[getPendingBankTransfers] Syncing legacy payment ${lp._id}`);

            await PaymentIntent.create({
              userId: lp.userId,
              purchaseType: 'PLAN',
              planId: lp.segmentPlanId,
              baseAmount: (lp.amount && lp.gstAmount) ? (lp.amount - lp.gstAmount) : (lp.amount || 0),
              gstAmount: lp.gstAmount || 0,
              totalAmount: lp.amount || 0,
              razorpayOrderId: uniqueId,
              status: lp.paymentProof ? 'VERIFICATION_PENDING' : 'PENDING_BANK_TRANSFER',
              paymentMethod: 'BANK_TRANSFER',
              proofImage: lp.paymentProof,
              preferredSegmentId: lp.segmentId,
              preferredPlanId: lp.segmentPlanId,
              createdAt: lp.createdAt
            });
          }
        }
      } catch (syncErr) {
        console.error('[getPendingBankTransfers] Legacy sync error:', syncErr);
      }
      // --- SYNC LEGACY PAYMENTS END ---

      let { page, pageSize, search, status } = query;
      page = page ? parseInt(page) : 1;
      pageSize = pageSize ? parseInt(pageSize) : 20;
      const skip = (page - 1) * pageSize;

      const queryArgs = {
        $or: [
          { proofImage: { $ne: null, $exists: true } }, // Regular payment with proof (legacy)
          { 'proofImages.0': { $exists: true } }, // Regular payment with multiple proofs
          { 'partialPaymentsHistory.0': { $exists: true } } // Partial payment with at least one history entry
        ]
      };

      if (status && status !== 'All') {
        if (status === 'Approved') {
          queryArgs.status = { $in: ['PAID', 'APPROVED', 'PARTIAL-PAID'] };
        } else if (status === 'Partial') {
          // We might still want to show partial payments in various states, usually VERIFICATION_PENDING or PENDING_BANK_TRANSFER or PAID
          queryArgs.isPartial = true;
        } else if (status === 'Rejected') {
          queryArgs.status = 'REJECTED';
        } else if (status === 'Pending') {
          queryArgs.status = { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] };
        }
      } else {
        queryArgs.status = { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING', 'PAID', 'REJECTED'] };
      }

      // Restrict payments by staff/director assignment
      const callerId = user?._id || user?.userId;
      if (callerId) {
        const staffMember = await staffModel.findById(callerId);
        if (staffMember) {
          const role = (staffMember.userType || "").toLowerCase();
          const isSystemAdmin = role === 'admin' || role === 'super_admin';
          if (!isSystemAdmin) {
            let targetStaffIds = [staffMember._id];
            const dept = (staffMember.department || staffMember.deparment || "").toLowerCase();
            if (dept.includes('director')) {
              // Find all managers assigned to this director
              const managers = await staffModel.find({ assignedDirector: staffMember._id }).select('_id');
              const managerIds = managers.map(m => m._id);
              targetStaffIds = [...targetStaffIds, ...managerIds];
            }
            const assignments = await staffAssigmentModel.find({ staffId: { $in: targetStaffIds } });
            const assignedUserIds = assignments.map(a => a.userId);
            
            queryArgs.userId = { $in: assignedUserIds };
          }
        }
      }

      if (search && search.trim() !== '') {
        const searchRegex = new RegExp(search.trim(), 'i');
        const matchedUsers = await userModel.find({
          $or: [
            { fullName: searchRegex },
            { phone: searchRegex },
            { registrationType: searchRegex }
          ]
        }).select('_id');
        const userIds = matchedUsers.map(u => u._id);

        const matchedPlans = await segmentsPlanModel.find({
          planName: searchRegex
        }).select('_id');
        const planIds = matchedPlans.map(p => p._id);

        const matchedSegments = await segmentsModel.find({
          segmentName: searchRegex
        }).select('_id');
        const segmentIds = matchedSegments.map(s => s._id);

        queryArgs.$and = [
          {
            $or: [
              { userId: { $in: userIds } },
              { planId: { $in: planIds } },
              { preferredSegmentId: { $in: segmentIds } },
              { utrNumber: searchRegex },
              { 'partialPaymentsHistory.utrNumber': searchRegex },
              { razorpayOrderId: searchRegex }
            ]
          }
        ];
      }

      console.log('[getPendingBankTransfers] Querying PaymentIntent with:', JSON.stringify(queryArgs, null, 2));

      const intents = await PaymentIntent
        .find(queryArgs)
        .populate({
          path: 'userId',
          select: 'fullName phone email kycStatus registrationType'
        })
        .populate({
          path: 'planId',
          model: 'segmentsPlan',
          select: 'planName price duration'
        })
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(pageSize);

      const totalCount = await PaymentIntent.countDocuments(queryArgs);

      console.log('[getPendingBankTransfers] Found', intents.length, 'pending payments');

      // Debug: Log each intent's proof status
      intents.forEach((intent, idx) => {
        console.log(`[DEBUG] Intent ${idx + 1}:`, {
          id: intent._id,
          purchaseType: intent.purchaseType,
          hasProofImage: !!intent.proofImage,
          proofImage: intent.proofImage,
          hasPartialHistory: intent.partialPaymentsHistory?.length > 0,
          historyCount: intent.partialPaymentsHistory?.length || 0,
          status: intent.status
        });
      });

      // Map to frontend expected format
      const pendingPayments = await Promise.all(intents.map(async intent => {
        let planObj = intent.planId;
        let segmentName = 'N/A';

        // Fetch segment name if ID exists
        if (intent.preferredSegmentId) {
          const seg = await segmentsModel.findById(intent.preferredSegmentId);
          if (seg) segmentName = seg.segmentName;
        }

        if (intent.purchaseType === 'REGISTRATION') {
          const isLifetime = intent.baseAmount === 10000;
          planObj = {
            _id: 'REGISTRATION',
            planName: isLifetime ? 'Gold Registration' : 'Silver Registration',
            price: intent.baseAmount,
            duration: isLifetime ? '3652' : '365',
            segmentsName: 'Platform'
          };
          segmentName = 'Platform';
        } else if (!planObj) {
          planObj = { planName: 'Unknown Plan', segmentsName: segmentName };
        } else {
          // Flatten segmentsName into planObj for easier frontend access if desired
          planObj = {
            ...planObj.toObject ? planObj.toObject() : planObj,
            segmentsName: segmentName
          };
        }

        // Construct full URL for proof image
        const baseUrl = process.env.BASE_URL || 'https://api.researchvia.in';
        const paymentProof = intent.proofImage ? `${baseUrl}/${intent.proofImage}` : null;
        const paymentProofs = (intent.proofImages && intent.proofImages.length > 0)
          ? intent.proofImages.map(img => `${baseUrl}/${img}`)
          : (paymentProof ? [paymentProof] : []);

        // Map history proof images with the same baseUrl
        const historyMapped = (intent.partialPaymentsHistory || []).map(h => {
          let hq = h.toObject ? h.toObject() : h;
          hq.proofImage = hq.proofImage ? `${baseUrl}/${hq.proofImage}` : null;
          hq.proofImages = (hq.proofImages && hq.proofImages.length > 0)
            ? hq.proofImages.map(img => `${baseUrl}/${img}`)
            : (hq.proofImage ? [hq.proofImage] : []);
          return hq;
        });

        // Determine Frontend Status
        let displayStatus = intent.status;
        if (intent.isPartial && intent.status !== 'PAID') {
          // Check if any installment is approved
          const hasApproved = (intent.partialPaymentsHistory || []).some(h => h.status === 'APPROVED');
          if (hasApproved) {
            displayStatus = 'PARTIAL-PAID';
          }
        }

        // Look up the linked invoice to get the official invoiceNumber (same as shown in mobile app)
        const linkedInvoice = await invoiceModel.findOne({ paymentRefId: intent._id.toString() }).select('invoiceNumber').lean();

        return {
          _id: intent._id,
          userId: intent.userId,
          segmentPlanId: planObj,
          amount: intent.totalAmount,
          amountPaid: intent.amountPaid,
          paymentProof: paymentProof,
          paymentProofs: paymentProofs,
          razorpayOrderId: intent.razorpayOrderId,
          createdAt: intent.createdAt,
          isPartial: intent.isPartial,
          partialTotalTarget: intent.partialTotalTarget,
          perDayCharge: intent.perDayCharge,
          maxAllowedDays: intent.maxAllowedDays,
          partialPaymentsHistory: historyMapped,
          walletBalance: intent.walletBalance,
          utrNumber: intent.utrNumber,
          transactionDate: intent.transactionDate,
          purchaseType: intent.purchaseType,
          correctionVersion: intent.correctionVersion || 0,
          correctionHistory: intent.correctionHistory || [],
          discount: intent.discount || 0,
          status: displayStatus,
          invoiceNumber: linkedInvoice?.invoiceNumber || null,
          paymentMethod: intent.paymentMethod || 'BANK_TRANSFER',
          preferredSegmentId: intent.preferredSegmentId,
          preferredPlanId: intent.preferredPlanId,
          planId: intent.planId?._id || intent.planId,
          serviceStartDate: intent.serviceStartDate,
          currentExpiryDate: intent.currentExpiryDate,
        };
      }));
      return {
        status: 200,
        message: "Pending Bank Transfers",
        data: { totalCount, pendingPayments }
      };
    } catch (error) {
      console.error('[getPendingBankTransfers] Error:', error);
      return { status: 400, message: error.message, data: {} };
    }
  },
  segmentsPaymentVerify: async ({ body }) => {
    try {
      const {
        segmentId,
        razorpay_order_id,
        razorpay_payment_id,
        razorpay_signature,
      } = body;

      const segmentsPayment = await segmentsPaymentModel.findOne({
        razorpayOrderId: razorpay_order_id,
      });

      if (segmentsPayment.paymentStatus === 'paid') {
        return {
          status: 200,
          success: true,
          message: "Payment already processed",
          data: { segmentsPayment },
        };
      }

      if (segmentsPayment) {
        // Idempotency check handled above
      }

      const segmentPlan = await segmentsPlanModel.findById(segmentsPayment.segmentPlanId);
      if (!segmentPlan) {
        return {
          status: 404,
          success: false,
          message: "Segment Plan not found",
          data: {},
        };
      }

      // ... existing date logic ...
      const purchaseDate = new Date();
      const expiryDate = new Date();
      const duration = parseInt(segmentPlan.duration) || 0;
      // const unit = (segmentPlan.day || '').toLowerCase(); // DEPRECATED - Always Days

      const days = duration > 0 ? duration : (parseInt(segmentPlan.day) || 30);
      expiryDate.setDate(expiryDate.getDate() + days);


      const secret = process.env.RAZORPAY_KEY_SECRET;
      const generatedSignature = crypto
        .createHmac("sha256", secret)
        .update(razorpay_order_id + "|" + razorpay_payment_id)
        .digest("hex");

      if (generatedSignature === razorpay_signature) {
        const razorpay = new Razorpay({
          key_id: process.env.RAZORPAY_KEY_ID,
          key_secret: process.env.RAZORPAY_KEY_SECRET
        });

        const payment = await razorpay.payments.fetch(razorpay_payment_id);

        // Amount Verification
        const expectedAmountPaise = Math.round(segmentsPayment.amount * 100);
        if (payment.amount !== expectedAmountPaise) {
          return {
            status: 400,
            success: false,
            message: "Payment amount mismatch! Potential fraud attempt.",
            data: {}
          };
        }

        segmentsPayment.razorpayPaymentId = razorpay_payment_id;
        segmentsPayment.razorpaySignature = razorpay_signature;
        segmentsPayment.paymentStatus = "paid";
        segmentsPayment.purchaseDate = purchaseDate;
        segmentsPayment.expiryDate = expiryDate
        segmentsPayment.paymentMethod = payment.method
        await segmentsPayment.save();

        // ... create userActiveSegment ...
        const userActiveSegment = await userActiveSegmentModel.create({
          userId: segmentsPayment.userId,
          segmentId: segmentsPayment.segmentId,
          isActive: true,
          purchaseDate: purchaseDate,
          expiryDate: expiryDate,
        });

        // CHUNK 7: Grant Entitlement (Access-Based)
        await grantEntitlement({
          userId: segmentsPayment.userId,
          type: 'PLAN',
          resourceId: segmentsPayment.segmentPlanId, // Plan Level
          segmentId: segmentsPayment.segmentId,
          days: duration > 0 ? duration : (parseInt(segmentPlan.day) || 30),
          grantedBy: 'SYSTEM',
          grantReason: 'ONLINE_PAYMENT',
          sourceRefId: segmentsPayment._id
        });

        // Also grant segment level? 
        // accessMiddleware checks 'hasAnyActivePlan' or checks by planId. 
        // We usually check by PlanId or SegmentId. 
        // entitlementService.js checks type='PLAN', resourceId=planId.
        // So granting PLAN is correct.

        const year = new Date().getFullYear();
        const count = await invoiceModel.countDocuments();
        const seq = String(count + 1).padStart(3, "0");
        const invoiceNumber = `RV/${year}/${seq}`;
        const paymentMode = payment.method || "UPI";

        const invoice = await invoiceModel.create({
          userId: segmentsPayment.userId,
          segmentId: segmentsPayment.segmentId,
          invoiceNumber: invoiceNumber,
          paymentMode: paymentMode,
          status: "paid",
          amount: segmentsPayment.amount,
          gstAmount: segmentsPayment.gstAmount,
          paymentRefId: razorpay_payment_id,
          userActiveSegmentsId: userActiveSegment._id,
          generatedBy: "ResearchVia Admin",
        });

        return {
          status: 200,
          success: true,
          message: "Payment verified successfully!",
          data: { segmentsPayment },
        };
      } else {
        // ... failed ...
        segmentsPayment.paymentStatus = "failed";
        await segmentsPayment.save();
        return {
          status: 200,
          success: false,
          message: "Invalid signature!",
          data: {},
        };
      }
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  getHniRequests: async ({ query }) => {
    try {
      const requests = await HniRequest.find()
        .populate('userId', 'fullName email phone')
        .populate('planId', 'planName')
        .populate('segmentId', 'segmentName')
        .sort({ createdAt: -1 });
      return { status: 200, message: "HNI Requests Fetched", data: { requests } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  adminGrantHniPlan: async ({ body, user }) => {
    try {
      const { requestId, userId, segmentId, planId, customPrice, customValidity, assignedRaId } = body;

      // Update Request Status if requestId provided
      if (requestId) {
        await HniRequest.findByIdAndUpdate(requestId, { status: 'APPROVED' });
      }

      const plan = await segmentsPlanModel.findById(planId);
      if (!plan) return { status: 404, message: "Plan not found", data: {} };

      const purchaseDate = new Date();
      const expiryDate = new Date();
      expiryDate.setDate(expiryDate.getDate() + parseInt(customValidity));

      // 1. Create PaymentIntent (Unified Entry Point)
      const paymentIntent = await PaymentIntent.create({
        userId,
        purchaseType: 'PLAN',
        planId: planId,
        baseAmount: customPrice,
        gstAmount: 0,
        totalAmount: customPrice,
        amountPaid: customPrice,
        status: 'PAID',
        paymentMethod: 'ADMIN_ENTITLEMENT',
        isHniGrant: true,
        originalPlanAmount: customPrice,
        originalDuration: parseInt(customValidity),
        serviceStartDate: purchaseDate,
        currentExpiryDate: expiryDate,
        gstRateUsed: 0,
        preferredSegmentId: segmentId,
        notes: `HNI Grant by Admin. RA: ${assignedRaId}`
      });

      // 2. Create Legacy Payment Record (Compatibility)
      const segmentsPayment = await segmentsPaymentModel.create({
        userId,
        segmentId,
        segmentPlanId: planId,
        razorpayOrderId: `HNI_GRANT_${paymentIntent._id}`,
        razorpayPaymentId: `MANUAL_HNI_${Date.now()}`,
        razorpaySignature: 'ADMIN_HNI',
        razorpayCurrency: 'INR',
        amount: customPrice,
        gstAmount: 0,
        paymentStatus: 'paid',
        paymentMethod: 'Off-System/Custom',
        purchaseDate,
        expiryDate
      });

      // 3. Create Active Segment with RA
      const userActiveSegment = await userActiveSegmentModel.create({
        userId,
        segmentId,
        isActive: true,
        purchaseDate,
        expiryDate,
        assignedRa: assignedRaId,
        isCustomPlan: true
      });

      // 4. Grant Entitlement (Access Engine)
      await grantEntitlement({
        userId,
        type: 'PLAN',
        resourceId: planId,
        segmentId,
        days: parseInt(customValidity),
        grantedBy: 'ADMIN',
        grantReason: 'HNI_CUSTOM_GRANT',
        sourceRefId: paymentIntent._id // Link to Intent for Corrections
      });

      // 5. Create Plan Purchase Record (Revenue Engine)
      await planPurchaseModel.create({
        userId,
        packageName: `HNI Custom - ${plan.planName}`,
        validity: parseInt(customValidity),
        startDate: purchaseDate,
        endDate: expiryDate,
        status: "active",
        basicAmount: customPrice,
        cgstAmount: 0,
        sgstAmount: 0,
        paymentMethod: "CUSTOM",
        expiryReminder: true,
        linkedPaymentIntent: paymentIntent._id // Explicit Link
      });

      return { status: 200, message: "HNI Plan Granted Successfully", data: {} };

    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  getUserActiveSegment: async ({ query }) => {
    try {
      let { userId } = query;
      // CHUNK 9: Consistency - Read from Entitlements
      const now = new Date();

      // Find active and suspended PLAN entitlements (excluding free trials)
      const activeEntitlements = await Entitlement.find({
        userId: userId,
        type: 'PLAN',
        status: { $in: ['ACTIVE', 'SUSPENDED'] },
        grantReason: { $ne: 'REGISTRATION_TRIAL' },
        startDate: { $lte: now },
        $or: [
          { endDate: null },
          { endDate: { $gte: now } }
        ]
      }).populate({
        path: 'resourceId',
        model: 'segmentsPlan'
      }).populate({
        path: 'segmentId',
        model: 'segments'
      });

      // Map to legacy format expected by UI
      // Legacy Format: { _id, userId, segmentId, purchaseDate (startDate), expiryDate (endDate), isActive: true }
      // We need to group by segment? UI probably expects list of segments.

      const activeSegments = activeEntitlements.map(ent => {
        const plan = ent.resourceId;

        return {
          _id: ent._id, // Use entitlement ID as unique ID
          userId: ent.userId,
          segmentId: ent.segmentId,
          purchaseDate: ent.startDate,
          expiryDate: ent.endDate,
          isActive: ent.status === 'ACTIVE',
          status: ent.status,
          // Extra metadata
          planName: plan?.planName,
          days: plan?.day,
        };
      }).filter(item => item !== null);

      if (!activeSegments || activeSegments.length === 0) {
        return {
          status: 200,
          message: "No active segments found",
          data: [],
        };
      }
      return {
        status: 200,
        message: "Current Active Segments",
        data: activeSegments,
      };
    } catch (error) {
      return { status: 400, message: error.message, data: [] };
    }
  },
  expireSegments: async ({ }) => {
    try {
      const result = await userActiveSegmentModel.updateMany(
        {
          expiryDate: { $lte: new Date() },
          isActive: true,
        },
        {
          $set: { isActive: false },
        },
      );
      console.log("Expired Segments");
    } catch (error) {
      console.log({ "Error expiring segments:": error });
    }
  },
  segmentInvoice: async ({ query }) => {
    try {
      let { segmentId, invoiceId } = query;

      let queryObj = {};
      if (invoiceId) {
        queryObj = { _id: invoiceId };
      } else if (segmentId) {
        queryObj = { segmentId: segmentId };
      } else {
        return { status: 400, message: "Missing segmentId or invoiceId", data: {} };
      }

      const invoice = await invoiceModel
        .findOne(queryObj)
        .sort({ createdAt: -1 })
        .populate({
          path: "userId",
          select: "fullName phone aadhaarNumber userObject gstin firmName",
        })
        .populate({
          path: "segmentId",
          select: "segmentName segmentCode segmentStatus",
        })
        .populate({
          path: "userActiveSegmentsId",
          select: "amount gstAmount purchaseDate expiryDate isActive",
        });

      if (!invoice) {
        return { status: 404, message: "Invoice not found", data: {} };
      }

      // Format Plan Name for Mobile App Receipt
      let planName = invoice.segmentId?.segmentName || "Subscription";
      let intentData = {};

      if (invoice.paymentRefId) {
        // Try to find the PaymentIntent to get the exact plan and segment
        const intent = await PaymentIntent.findById(invoice.paymentRefId).populate('planId');
        if (intent) {
          intentData = {
            totalAmount: intent.totalAmount,
            amountPaid: intent.amountPaid || 0,
            discount: intent.discount || 0,
            isPartial: intent.isPartial,
            purchaseType: intent.purchaseType,
            installments: (intent.partialPaymentsHistory || [])
              .filter(p => p.status === 'APPROVED')
              .map((p, index) => ({
                index: index + 1,
                date: p.verifiedAt || p.transactionDate,
                amount: p.amountPaid,
                note: p.note
              }))
          };

          if (intent.purchaseType === 'REGISTRATION') {
            // "gold, silver meaning registration type"
            if (intent.packageName) {
              planName = intent.packageName;
            } else {
              const isLifetime = intent.baseAmount === 10000 || intent.originalPlanAmount >= 11800;
              planName = isLifetime ? 'Gold' : 'Silver';
            }
          } else {
            const baseName = intent.planId?.planName || intent.packageName || "Plan Purchase";
            if (intent.preferredSegmentId) {
              const segment = await segmentsModel.findById(intent.preferredSegmentId).select('segmentName');
              planName = segment ? `${segment.segmentName} - ${baseName}` : baseName;
            } else {
              planName = baseName;
            }
          }
        }
      }

      const invoiceData = invoice.toObject();
      invoiceData.planName = planName;
      invoiceData.intentData = intentData;

      return {
        status: 200,
        message: "User Invoice",
        data: invoiceData,
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  segmentPaymentHistroy: async ({ params, query }) => {
    try {
      let { id } = params;
      let { page, pageSize } = query;
      page = page ? parseInt(page) : 1;
      pageSize = pageSize ? parseInt(pageSize) : 20;
      const skip = (page - 1) * pageSize;

      // 1. Fetch from segmentsPayment (Legacy/Confirmed)
      const segmentsPayment = await segmentsPaymentModel
        .find({ userId: id })
        .populate("segmentId")
        .populate("segmentPlanId")
        .sort({ createdAt: -1 })
        .lean();

      // 2. Fetch from PaymentIntent (Granular/Partial/History)
      const paymentIntents = await PaymentIntent
        .find({ userId: id })
        .populate({
          path: 'planId',
          model: 'segmentsPlan'
        })
        .sort({ createdAt: -1 })
        .lean();

      const allPayments = [];
      const seenOrderIds = new Set();
      const seenIntentIds = new Set();

      // --- PROCESS PAYMENT INTENTS FIRST (Most Granular) ---
      for (const intent of paymentIntents) {
        seenIntentIds.add(intent._id.toString());
        if (intent.razorpayOrderId) seenOrderIds.add(intent.razorpayOrderId);

        // Resolve common context
        let type = intent.purchaseType === 'REGISTRATION' ? 'Registration' : 'Segment Plan';
        let segmentName = '-';
        let planName = 'Unknown';

        if (intent.purchaseType === 'REGISTRATION') {
          const isGold = intent.baseAmount === 10000 || intent.packageName?.toLowerCase().includes('gold');
          planName = isGold ? 'Gold Registration' : 'Silver Registration';
        } else {
          // It's a Segment Plan
          planName = intent.planId?.planName || 'Plan';
          // Find segment name if available
          if (intent.preferredSegmentId) {
            const seg = await segmentsModel.findById(intent.preferredSegmentId).lean();
            if (seg) segmentName = seg.segmentName;
          }
        }

        // UNROLL installments if partial
        if (intent.isPartial && intent.partialPaymentsHistory && intent.partialPaymentsHistory.length > 0) {
          for (const item of intent.partialPaymentsHistory) {
            allPayments.push({
              _id: item._id, // Row ID
              paymentIntentId: intent._id,
              type,
              planName,
              segmentName,
              amount: item.amountPaid,
              date: item.transactionDate || intent.createdAt,
              status: item.status || 'PENDING',
              method: intent.paymentMethod || 'BANK_TRANSFER',
              transactionId: item.utrNumber || intent.razorpayOrderId || 'N/A',
              source: 'intent_history',
              segmentId: intent.preferredSegmentId,
              planId: intent.planId?._id || intent.planId,
              serviceStartDate: intent.serviceStartDate,
              currentExpiryDate: intent.currentExpiryDate,
            });
          }
        } else {
          // Full payment or partial with no uploads yet
          allPayments.push({
            _id: intent._id,
            paymentIntentId: intent._id,
            type,
            planName,
            segmentName,
            amount: intent.totalAmount,
            date: intent.createdAt,
            status: intent.status,
            method: intent.paymentMethod || 'ONLINE',
            transactionId: intent.razorpayOrderId || 'N/A',
            source: 'payment_intent',
            segmentId: intent.preferredSegmentId,
            planId: intent.planId?._id || intent.planId,
            serviceStartDate: intent.serviceStartDate,
            currentExpiryDate: intent.currentExpiryDate,
          });
        }
      }

      // --- PROCESS LEGACY SEGMENTS PAYMENT (Deduplicate) ---
      for (const payment of segmentsPayment) {
        // Skip if this order ID was already covered by PaymentIntent processing
        const orderId = payment.razorpayOrderId || payment._id.toString();
        if (seenOrderIds.has(orderId)) continue;

        let type = payment.purchaseType === 'REGISTRATION' ? 'Registration' : 'Segment Plan';
        let planName = payment.segmentPlanId?.planName || 'Plan';
        let segmentName = payment.segmentId?.segmentName || '-';

        // Check if it looks like a registration based on common patterns if type is PLAN but it shouldn't be
        if (type === 'Registration' || planName.toLowerCase().includes('registration')) {
          type = 'Registration';
          const isGold = payment.amount >= 10000;
          planName = planName !== 'Plan' ? planName : (isGold ? 'Gold Registration' : 'Silver Registration');
          segmentName = '-';
        }

        allPayments.push({
          _id: payment._id,
          type,
          planName,
          segmentName,
          amount: payment.amount,
          date: payment.createdAt,
          status: (payment.paymentStatus || 'paid').toUpperCase(),
          method: payment.paymentMethod || 'N/A',
          transactionId: payment.razorpayOrderId || 'N/A',
          source: 'segments_payment',
          segmentId: payment.segmentId?._id || payment.segmentId,
          planId: payment.segmentPlanId?._id || payment.segmentPlanId,
          startDate: payment.startDate,
          endDate: payment.endDate,
        });
      }

      // Final sort & pagination
      allPayments.sort((a, b) => new Date(b.date) - new Date(a.date));
      const totalCount = allPayments.length;
      const paginatedPayments = allPayments.slice(skip, skip + pageSize);

      return {
        status: 200,
        message: "Payment History",
        data: { segmentsPaymentCount: totalCount, segmentsPayment: paginatedPayments },
      };
    } catch (error) {
      console.error('[segmentPaymentHistroy] Error:', error);
      return { status: 400, message: error.message, data: {} };
    }
  },
  segmentsPlanCreate: async ({ body }) => {
    try {
      let { planName, segmentsId, duration, day, price, discription, planFeatures, planStatus } = body;

      let totalDays = parseInt(duration) || 0;
      let perDayCharge = (totalDays > 0) ? Math.round(price / totalDays) : 0;

      if (body.isHni) {
        duration = "0";
        price = 0;
        perDayCharge = 0;
      }

      const planData = {
        planName: planName,
        duration: duration,
        day: day,
        price: price,
        perDayCharge: perDayCharge,
        discription: discription,
        planFeatures: planFeatures,
        planStatus: planStatus
      };

      // Add isHni if provided
      if (body.isHni !== undefined) {
        planData.isHni = body.isHni;
      }

      let segmentPlan = await segmentsPlanModel.create(planData)
      return {
        status: 201,
        message: "segment plan created",
        data: { segmentPlan },
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  segmentsPlanUpdate: async ({ query, body }) => {
    try {
      let { id } = query
      let { planName, segmentsId, duration, day, price, discription, planFeatures, planStatus } = body;

      let totalDays = parseInt(duration) || 0;
      let perDayCharge = (totalDays > 0) ? Math.round(price / totalDays) : 0;

      if (body.isHni) {
        duration = "0";
        price = 0;
        perDayCharge = 0;
      }
      const segmentPlan = await segmentsPlanModel.findOne({ _id: id })
      if (!segmentPlan) {
        return {
          status: 200,
          message: "segment plan not found",
          data: {},
        };
      }

      segmentPlan.planName = planName
      segmentPlan.duration = duration
      segmentPlan.day = day
      segmentPlan.discription = discription
      segmentPlan.planFeatures = planFeatures
      segmentPlan.perDayCharge = perDayCharge
      segmentPlan.price = price
      segmentPlan.planStatus = planStatus

      // Handle isHni field if provided
      if (body.isHni !== undefined) {
        segmentPlan.isHni = body.isHni;
      }

      await segmentPlan.save()
      return {
        status: 201,
        message: "segment plan updated",
        data: { segmentPlan },
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  segmentsPlanDelete: async ({ query }) => {
    try {
      let { id } = query;
      const result = await segmentsPlanModel.deleteOne({ _id: id });
      return { status: 201, message: "segment plan deleted", data: {} };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  segmentsPlanList: async ({ query }) => {
    try {
      let { id } = query
      let planlist = await segmentsPlanModel.find({ planStatus: 'active' }).select("planName")
      return {
        status: 200,
        message: "segment plan list",
        data: { planlist },
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  fixPrices: async ({ }) => {
    try {
      const plans = await segmentsPlanModel.find({});
      let updatedCount = 0;
      for (const plan of plans) {
        let saveNeeded = false;

        // 1. Fix price if exponential (still keep check just in case)
        if (plan.price > 1000000) {
          plan.price = plan.price / 100;
          saveNeeded = true;
        }

        // 2. Recalculate perDayCharge with correct days logic
        let totalDays = parseInt(plan.duration);
        // Month/Year removed. Always days.

        const correctPerDayCharge = Math.round(plan.price / totalDays);
        // Only update if off by more than 1 (rounding diffs)
        if (Math.abs(plan.perDayCharge - correctPerDayCharge) > 1) {
          plan.perDayCharge = correctPerDayCharge;
          saveNeeded = true;
        }

        if (saveNeeded) {
          await plan.save();
          updatedCount++;
        }
      }
      return { status: 200, message: `Fixed ${updatedCount} plans`, data: {} };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  userSegmentPlanList: async ({ query }) => {
    try {
      let { page, pageSize, search, date } = query
      let queryArgs = {}
      let newStartDate = date ? new Date(date) : null;
      search = search ? search.trim() : ''
      page = page ? parseInt(page) : ''
      pageSize = pageSize ? parseInt(pageSize) : '';

      const aggregationPipeline = [

        {
          $lookup: {
            from: "staffassigments",
            localField: "userId",
            foreignField: "userId",
            as: "staffAssignData"
          }
        },
        {
          $unwind: {
            path: "$staffAssignData",
            preserveNullAndEmptyArrays: true
          }
        },
        {
          $lookup: {
            from: "users",
            localField: "userId",
            foreignField: "_id",
            as: "userData"
          }
        },
        {
          $unwind: {
            path: "$userData",
            preserveNullAndEmptyArrays: true
          }
        },

        {
          $lookup: {
            from: "segments",
            localField: "segmentId",
            foreignField: "_id",
            as: "segmentData"
          }
        },
        {
          $unwind: {
            path: "$segmentData",
            preserveNullAndEmptyArrays: true
          }
        },
        {
          $lookup: {
            from: "segmentsplans",
            localField: "segmentPlanId",
            foreignField: "_id",
            as: "segmentPlanData"
          }
        },
        {
          $unwind: {
            path: "$segmentPlanData",
            preserveNullAndEmptyArrays: true
          }
        },
        {
          $project: {
            fullName: "$userData.fullName",
            phone: "$userData.phone",
            email: "$userData.email",
            segmentName: "$segmentData.segmentName",
            purchaseDate: "$segmentData.purchaseDate",
            expiryDate: "$segmentData.expiryDate",
            plan: "$segmentPlanData.planName",
            price: "$segmentPlanData.price",
            duration: "$segmentPlanData.duration",
            staffAssignUserId: "$staffAssignData.userId",
            staffAssignStaffId: "$staffAssignData.staffId",
            manager: "$staffAssignData.staffName",
          }
        },
        { $sort: { createdAt: -1 } }
      ];
      if (search) {
        queryArgs = {
          "$or": [
            { fullName: { $regex: search, $options: 'i' } },
            { phone: { $regex: search, $options: 'i' } },
            { manager: { $regex: search, $options: 'i' } },
          ]
        };
      }
      if (newStartDate) {
        queryArgs.createdAt = { $gte: newStartDate.toISOString() };
      }
      aggregationPipeline.push({ $match: queryArgs })
      let countPipeLine = [...aggregationPipeline, { $group: { _id: null, count: { $sum: 1 } } }];
      const countResult = await segmentsPaymentModel.aggregate(countPipeLine);
      let totalCount = countResult.length > 0 ? countResult[0].count : 0;
      if (page && pageSize) {
        aggregationPipeline.push(
          { $skip: (page - 1) * pageSize },
          { $limit: pageSize },
        );
      }
      const userData = await segmentsPaymentModel.aggregate(aggregationPipeline);
      return { status: 200, data: { totalCount, userData } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };

    }
  },
  subscriptionsPlanList: async ({ query }) => {
    try {
      let { page, pageSize, search, status, segmentId, category } = query
      let queryArgs = {}
      search = search ? search.trim() : ''
      page = page ? parseInt(page) : ''
      pageSize = pageSize ? parseInt(pageSize) : '';
      if (search) {
        queryArgs.planName = { $regex: search, $options: 'i' };
      }
      if (status && status !== 'All Status') {
        queryArgs.planStatus = status.toLowerCase();
      }

      let segmentsData = segmentsPlanModel.find(queryArgs).sort({ createdAt: -1 }).lean();
      let totalCount = await segmentsPlanModel.countDocuments(queryArgs).exec();
      if (page && pageSize) {
        segmentsData = segmentsData.skip((page - 1) * pageSize).limit(pageSize);
      }
      const data = await segmentsData.exec();
      return { status: 200, message: "success", data: { totalCount, data } };

    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  // ─────────────────────────────────────────────────────────────────────────
  // TWO-WAY APPROVAL SYSTEM
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * revertApproval — Approved ➔ Rejected
   * Deletes ALL records created by the original approval, then marks the
   * PaymentIntent as REJECTED. The PaymentIntent itself is NEVER deleted
   * so the financial audit trail is always preserved.
   */
  revertApproval: async ({ body, user }) => {
    let session;
    let useTransaction = false;
    try {
      session = await mongoose.startSession();
      session.startTransaction();
      // Dummy query to test if the Mongo instance supports transactions (Replica Set)
      // If it's a Standalone server, this will immediately throw the "Transaction numbers" error.
      await PaymentIntent.findOne({ _id: null }).session(session);
      useTransaction = true;
    } catch (err) {
      console.warn("[revertApproval] MongoDB Transactions NOT supported (Standalone instance detected). Falling back to sequential execution.", err.message);
      if (session) {
        await session.endSession();
        session = undefined; // Mongoose will ignore .session(undefined)
      }
      useTransaction = false;
    }

    try {
      const { paymentIntentId, historyId, reason } = body;
      const adminId = user ? user._id : null;

      // 1. Fetch PaymentIntent
      const intent = await PaymentIntent.findById(paymentIntentId).session(session);
      if (!intent) {
        if (useTransaction) { await session.abortTransaction(); session.endSession(); }
        return { status: 404, message: 'Payment Intent not found', data: {} };
      }

      // Idempotency: overall intent
      if (!historyId && intent.status === 'REJECTED') {
        if (useTransaction) { await session.abortTransaction(); session.endSession(); }
        return { status: 200, message: 'Already reverted', data: {} };
      }

      const REVERTABLE_STATUSES = new Set(['PAID', 'PARTIAL-PAID', 'PENDING_BANK_TRANSFER', 'APPROVED']);

      const userId = intent.userId;

      // ── FLOW A: REGISTRATION (non-partial) ──────────────────────────────
      if (intent.purchaseType === 'REGISTRATION' && !intent.isPartial) {
        if (!REVERTABLE_STATUSES.has(intent.status) && intent.status !== 'REJECTED') {
           if (useTransaction) { await session.abortTransaction(); session.endSession(); }
           return { status: 400, message: `Payment cannot be rejected from status: ${intent.status}`, data: {} };
        }

        // Both REGISTRATION and REGISTRATION_TRIAL entitlements share sourceRefId = intent._id
        await Entitlement.deleteMany({
          userId,
          sourceRefId: intent._id.toString()
        }).session(session);

        // Soft-expire bundled plans granted from offline
        await planPurchaseModel.updateMany({
           userId,
           source: 'REGISTRATION_BUNDLE',
           status: 'active'
        }, {
           status: 'REVOKED',
           endDate: new Date(),
           remarks: '[Admin] Revoked due to registration revert'
        }).session(session);

        // Delete any generated invoice for this registration
        await invoiceModel.deleteMany({
          userId,
          paymentRefId: intent._id.toString()
        }).session(session);

        // Revert user registration flags
        await userModel.findByIdAndUpdate(userId, {
          registrationStatus: 'REJECTED',
          registrationFeePaid: false,
          registrationExpiry: null
        }).session(session);

      // ── FLOW B: PARTIAL PAYMENT (any purchaseType) ───────────────────────
      } else if (intent.isPartial) {
        if (!historyId) {
          if (!REVERTABLE_STATUSES.has(intent.status) && intent.status !== 'REJECTED') {
             if (useTransaction) { await session.abortTransaction(); session.endSession(); }
             return { status: 400, message: `Payment cannot be rejected from status: ${intent.status}`, data: {} };
          }

          // Destructive backward compatibility. If no historyId is passed, reject all approved.
          await Entitlement.deleteMany({
            userId,
            sourceRefId: intent._id.toString()
          }).session(session);

          await planPurchaseModel.deleteMany({
            userId,
            remarks: { $regex: intent._id.toString() }
          }).session(session);

          await invoiceModel.deleteMany({
            userId,
            paymentRefId: intent._id.toString()
          }).session(session);

          // Reset all APPROVED history items back to REJECTED
          let hadApproved = false;
          intent.partialPaymentsHistory.forEach(h => {
            if (h.status === 'APPROVED') {
              h.status = 'REJECTED';
              hadApproved = true;
            }
          });
          if (hadApproved) {
            intent.amountPaid = 0;
            intent.walletBalance = 0;
            intent.markModified('partialPaymentsHistory');
          }
          // ⚠️ FIX: Must explicitly save here — this branch does NOT fall through
          // to the shared intent.save() at line 2332. Without this, all in-memory
          // mutations (status, amountPaid, walletBalance, history) are silently lost.
          intent.status = 'REJECTED';
          await intent.save({ session });

          if (intent.purchaseType === 'REGISTRATION') {
            await userModel.findByIdAndUpdate(userId, {
              registrationStatus: 'REJECTED',
              registrationFeePaid: false,
              registrationExpiry: null
            }).session(session);
          }

        } else {
          // INSTALLMENT SPECIFIC REJECTION
          const historyItem = intent.partialPaymentsHistory.id(historyId);
          if (!historyItem) {
             if (useTransaction) { await session.abortTransaction(); session.endSession(); }
             return { status: 404, message: 'Installment history item not found', data: {} };
          }

          if (historyItem.status === 'REJECTED') {
             if (useTransaction) { await session.abortTransaction(); session.endSession(); }
             return { status: 200, message: 'Already reverted', data: {} };
          }

          if (historyItem.status !== 'APPROVED') {
             if (useTransaction) { await session.abortTransaction(); session.endSession(); }
             return { status: 400, message: `Cannot revert installment as it is not APPROVED (current: ${historyItem.status})`, data: {} };
          }

          // Mark specific item as REJECTED
          historyItem.status = 'REJECTED';
          
          // Re-calculate the remaining approved
          const remainingApproved = intent.partialPaymentsHistory.filter(h => h.status === 'APPROVED');
          
          if (remainingApproved.length === 0) {
            // No approvals left, so do the destructive path
            await Entitlement.deleteMany({
              userId,
              sourceRefId: intent._id.toString()
            }).session(session);

            await planPurchaseModel.deleteMany({
              userId,
              remarks: { $regex: intent._id.toString() }
            }).session(session);

            await invoiceModel.deleteMany({
              userId,
              paymentRefId: intent._id.toString()
            }).session(session);

            intent.amountPaid = 0;
            intent.walletBalance = 0;
            intent.markModified('partialPaymentsHistory');

            if (intent.purchaseType === 'REGISTRATION') {
              await userModel.findByIdAndUpdate(userId, {
                registrationStatus: 'REJECTED',
                registrationFeePaid: false,
                registrationExpiry: null
              }).session(session);
            }
          } else {
            // Some installments still remain APPROVED. Do Soft-Path Downward Recalculation.
            const totalPaid = remainingApproved.reduce((sum, h) => sum + (h.amountPaid || 0), 0);
            
            const currentTarget = intent.partialTotalTarget || intent.totalAmount;
            let amountUsedForDays = totalPaid;
            let walletBalance = 0;
            if (totalPaid > currentTarget) {
              amountUsedForDays = currentTarget;
              walletBalance = totalPaid - currentTarget;
            }
            
            const perDayCharge = intent.perDayCharge || 1;
            const maxAllowedDays = intent.maxAllowedDays || 365;
            
            let totalDaysToGrant = Math.ceil(amountUsedForDays / perDayCharge);
            let finalDays = Math.min(totalDaysToGrant, maxAllowedDays);
            
            if (intent.purchaseType === 'REGISTRATION' || intent.packageName?.toLowerCase().includes("registration")) {
               finalDays = intent.originalDuration || 365;
            }
            if (totalPaid >= currentTarget) {
               finalDays = intent.originalDuration || 365;
            }

            intent.amountPaid = totalPaid;
            intent.walletBalance = walletBalance;
            intent.markModified('partialPaymentsHistory');
            
            if (!intent.serviceStartDate) {
              intent.serviceStartDate = new Date();
            }
            const expiryDate = new Date(intent.serviceStartDate);
            expiryDate.setDate(expiryDate.getDate() + finalDays + (intent.manualDaysAdjustment || 0));
            intent.currentExpiryDate = expiryDate;
            
            if (totalPaid >= (currentTarget - 1)) {
               intent.status = 'PAID';
            } else {
               intent.status = 'PENDING_BANK_TRANSFER';
            }
            
            await intent.save({ session });
            
            // Sync Enitlement Expiry Atomically
            await Entitlement.updateMany({
              userId,
              sourceRefId: intent._id.toString(),
              status: { $in: ['ACTIVE', 'SUSPENDED'] }
            }, {
              endDate: intent.currentExpiryDate
            }).session(session);

            // Sync PlanPurchase Expiry Atomically
            if (intent.purchaseType === 'PLAN') {
              await planPurchaseModel.updateMany({
                userId,
                $or: [
                   { linkedPaymentIntent: intent._id },
                   { remarks: { $regex: intent._id.toString() } }
                ]
              }, {
                endDate: intent.currentExpiryDate,
                $set: {
                  isPartial: totalPaid < currentTarget,
                  validity: totalPaid < currentTarget ? intent.maxAllowedDays : intent.originalDuration
                }
              }).session(session);
            }
            
            // Sync user model registration fee flag atomic
            if (intent.purchaseType === 'REGISTRATION') {
              const target = intent.partialTotalTarget || intent.totalAmount;
              const isFull = totalPaid >= target;
              await userModel.findByIdAndUpdate(userId, {
                  registrationFeePaid: isFull,
                  registrationExpiry: intent.currentExpiryDate,
                  registrationStatus: 'ACTIVE'
              }).session(session);
            }

            // Sync Invoice atomic
            try {
              const invoice = await invoiceModel.findOne({
                 userId,
                 paymentRefId: intent._id.toString()
              }).session(session);
              if (invoice) {
                const gstPercent = intent.gstRateUsed || 18;
                const totalBase = Math.round((totalPaid / (1 + gstPercent / 100)) * 100) / 100;
                const totalGst = totalPaid - totalBase;
                invoice.amount = totalPaid;
                invoice.gstAmount = totalGst;
                await invoice.save({ session });
              }
            } catch (err) {
              console.error("[revertApproval] error updating invoice for soft path:", err);
            }

            // Audit
            try {
               await AdminAuditLog.create([{
                 adminId: adminId || userId,
                 action: 'PAYMENT_APPROVAL_REVERTED',
                 targetUserId: userId,
                 reason: reason || `Admin reverted an approved installment. Soft path downward recalculation.`,
                 meta: {
                   paymentIntentId,
                   historyId,
                   purchaseType: intent.purchaseType,
                   isPartial: intent.isPartial,
                   newTotalPaid: totalPaid
                 }
               }], { session });
            } catch (aErr) {}

            if (useTransaction) { await session.commitTransaction(); session.endSession(); }
            return { status: 200, message: 'Installment rejected. Associated balances adjusted downward.', data: {} };
          }
        }

      // ── FLOW C: FULL NON-PARTIAL PLAN ───────────────────────────────────
      } else {
        if (!REVERTABLE_STATUSES.has(intent.status) && intent.status !== 'REJECTED') {
           if (useTransaction) { await session.abortTransaction(); session.endSession(); }
           return { status: 400, message: `Payment cannot be rejected from status: ${intent.status}`, data: {} };
        }

        const segPay = await segmentsPaymentModel.findOne({
          razorpayOrderId: intent.razorpayOrderId
        }).session(session);

        const invoice = await invoiceModel.findOne({
          userId,
          paymentRefId: intent.razorpayOrderId
        }).session(session);

        const sourceRefs = [intent._id.toString()];
        if (segPay) sourceRefs.push(segPay._id.toString());

        await Entitlement.deleteMany({
          userId,
          sourceRefId: { $in: sourceRefs }
        }).session(session);

        const planPurchaseQuery = {
          userId,
          status: 'active',
          basicAmount: intent.baseAmount
        };
        if (intent.currentExpiryDate) {
          planPurchaseQuery.endDate = intent.currentExpiryDate;
        }
        await planPurchaseModel.deleteMany(planPurchaseQuery).session(session);

        if (invoice && invoice.userActiveSegmentsId) {
          await userActiveSegmentModel.deleteOne({ _id: invoice.userActiveSegmentsId }).session(session);
        }

        if (invoice) {
          await invoiceModel.deleteOne({ _id: invoice._id }).session(session);
        }

        if (segPay) {
          await segmentsPaymentModel.deleteOne({ _id: segPay._id }).session(session);
        }
      }

      // 3. Mark PaymentIntent as REJECTED
      intent.status = 'REJECTED';
      
      const conciseNote = `[Admin REVERT]: ${reason || 'Manual Revert'} on ${new Date().toISOString()} by ${adminId}`;
      intent.notes = intent.notes ? `${intent.notes}\n${conciseNote}` : conciseNote;
      
      await intent.save({ session });

      // 4. Audit Log
      try {
        await AdminAuditLog.create([{
          adminId: adminId || userId,
          action: 'PAYMENT_APPROVAL_REVERTED',
          targetUserId: userId,
          reason: reason || 'Admin reverted approved payment',
          meta: {
            paymentIntentId,
            purchaseType: intent.purchaseType,
            isPartial: intent.isPartial,
            totalAmount: intent.totalAmount
          }
        }], { session });
      } catch (auditErr) {
        console.error('[revertApproval] Audit log failed (non-fatal):', auditErr.message);
      }

      if (useTransaction) { await session.commitTransaction(); session.endSession(); }
      console.log(`[revertApproval] Successfully reverted intent ${paymentIntentId} to REJECTED`);
      return { status: 200, message: 'Payment approval reverted. User access has been removed.', data: {} };

    } catch (error) {
      if (useTransaction) { await session.abortTransaction(); session.endSession(); }
      console.error('[revertApproval] Error:', error);
      return { status: 400, message: error.message, data: {} };
    }
  },

  /**
   * revertRejection — Rejected ➔ Approved
   * Delegates entirely to the existing, battle-tested approval engines.
   * For full payments: calls adminGrantSegment (creates all records fresh).
   * For partial payments: resets the history item to PENDING then calls
   * approvePartialPayment (existing duplication guard is bypassed safely).
   */
  revertRejection: async ({ body, user }) => {
    try {
      const { paymentIntentId, historyId, reason } = body;
      const adminId = user ? user._id : null;

      // 1. Fetch PaymentIntent
      const intent = await PaymentIntent.findById(paymentIntentId);
      if (!intent) return { status: 404, message: 'Payment Intent not found', data: {} };

      // ── PARTIAL PAYMENT ──────────────────────────────────────────────────
      if (intent.isPartial) {
        if (!historyId) {
          return { status: 400, message: 'historyId is required to re-approve a partial installment', data: {} };
        }

        const historyItem = intent.partialPaymentsHistory.id(historyId);
        if (!historyItem) return { status: 404, message: 'Installment history item not found', data: {} };
        
        if (historyItem.status === 'APPROVED') {
          return { status: 200, message: 'Already restored', data: {} };
        }

        if (historyItem.status !== 'REJECTED') {
          return { status: 400, message: `Installment is not in a REJECTED state (current: ${historyItem.status})`, data: {} };
        }

        // Reset this installment to PENDING so approvePartialPayment can process it
        historyItem.status = 'PENDING';
        historyItem.verifiedAt = undefined;
        historyItem.verifiedBy = undefined;

        // Set intent status back so the approval function doesn't block
        intent.status = 'PENDING_BANK_TRANSFER';
        intent.markModified('partialPaymentsHistory');
        
        const conciseNote = `[Admin RESTORE]: ${reason || 'Manual Restore'} on ${new Date().toISOString()} by ${adminId}`;
        intent.notes = intent.notes ? `${intent.notes}\n${conciseNote}` : conciseNote;

        // Save FIRST then delegate — approvePartialPayment needs the updated status
        await intent.save();

        // Delegate to existing engine (creates Entitlement, PlanPurchase, Invoice)
        // NOTE: If this throws, intent is already saved with status PENDING_BANK_TRANSFER.
        // This is acceptable — the admin may click APPROVE again to retry.
        // A full session transaction here is blocked by approvePartialPayment not accepting a session.
        let partialResult;
        try {
          partialResult = await approvePartialPayment(paymentIntentId, historyId, adminId, reason || 'Restored from Rejection', 0);
        } catch (approveErr) {
          // Roll back the in-memory mutation we already committed
          console.error('[revertRejection] approvePartialPayment failed after intent save:', approveErr);
          // Best-effort: revert intent back to REJECTED so the UI shows the correct state
          historyItem.status = 'REJECTED';
          intent.status = 'REJECTED';
          intent.markModified('partialPaymentsHistory');
          await intent.save().catch(() => {});
          return { status: 500, message: 'Failed to restore partial payment. State has been rolled back.', data: {} };
        }

      // ── FULL PAYMENT (PLAN or REGISTRATION) ─────────────────────────────
      } else {
        if (intent.status === 'PAID' || intent.status === 'APPROVED' || intent.status === 'PARTIAL-PAID') {
           return { status: 200, message: 'Already restored', data: {} };
        }

        if (intent.status !== 'REJECTED') {
          return { status: 400, message: `Payment is not in a REJECTED state (current: ${intent.status})`, data: {} };
        }
        
        // Save note and status update ONLY after grant succeeds
        const result = await segmentsService.adminGrantSegment({
          body: {
            userId: intent.userId.toString(),
            segmentPlanId: intent.planId ? intent.planId.toString() : 'REGISTRATION',
            paymentRefId: intent.razorpayOrderId,
            amount: intent.totalAmount,
            paymentMode: intent.paymentMethod || 'BANK_TRANSFER',
            comment: reason || 'Restored from Rejection'
          },
          user
        });

        if (result.status !== 200 && result.status !== 201) {
          return result; // Propagate any errors from the grant engine — intent untouched
        }

        // Grant succeeded — now persist the audit note
        const conciseNote = `[Admin RESTORE]: ${reason || 'Manual Restore'} on ${new Date().toISOString()} by ${adminId}`;
        intent.notes = intent.notes ? `${intent.notes}\n${conciseNote}` : conciseNote;
        await intent.save();
      }

      // 3. Audit Log
      try {
        await AdminAuditLog.create({
          adminId: adminId || intent.userId,
          action: 'PAYMENT_REJECTION_REVERTED',
          targetUserId: intent.userId,
          reason: reason || 'Admin approved previously rejected payment',
          meta: {
            paymentIntentId,
            historyId: historyId || null,
            purchaseType: intent.purchaseType,
            isPartial: intent.isPartial,
            totalAmount: intent.totalAmount
          }
        });
      } catch (auditErr) {
        console.error('[revertRejection] Audit log failed (non-fatal):', auditErr.message);
      }

      console.log(`[revertRejection] Successfully re-approved intent ${paymentIntentId}`);
      return { status: 200, message: 'Payment approved. User access has been restored.', data: {} };

    } catch (error) {
      console.error('[revertRejection] Error:', error);
      return { status: 400, message: error.message, data: {} };
    }
  },

  subscriptionsSegmentList: async ({ query }) => {
    try {
      let segmentsData = await segmentsModel.find().sort({ createdAt: -1 });
      return { status: 200, message: "success", data: { segmentsData } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }

  }

};
export default segmentsService;
