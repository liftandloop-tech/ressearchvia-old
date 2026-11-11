import mongoose from "mongoose";

const branchSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true,
        unique: true
    },
    code: {
        type: String,
        trim: true,
        uppercase: true,
        default: null
    },
    city: {
        type: String,
        trim: true,
        default: null
    },
    state: {
        type: String,
        trim: true,
        default: "Madhya Pradesh"
    },
    address: {
        type: String,
        trim: true,
        default: null
    },
    pincode: {
        type: String,
        trim: true,
        default: null
    },
    isActive: {
        type: Boolean,
        default: true
    },
    companyId: {
        type: String,
        default: "default_company"
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "staff",
        default: null
    }
}, { timestamps: true });

branchSchema.index({ isActive: 1 });

const branchModel = mongoose.model("Branch", branchSchema);
export default branchModel;
