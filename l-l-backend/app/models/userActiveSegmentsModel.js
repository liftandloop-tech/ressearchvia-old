import mongoose from "mongoose";

const userActiveSegmentSchema = new mongoose.Schema({
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
    purchaseDate: {
        type: Date,
        required: true
    },
    expiryDate: {
        type: Date,
        required: true
    },
    isActive: {
        type: Boolean,
        default: false
    },
    assignedRa: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "staff",
        default: null
    },
    isCustomPlan: {
        type: Boolean,
        default: false
    }
}, { timestamps: true, versionKey: false });

const userActiveSegment = mongoose.model("userActiveSegment", userActiveSegmentSchema);
export default userActiveSegment;
