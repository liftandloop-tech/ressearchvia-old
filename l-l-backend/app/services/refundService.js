import mongoose from "mongoose";
import Refund from "../models/refundModel.js";
import Transaction from "../models/transactionModel.js";
import userModel from "../models/userModel.js";
import paymentIntentModel from "../models/paymentIntentModel.js";
import segmentsPaymentModel from "../models/segmentsPaymentModel.js";
import planPurchaseModel from "../models/planPurchaseModel.js";
import userActiveSegmentModel from "../models/userActiveSegmentsModel.js";
import Entitlement from "../models/entitlementModel.js";
import walletLedgerModel from "../models/walletLedgerModel.js";
import AdminAuditLog from "../models/adminAuditLogModel.js";
import { getRazorpay } from "./razorpayClient.js";

const refundService = {
    /**
     * Preview refund calculation based on plan tenure and utilized days
     */
    previewRefundCalculation: async ({ body }) => {
        try {
            const { userId, planId, paymentIntentId, originalAmount, startDate, endDate } = body;

            const amount = Number(originalAmount) || 0;
            if (amount <= 0) {
                return { status: 400, message: "Original amount must be greater than 0", data: {} };
            }

            let start = startDate ? new Date(startDate) : null;
            let end = endDate ? new Date(endDate) : null;

            // Fallback: Check PaymentIntent if dates not provided
            if ((!start || !end) && paymentIntentId) {
                const intent = await paymentIntentModel.findById(paymentIntentId);
                if (intent) {
                    start = start || intent.serviceStartDate || intent.createdAt;
                    end = end || intent.currentExpiryDate;
                }
            }

            // Fallback: Check active plan purchase
            if ((!start || !end) && userId) {
                const query = planId ? { userId, planId, status: 'active' } : { userId, status: 'active' };
                const planPurchase = await planPurchaseModel.findOne(query).sort({ createdAt: -1 });
                if (planPurchase) {
                    start = start || planPurchase.startDate;
                    end = end || planPurchase.endDate;
                }
            }

            const now = new Date();
            let totalDays = 30; // default standard month
            let daysUsed = 0;
            let daysRemaining = 30;

            if (start && end) {
                const diffTotalMs = Math.max(0, new Date(end) - new Date(start));
                totalDays = Math.max(1, Math.ceil(diffTotalMs / (1000 * 60 * 60 * 24)));

                const diffUsedMs = Math.max(0, now - new Date(start));
                daysUsed = Math.min(totalDays, Math.ceil(diffUsedMs / (1000 * 60 * 60 * 24)));
                daysRemaining = Math.max(0, totalDays - daysUsed);
            }

            const perDayCost = totalDays > 0 ? (amount / totalDays) : 0;
            const suggestedProratedAmount = Math.max(0, Math.round(perDayCost * daysRemaining));
            const usedServiceAmount = Math.max(0, amount - suggestedProratedAmount);

            const totalMonths = totalDays >= 30 ? Math.round(totalDays / 30) : (totalDays / 30);
            const monthsUsed = Math.min(totalMonths, Math.max(0, Math.round(daysUsed / 30)));
            const monthsRemaining = Math.max(0, totalMonths - monthsUsed);

            return {
                status: 200,
                message: "Refund calculation preview generated",
                data: {
                    originalAmount: amount,
                    totalDays,
                    daysUsed,
                    daysRemaining,
                    totalMonths,
                    monthsUsed,
                    monthsRemaining,
                    perDayCost: Number(perDayCost.toFixed(2)),
                    usedServiceAmount,
                    suggestedFullRefund: amount,
                    suggestedProratedRefund: suggestedProratedAmount,
                    startDate: start,
                    endDate: end
                }
            };
        } catch (error) {
            console.error("[previewRefundCalculation] Error:", error);
            return { status: 500, message: error.message, data: {} };
        }
    },

    /**
     * Process & Record User Refund (Strict Admin Only)
     */
    processRefund: async ({ body, adminUser }) => {
        try {
            const {
                userId,
                planId,
                planName,
                segmentName,
                paymentIntentId,
                segmentsPaymentId,
                originalAmount,
                refundAmount,
                deductionAmount = 0,
                refundType = "FULL",
                reason,
                reasonCategory = "OTHER",
                refundMethod = "MANUAL",
                bankDetails = {},
                utrNumber = null,
                subscriptionAction = "REVOKE_IMMEDIATELY",
                adminNotes = ""
            } = body;

            // 1. Mandatory Validations
            if (!userId) {
                return { status: 400, message: "User ID is required", data: {} };
            }

            if (!reason || reason.trim().length === 0) {
                return { status: 400, message: "Reason for refund is mandatory", data: {} };
            }

            if (!planName || planName.trim().length === 0) {
                return { status: 400, message: "User Plan name is required", data: {} };
            }

            const parsedOriginalAmount = Number(originalAmount);
            const parsedRefundAmount = Number(refundAmount);
            const parsedDeduction = Number(deductionAmount) || 0;

            if (isNaN(parsedOriginalAmount) || parsedOriginalAmount <= 0) {
                return { status: 400, message: "Valid original amount is required", data: {} };
            }

            if (isNaN(parsedRefundAmount) || parsedRefundAmount <= 0) {
                return { status: 400, message: "Refund amount must be greater than 0", data: {} };
            }

            if (parsedRefundAmount > parsedOriginalAmount) {
                return { status: 400, message: "Refund amount cannot exceed original paid amount", data: {} };
            }

            const targetUser = await userModel.findById(userId);
            if (!targetUser) {
                return { status: 404, message: "User not found", data: {} };
            }

            const adminId = adminUser?._id || adminUser?.id;
            if (!adminId) {
                return { status: 403, message: "Admin context missing or unauthorized", data: {} };
            }

            let gatewayRefundId = null;

            // 2. Gateway API Refund Execution (Razorpay)
            if (refundMethod === "RAZORPAY") {
                let razorpayPaymentId = null;

                if (paymentIntentId) {
                    const intent = await paymentIntentModel.findById(paymentIntentId);
                    if (intent && intent.razorpayPaymentId) {
                        razorpayPaymentId = intent.razorpayPaymentId;
                    }
                }

                if (!razorpayPaymentId && segmentsPaymentId) {
                    const segPay = await segmentsPaymentModel.findById(segmentsPaymentId);
                    if (segPay && segPay.razorpayPaymentId) {
                        razorpayPaymentId = segPay.razorpayPaymentId;
                    }
                }

                if (razorpayPaymentId) {
                    try {
                        const razorpay = getRazorpay();
                        if (razorpay && razorpay.payments && razorpay.payments.refund) {
                            const refundResponse = await razorpay.payments.refund(razorpayPaymentId, {
                                amount: Math.round(parsedRefundAmount * 100), // convert to paise
                                notes: {
                                    reason: reason.substring(0, 100),
                                    refundType,
                                    adminId: adminId.toString()
                                }
                            });
                            gatewayRefundId = refundResponse?.id || "RAZORPAY_REFUND_SUCCESS";
                        }
                    } catch (rpErr) {
                        console.error("[Razorpay API Refund Error]:", rpErr.message);
                        // If direct gateway refund fails, record it but allow admin to proceed as offline/manual
                        gatewayRefundId = `RP_FAILED_${Date.now()}`;
                    }
                }
            }

            // 3. Wallet Credit Alternative
            if (refundMethod === "WALLET_CREDIT") {
                targetUser.wallet_balance = (Number(targetUser.wallet_balance) || 0) + parsedRefundAmount;
                await targetUser.save();

                await walletLedgerModel.create({
                    userId: targetUser._id,
                    amount: parsedRefundAmount,
                    balanceAfter: targetUser.wallet_balance,
                    type: "CREDIT",
                    transactionType: "REFUND",
                    description: `Refund credited to wallet for plan: ${planName}. Reason: ${reason}`,
                    referenceId: adminId.toString()
                });
            }

            // 4. Subscription & Entitlement Action
            if (subscriptionAction === "REVOKE_IMMEDIATELY") {
                // A. Revoke Entitlements
                const entitlementQuery = { userId: targetUser._id, status: "ACTIVE" };
                if (planId) {
                    entitlementQuery.$or = [
                        { resourceId: planId },
                        { _id: planId }
                    ];
                }
                await Entitlement.updateMany(
                    entitlementQuery,
                    {
                        $set: {
                            status: "REVOKED",
                            revokedReason: `ADMIN_REFUND: ${reason}`,
                            revokedAt: new Date()
                        }
                    }
                );

                // B. Revoke Plan Purchases
                const planPurchaseQuery = { userId: targetUser._id, status: "active" };
                if (planId) {
                    planPurchaseQuery.$or = [
                        { planId: planId },
                        { _id: planId }
                    ];
                }
                await planPurchaseModel.updateMany(
                    planPurchaseQuery,
                    {
                        $set: {
                            status: "revoked",
                            updatedAt: new Date()
                        }
                    }
                );

                // C. Deactivate legacy active segments if matching
                const segQuery = { userId: targetUser._id, isActive: true };
                if (planId) {
                    segQuery.planId = planId;
                }
                await userActiveSegmentModel.updateMany(
                    segQuery,
                    { $set: { isActive: false } }
                );
            }

            // 5. Update Underlying Payment Records
            if (paymentIntentId) {
                await paymentIntentModel.findByIdAndUpdate(paymentIntentId, {
                    $set: {
                        status: "refunded",
                        notes: `REFUNDED: ₹${parsedRefundAmount} on ${new Date().toISOString()}. Reason: ${reason}`
                    }
                });
            }

            if (segmentsPaymentId) {
                await segmentsPaymentModel.findByIdAndUpdate(segmentsPaymentId, {
                    $set: {
                        paymentStatus: "refunded"
                    }
                });
            }

            // 6. Create Immutable Transaction Record
            const transactionRecord = await Transaction.create({
                userId: targetUser._id,
                planId: planId || null,
                amount: parsedRefundAmount,
                currency: "INR",
                source: refundMethod === "RAZORPAY" ? "RAZORPAY" : (refundMethod === "WALLET_CREDIT" ? "WALLET_ADJUSTMENT" : "BANK_TRANSFER"),
                paymentType: "REFUND",
                status: "REFUNDED",
                utrNumber: utrNumber || null,
                providerReferenceId: gatewayRefundId || (utrNumber ? `REF_${utrNumber}` : `REF_${Date.now()}`),
                verifiedBy: adminId,
                verifierNote: reason,
                isProcessed: true,
                metadata: {
                    originalAmount: parsedOriginalAmount,
                    deductionAmount: parsedDeduction,
                    refundType,
                    reasonCategory,
                    subscriptionAction,
                    adminNotes
                }
            });

            // 7. Save Refund Document
            const refundRecord = await Refund.create({
                userId: targetUser._id,
                planId: planId || null,
                planName: planName.trim(),
                segmentName: segmentName || "-",
                paymentIntentId: paymentIntentId || null,
                segmentsPaymentId: segmentsPaymentId || null,
                originalAmount: parsedOriginalAmount,
                refundAmount: parsedRefundAmount,
                deductionAmount: parsedDeduction,
                refundType,
                reason: reason.trim(),
                reasonCategory,
                refundMethod,
                status: "PROCESSED",
                gatewayRefundId,
                utrNumber: utrNumber || null,
                bankDetails: bankDetails || {},
                subscriptionAction,
                processedBy: adminId,
                adminNotes: adminNotes || "",
                metadata: {
                    transactionId: transactionRecord._id
                }
            });

            // 8. Admin Audit Trail
            await AdminAuditLog.create({
                adminId,
                action: "USER_REFUND_PROCESSED",
                targetUserId: targetUser._id,
                reason: `Refund of ₹${parsedRefundAmount} for plan ${planName}. Reason: ${reason}`,
                meta: {
                    refundId: refundRecord._id,
                    refundAmount: parsedRefundAmount,
                    originalAmount: parsedOriginalAmount,
                    refundMethod,
                    subscriptionAction
                }
            });

            return {
                status: 200,
                message: `Refund of ₹${parsedRefundAmount} processed successfully for ${planName}`,
                data: {
                    refund: refundRecord,
                    transaction: transactionRecord
                }
            };

        } catch (error) {
            console.error("[processRefund] Error:", error);
            return { status: 500, message: error.message || "Failed to process refund", data: {} };
        }
    },

    /**
     * Get list of refunds for a specific user
     */
    getUserRefundHistory: async ({ params }) => {
        try {
            const { userId } = params;
            if (!userId) {
                return { status: 400, message: "User ID is required", data: {} };
            }

            const refunds = await Refund.find({ userId })
                .populate("processedBy", "fullName email role userType")
                .sort({ createdAt: -1 })
                .lean();

            return {
                status: 200,
                message: "User refund history retrieved successfully",
                data: { refunds }
            };
        } catch (error) {
            console.error("[getUserRefundHistory] Error:", error);
            return { status: 500, message: error.message, data: {} };
        }
    }
};

export default refundService;
