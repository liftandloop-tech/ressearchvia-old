import mongoose from "mongoose";

const leadPoolSchema = new mongoose.Schema({
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
        default: null
    }
}, { timestamps: true, versionKey: false });

// Compound index to scope uniqueness to company/tenant
leadPoolSchema.index({ companyId: 1, name: 1 }, { unique: true });

const leadPoolModel = mongoose.model("leadPool", leadPoolSchema);
export default leadPoolModel;
