import mongoose from "mongoose";

const userSubscriptionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true
    },
    type: {
        type: String,
        enum: ["REGISTRATION", "PLAN"],
        required: true
    },
    // Current Active Plan Details (if type === PLAN)
    planId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "segmentsPlans",
        default: null
    },
    customPlanId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "customplans",
        default: null
    },
    segmentId: {
        type: String, // Or ObjectId depending on your segment architecture
        default: null
    },

    // Access State
    status: {
        type: String,
        enum: ["ACTIVE", "PARTIAL", "EXPIRED", "SUSPENDED"],
        default: "PARTIAL",
        index: true
    },

    // Validity Period
    validFrom: {
        type: Date,
        default: null
    },
    validTill: {
        type: Date,
        default: null
    },

    // Financial State (The Contract Progress)
    totalPlanCost: {
        type: Number,
        required: true,
        default: 0
    },
    amountPaidSoFar: {
        type: Number,
        default: 0
    },

    // Flags
    isLifetime: {
        type: Boolean,
        default: false
    },

    // Audit Trace
    lastTransactionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "transactions",
        default: null
    }
}, { timestamps: true, versionKey: false });

// Ensure one active subscription type per user (Compound Index)
// Note: We might allow multiple plans later, but usually one 'REGISTRATION' and one 'PLAN' slot is standard.
// If user can have multiple DIFFERENT plans active, we remove 'unique: true' from this index.
// Based on current requirements, a user typically has one active plan focus. 
// However, to be safe for future (Multiple Segments), we will NOT make it unique, but index it for speed.
userSubscriptionSchema.index({ userId: 1, type: 1 }); // Fast lookup
userSubscriptionSchema.index({ status: 1 });

const UserSubscription = mongoose.model("usersubscriptions", userSubscriptionSchema);
export default UserSubscription;
