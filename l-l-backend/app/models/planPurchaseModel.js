import mongoose from "mongoose";

const planPurchaseSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true
    },
    packageName: {
        type: String,
        required: true
    },
    validity: {
        type: Number,
        default: 365
    },
    startDate: {
        type: Date,
        default: Date.now
    },
    endDate: {
        type: Date,
        required: true
    },
    status: {
        type: String,
        enum: ['active', 'expired', 'failed', 'pending', 'suspended'],
        default: 'pending'
    },
    basicAmount: {
        type: Number,
        default: 0
    },
    cgstAmount: {
        type: Number,
        default: 0
    },
    sgstAmount: {
        type: Number,
        default: 0
    },
    paymentMethod: {
        type: String,
        default: 'ONLINE'
    },
    expiryReminder: {
        type: Boolean,
        default: true
    },
    isPartial: {
        type: Boolean,
        default: false
    },
    remarks: {
        type: String,
        default: null
    },
    totalPlanAmount: {
        type: Number,
        default: null
    },
    gstAmount: {
        type: Number,
        default: null
    },
    discount: {
        type: Number,
        default: 0
    }
}, { timestamps: true, versionKey: false });

const planPurchaseModel = mongoose.model("planpurchases", planPurchaseSchema);
export default planPurchaseModel;
