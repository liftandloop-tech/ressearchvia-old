import mongoose from "mongoose";

const segmentsPaymentSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        require: true
    },
    segmentId: {
        type: mongoose.Schema.Types.ObjectId,
        require: true,
        ref: "segments"
    },
    segmentPlanId: {
        type: mongoose.Schema.Types.ObjectId,
        require: true,
        ref: "segmentsPlan"
    },
    razorpayOrderId: {
        type: String,
    },
    razorpayPaymentId: {
        type: String
    },
    razorpaySignature: {
        type: String,
    },
    razorpayReceipt: {
        type: String,
    },
    amount: {
        type: Number,
    },
    gstAmount: {
        type: Number,
    },
    razorpayCurrency: {
        type: String
    },
    paymentStatus: {
        type: String,
        enum: ["created", "paid", "failed", "refunded", "pending", "suspended"],
        default: "created",
    },

    paymentMethod: {
        type: String,
    },
    purchaseDate: {
        type: Date,
    },
    expiryDate: {
        type: Date,
    },
    paymentProof: {
        type: String,
        default: null
    }

}, { timestamps: true, versionKey: false });

const segmentsPayment = mongoose.model("segmentsPayment", segmentsPaymentSchema);
export default segmentsPayment;