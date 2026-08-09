import mongoose from "mongoose";

const customPlanSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true,
        index: true
    },
    title: {
        type: String,
        required: true // e.g., "Special HNI Portfolio Plan"
    },
    description: {
        type: String,
        default: ""
    },

    // Contract Details
    totalAmount: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        default: "INR"
    },
    validityDays: {
        type: Number,
        required: true // e.g., 365
    },

    // Relations
    segmentId: {
        type: String,
        default: null
    },
    // If based on an existing plan but modified
    basePlanId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "segmentsPlans",
        default: null
    },

    // Configuration
    paymentModeAllowed: {
        type: String,
        enum: ["RAZORPAY", "BANK_TRANSFER", "BOTH"],
        default: "BOTH"
    },

    // Flow State
    status: {
        type: String,
        enum: ["DRAFT", "SENT", "ACCEPTED", "EXPIRED", "PAID", "REJECTED"],
        default: "DRAFT",
        index: true
    },

    // Internal
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users", // Admin ID
        required: true
    },
    expiresAt: {
        type: Date,
        default: null // Optional expiry for the offer
    }
}, { timestamps: true, versionKey: false });

const CustomPlan = mongoose.model("customplans", customPlanSchema);
export default CustomPlan;
