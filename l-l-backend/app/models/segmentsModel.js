import mongoose from "mongoose";

const segmentsSchema = new mongoose.Schema({
    segmentName: {
        type: String,
        required: true
    },
    segmentDiscription: {
        type: String,
        required: true
    },
    segmentStatus: {
        type: String,
        enum: ["active", "inactive"],
        default: "active"
    }
}, { timestamps: true, versionKey: false });
const segments = mongoose.model("segments", segmentsSchema);
export default segments;