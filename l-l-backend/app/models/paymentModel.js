import mongoose from "mongoose";

const paymentSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        require: true
    },
    packageId: {
        type: mongoose.Schema.Types.ObjectId,
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
    razorpayCurrency: {
        type: String
    },
    paymentMethod: {
        type: String
    },
    proofImage: {
        type: String
    },
    status: {
        type: String,
        enum: ["created", "paid", "failed", "refunded", "pending_verification"],
        default: "created",
    },
    discount: {
        type: Number,
        default: 0
    }
}, { timestamps: true, versionKey: false });

const paymentModel = mongoose.model("Payment", paymentSchema);
export default paymentModel;


