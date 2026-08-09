import mongoose from "mongoose";

const leadSchema = new mongoose.Schema({
    fullName: {
        type: String,
        required: true
    },
    mobileNumber: {
        type: String,
        required: true
    },
    emailAddress: {
        type: String,
        default: null
    },
    assignedRM: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'staff',
        default: null
    },
    stage: {
        type: String,
        enum: ['New', 'Contacted', 'Onboarding', 'Converted', 'Rejected'],
        default: 'New'
    },
    personalDetails: {
        city: { type: String, default: null },
        state: { type: String, default: null }
    },
    followUps: [{
        notes: { type: String, required: true },
        followUpDate: { type: Date, required: true },
        createdAt: { type: Date, default: Date.now }
    }]
}, { timestamps: true, versionKey: false });

const leadModel = mongoose.model("lead", leadSchema);
export default leadModel;
