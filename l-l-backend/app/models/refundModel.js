import mongoose from "mongoose";

const refundSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true,
        index: true
    },
    planId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "segmentsPlans",
        default: null
    },
    planName: {
        type: String,
        required: true
    },
    segmentName: {
        type: String,
        default: "-"
    },
    paymentIntentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "payment_intents",
        default: null
    },
    segmentsPaymentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "segments_payment",
        default: null
    },
    originalAmount: {
        type: Number,
        required: true
    },
    refundAmount: {
        type: Number,
        required: true
    },
    deductionAmount: {
        type: Number,
        default: 0
    },
    refundType: {
        type: String,
        enum: ["FULL", "PRORATED", "CUSTOM"],
        default: "FULL"
    },
    reason: {
        type: String,
        required: true
    },
    reasonCategory: {
        type: String,
        enum: [
            "COOLING_PERIOD_CANCELLATION",
            "SERVICE_DISSATISFACTION",
            "DUPLICATE_PAYMENT",
            "TECHNICAL_ISSUE",
            "ACCOUNT_TERMINATION",
            "MUTUAL_AGREEMENT",
            "OTHER"
        ],
        default: "OTHER"
    },
    refundMethod: {
        type: String,
        enum: ["RAZORPAY", "BANK_TRANSFER", "WALLET_CREDIT", "MANUAL"],
        required: true
    },
    status: {
        type: String,
        enum: ["PENDING", "PROCESSED", "FAILED", "REJECTED"],
        default: "PROCESSED"
    },
    gatewayRefundId: {
        type: String,
        default: null
    },
    utrNumber: {
        type: String,
        default: null
    },
    bankDetails: {
        accountHolderName: { type: String, default: null },
        accountNumber: { type: String, default: null },
        ifscCode: { type: String, default: null },
        bankName: { type: String, default: null }
    },
    subscriptionAction: {
        type: String,
        enum: ["REVOKE_IMMEDIATELY", "ADJUST_DATES", "NONE"],
        default: "REVOKE_IMMEDIATELY"
    },
    processedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true
    },
    adminNotes: {
        type: String,
        default: ""
    },
    metadata: {
        type: Object,
        default: {}
    }
}, { timestamps: true, versionKey: false });

refundSchema.index({ userId: 1, createdAt: -1 });

const Refund = mongoose.model("refunds", refundSchema);
export default Refund;
