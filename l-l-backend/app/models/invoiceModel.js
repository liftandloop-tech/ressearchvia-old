import mongoose from "mongoose";

const invoiceSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: "users"
    },
    segmentId: {
        type: mongoose.Schema.Types.ObjectId,
        default: null,
        ref: "segments"
    },
    userActiveSegmentsId: {
        type: mongoose.Schema.Types.ObjectId,
        default: null,
        ref: "userActiveSegment"
    },
    invoiceNumber: {
        type: String,
        required: true
    },
    paymentMode: {
        type: String,
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    gstAmount: {
        type: Number,
        required: true
    },
    paymentRefId: {
        type: String,
        required: true
    },
    generatedBy: {
        type: String,
        required: true
    },
    status: {
        type: String,
        enum: ["paid", "failed"],
        default: "failed"
    },
    discount: {
        type: Number,
        default: 0
    }
}, { timestamps: true, versionKey: false });

const invoiceModel = mongoose.model("invoice", invoiceSchema);
export default invoiceModel;