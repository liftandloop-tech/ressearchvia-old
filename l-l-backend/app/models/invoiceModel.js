import mongoose from "mongoose";

const invoiceSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        require: true,
        ref: "users"
    },
    segmentId: {
        type: mongoose.Schema.Types.ObjectId,
        require: true,
        ref: "segments"
    },
    userActiveSegmentsId: {
        type: mongoose.Schema.Types.ObjectId,
        require: true,
        ref: "userActiveSegment"
    },
    invoiceNumber: {
        type: String,
        require: true
    },
    paymentMode: {
        type: String,
        require: true
    },
    amount: {
        type: Number,
        require: true
    },
    gstAmount: {
        type: Number,
        require: true
    },
    paymentRefId: {
        type: String,
        require: true
    },
    generatedBy: {
        type: String,
        require: true
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