import mongoose from "mongoose";

const walletLedgerSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true
    },
    amount: {
        type: Number,
        required: true // Positive for credit, negative for debit
    },
    balanceAfter: {
        type: Number,
        required: true
    },
    type: {
        type: String,
        enum: ["CREDIT", "DEBIT"],
        required: true
    },
    transactionType: {
        type: String,
        enum: ["ADMIN_MANUAL", "REFUND", "PURCHASE", "BONUS"],
        required: true
    },
    description: {
        type: String,
        default: ""
    },
    referenceId: {
        type: String, // paymentId or adminId
        default: null
    }
}, { timestamps: true, versionKey: false });

const walletLedgerModel = mongoose.model("WalletLedger", walletLedgerSchema);
export default walletLedgerModel;
