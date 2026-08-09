import mongoose from "mongoose";

const segmentsPlansSchema = new mongoose.Schema({
    planName: {
        type: String,
        require: true
    },
    duration: {
        type: String,
        require: true
    },
    day: {
        type: String,
        require: true
    },
    price: {
        type: Number,
        require: true
    },
    perDayCharge: {
        type: Number,
        require: true
    },
    planStatus: {
        type: String,
        enum: ["active", "inactive"],
        default: "active"
    },
    discription: {
        type: String,
        require: true
    },
    planFeatures: {
        type: String,
        require: true
    },
    isHni: {
        type: Boolean,
        default: false
    }
}, { timestamps: true, versionKey: false });
const segmentsPlanModel = mongoose.model("segmentsPlan", segmentsPlansSchema);
export default segmentsPlanModel;