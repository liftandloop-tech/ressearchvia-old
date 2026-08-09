import mongoose from "mongoose";

const paymentIntentSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true
    },
    purchaseType: {
        type: String,
        enum: ["REGISTRATION", "PLAN"],
        required: true
    },
    planId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "segmentsPlan", // Adjust ref if needed
        default: null
    },
    baseAmount: {
        type: Number,
        required: true
    },
    gstAmount: {
        type: Number,
        required: true
    },
    totalAmount: {
        type: Number,
        required: true
    },
    razorpayOrderId: {
        type: String,
        required: true
    },
    paymentId: {
        type: String,
        default: null
    },
    proofImage: {
        type: String,
        default: null
    },
    proofImages: [{
        type: String
    }],
    status: {
        type: String,
        enum: ["CREATED", "PAID", "FAILED", "PENDING_BANK_TRANSFER", "VERIFICATION_PENDING", "PENDING_ADMIN_APPROVAL", "REJECTED"],
        default: "CREATED"
    },
    paymentMethod: {
        type: String,
        enum: ["RAZORPAY", "BANK_TRANSFER", "ADMIN_ENTITLEMENT", "OFFLINE", "MANUAL"],
        default: "RAZORPAY"
    },
    preferredSegmentId: {
        type: String, // Storing ID as string or ObjectId if strictly validated
        default: null
    },
    preferredPlanId: {
        type: String,
        default: null
    },
    transactionDate: {
        type: Date,
        default: null
    },
    utrNumber: {
        type: String,
        default: null
    },
    amountPaid: {
        type: Number,
        default: null
    },
    remainingAmount: {
        type: Number,
        default: 0
    },
    isPartial: {
        type: Boolean,
        default: false
    },
    originalPlanAmount: {
        type: Number,
        default: 0
    },
    originalDuration: {
        type: Number,
        default: 0
    },
    partialTotalTarget: {
        type: Number,
        default: 0
    },
    perDayCharge: {
        type: Number,
        default: 0
    },
    maxAllowedDays: {
        type: Number,
        default: 0
    },
    serviceStartDate: {
        type: Date,
        default: null
    },
    currentExpiryDate: {
        type: Date,
        default: null
    },
    gstRateUsed: {
        type: Number,
        default: 18
    },
    walletBalance: {
        type: Number,
        default: 0
    },
    partialPaymentsHistory: [
        {
            amountPaid: Number,
            transactionDate: { type: Date, default: Date.now },
            proofImage: String,
            proofImages: [{ type: String }],
            utrNumber: String,
            status: {
                type: String,
                enum: ["PENDING", "APPROVED", "REJECTED"],
                default: "PENDING"
            },
            calculatedDaysAdded: { type: Number, default: 0 },
            note: { type: String, default: '' },
            verifiedAt: Date,
            verifiedBy: { type: mongoose.Schema.Types.ObjectId, ref: "staff" }
        }
    ],
    notes: {
        type: String,
        default: ""
    },
    isCorrected: {
        type: Boolean,
        default: false
    },
    discount: {
        type: Number,
        default: 0
    },
    manualDaysAdjustment: {
        type: Number,
        default: 0
    },
    correctionVersion: {
        type: Number,
        default: 0
    },
    correctionHistory: [
        {
            oldAmount: Number,
            newAmount: Number,
            oldMode: Boolean,
            newMode: Boolean,
            oldSegmentName: String,
            newSegmentName: String,
            oldPlanName: String,
            newPlanName: String,
            oldStartDate: Date,
            newStartDate: Date,
            oldExpiry: Date,
            newExpiry: Date,
            reason: String,
            correctedBy: { type: mongoose.Schema.Types.ObjectId, ref: "staff" },
            correctedAt: { type: Date, default: Date.now },
            snapShotBefore: Object,
            snapShotAfter: Object
        }
    ]
}, { timestamps: true, versionKey: false });

paymentIntentSchema.index({ status: 1, createdAt: 1 });
paymentIntentSchema.index({ isPartial: 1, status: 1, currentExpiryDate: 1 });
paymentIntentSchema.index({ userId: 1, status: 1 });

const paymentIntentModel = mongoose.model("PaymentIntent", paymentIntentSchema);
export default paymentIntentModel;
