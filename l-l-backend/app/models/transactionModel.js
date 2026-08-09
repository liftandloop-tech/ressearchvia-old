import mongoose from "mongoose";

const transactionSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true,
        index: true
    },
    planId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "segmentsPlans", // Nullable for registration or custom plans
        default: null
    },
    customPlanId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "customplans", // Link to HNI Contract if applicable
        default: null
    },
    amount: {
        type: Number,
        required: true // Actual amount of money moved/attempted
    },
    currency: {
        type: String,
        default: "INR"
    },
    source: {
        type: String,
        enum: ["RAZORPAY", "BANK_TRANSFER", "ADMIN_GRANT", "SYSTEM", "WALLET_ADJUSTMENT"],
        required: true
    },
    paymentType: {
        type: String,
        enum: ["FULL", "INSTALLMENT", "REGISTRATION", "TRIAL", "REFUND"],
        required: true
    },
    status: {
        type: String,
        enum: ["INITIATED", "PENDING_PROOF", "VERIFICATION_PENDING", "SUCCESS", "FAILED", "REJECTED", "REFUNDED"],
        default: "INITIATED",
        index: true
    },
    // Idempotency & Provider Reference
    providerReferenceId: {
        type: String,
        unique: true, // Key for idempotency (e.g., Razorpay Payment ID, UTR)
        sparse: true  // Allow nulls for INITIATED transactions that haven't got IDs yet
    },
    razorpayOrderId: {
        type: String, // For matching with Razorpay Orders
        index: true
    },
    // Bank Transfer Specifics
    proofImage: {
        type: String,
        default: null
    },
    utrNumber: {
        type: String,
        default: null
    },
    // Refund Tracking
    parentTransactionId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "transactions",
        default: null
    },
    // Meta & Audit
    metadata: {
        type: Object, // Store raw provider JSON, admin notes, etc.
        default: {}
    },
    verifiedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users", // Admin ID
        default: null
    },
    verifierNote: {
        type: String,
        default: null
    },
    isProcessed: {
        type: Boolean,
        default: false // Safety flag: Has this transaction been applied to subscription?
    }
}, { timestamps: true, versionKey: false });

// Indexes for common queries
transactionSchema.index({ userId: 1, status: 1 });
transactionSchema.index({ createdAt: -1 });

const Transaction = mongoose.model("transactions", transactionSchema);
export default Transaction;
