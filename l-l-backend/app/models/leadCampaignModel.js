import mongoose from "mongoose";

const leadCampaignSchema = new mongoose.Schema({
    companyId: {
        type: String,
        default: "default_company",
        index: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    description: {
        type: String,
        default: ""
    },
    isActive: {
        type: Boolean,
        default: true
    },
    startDate: {
        type: Date,
        default: null
    },
    endDate: {
        type: Date,
        default: null
    },
    budget: {
        type: Number,
        default: 0
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "staff",
        default: null
    }
}, { timestamps: true, versionKey: false });

leadCampaignSchema.index({ companyId: 1, name: 1 }, { unique: true });

const leadCampaignModel = mongoose.model("leadCampaign", leadCampaignSchema);
export default leadCampaignModel;

