import mongoose from "mongoose";

const segmentsPlansSchema = new mongoose.Schema({
    planName: {
        type: String,
        required: true
    },
    duration: {
        type: String,
        default: "30"
    },
    day: {
        type: String,
        default: "days"
    },
    price: {
        type: Number,
        required: true
    },
    perDayCharge: {
        type: Number,
        default: 0
    },
    planStatus: {
        type: String,
        enum: ["active", "inactive"],
        default: "active"
    },
    discription: {
        type: String,
        default: ""
    },
    planFeatures: {
        type: String,
        default: ""
    },
    isHni: {
        type: Boolean,
        default: false
    }
}, { timestamps: true, versionKey: false });
const segmentsPlanModel = mongoose.model("segmentsPlan", segmentsPlansSchema);
export default segmentsPlanModel;