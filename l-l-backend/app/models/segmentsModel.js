import mongoose from "mongoose";

const segmentsSchema = new mongoose.Schema({
    segmentName: {
        type: String,
        require: true
    },
    segmentDiscription: {
        type: String,
        require: true
    },
    segmentStatus: {
        type: String,
        enum: ["active", "inactive"],
        default: "active"
    }
}, { timestamps: true, versionKey: false });
const segments = mongoose.model("segments", segmentsSchema);
export default segments;