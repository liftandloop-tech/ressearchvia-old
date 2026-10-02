import mongoose from "mongoose";

const segmentsPlansSchema = new mongoose.Schema({
    planName: {
        type: String,
        required: true
    },
    duration: {
        type: String,
        required: true
    },
    day: {
        type: String,
        required: true
    },
    price: {
        type: Number,
        required: true
    },
    perDayCharge: {
        type: Number,
        required: true
    },
    planStatus: {
        type: String,
        enum: ["active", "inactive"],
        default: "active"
    },
    discription: {
        type: String,
        required: true
    },
    planFeatures: {
        type: String,
        required: true
    },
    isHni: {
        type: Boolean,
        default: false
    }
}, { timestamps: true, versionKey: false });
const segmentsPlanModel = mongoose.model("segmentsPlan", segmentsPlansSchema);
export default segmentsPlanModel;