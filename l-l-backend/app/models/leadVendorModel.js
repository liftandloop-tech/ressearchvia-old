import mongoose from "mongoose";

const leadVendorSchema = new mongoose.Schema({
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
    code: {
        type: String,
        trim: true,
        default: ""
    },
    contactPerson: {
        type: String,
        default: ""
    },
    mobile: {
        type: String,
        default: ""
    },
    email: {
        type: String,
        default: ""
    },
    costPerLead: {
        type: Number,
        default: 0
    },
    isActive: {
        type: Boolean,
        default: true
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "staff",
        default: null
    }
}, { timestamps: true, versionKey: false });

leadVendorSchema.index({ companyId: 1, name: 1 }, { unique: true });

const leadVendorModel = mongoose.model("leadVendor", leadVendorSchema);
export default leadVendorModel;

