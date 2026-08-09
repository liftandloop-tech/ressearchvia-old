import mongoose from "mongoose";

const hniRequestSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: "users"
    },
    segmentId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: "segments"
    },
    planId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: "segmentsPlan"
    },
    status: {
        type: String,
        enum: ["PENDING", "APPROVED", "REJECTED"],
        default: "PENDING"
    },
    adminNotes: {
        type: String,
        default: ""
    }
}, { timestamps: true, versionKey: false });

const HniRequest = mongoose.model("HniRequest", hniRequestSchema);
export default HniRequest;
