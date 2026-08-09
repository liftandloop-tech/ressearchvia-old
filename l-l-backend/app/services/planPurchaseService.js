import mongoose from "mongoose";
import planPurchaseModel from "../models/planPurchaseModel.js";
import userModel from "../models/userModel.js";
import Razorpay from "razorpay";
import crypto from "crypto";
import paymentModel from "../models/paymentModel.js";
import axios from "axios";
import expiryAlertSettingsModel from "../models/expiryAlertSettingsModel.js";

import segmentsPlanModel from "../models/segmentsPlansModel.js";
import notificationService from "./notificationService.js";
import emailService from "./emailService.js";
import invoiceGenerator from "./invoiceGenerator.js";
import { grantEntitlement } from "./entitlementService.js"; // CHUNK 7 Integration
import Entitlement from "../models/entitlementModel.js"; // CHUNK 8
import AdminAuditLog from "../models/adminAuditLogModel.js"; // CHUNK 8.5
import invoiceModel from "../models/invoiceModel.js";
import segmentsPaymentModel from "../models/segmentsPaymentModel.js";
import PaymentIntent from "../models/paymentIntentModel.js";
import { logSubscriptionExtended, logSubscriptionRevoked, logSubscriptionSuspended, logSubscriptionActivated, logPlanCreated, logPlanTopup } from "./activityLogService.js";
import { getUserTokens } from "../repositories/user.repository.js";
import segmentsModel from "../models/segmentsModel.js";


const planPurchaseService = {
  // ... existing methods ...

  extendSubscription: async ({ body, user, req }) => {
    try {
      const { userId, days } = body;
      const adminId = user ? user._id : null;
      const activePlan = await planPurchaseModel.findOne({ userId: userId, status: "active" });

      if (activePlan) {
        activePlan.endDate.setDate(activePlan.endDate.getDate() + parseInt(days));
        await activePlan.save();
      }

      const entitlement = await grantEntitlement({
        userId: userId,
        type: 'PLAN',
        days: parseInt(days),
        grantedBy: 'ADMIN',
        grantReason: 'MANUAL',
        sourceRefId: activePlan ? activePlan._id : 'ADMIN_EXTEND',
        remarks: `Extended by ${days} days`
      });

      await AdminAuditLog.create({
        adminId: adminId || userId,
        action: 'SUBSCRIPTION_EXTEND',
        targetUserId: userId,
        entitlementId: entitlement._id,
        reason: `Extended by ${days} days`,
        meta: { days, activePlanId: activePlan ? activePlan._id : null }
      });

      // --- COMPLIANCE LOG ---
      logSubscriptionExtended({
        userId,
        days,
        planName: activePlan?.packageName,
        performedBy: { id: adminId?.toString(), name: user?.fullName, role: user?.userType || 'ADMIN' },
        req
      });

      return { status: 200, message: "Subscription extended successfully", data: { activePlan } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  revokeSubscription: async ({ body, user, req }) => {
    try {
      const { userId, planId } = body;
      const adminId = user ? user._id : null;

      const query = planId ? { _id: planId } : { userId: userId, status: "active" };
      const activePlan = await planPurchaseModel.findOne(query);

      if (activePlan) {
        activePlan.status = "revoked";
        await activePlan.save();
      } else {
        return { status: 404, message: "No active plan found to revoke", data: {} };
      }

      const entitlementQuery = { userId: userId, type: 'PLAN', status: 'ACTIVE' };
      if (activePlan) {
        entitlementQuery.sourceRefId = activePlan._id;
      }

      await Entitlement.updateMany(
        entitlementQuery,
        { $set: { status: 'REVOKED', revokedReason: 'ADMIN_REVOKE', revokedAt: new Date() } }
      );

      await AdminAuditLog.create({
        adminId: adminId || userId,
        action: 'SUBSCRIPTION_REVOKE',
        targetUserId: userId,
        reason: 'Admin Revoked Access',
        meta: { previousPlanId: activePlan ? activePlan._id : null }
      });

      // --- COMPLIANCE LOG ---
      logSubscriptionRevoked({
        userId,
        planName: activePlan?.packageName,
        performedBy: { id: adminId?.toString(), name: user?.fullName, role: user?.userType || 'ADMIN' },
        req
      });

      return { status: 200, message: "Subscription revoked successfully", data: { activePlan } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  changePlan: async ({ body }) => {
    try {
      const { userId, newPlanId } = body;
      const activePlan = await planPurchaseModel.findOne({ userId: userId, status: "active" });
      if (!activePlan) {
        return { status: 404, message: "No active plan found", data: {} };
      }

      const newPlan = await segmentsPlanModel.findById(newPlanId);
      if (!newPlan) {
        return { status: 404, message: "New plan not found", data: {} };
      }

      activePlan.packageName = newPlan.planName;
      await activePlan.save();
      // Optionally update Entitlement Resource ID?
      // Entitlements aren't strictly linked to Plan Name strings, but to SegmentPlan IDs. 
      // If we change plan, we should update the entitlement.
      // Since specific logic absent, we assume simple name change for now.

      return { status: 200, message: "Plan changed successfully", data: { activePlan } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  suspendSubscription: async ({ body, user, req }) => {
    try {
      const { userId, planId, reason } = body;
      const adminId = user ? user._id : null;

      if (!reason && planId) {
        // We might want to enforce reason for registration plans, 
        // but let's see if we can identify it first.
      }

      let relevantEntitlements = [];

      let entitlement = await Entitlement.findById(planId);
      if (entitlement) {
        entitlement.status = 'SUSPENDED';
        entitlement.revokedReason = 'ADMIN_SUSPEND';
        entitlement.revokedAt = new Date();
        await entitlement.save();
        relevantEntitlements.push(entitlement);

        let targetPlanId = entitlement.sourceRefId;
        if (targetPlanId) {
          await planPurchaseModel.findByIdAndUpdate(targetPlanId, { status: 'suspended' }).catch(() => { });
        }

        // Sync User Account Status if it's a Registration Entitlement
        if (entitlement.type === 'REGISTRATION') {
          await userModel.findByIdAndUpdate(userId, {
            userStatus: 'SUSPENDED',
            suspensionReason: reason || 'Registration entitlement suspended'
          });
        }
      } else {
        const activePlan = await planPurchaseModel.findById(planId);
        if (activePlan) {
          activePlan.status = 'suspended';
          await activePlan.save();

          let sourceRefIds = [activePlan._id.toString()];
          const match = activePlan.remarks ? activePlan.remarks.match(/LinkedIntent:([a-f0-9]{24})/) : null;
          if (match) sourceRefIds.push(match[1]);

          let ents = await Entitlement.find({ sourceRefId: { $in: sourceRefIds }, status: 'ACTIVE' });

          if (ents.length === 0) {
            if (activePlan.packageName.toLowerCase().includes('registration')) {
              ents = await Entitlement.find({ userId: activePlan.userId, type: 'REGISTRATION', status: 'ACTIVE' });

              // Sync User Account Status for Registration Suspension
              await userModel.findByIdAndUpdate(activePlan.userId, {
                userStatus: 'SUSPENDED',
                suspensionReason: reason || 'Registration plan suspended'
              });
            } else {
              const activeEnts = await Entitlement.find({ userId: activePlan.userId, type: 'PLAN', status: 'ACTIVE' }).populate('resourceId');
              for (const ae of activeEnts) {
                if (ae.resourceId && ae.resourceId.planName) {
                  if (activePlan.packageName.toLowerCase().includes(ae.resourceId.planName.toLowerCase())) {
                    ents.push(ae);
                  }
                }
              }
            }
          }

          for (const e of ents) {
            e.status = 'SUSPENDED';
            e.revokedReason = 'ADMIN_SUSPEND';
            e.revokedAt = new Date();
            await e.save();
            relevantEntitlements.push(e);

            // Double check: if any of these entitlements are REGISTRATION, sync user status
            if (e.type === 'REGISTRATION') {
              await userModel.findByIdAndUpdate(userId, {
                userStatus: 'SUSPENDED',
                suspensionReason: reason || 'Registration plan suspended'
              });
            }
          }
        } else {
          return { status: 404, message: "Subscription not found", data: {} };
        }
      }

      await AdminAuditLog.create({
        adminId: adminId || userId,
        action: 'SUBSCRIPTION_SUSPEND',
        targetUserId: userId,
        reason: 'Admin Suspended Subscription',
        meta: { planId }
      });

      // --- COMPLIANCE LOG ---
      logSubscriptionSuspended({
        userId,
        planId,
        performedBy: { id: adminId?.toString(), name: user?.fullName, role: user?.userType || 'ADMIN' },
        req
      });

      // --- SYNC STATUS WITH LEGACY TABLES (Robust Refactor) ---
      try {
        for (const e of relevantEntitlements) {
          let sid = e.segmentId;
          if (!sid && e.resourceId) {
            const plan = await segmentsPlanModel.findById(e.resourceId);
            if (plan && plan.segmentsId) sid = plan.segmentsId;
          }

          if (sid) {
            await segmentsPaymentModel.updateMany(
              { userId: userId, segmentId: sid, paymentStatus: 'paid' },
              { $set: { paymentStatus: 'suspended' } }
            );
            await userActiveSegmentModel.updateMany(
              { userId: userId, segmentId: sid, isActive: true },
              { $set: { isActive: false } }
            );
          }
        }
      } catch (syncErr) {
        console.warn("[SUSPEND_SYNC_WARNING] Failed syncing legacy tables:", syncErr.message);
      }

      return { status: 200, message: "Subscription suspended successfully", data: {} };
    } catch (e) {
      console.error("Suspend error:", e);
      return { status: 400, message: e.message, data: {} };
    }
  },

  activateSubscription: async ({ body, user, req }) => {
    try {
      const { userId, planId } = body;
      const adminId = user ? user._id : null;

      let relevantEntitlements = [];

      let entitlement = await Entitlement.findById(planId);
      if (entitlement) {
        entitlement.status = 'ACTIVE';
        entitlement.revokedReason = null;
        entitlement.revokedAt = null;
        await entitlement.save();
        relevantEntitlements.push(entitlement);

        let targetPlanId = entitlement.sourceRefId;
        if (targetPlanId) {
          await planPurchaseModel.findByIdAndUpdate(targetPlanId, { status: 'active' }).catch(() => { });
        }

        // Sync User Account Status if it's a Registration Entitlement
        if (entitlement.type === 'REGISTRATION') {
          await userModel.findByIdAndUpdate(userId, {
            userStatus: 'ACTIVE',
            suspensionReason: null
          });
        }
      } else {
        const plan = await planPurchaseModel.findById(planId);
        if (plan) {
          plan.status = 'active';
          await plan.save();

          let sourceRefIds = [plan._id.toString()];
          const match = plan.remarks ? plan.remarks.match(/LinkedIntent:([a-f0-9]{24})/) : null;
          if (match) sourceRefIds.push(match[1]);

          let ents = await Entitlement.find({ sourceRefId: { $in: sourceRefIds }, status: 'SUSPENDED' });

          if (ents.length === 0) {
            if (plan.packageName.toLowerCase().includes('registration')) {
              ents = await Entitlement.find({ userId: plan.userId, type: 'REGISTRATION', status: 'SUSPENDED' });
            } else {
              const suspendedEnts = await Entitlement.find({ userId: plan.userId, type: 'PLAN', status: 'SUSPENDED' }).populate('resourceId');
              for (const se of suspendedEnts) {
                if (se.resourceId && se.resourceId.planName) {
                  if (plan.packageName.toLowerCase().includes(se.resourceId.planName.toLowerCase())) {
                    ents.push(se);
                  }
                }
              }
            }
          }

          for (const e of ents) {
            e.status = 'ACTIVE';
            e.revokedReason = null;
            e.revokedAt = null;
            await e.save();
            relevantEntitlements.push(e);

            // Double check: if any of these entitlements are REGISTRATION, sync user status
            if (e.type === 'REGISTRATION') {
              await userModel.findByIdAndUpdate(userId, {
                userStatus: 'ACTIVE',
                suspensionReason: null
              });
            }
          }
        } else {
          return { status: 404, message: "Subscription not found", data: {} };
        }
      }

      await AdminAuditLog.create({
        adminId: adminId || userId,
        action: 'SUBSCRIPTION_ACTIVATE',
        targetUserId: userId,
        reason: 'Admin Activated Subscription',
        meta: { planId }
      });

      // --- COMPLIANCE LOG ---
      logSubscriptionActivated({
        userId,
        planId,
        performedBy: { id: adminId?.toString(), name: user?.fullName, role: user?.userType || 'ADMIN' },
        req
      });

      // --- SYNC STATUS WITH LEGACY TABLES (Robust Refactor) ---
      try {
        for (const e of relevantEntitlements) {
          let sid = e.segmentId;
          if (!sid && e.resourceId) {
            const plan = await segmentsPlanModel.findById(e.resourceId);
            if (plan && plan.segmentsId) sid = plan.segmentsId;
          }

          if (sid) {
            await segmentsPaymentModel.updateMany(
              { userId: userId, segmentId: sid, paymentStatus: 'suspended' },
              { $set: { paymentStatus: 'paid' } }
            );
            await userActiveSegmentModel.updateMany(
              { userId: userId, segmentId: sid, isActive: false },
              { $set: { isActive: true } }
            );
          }
        }
      } catch (syncErr) {
        console.warn("[ACTIVATE_SYNC_WARNING] Failed syncing legacy tables:", syncErr.message);
      }

      return { status: 200, message: "Subscription activated successfully", data: {} };
    } catch (e) {
      console.error("Activate error:", e);
      return { status: 400, message: e.message, data: {} };
    }
  },

  updateSubscriptionDates: async ({ body, user }) => {
    try {
      const { planId, startDate, endDate, editReason } = body; // planId here is actually Entitlement ID from frontend

      // Production Rule: Admin must provide a reason for manual date edits
      if (!editReason || editReason.trim().length < 5) {
        return { status: 400, message: "A valid reason (min 5 chars) is required for manual date edits", data: {} };
      }

      // Production Rule: End Date cannot precede Start Date
      const sDate = startDate ? new Date(startDate) : null;
      const eDate = endDate ? new Date(endDate) : null;

      if (sDate && eDate && sDate > eDate) {
        return { status: 400, message: "End Date cannot be before Start Date", data: {} };
      }

      // 1. Update Entitlement (Primary Source for Admin Panel)
      const entitlement = await Entitlement.findById(planId);
      if (!entitlement) {
        // Fallback: It might be a direct planId if legacy or called differently? 
        const plan = await planPurchaseModel.findById(planId);
        if (plan) {
          const oldSnapshot = { startDate: plan.startDate, endDate: plan.endDate };
          if (startDate) plan.startDate = new Date(startDate);
          if (endDate) plan.endDate = new Date(endDate);
          await plan.save();

          // Audit for Legacy
          await AdminAuditLog.create({
            adminId: user ? user._id : plan.userId,
            action: 'SUBSCRIPTION_UPDATE_DATES',
            targetUserId: plan.userId,
            reason: editReason,
            meta: { 
              planId: plan._id, 
              snapshotBefore: oldSnapshot,
              snapshotAfter: { startDate: plan.startDate, endDate: plan.endDate }
            }
          });

          return { status: 200, message: "Legacy Plan Updated", data: { plan } };
        }
        return { status: 404, message: "Subscription not found", data: {} };
      }

      // Production Rule: Prevent Overlapping Subscriptions for the same resource/type
      const overlapQuery = {
        userId: entitlement.userId,
        type: entitlement.type,
        status: 'ACTIVE',
        _id: { $ne: entitlement._id }, // Not ourselves
        $or: [
            { startDate: { $lte: eDate || entitlement.endDate }, endDate: { $gte: sDate || entitlement.startDate } }
        ]
      };

      // Specifically check for Plan/Segment conflicts to allow multiple different plans but NOT two of the same
      if (entitlement.type === 'PLAN') {
          if (entitlement.resourceId) overlapQuery.resourceId = entitlement.resourceId;
          if (entitlement.segmentId) overlapQuery.segmentId = entitlement.segmentId;
      }

      const overlapping = await Entitlement.findOne(overlapQuery);
      if (overlapping) {
          return { 
            status: 400, 
            message: `Update failed: This period overlaps with another active ${entitlement.type} entitlement (${overlapping.packageName || overlapping._id})`, 
            data: {} 
          };
      }

      const snapshotBefore = { startDate: entitlement.startDate, endDate: entitlement.endDate };

      if (startDate) entitlement.startDate = new Date(startDate);
      if (endDate) entitlement.endDate = new Date(endDate);
      await entitlement.save();

      // 2. Sync with PlanPurchaseModel (Legacy Source for Mobile App)
      let targetPlanId = null;

      if (entitlement.grantReason === 'MANUAL') {
        targetPlanId = entitlement.sourceRefId;
      } else if (['ONLINE_PAYMENT', 'OFFLINE_PAYMENT'].includes(entitlement.grantReason)) {
        const payment = await paymentModel.findById(entitlement.sourceRefId);
        if (payment) targetPlanId = payment.packageId;
      }

      if (targetPlanId) {
        await planPurchaseModel.findByIdAndUpdate(targetPlanId, {
          startDate: entitlement.startDate,
          endDate: entitlement.endDate
        });
      }

      // Audit (Enhanced with Snapshots)
      await AdminAuditLog.create({
        adminId: user ? user._id : entitlement.userId,
        action: 'SUBSCRIPTION_UPDATE_DATES',
        targetUserId: entitlement.userId,
        reason: editReason,
        meta: { 
          entitlementId: entitlement._id, 
          snapshotBefore: snapshotBefore,
          snapshotAfter: { startDate: entitlement.startDate, endDate: entitlement.endDate }
        }
      });

      return { status: 200, message: "Dates updated successfully", data: { entitlement } };
    } catch (e) {
      console.error("Update Date Error:", e);
      return { status: 400, message: e.message, data: {} };
    }
  },

  adminCreatePlan: async ({ body, user, req }) => {
    try {
      const {
        userId, packageName, amount, validity, startDate, planId, segmentPlanId,
        segmentId, segmentIds, isPartial, comment,
        totalAgreementPrice, raId, isHniGrant
      } = body;

      const duration = parseInt(validity) || 365;
      const start = startDate ? new Date(startDate) : new Date();
      const end = new Date(start);
      // Default end calculation (will be overridden if partial)
      end.setDate(end.getDate() + duration);

      const resourceId = planId || segmentPlanId || null;

      // Handle HNI Price & RA Assignment
      let fullPrice = Number(amount || 0);
      if (isHniGrant && totalAgreementPrice > 0) {
        fullPrice = Number(totalAgreementPrice);
      }

      if (raId) {
        await userModel.findByIdAndUpdate(userId, { raId: raId });
      }

      // --- PARTIAL PAYMENT LOGIC ---
      if (isPartial) {
        const plan = await segmentsPlanModel.findById(resourceId);
        if (!plan) throw new Error("Plan not found. Cannot calculate partial payment.");

        // Identify if it's a registration plan
        const isRegistration = packageName && (packageName.toLowerCase().includes("registration"));
        const multiplier = isRegistration ? 1 : 1.5;

        // Use fullPrice instead of amount for target calculation if HNI
        const basePrice = (isHniGrant && totalAgreementPrice > 0) ? totalAgreementPrice : plan.price || 0;
        const gstPercent = 18;
        const gstAmountFull = Math.round((basePrice * gstPercent) / 100);
        const totalFullAmount = Math.ceil(basePrice + gstAmountFull);

        const partialTotalTarget = Math.ceil(totalFullAmount * multiplier);
        let originalDuration = 30;
        if (plan.day && plan.day.toLowerCase().includes('year')) originalDuration = 365;
        else if (plan.day && (plan.day.toLowerCase().includes('month') || plan.day.toLowerCase().includes('silver'))) originalDuration = 30 * (parseInt(plan.duration) || 1);
        else if (isRegistration && (packageName.toLowerCase().includes('lifetime') || packageName.toLowerCase().includes('gold'))) originalDuration = 3652;
        else if (isRegistration && (packageName.toLowerCase().includes('yearly') || packageName.toLowerCase().includes('silver'))) originalDuration = 365;
        else if (isRegistration) originalDuration = 365;
        else originalDuration = parseInt(plan.duration) || 30;

        const perDayCharge = partialTotalTarget / originalDuration;
        const maxAllowedDays = Math.ceil(totalFullAmount / perDayCharge);

        // 2. Validate Amount Paid (amount variable holds the paid amount)
        const paidAmount = Number(amount || 0);
        if (paidAmount <= 0) {
          throw new Error("Paid amount must be greater than 0 for partial payment");
        }

        // 3. Create Intent (Already Approved)
        const receipt = `manual_partial_${userId.toString().slice(-8)}_${Date.now()}`;

        // Calculate Days Granted
        let amountUsedForDays = paidAmount;
        let walletBalance = 0;
        if (paidAmount > totalFullAmount) {
          amountUsedForDays = totalFullAmount;
          walletBalance = paidAmount - totalFullAmount;
        }

        let daysGranted = Math.min(Math.ceil(amountUsedForDays / perDayCharge), maxAllowedDays);
        if (isRegistration) {
          daysGranted = originalDuration;
        }

        const partialEnd = new Date(start);
        partialEnd.setDate(partialEnd.getDate() + daysGranted);

        let status = 'PENDING_BANK_TRANSFER';
        if (paidAmount >= totalFullAmount) {
          status = 'PAID';
        }

        const paymentIntent = await PaymentIntent.create({
          userId,
          purchaseType: isRegistration ? 'REGISTRATION' : 'PLAN',
          planId: plan._id,
          baseAmount: basePrice,
          gstAmount: gstAmountFull,
          totalAmount: totalFullAmount,
          razorpayOrderId: `MANUAL_${receipt}`,
          status: status,
          paymentMethod: 'OFFLINE',
          isPartial: true,
          partialTotalTarget,
          perDayCharge,
          maxAllowedDays,
          amountPaid: paidAmount,
          walletBalance: walletBalance,
          serviceStartDate: start,
          currentExpiryDate: partialEnd,
          preferredSegmentId: segmentId,
          notes: comment || "",
          partialPaymentsHistory: [{
            amountPaid: paidAmount,
            transactionDate: new Date(),
            status: 'APPROVED',
            verifiedBy: user ? user._id : null,
            verifiedAt: new Date(),
            utrNumber: `MANUAL_${Date.now()}`,
            proofImage: 'MANUAL_GRANT'
          }]
        });

        const userPlan = new planPurchaseModel({
          userId,
          packageName: `${packageName} (Partial)`,
          validity: daysGranted,
          startDate: start,
          endDate: partialEnd,
          status: 'active',
          basicAmount: paidAmount,
          cgstAmount: 0,
          sgstAmount: 0,
          paymentMethod: 'OFFLINE',
          expiryReminder: true,
          isPartial: true,
          remarks: comment || null,
          totalPlanAmount: totalFullAmount,
          gstAmount: gstAmountFull
        });
        await userPlan.save();

        // Update User Model for Registration
        if (isRegistration) {
          await userModel.findByIdAndUpdate(userId, {
            registrationStatus: 'ACTIVE',
            registrationType: (packageName.toLowerCase().includes("lifetime") || packageName.toLowerCase().includes("gold")) ? 'LIFETIME' : 'YEARLY',
            registrationExpiry: partialEnd,
            registrationFeePaid: false // It's partial
          });
        }

        const segmentsToGrant = segmentIds && Array.isArray(segmentIds) && segmentIds.length > 0
          ? segmentIds
          : (segmentId ? [segmentId] : [null]);

        for (const sId of segmentsToGrant) {
          await grantEntitlement({
            userId: userId,
            type: isRegistration ? 'REGISTRATION' : 'PLAN',
            resourceId: plan._id,
            segmentId: sId,
            days: daysGranted,
            startDate: start, // Include start date
            grantedBy: 'ADMIN',
            grantReason: 'MANUAL_PARTIAL',
            sourceRefId: paymentIntent._id.toString(),
            remarks: comment || ""
          });
        }

        await AdminAuditLog.create({
          adminId: user ? user._id : userId,
          action: 'ADMIN_CREATE_PLAN_PARTIAL',
          targetUserId: userId,
          reason: 'Admin Manually Created Partial Plan',
          meta: { packageName, amountPaid: paidAmount, daysGranted, segmentIds: segmentsToGrant }
        });

        return { status: 200, message: `Partial Plan Granted. ${daysGranted} days access given.`, data: { userPlan, paymentIntent } };
      }

      // --- END PARTIAL ---

      const userPlan = new planPurchaseModel({
        userId,
        packageName,
        validity: duration,
        startDate: start,
        endDate: end,
        status: 'active',
        basicAmount: fullPrice,
        cgstAmount: 0,
        sgstAmount: 0,
        paymentMethod: 'OFFLINE',
        expiryReminder: true,
        remarks: comment || null,
        totalPlanAmount: fullPrice,
        gstAmount: 0
      });
      // Check if Registration Plan
      let entitlementType = 'PLAN';
      let isLifetime = false;
      let userToUpdate = null;

      if (packageName && (packageName.toLowerCase().includes("registration"))) {
        entitlementType = 'REGISTRATION';
        userToUpdate = await userModel.findById(userId);
        if (userToUpdate) {
          userToUpdate.registrationStatus = 'ACTIVE';
          userToUpdate.registrationExpiry = end;
          userToUpdate.registrationFeePaid = true;

          if (packageName.toLowerCase().includes("lifetime")) {
            userToUpdate.registrationType = 'LIFETIME';
            userToUpdate.registrationExpiry = null;
            isLifetime = true;
          } else {
            userToUpdate.registrationType = 'YEARLY';
          }
        }
      }

      const segmentsToGrant = segmentIds && Array.isArray(segmentIds) && segmentIds.length > 0
        ? segmentIds
        : (segmentId ? [segmentId] : [null]);

      for (const sId of segmentsToGrant) {
        await grantEntitlement({
          userId,
          type: entitlementType,
          resourceId: resourceId,
          segmentId: sId,
          days: isLifetime ? 3652 : duration,
          isLifetime: isLifetime,
          startDate: start, // Include start date
          grantedBy: 'ADMIN',
          grantReason: isHniGrant ? 'HNI_CUSTOM_GRANT' : 'MANUAL',
          sourceRefId: userPlan._id,
          remarks: comment || ""
        });
      }

      if (userToUpdate) {
        await userToUpdate.save();
      }

      await userPlan.save();

      // Audit
      await AdminAuditLog.create({
        adminId: user ? user._id : userId,
        action: 'ADMIN_CREATE_PLAN',
        targetUserId: userId,
        reason: 'Admin Manually Created Plan',
        meta: { packageName, amount }
      });

      // --- COMPLIANCE LOG ---
      logPlanCreated({
        userId,
        packageName,
        amount,
        days: duration,
        performedBy: { id: user?._id?.toString(), name: user?.fullName, role: user?.userType || 'ADMIN' },
        req
      });

      return { status: 200, message: "Plan created successfully", data: { userPlan } };
    } catch (e) {
      return { status: 400, message: e.message, data: {} };
    }
  },

  adminTopUpPartialPlan: async ({ body, user, req: request }) => {
    try {
      const { userId, entitlementId, amount, comment } = body;
      const topUpAmount = Number(amount);
      if (!topUpAmount || topUpAmount <= 0) {
        throw new Error("Invalid top-up amount");
      }

      // 1. Find the Entitlement and linked PaymentIntent
      const entitlement = await Entitlement.findById(entitlementId);
      if (!entitlement) throw new Error("Entitlement not found");

      if (!['MANUAL_PARTIAL', 'OFFLINE_PAYMENT'].includes(entitlement.grantReason) || !entitlement.sourceRefId) {
        throw new Error("This plan is not a trackable partial plan.");
      }

      const PaymentIntent = (await import('../models/paymentIntentModel.js')).default;
      const paymentIntent = await PaymentIntent.findById(entitlement.sourceRefId);

      if (!paymentIntent) throw new Error("Linked Payment Record not found");
      if (!paymentIntent.isPartial) throw new Error("Linked record is not partial");

      // 2. Calculate New Values
      const previousAmount = paymentIntent.amountPaid || 0;
      const totalCap = paymentIntent.totalAmount; // Max allowed (Plan + GST)
      const newTotalPaid = previousAmount + topUpAmount;

      if (totalCap && newTotalPaid > totalCap) {
        throw new Error(`Top-up exceeds Total Plan Amount (₹${totalCap}). Max allowed top-up: ₹${totalCap - previousAmount}`);
      }

      const perDayCharge = paymentIntent.perDayCharge || 1; // Avoid div by zero

      const additionalDays = Math.floor(topUpAmount / perDayCharge);

      // 3. Update Payment Intent
      paymentIntent.amountPaid = newTotalPaid;
      paymentIntent.partialPaymentsHistory.push({
        amountPaid: topUpAmount,
        transactionDate: new Date(),
        status: 'APPROVED',
        verifiedBy: user ? user._id : null,
        verifiedAt: new Date(),
        utrNumber: `MANUAL_TOPUP_${Date.now()}`,
        proofImage: 'MANUAL_TOPUP',
        note: comment || "Admin TopUp"
      });

      if (paymentIntent.notes) {
        paymentIntent.notes += `\n[${new Date().toLocaleDateString()}] TopUp ₹${topUpAmount}: ${comment || ''}`;
      } else {
        paymentIntent.notes = `[${new Date().toLocaleDateString()}] TopUp ₹${topUpAmount}: ${comment || ''}`;
      }

      if (newTotalPaid >= paymentIntent.totalAmount) {
        paymentIntent.status = 'PAID';
      }

      // Update Expiry Date in PI
      const currentExpiry = new Date(paymentIntent.currentExpiryDate);
      const newExpiry = new Date(currentExpiry);
      newExpiry.setDate(newExpiry.getDate() + additionalDays);
      paymentIntent.currentExpiryDate = newExpiry;

      await paymentIntent.save();

      // 4. Update Entitlement (Extend End Date)
      entitlement.endDate = newExpiry;
      const topUpNote = comment ? `TopUp ₹${topUpAmount}: ${comment}` : `TopUp ₹${topUpAmount}`;
      if (entitlement.remarks) {
        entitlement.remarks += ` | ${topUpNote}`;
      } else {
        entitlement.remarks = topUpNote;
      }
      await entitlement.save();

      // 5. Update PlanPurchase
      const planPurchase = await planPurchaseModel.findOne({
        userId: userId,
        status: 'active',
        isPartial: true
      }).sort({ createdAt: -1 });

      if (planPurchase) {
        // Double check if planPurchase matches roughly (dates overlap)
        // Or if it's the latest active one
        planPurchase.endDate = newExpiry;
        planPurchase.basicAmount = (planPurchase.basicAmount || 0) + topUpAmount;
        planPurchase.validity = (planPurchase.validity || 0) + additionalDays;

        // Append the new comment into remarks
        if (comment) {
          planPurchase.remarks = planPurchase.remarks ? `${planPurchase.remarks} | TopUp: ${comment}` : `TopUp: ${comment}`;
        }
        await planPurchase.save();
      }

      // 6. Audit
      await AdminAuditLog.create({
        adminId: user ? user._id : userId,
        action: 'ADMIN_CREATE_PLAN_PARTIAL',
        targetUserId: userId,
        reason: 'Admin TopUp Partial Plan',
        meta: { topUpAmount, additionalDays, newTotalPaid }
      });

      // --- COMPLIANCE LOG ---
      logPlanTopup({
        userId,
        topUpAmount,
        additionalDays,
        performedBy: { id: user?._id?.toString(), name: user?.fullName, role: user?.userType || 'ADMIN' },
        req: request
      });

      return {
        status: 200,
        message: `Plan TopUp Successful. Added ₹${topUpAmount} (+${additionalDays} days).`,
        data: { newExpiry, newTotalPaid }
      };

    } catch (e) {
      console.log(e);
      return { status: 400, message: e.message, data: {} };
    }
  },

  // Private helper for Unified Financial Engine
  _calculateCorrectionEffect: ({ payment, newAmount, targetIsPartial }) => {
    // 1. Derive Base Rates from Frozen Snapshots
    // For HNI or new records with snapshots, use them.
    // For legacy records, fallback to current plan values (unavoidable for old data)
    let standardDuration;
    let basePrice;

    if (payment.originalPlanAmount > 0 && payment.originalDuration > 0) {
      standardDuration = payment.originalDuration;
      basePrice = payment.originalPlanAmount;
    } else if (payment.planId) {
      standardDuration = parseInt(payment.planId.duration) || parseInt(payment.planId.day) || 30;
      basePrice = payment.planId.price || 0;
    } else if (payment.purchaseType === 'REGISTRATION' || (payment.packageName && payment.packageName.toLowerCase().includes('registration'))) {
      // Legacy Registration fallback
      const isLifetime = (payment.packageName && payment.packageName.toLowerCase().includes('gold')) || payment.amountPaid > 6000;
      standardDuration = isLifetime ? 3652 : 365;
      basePrice = isLifetime ? 10000 : 5000;
    } else {
      throw new Error("Cannot determine base rate: Plan details missing for this record.");
    }

    const dailyRate = basePrice / standardDuration;

    // Use 1x multiplier for REGISTRATION, 1.5x for PLAN
    const isRegistration = (payment.purchaseType === 'REGISTRATION') || (payment.packageName && payment.packageName.toLowerCase().includes('registration'));
    const multiplier = isRegistration ? 1 : 1.5;
    const effectiveRate = targetIsPartial ? (dailyRate * multiplier) : dailyRate;

    // 2. Recalculate Validity (Floor rounding to prevent over-entitlement)
    let newValidity = Math.floor(newAmount / effectiveRate);
    if (newValidity > standardDuration) newValidity = standardDuration;

    // 3. Expiry Calculation (Anchored to ORIGINAL start date to prevent Cumulative Drift)
    const startDate = payment.serviceStartDate || payment.createdAt;
    const newExpiry = new Date(startDate);
    newExpiry.setDate(newExpiry.getDate() + newValidity);

    return {
      newExpiry,
      newValidityDays: newValidity,
      effectiveRate,
      standardDuration,
      originalStartDate: startDate
    };
  },

  adminPreviewCorrection: async ({ body }) => {
    try {
      const { paymentIntentId, newAmount, targetIsPartial } = body;

      const payment = await PaymentIntent.findById(paymentIntentId).populate('planId');
      if (!payment) throw new Error("Payment record not found");

      const effect = planPurchaseService._calculateCorrectionEffect({ payment, newAmount, targetIsPartial });

      return {
        status: 200,
        message: "Correction Preview Generated",
        data: {
          currentExpiry: payment.currentExpiryDate,
          newExpiry: effect.newExpiry,
          newValidityDays: effect.newValidityDays,
          dailyRate: effect.effectiveRate,
          standardDuration: effect.standardDuration,
          originalStartDate: effect.originalStartDate
        }
      };
    } catch (e) {
      return { status: 400, message: e.message, data: {} };
    }
  },

  adminUpdatePayment: async ({ body, user, req }) => {
    try {
      let { paymentIntentId, newAmount, targetIsPartial, reason, previewTimestamp, utrNumber } = body;
      const adminId = user?._id;

      // Ensure proper parsing from FormData
      newAmount = parseFloat(newAmount);
      targetIsPartial = targetIsPartial === true || targetIsPartial === 'true';

      const payment = await PaymentIntent.findById(paymentIntentId);
      if (!payment) throw new Error("Payment record not found");

      // Optional Info update
      if (utrNumber !== undefined && utrNumber !== '') payment.utrNumber = utrNumber;
      if (req.files && req.files.length > 0) {
        const imageUrls = req.files.map(file => file.location || `uploads/receipts/${file.filename}`);
        payment.proofImage = imageUrls[0]; // fallback
        payment.proofImages = imageUrls;
        
        // Auto-promote to VERIFICATION_PENDING if status is PENDING_BANK_TRANSFER
        if (payment.status === 'PENDING_BANK_TRANSFER') {
            payment.status = 'VERIFICATION_PENDING';
        }
      }

      // PHASE 1: Pre-Approval Edit (Draft Mode)
      if (payment.status !== 'PAID' && payment.status !== 'APPROVED') {
        const oldAmount = payment.amountPaid;
        const oldMode = payment.isPartial;

        // For partial payments: update the LATEST installment (by index) and recalculate total
        if (payment.isPartial && payment.partialPaymentsHistory && payment.partialPaymentsHistory.length > 0) {
          // Always target the LAST installment entry (most recent by position)
          const lastIdx = payment.partialPaymentsHistory.length - 1;
          const targetInstallment = payment.partialPaymentsHistory[lastIdx];

          // Save old amount for the delta recalculation
          const oldInstallmentAmount = targetInstallment.amountPaid || 0;

          // Update the installment amount
          targetInstallment.amountPaid = newAmount;

          // Optionally update proof/utr/note on that installment
          if (utrNumber !== undefined && utrNumber !== '') {
            targetInstallment.utrNumber = utrNumber;
          }
          if (req.files && req.files.length > 0) {
            const imageUrls = req.files.map(file => file.location || `uploads/receipts/${file.filename}`);
            targetInstallment.proofImage = imageUrls[0];
            targetInstallment.proofImages = imageUrls;
            payment.proofImage = imageUrls[0]; // also update top-level
            payment.proofImages = imageUrls;
          }
          if (reason) {
            targetInstallment.note = reason;
          }

          // Recalculate total amountPaid:
          // Sum ALL installments except the last one + the new corrected amount
          const otherInstallmentsSum = payment.partialPaymentsHistory
            .slice(0, lastIdx)
            .reduce((sum, h) => sum + (h.amountPaid || 0), 0);

          payment.amountPaid = otherInstallmentsSum + newAmount;
          payment.remainingAmount = Math.max(0, payment.totalAmount - payment.amountPaid - (payment.discount || 0));

          console.log(`[PARTIAL_CORRECTION] Intent: ${payment._id}. Installment[${lastIdx}] updated: ₹${oldInstallmentAmount} → ₹${newAmount}. New total: ₹${payment.amountPaid}`);
        } else {
          // Non-partial payment: update amounts directly
          payment.amountPaid = newAmount;
          payment.isPartial = targetIsPartial;
          payment.remainingAmount = Math.max(0, payment.totalAmount - newAmount - (payment.discount || 0));

          // Update math fields if switching to partial
          if (targetIsPartial) {
            // Identify if it's a registration plan
            const isRegistration = (payment.purchaseType === 'REGISTRATION') || (payment.packageName && payment.packageName.toLowerCase().includes('registration'));
            const multiplier = isRegistration ? 1 : 1.5;

            const partialTotalTarget = Math.ceil(payment.totalAmount * multiplier);
            payment.partialTotalTarget = partialTotalTarget;
            payment.perDayCharge = partialTotalTarget / (payment.originalDuration || 30);
            payment.maxAllowedDays = Math.ceil(payment.totalAmount / payment.perDayCharge);
          }
        }

        // ── Recalculate & Sync Expiry ──────────────────────────────────────────────
        // Populate plan so the math engine has what it needs
        try {
          await payment.populate('planId');
          const effect = planPurchaseService._calculateCorrectionEffect({
            payment,
            newAmount: payment.amountPaid, // use the already-recalculated total
            targetIsPartial: payment.isPartial
          });

          const newExpiry = effect.newExpiry;
          const newValidityDays = effect.newValidityDays;

          // Update currentExpiryDate on the PaymentIntent
          payment.currentExpiryDate = newExpiry;

          // Auto-promote to PAID if corrected amount + discount covers the plan
          const targetAmount = (payment.isPartial ? payment.partialTotalTarget : payment.totalAmount) || payment.totalAmount;
          const isFull = payment.amountPaid >= (targetAmount - 1);
          if (isFull) {
            payment.status = 'PAID';
          }

          await payment.save();

          // Sync User Flags if Registration
          if (payment.purchaseType === 'REGISTRATION') {
            const User = mongoose.model('users');
            await User.findByIdAndUpdate(payment.userId, {
              registrationFeePaid: isFull,
              registrationStatus: 'ACTIVE'
            });
          }

          // Update Entitlement end date
          await Entitlement.updateMany(
            { sourceRefId: payment._id.toString() },
            { $set: { endDate: newExpiry, remarks: `Draft correction: ${reason || 'Admin update'}` } }
          );

          // Update linked PlanPurchase end date
          const planPurchase = await planPurchaseModel.findOne({
            $or: [
              { linkedPaymentIntent: payment._id },
              { remarks: { $regex: payment._id.toString() } }
            ]
          });
          if (planPurchase) {
            planPurchase.endDate = newExpiry;
            planPurchase.validity = newValidityDays;
            await planPurchase.save();
          }

          console.log(`[PHASE1_EXPIRY_SYNC] Intent: ${payment._id}. New expiry: ${newExpiry}. Validity: ${newValidityDays} days.`);

          await AdminAuditLog.create([{
            adminId: adminId,
            action: 'PAYMENT_PRE_APPROVAL_EDIT',
            targetUserId: payment.userId,
            reason: reason || 'Draft correction',
            meta: { paymentIntentId, oldAmount, newAmount: payment.amountPaid, oldMode, newMode: payment.isPartial, newExpiry, newValidityDays }
          }]);

          return { status: 200, message: "Payment draft updated and expiry recalculated successfully", data: { payment, newExpiry, newValidityDays } };

        } catch (mathErr) {
          // If math engine fails (e.g. plan data missing), still save and return without expiry update
          console.warn(`[PHASE1_EXPIRY_SKIP] Could not recalculate expiry for Intent ${payment._id}: ${mathErr.message}`);
          await payment.save();

          await AdminAuditLog.create([{
            adminId: adminId,
            action: 'PAYMENT_PRE_APPROVAL_EDIT',
            targetUserId: payment.userId,
            reason: reason || 'Draft correction',
            meta: { paymentIntentId, oldAmount, newAmount: payment.amountPaid, oldMode, newMode: payment.isPartial }
          }]);

          return { status: 200, message: "Payment draft updated successfully (expiry sync skipped)", data: payment };
        }
      }

      // PHASE 2: Post-Approval Correction (Ledger Revaluation)
      
      // If the admin is ONLY updating files/UTR and NOT changing the amount, save and exit early!
      if (payment.amountPaid === newAmount && payment.isPartial === targetIsPartial) {
          // Just save the payment record with the updated URL/UTR and skip tracking as a financial correction
          await payment.save();
          return { status: 200, message: "Payment info updated successfully without ledger revaluation.", data: { payment } };
      }

      // 1. Concurrency Check (Optimistic Locking)
      if (previewTimestamp && payment.updatedAt > new Date(previewTimestamp)) {
        console.warn(`[CONCURRENCY_ABORT] Intent: ${paymentIntentId}. Admin: ${adminId}. Reason: Preview stale.`);
        throw new Error("Financial record was updated by another admin. Please refresh.");
      }

      if (!reason || reason.length < 10) {
        throw new Error("A valid reason (min 10 chars) is mandatory for post-approval corrections.");
      }

      // Populate plan for math engine (needed for legacy fallback)
      await payment.populate('planId');

      // 2. Run Mathematical Engine (Frozen Rate Logic)
      const effect = planPurchaseService._calculateCorrectionEffect({ payment, newAmount, targetIsPartial });

      const newExpiry = effect.newExpiry;
      const newValidityDays = effect.newValidityDays;
      const oldAmount = payment.amountPaid;
      const oldMode = payment.isPartial;
      const oldExpiry = payment.currentExpiryDate;

      const snapShotBefore = {
        amountPaid: payment.amountPaid,
        isPartial: payment.isPartial,
        validity: payment.maxAllowedDays, // for partials
        expiry: payment.currentExpiryDate
      };

      // 3. Update PaymentIntent
      payment.amountPaid = newAmount;
      payment.isPartial = targetIsPartial;
      payment.isCorrected = true;
      payment.correctionVersion = (payment.correctionVersion || 0) + 1;
      payment.currentExpiryDate = newExpiry;
      payment.remainingAmount = Math.max(0, payment.totalAmount - newAmount);

      payment.correctionHistory.push({
        oldAmount,
        newAmount,
        oldMode,
        newMode: targetIsPartial,
        oldExpiry,
        newExpiry,
        reason,
        correctedBy: adminId,
        correctedAt: new Date(),
        snapShotBefore,
        snapShotAfter: {
          amountPaid: newAmount,
          isPartial: targetIsPartial,
          expiry: newExpiry
        }
      });

      // Sensitivity Check (Fraud/Audit Protection)
      const amountDelta = Math.abs(newAmount - oldAmount) / (oldAmount || 1);
      const isHighSensitivity = (payment.correctionVersion > 3) || (amountDelta > 0.4);

      if (isHighSensitivity) {
        console.warn(`[HIGH_SENSITIVITY_CORRECTION] Intent: ${paymentIntentId}. Admin: ${adminId}. Version: ${payment.correctionVersion}. Delta: ${(amountDelta * 100).toFixed(2)}%`);
      }

      await payment.save();

      // 4. Update Linked PlanPurchase
      const planPurchase = await planPurchaseModel.findOne({
        $or: [
          { linkedPaymentIntent: payment._id },
          { remarks: { $regex: payment._id.toString() } }
        ]
      });

      if (planPurchase) {
        const gstPercent = payment.gstRateUsed || 18;
        const baseAmount = newAmount / (1 + (gstPercent / 100));

        planPurchase.basicAmount = baseAmount;
        planPurchase.gstAmount = newAmount - baseAmount;
        planPurchase.totalPlanAmount = newAmount;
        planPurchase.validity = newValidityDays;
        planPurchase.endDate = newExpiry;
        planPurchase.isPartial = targetIsPartial;
        planPurchase.remarks = planPurchase.remarks ? `${planPurchase.remarks} | Corrected: ${reason}` : `Corrected: ${reason}`;

        await planPurchase.save();
      }

      // 5. Update Linked Entitlements
      await Entitlement.updateMany(
        { sourceRefId: payment._id.toString() },
        {
          $set: {
            endDate: newExpiry,
            remarks: `Corrected: ${reason}`
          }
        }
      );

      // 6. Final Audit Log
      await AdminAuditLog.create([{
        adminId: adminId,
        action: isHighSensitivity ? 'HIGH_SENSITIVITY_CORRECTION' : 'PAYMENT_LEDGER_CORRECTION',
        targetUserId: payment.userId,
        reason: reason,
        meta: {
          paymentIntentId,
          version: payment.correctionVersion,
          oldAmount, newAmount,
          oldExpiry, newExpiry,
          oldMode, newMode: targetIsPartial
        }
      }]);

      return {
        status: 200,
        message: "Ledger correction applied successfully. Entitlements updated.",
        data: { newExpiry, newAmount }
      };

    } catch (e) {
      console.error(`[FATAL_FINANCIAL_ERROR] Intent: ${body.paymentIntentId}. Admin: ${user?._id}. Error: ${e.message}`);
      return { status: 400, message: e.message, data: {} };
    }
  },

  purchasePlan: async ({ params, body }) => {
    try {
      let { id } = params;
      let { packageName, amount, validity, cgstAmount, sgstAmount } = body;
      validity = parseInt(validity)
      cgstAmount = parseFloat(cgstAmount)
      sgstAmount = parseFloat(sgstAmount)
      let currency = process.env.CURRENCY || "INR";
      let startDate = new Date();
      let endDate = new Date(startDate);
      const receipt = `receipt${Date.now()}`; // unique receipt
      const amountPaise = Math.round(amount * 100);
      endDate.setDate(endDate.getDate() + validity);

      // ── DUPLICATE PLAN GUARD (Legacy purchasePlan) ──────────────────────────
      // 1. Block if user has active/suspended plan
      const activeEntitlement = await Entitlement.findOne({
        userId: id,
        type: 'PLAN',
        status: { $in: ['ACTIVE', 'SUSPENDED'] },
        $or: [{ endDate: null }, { endDate: { $gt: new Date() } }]
      });
      if (activeEntitlement) {
        throw new Error('You already have an active subscription for this plan.');
      }

      // 2. Block if pending/partial exists
      const pendingIntent = await PaymentIntent.findOne({
        userId: id,
        purchaseType: 'PLAN',
        status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] }
      }).sort({ createdAt: -1 });
      if (pendingIntent) {
        throw new Error('Your previous payment is pending verification or completion.');
      }

      // 3. Razorpay Idempotency for legacy payment table
      const tenMinsAgo = new Date(Date.now() - 10 * 60 * 1000);
      const existingPayment = await paymentModel.findOne({
        userId: id,
        status: 'pending',
        razorpayOrderId: { $exists: true },
        createdAt: { $gte: tenMinsAgo }
      }).sort({ createdAt: -1 });

      if (existingPayment) {
        const userPlan = await planPurchaseModel.findById(existingPayment.packageId);
        if (userPlan) {
          return {
            status: 200,
            message: "Order resumed",
            data: { orderCreate: existingPayment, userPlan },
          };
        }
      }
      // ── END GUARD ─────────────────────────────────────────────────────────────

      const user = await userModel.findOne({ _id: id });
      if (!user) {
        return { status: 404, message: "User not found", data: {} };
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
      // Ensure registration fee is paid before buying plan (unless admin provisioned or mixed)
      if (user.account_type === 'SELF_REGISTERED' && user.registrationStatus !== 'ACTIVE' && user.registrationStatus !== 'COMPLETE') {
        // Allow if they are buying a plan that INCLUDES registration? No, plans are separate.
        // STRICT GATE: Must pay registration first.
        return {
          status: 403,
          message: "Platform Access Fee Required. Please pay registration fee first.",
          data: {}
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
      const userPlan = new planPurchaseModel({
        userId: id,
        packageName: packageName,
        validity: validity,
        startDate: startDate,
        endDate: endDate,
        status: "pending",
        basicAmount: amount,
        cgstAmount: cgstAmount,
        sgstAmount: sgstAmount
      });
      await userPlan.save();
      const orderCreate = await paymentModel.create({
        userId: id,
        packageId: userPlan._id,
        razorpayOrderId: order.id,
        razorpayCurrency: currency,
        razorpayReceipt: receipt,
        amount: amount,
        paymentMethod: null // initially null

      });
      console.log("====", order)
      await orderCreate.save();
      if (!orderCreate || orderCreate === null) {
        await userPlan.deleteOne();
        return {
          status: 500,
          message: "Failed to create payment record",
          data: {},
        };
      }
      return {
        status: 200,
        message: "Order created successfully",
        data: { orderCreate, userPlan },
      };
    } catch (error) {
      console.log("error", error);
      return { status: 400, message: error.message || error, data: {} };
    }
  },
  paymentVerify: async ({ body }) => {
    try {
      const { paymentId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = body;
      const payment = await paymentModel.findOne({ _id: paymentId });
      if (!payment) {
        return {
          status: 404,
          success: false,
          message: "Payment not found",
          data: {},
        };
      }

      if (payment.status === 'paid') {
        return {
          status: 200,
          success: true,
          message: "Payment already processed",
          data: { payment },
        };
      }

      const secret = process.env.RAZORPAY_KEY_SECRET;
      const generatedSignature = crypto
        .createHmac("sha256", secret)
        .update(razorpay_order_id + "|" + razorpay_payment_id)
        .digest("hex");

      if (generatedSignature === razorpay_signature) {

        // Amount Verification
        const razorpay = new Razorpay({
          key_id: process.env.RAZORPAY_KEY_ID,
          key_secret: process.env.RAZORPAY_KEY_SECRET,
        });

        const razorpayPayment = await razorpay.payments.fetch(razorpay_payment_id);
        const expectedAmountPaise = Math.round(payment.amount * 100);

        if (razorpayPayment.amount !== expectedAmountPaise) {
          console.error(`Fraud Alert: Amount mismatch. Expected ${expectedAmountPaise}, got ${razorpayPayment.amount}`);
          return {
            status: 400,
            success: false,
            message: "Payment amount mismatch! Potential fraud attempt.",
            data: {}
          };
        }

        payment.razorpayPaymentId = razorpay_payment_id;
        payment.razorpaySignature = razorpay_signature;
        payment.status = "paid";
        payment.paymentMethod = razorpayPayment.method; // Store method
        await payment.save();

        const plan = await planPurchaseModel.findByIdAndUpdate(payment.packageId, {
          status: "active",
        });

        // UNIFIED ENGINE: Finalize PaymentIntent
        try {
          const intent = await PaymentIntent.findOne({ razorpayOrderId: razorpay_order_id });
          if (intent) {
            intent.status = 'PAID';
            intent.amountPaid = payment.amount;
            intent.paymentMethod = razorpayPayment.method || 'ONLINE';
            if (!intent.serviceStartDate) {
              intent.serviceStartDate = new Date();
            }
            if (plan && plan.endDate) {
              intent.currentExpiryDate = plan.endDate;
            }
            await intent.save();
          }
        } catch (intentErr) {
          console.error("Error finalizing PaymentIntent in verification:", intentErr);
        }

        // Update User Registration Status if this was a Registration Purchase
        const user = await userModel.findById(payment.userId);
        if (plan.packageName.includes("Registration") && user) {
          user.registrationStatus = 'ACTIVE';
          if (plan.packageName.includes("Lifetime")) {
            user.registrationType = 'LIFETIME';
            user.registrationExpiry = null;
            // CHUNK 7: Grant Entitlement
            await grantEntitlement({
              userId: user._id,
              type: 'REGISTRATION',
              isLifetime: true,
              grantedBy: 'SYSTEM',
              grantReason: 'ONLINE_PAYMENT',
              sourceRefId: payment._id
            });
          } else {
            user.registrationType = 'YEARLY';
            // Calculate expiry based on validity
            const expiry = new Date(plan.startDate);
            expiry.setDate(expiry.getDate() + (plan.validity || 365));
            user.registrationExpiry = expiry;
            // CHUNK 7: Grant Entitlement
            await grantEntitlement({
              userId: user._id,
              type: 'REGISTRATION',
              days: (plan.validity || 365),
              grantedBy: 'SYSTEM',
              grantReason: 'ONLINE_PAYMENT',
              sourceRefId: payment._id
            });
          }
          await user.save();
        }


        try {
          if (user && plan) {
            const invoiceData = {
              invoiceNumber: payment.razorpayReceipt,
              date: new Date(),
              customerName: user.fullName || 'Valued Customer',
              customerEmail: user.email,
              customerPhone: user.phone,
              planName: plan.packageName,
              basicAmount: plan.basicAmount || 0,
              cgst: plan.cgstAmount || 0,
              sgst: plan.sgstAmount || 0,
              totalAmount: payment.amount,
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

            // ... invoice logic ...
            const pdfBytes = await invoiceGenerator.generateInvoice(invoiceData);

            /* 
            if (user.email) {
              await emailService.sendEmail({
                to: user.email,
                subject: "Payment Invoice - ResearchVia",
                htmlContent: `<p>Dear ${user.fullName || 'Customer'},</p>
                         <p>Thank you for subscribing to ResearchVia. Your payment of ₹${payment.amount} was successful.</p>
                         <p>Please find your invoice attached.</p>
                         <p>Regards,<br>Team ResearchVia</p>`,
                attachments: [{
                  filename: `Invoice_${payment.razorpayReceipt}.pdf`,
                  content: Buffer.from(pdfBytes),
                  contentType: 'application/pdf'
                }]
              });
              console.log(`Invoice sent to ${user.email}`);
            }
            */
          }
        } catch (invoiceError) {
          console.error("Error sending invoice:", invoiceError);
        }
        // -------------------------------

        return {
          status: 200,
          success: true,
          message: "Payment verified successfully!",
          data: { payment },
        };
      } else {
        // ... fail logic existing ...
        payment.status = "failed";
        await payment.save();
        await planPurchaseModel.findByIdAndUpdate(payment.packageId, {
          status: "failed",
        });
        // ... 
        return {
          status: 200,
          success: false,
          message: "Invalid signature!",
          data: {}
        };
      }
    } catch (error) {
      return { status: 400, success: false, message: error.message, data: {} };
    }
  },
  expirePlan: async () => {
    try {
      console.log("Expired plans updated");
      const today = new Date();
      await planPurchaseModel.updateMany(
        { endDate: { $lt: today }, status: "active" },
        { $set: { status: "expired" } },
      );

      // PARTIAL PAYMENT - PHASE 3: Handle Wallet Overflow for Expired Partials
      try {
        const acquisitionService = await import("./acquisitionService.js");
        await acquisitionService.handleExpiredPartials();
      } catch (err) {
        console.error("Error in partial payment overflow cron:", err);
      }

      console.log("Your plan is expire");
    } catch (error) {
      console.log("Your plan is expire", error.message);
    }
  },

  sendExpiryReminders: async () => {
    try {
      // Default fallbacks
      let checkDays = [7, 3, 1];

      // Fetch global settings
      const settings = await expiryAlertSettingsModel.findOne();

      if (settings) {
        // Check global master switch
        if (settings.isAutomatedAlertsEnabled === false) {
          console.log("Expiry alerts are disabled globally.");
          return;
        }

        const activeAlerts = (settings && settings.alerts)
          ? settings.alerts.filter(a => a.enabled === true)
          : [{ days: 7, enabled: true, title: "Subscription Expiring Soon!", body: "Your {{planName}} plan expires in {{days}} days. Renew now to continue services." }];

        for (const alert of activeAlerts) {
          const days = alert.days;
          const targetDateStart = new Date();
          targetDateStart.setDate(targetDateStart.getDate() + days);
          targetDateStart.setHours(0, 0, 0, 0);

          const targetDateEnd = new Date(targetDateStart);
          targetDateEnd.setHours(23, 59, 59, 999);

          const plans = await planPurchaseModel.find({
            status: 'active',
            endDate: { $gte: targetDateStart, $lte: targetDateEnd },
            expiryReminder: true
          });

          for (const plan of plans) {
            const user = await userModel.findById(plan.userId);
            if (!user) continue;

            // Replace placeholders
            const replacements = {
              '{{planName}}': plan.packageName || 'active',
              '{{days}}': days.toString(),
              '{{customerName}}': user.fullName || 'Valued User'
            };

            let title = alert.title || "Subscription Expiring Soon!";
            let body = alert.body || `Your ${plan.packageName} plan expires in ${days} days. Renew now to continue services.`;

            Object.keys(replacements).forEach(key => {
              title = title.split(key).join(replacements[key]);
              body = body.split(key).join(replacements[key]);
            });

            // 1. Send Push Notification (Robust via Repository)
            const tokens = await getUserTokens(user._id);
            if (tokens && tokens.length > 0) {
              await notificationService.sendPushNotification(tokens, title, body, {
                type: 'EXPIRY_REMINDER',
                planId: plan._id.toString(),
                daysRemaining: days.toString()
              });
            }

            // 2. Send Email
            if (user.email) {
              await emailService.sendEmail({
                to: user.email,
                subject: title,
                htmlContent: `<p>Hello ${user.fullName || 'User'},</p><p>${body}</p><p>Regards,<br>Team ResearchVia</p>`
              });
            }

          }
        }
      }
      console.log("Expiry reminders check completed");
    } catch (error) {
      console.error("Error sending expiry reminders:", error);
    }
  },


  expiryReminderOnOff: async ({ params, body }) => {
    try {
      let { id } = params;
      let { expiryReminder } = body;
      let expiryReminderstatus = await planPurchaseModel.findOne({
        userId: id,
        status: "active",
      });
      if (expiryReminderstatus.expiryReminder == true) {
        expiryReminderstatus.expiryReminder = expiryReminder;
        expiryReminderstatus.save();
      } else {
        expiryReminderstatus.expiryReminder = expiryReminder;
        expiryReminderstatus.save();
      }
      let expiryReminderOnOff = expiryReminderstatus.expiryReminder;
      return { status: 201, message: "success", data: { expiryReminderOnOff } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  getUserActivePlan: async ({ params }) => {
    try {
      let { id } = params;
      const activePlan = await planPurchaseModel.findOne({ userId: id, status: "active" }).sort({ createdAt: -1 })
      if (!activePlan || activePlan == null) {
        return {
          status: 200,
          message: "User Active Plan not Found",
          data: {},
        };
      }
      return {
        status: 200,
        message: "User Active Plan",
        data: { activePlan },
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  subcriptionHistory: async ({ params, query, user }) => {
    try {
      let { id } = params;
      let { page, pageSize, search, type, includeTrials } = query;
      let queryArgs = { userId: id };

      if (type) {
        // Map frontend 'registration'/'plan' to backend 'REGISTRATION'/'PLAN'
        queryArgs.type = type.toUpperCase();
      }

      // Default pagination values
      page = page ? parseInt(page) : 1;
      pageSize = pageSize ? parseInt(pageSize) : 10;

      // Filter out free trials from history by default, unless explicitly requested by Admin
      if (includeTrials === 'true') {
        // Role check: Only admin, super_admin, or specific roles can view trials
        const allowedRoles = ['admin', 'super_admin', 'Researcher', 'Director']; // Based on accessMiddleware
        if (!user || (!allowedRoles.includes(user.userType) && !allowedRoles.includes(user.role))) {
          return { status: 403, message: "Forbidden: Unauthorized access to trial data", data: {} };
        }
        // If authorized, we don't apply the NE filter, so trials ARE included
      } else {
        queryArgs.grantReason = { $ne: 'REGISTRATION_TRIAL' };
      }

      const totalCount = await Entitlement.countDocuments(queryArgs);

      const entitlements = await Entitlement.find(queryArgs)
        .populate({
          path: 'resourceId',
          model: 'segmentsPlan',
          select: 'planName price duration day segmentsName'
        })
        .populate({
          path: 'segmentId',
          model: 'segments',
          select: 'segmentName'
        })
        .sort({ createdAt: -1 })
        .skip((page - 1) * pageSize)
        .limit(parseInt(pageSize));

      const userSubcriptionHistory = await Promise.all(entitlements.map(async (ent) => {
        let packageName = 'Unknown Plan';
        let amount = 0;
        let validity = 0;
        let isPartial = false;
        let paymentIntentId = null;
        let invoiceId = null;
        let segmentDefId = null;
        let remarks = ent.remarks || "";

        if (ent.type === 'REGISTRATION') {
          // Infer registration details
          const start = new Date(ent.startDate);
          let end = ent.endDate ? new Date(ent.endDate) : null;

          if (end) {
            const diffTime = Math.abs(end - start);
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            validity = diffDays;

            if (diffDays > 400) { // Lifetime ~ 3650
              packageName = 'Gold Registration';
              amount = 10000; // Base amount
            } else {
              packageName = 'Silver Registration';
              amount = 5000;
            }
          } else {
            packageName = 'Gold Registration';
            amount = 10000;
            validity = 3652;
            // No endDate for Lifetime/Gold usually, but let's keep it null
          }
        } else if (ent.type === 'PLAN') {
          if (ent.resourceId) {
            const segName = ent.segmentId?.segmentName || ent.resourceId.segmentsName;
            packageName = segName ? `${segName} - ${ent.resourceId.planName}` : ent.resourceId.planName;
            amount = ent.resourceId.price || 0;
            // Calc validity from dates or plan
            if (ent.endDate) {
              const diffTime = Math.abs(new Date(ent.endDate) - new Date(ent.startDate));
              validity = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            } else {
              validity = parseInt(ent.resourceId.duration) || 30;
            }

            // Look up PaymentIntent to get isPartial flag & Invoice & Remarks
            segmentDefId = ent.segmentId ? ent.segmentId._id : (ent.resourceId ? ent.resourceId.segmentsId : null);
            try {
              const PaymentIntent = (await import('../models/paymentIntentModel.js')).default;
              const Invoice = (await import('../models/invoiceModel.js')).default;

              // 1. Try Direct Link via sourceRefId (Best for Manual Grants & New System)
              let paymentIntent = null;

              if (ent.sourceRefId) {
                // Try to find if sourceRefId is a PaymentIntent
                const possiblePI = await PaymentIntent.findById(ent.sourceRefId);
                if (possiblePI) {
                  paymentIntent = possiblePI;
                }
              }

              // 2. Logic to determine isPartial and Correct Amount
              if (paymentIntent) {
                // Found a linked Payment Intent (e.g. Partial Grant)
                paymentIntentId = paymentIntent._id;
                isPartial = paymentIntent.isPartial || false;

                if (isPartial && paymentIntent.amountPaid !== undefined) {
                  amount = paymentIntent.amountPaid; // Use actual paid amount for partials
                }
                if (paymentIntent.notes) {
                  remarks = paymentIntent.notes;
                } else if (!remarks && ent.grantReason === 'MANUAL_PARTIAL') {
                  remarks = "Partial Payment Grant";
                }

              } else if (ent.grantReason === 'MANUAL') {
                // If no PaymentIntent found, it might be a Legacy PlanPurchase (Full Grant)
                // Check PlanPurchase if sourceRefId points to it
                if (ent.sourceRefId) {
                  const planPurchase = await planPurchaseModel.findById(ent.sourceRefId);
                  if (planPurchase) {
                    amount = planPurchase.basicAmount; // This is full amount for full grants
                    // Make sure isPartial is false unless explicitly set (if we add isPartial to PlanPurchase)
                    if (planPurchase.isPartial === true) {
                      isPartial = true;
                    }
                  }
                }
              } else if (ent.grantReason === 'MANUAL_PARTIAL') {
                // Fallback: If reason says partial but no PI found (unlikely), flag it
                isPartial = true;
                remarks = remarks || "Partial Payment (Manual)";
              } else {
                // Fallback for Older Data (The "Loose Query")
                // ONLY if we haven't determined it's a Manual Full Grant
                // Be careful: this causes the bug where Full Plans get flagged as Partial if a Partial PI exists for the plan.
                // We should avoid this unless absolutely necessary.
                // Given the recent partial implementation, we can skip this loose query to avoid false positives.
                // The new system relies on sourceRefId.
              }


              // HNI Custom Plan Override (Logic preserved)
              if (ent.grantReason === 'HNI_CUSTOM_GRANT' && ent.sourceRefId) {
                try {
                  const sp = await segmentsPaymentModel.findById(ent.sourceRefId);
                  if (sp) {
                    amount = sp.amount;
                    if (!packageName.includes('Custom')) {
                      packageName = `HNI Custom - ${packageName}`;
                    }
                  }
                } catch (err) {
                  console.error("Error fetching HNI payment info:", err);
                }
              }

              const conditions = [];
              if (paymentIntent && paymentIntent.razorpayOrderId) conditions.push({ paymentRefId: paymentIntent.razorpayOrderId });
              if (ent.sourceRefId) {
                conditions.push({ paymentRefId: ent.sourceRefId });
                conditions.push({ userActiveSegmentsId: ent.sourceRefId });
              }

              if (conditions.length > 0) {
                const inv = await Invoice.findOne({ userId: id, $or: conditions }).select('_id');
                if (inv) invoiceId = inv._id;
              }

            } catch (err) {
              console.error("Error fetching partial info/invoice for history:", err);
            }
          }
        }

        // Unified Engine metadata fetching
        let piData = null;
        if (paymentIntentId) {
          const PaymentIntent = (await import('../models/paymentIntentModel.js')).default;
          piData = await PaymentIntent.findById(paymentIntentId).lean();
        }

        return {
          _id: ent._id,
          type: ent.type === 'REGISTRATION' ? 'registration' : 'plan',
          packageName: packageName,
          planName: packageName, // For frontend compatibility
          startDate: ent.startDate,
          endDate: ent.endDate,
          status: ent.status.toLowerCase(), // 'active', 'expired', 'revoked'
          basicAmount: amount, // Approximated from plan/reg type or Override
          amount: amount,
          validity: validity,
          isTrial: ent.grantReason === 'REGISTRATION_TRIAL',
          grantReason: ent.grantReason,
          createdAt: ent.createdAt,
          isPartial: isPartial,
          paymentIntentId: paymentIntentId,
          paymentIntentStatus: piData?.status || null,
          invoiceId: invoiceId,
          segmentId: segmentDefId,
          planId: piData?.preferredPlanId || (ent.resourceId ? ent.resourceId._id : null),
          preferredPlanId: piData?.preferredPlanId,
          preferredSegmentId: piData?.preferredSegmentId,
          serviceStartDate: piData?.serviceStartDate,
          currentExpiryDate: piData?.currentExpiryDate,
          remarks: remarks || "",
          totalPlanAmount: piData?.totalAmount || null,
          amountPaid: piData?.amountPaid != null ? piData.amountPaid : (amount || 0),
          totalAmount: (piData?.totalAmount != null && piData.totalAmount > 0) ? piData.totalAmount : (amount || 0),
          baseAmount: piData?.baseAmount || (amount > 0 ? Math.round(amount / (1 + (piData?.gstRateUsed || 18) / 100)) : 0),
          gstAmount: piData?.gstAmount || (amount > 0 ? (amount - Math.round(amount / (1 + (piData?.gstRateUsed || 18) / 100))) : 0),
          discount: piData?.discount || 0,
          totalAgreedAmount: piData?.isPartial ? (piData.partialTotalTarget || piData.totalAmount) : (piData?.totalAmount || amount || 0),
          effective_total_payable: Math.max(0, ((piData?.totalAmount != null && piData.totalAmount > 0) ? piData.totalAmount : (amount || 0)) - (piData?.discount || 0)),
          remainingAmount: (piData?.totalAmount != null && piData.totalAmount > 0)
            ? Math.max(0, piData.totalAmount - (piData.amountPaid || 0) - (piData.discount || 0))
            : Math.max(0, (amount || 0) - (ent.amountPaid || 0)),
          baseRemaining: (piData?.totalAmount != null && piData.totalAmount > 0)
            ? Math.round(Math.max(0, piData.totalAmount - (piData.amountPaid || 0) - (piData.discount || 0)) / (1 + (piData?.gstRateUsed || 18) / 100) * 100) / 100
            : Math.round(Math.max(0, (amount || 0) - (ent.amountPaid || 0)) / 1.18 * 100) / 100,
          gstRemaining: (piData?.totalAmount != null && piData.totalAmount > 0)
            ? Math.round((Math.max(0, piData.totalAmount - (piData.amountPaid || 0) - (piData.discount || 0)) - (Math.max(0, piData.totalAmount - (piData.amountPaid || 0) - (piData.discount || 0)) / (1 + (piData?.gstRateUsed || 18) / 100))) * 100) / 100
            : Math.round((Math.max(0, (amount || 0) - (ent.amountPaid || 0)) - (Math.max(0, (amount || 0) - (ent.amountPaid || 0)) / 1.18)) * 100) / 100,
          partialTotalTarget: piData?.partialTotalTarget || null,
          perDayCharge: (piData?.totalAmount != null && (piData.originalDuration || validity) > 0) ? (piData.totalAmount / (piData.originalDuration || validity)) : (amount > 0 && validity > 0 ? amount / validity : (piData?.perDayCharge || null)),
          maxAllowedDays: piData?.maxAllowedDays || null,
          partialPaymentsHistory: (piData?.partialPaymentsHistory || []).map(inst => {
            const gstRate = piData?.gstRateUsed || 18;
            const baseInst = Math.round((inst.amountPaid || 0) / (1 + gstRate / 100) * 100) / 100;
            const gstInst = Math.round(((inst.amountPaid || 0) - baseInst) * 100) / 100;
            return {
              ...inst,
              baseAmount: baseInst,
              gstAmount: gstInst
            };
          }),
          correctionVersion: piData?.correctionVersion || 0,
          correctionHistory: piData?.correctionHistory || []
        };
      }));

      return {
        status: 200,
        message: "User Subscription History (Entitlements)",
        data: { totalCount, userSubcriptionHistory },
      };
    } catch (error) {
      console.error("Error in subcriptionHistory:", error);
      return { status: 400, message: error.message, data: {} };
    }
  },
  purchaseRegistration: async ({ params, body }) => {
    try {
      let { id } = params;
      let { type, paymentMode } = body; // type: 'YEARLY' or 'LIFETIME', paymentMode: 'ONLINE' | 'OFFLINE'
      paymentMode = paymentMode || 'ONLINE';

      const user = await userModel.findOne({ _id: id });
      if (!user) {
        return { status: 404, message: "User not found", data: {} };
      }

      // CHUNK 3: KYC Gate for Registration Purchase too?
      // Yes, Platform Access usually implies verified identity.
      const validKycStatus = ['VERIFIED', 'APPROVED'];
      if (!validKycStatus.includes(user.kycStatus)) {
        return {
          status: 403,
          message: "KYC Verification Required before payment.",
          data: {}
        };
      }

      // ── DUPLICATE REGISTRATION GUARD (Legacy purchaseRegistration) ────────────
      // 1. Block if active/suspended
      const activeReg = await Entitlement.findOne({
        userId: id,
        type: 'REGISTRATION',
        status: { $in: ['ACTIVE', 'SUSPENDED'] },
        $or: [{ endDate: null }, { endDate: { $gt: new Date() } }]
      });
      if (activeReg) {
        throw new Error('Registration is already active or suspended.');
      }

      // 2. Block if pending/partial exists
      const pendingReg = await PaymentIntent.findOne({
        userId: id,
        purchaseType: 'REGISTRATION',
        status: { $in: ['PENDING_BANK_TRANSFER', 'VERIFICATION_PENDING'] }
      }).sort({ createdAt: -1 });
      if (pendingReg) {
        throw new Error('Previous registration payment is pending verification or completion.');
      }
      // ── END GUARD ─────────────────────────────────────────────────────────────

      let validity = 365;
      let packageName = "Silver Registration";
      let baseAmount = 5000;

      if (type === 'LIFETIME') {
        validity = 3652; // 10 years
        packageName = "Gold Registration";
        baseAmount = 10000;
      } else {
        // Default YEARLY
        validity = 365;
        packageName = "Silver Registration";
        baseAmount = 5000;
      }

      // Calculate Tax (18%)
      const gstPercent = 18;
      const gstAmount = Math.round((baseAmount * gstPercent) / 100);
      const totalAmount = baseAmount + gstAmount;

      const cgstAmount = gstAmount / 2;
      const sgstAmount = gstAmount / 2;

      let currency = process.env.CURRENCY || "INR";
      let startDate = new Date();
      let endDate = new Date(startDate);
      const receipt = `reg_rcpt_${Date.now()}`;

      endDate.setDate(endDate.getDate() + validity);

      // OFFLINE / BANK TRANSFER FLOW
      if (paymentMode === 'OFFLINE') {
        const userPlan = new planPurchaseModel({
          userId: id,
          packageName: packageName,
          validity: validity,
          startDate: startDate,
          endDate: endDate,
          status: "pending_verification",
          basicAmount: baseAmount,
          cgstAmount: cgstAmount,
          sgstAmount: sgstAmount
        });
        await userPlan.save();

        const payment = await paymentModel.create({
          userId: id,
          packageId: userPlan._id,
          amount: totalAmount,
          status: "created",
          paymentMethod: 'OFFLINE',
          razorpayReceipt: receipt
        });

        return {
          status: 200,
          message: "Registration initiated (Bank Transfer). Please upload proof.",
          data: {
            paymentId: payment._id,
            amount: totalAmount,
            plan: userPlan
          }
        };
      }

      // ONLINE (RAZORPAY) FLOW
      const amountPaise = Math.round(totalAmount * 100);

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

      const userPlan = new planPurchaseModel({
        userId: id,
        packageName: packageName,
        validity: validity,
        startDate: startDate,
        endDate: endDate,
        status: "pending",
        basicAmount: baseAmount,
        cgstAmount: cgstAmount,

        sgstAmount: sgstAmount,
        expiryReminder: false
      });
      await userPlan.save();

      const orderCreate = await paymentModel.create({
        userId: id,
        packageId: userPlan._id,
        razorpayOrderId: order.id,
        razorpayCurrency: currency,
        razorpayReceipt: receipt,
        amount: totalAmount,
        paymentMethod: null
      });

      return {
        status: 200,
        message: "Registration Order created",
        data: { orderCreate, userPlan },
      };

    } catch (error) {
      return { status: 400, message: error.message || error, data: {} };
    }
  },

  recentPaymentList: async ({ body }) => {
    try {
      const aggregationPipeline = [
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
          $project: {
            fullName: "$userData.fullName",
            phone: "$userData.phone",
            packageName: "$packageName",
            packageAmount: "$amount",
            packagestatus: "$status",
            packageStartDate: "$startDate",
            packageEndDate: "$endDate",
            createdAt: 1,
            updatedAt: 1,
          }
        },
        { $sort: { createdAt: -1 } },
        { $limit: 5 }

      ];
      const recentPaymentList = await planPurchaseModel.aggregate(aggregationPipeline);
      return {
        status: 200,
        message: "recent payment list",
        data: { recentPaymentList },
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  subcriptionBillingHistory: async ({ params }) => {
    try {
      const { id } = params;

      const histories = await PaymentIntent.find({ userId: id })
        .populate({
          path: 'planId',
          model: 'segmentsPlan',
          select: 'planName'
        })
        .sort({ createdAt: -1 });

      // 10-minute threshold — intents created but never paid within this window are abandoned
      const ABANDON_THRESHOLD_MS = 10 * 60 * 1000;

      const billingHistory = await Promise.all(histories.map(async (doc) => {
        let planName = doc.purchaseType === 'REGISTRATION' ? 'Registration Fee' : 'Plan Purchase';

        if (doc.purchaseType === 'REGISTRATION') {
          if (doc.packageName && !doc.packageName.toLowerCase().includes("registration fee")) {
            planName = doc.packageName;
          } else {
            const isLifetime = doc.baseAmount === 10000 || (doc.originalPlanAmount || 0) >= 11800;
            planName = isLifetime ? 'Gold' : 'Silver';
          }
        } else if (doc.purchaseType === 'PLAN') {
          const baseName = doc.planId?.planName || doc.packageName || 'Plan Purchase';
          if (doc.preferredSegmentId) {
            const segment = await segmentsModel.findById(doc.preferredSegmentId).select('segmentName');
            planName = segment ? `${segment.segmentName} - ${baseName}` : baseName;
          } else {
            planName = baseName;
          }
        }

        // --- Effective Status: treat stale blank CREATED intents as FAILED at read-time ---
        // This provides an immediate UX fix while the cron persists the change to the DB.
        const isAbandoned =
          doc.status === 'CREATED' &&
          (!doc.amountPaid || doc.amountPaid === 0) &&
          (Date.now() - new Date(doc.createdAt).getTime()) > ABANDON_THRESHOLD_MS;
        const effectiveStatus = isAbandoned ? 'FAILED' : doc.status;

        // Logic for invoice availability: Paid, or partial with at least one approved payment
        const hasApprovedPayments = (doc.partialPaymentsHistory || []).some(p => p.status === 'APPROVED');
        const isInvoiceAvailable = effectiveStatus === 'PAID' || (doc.isPartial && hasApprovedPayments);

        let invoiceId = null;
        if (isInvoiceAvailable) {
          const inv = await invoiceModel.findOne({
            userId: id,
            $or: [
              { paymentRefId: doc._id.toString() },
              { paymentRefId: doc.razorpayOrderId }
            ]
          }).select('_id');
          if (inv) invoiceId = inv._id;
        }

        return {
          id: doc._id,
          planName: planName,
          purchaseDate: doc.createdAt,
          amountPaid: doc.amountPaid || 0,
          baseAmountPaid: Math.round((doc.amountPaid || 0) / (1 + (doc.gstRateUsed || 18) / 100) * 100) / 100,
          gstAmountPaid: Math.round(((doc.amountPaid || 0) - ((doc.amountPaid || 0) / (1 + (doc.gstRateUsed || 18) / 100))) * 100) / 100,
          totalAmount: (doc.totalAmount != null && doc.totalAmount > 0) ? doc.totalAmount : (doc.partialTotalTarget || 0),
          baseTotalAmount: Math.round(((doc.totalAmount != null && doc.totalAmount > 0) ? doc.totalAmount : (doc.partialTotalTarget || 0)) / (1 + (doc.gstRateUsed || 18) / 100) * 100) / 100,
          gstTotalAmount: Math.round((((doc.totalAmount != null && doc.totalAmount > 0) ? doc.totalAmount : (doc.partialTotalTarget || 0)) - (((doc.totalAmount != null && doc.totalAmount > 0) ? doc.totalAmount : (doc.partialTotalTarget || 0)) / (1 + (doc.gstRateUsed || 18) / 100))) * 100) / 100,
          totalAgreedAmount: doc.isPartial ? (doc.partialTotalTarget || doc.totalAmount) : doc.totalAmount,
          remainingAmount: (doc.totalAmount != null && doc.totalAmount > 0) ? Math.max(0, doc.totalAmount - (doc.amountPaid || 0)) : (doc.remainingAmount || 0),
          status: effectiveStatus,
          isPartial: doc.isPartial,
          isInvoiceAvailable: isInvoiceAvailable && !!invoiceId,
          invoiceId: invoiceId,
          paymentMethod: doc.paymentMethod,
          razorpayOrderId: doc.razorpayOrderId
        };
      }));

      return {
        status: 200,
        message: "Billing History Fetched",
        data: { billingHistory }
      };
    } catch (error) {
      console.error("Error in subcriptionBillingHistory:", error);
      return { status: 400, message: error.message, data: {} };
    }
  },

  adminDeletePlan: async ({ params }) => {
    // ... (if needed, but skipping to just add uploadPaymentProof)
    return { status: 400, message: "Not implemented", data: {} };
  }, // Placeholder to ensure comma
  uploadPaymentProof: async ({ body, files }) => {
    try {
      const { paymentId } = body;
      if (!paymentId) return { status: 400, message: "Payment ID required", data: {} };
      if (!files || files.length === 0) return { status: 400, message: "Proof image required", data: {} };

      // Construct URL - Logic depends on how files are served. 
      // Assuming 'uploads/' is static folder.
      // We use full URL if possible, or relative.
      const imageUrls = files.map(file => `uploads/${file.filename}`);

      const payment = await paymentModel.findById(paymentId);
      if (!payment) return { status: 404, message: "Payment not found", data: {} };

      payment.proofImage = imageUrls[0]; // Backward compatibility
      payment.proofImages = imageUrls;
      payment.paymentMethod = 'OFFLINE'; // Enforce offline
      payment.status = "pending_verification";
      await payment.save();

      return { status: 200, message: "Proof uploaded successfully. Waiting for Verification.", data: { payment } };
    } catch (e) {
      return { status: 400, message: e.message, data: {} };
    }
  }
};
export default planPurchaseService;
