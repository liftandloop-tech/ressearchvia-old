import mongoose from "mongoose";

const departmentSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        unique: true,
        trim: true
    },
    code: {
        type: String,
        trim: true,
        default: null
    },
    description: {
        type: String,
        default: null
    },
    assignedPages: {
        type: [String],
        default: []
    },
    isGlobal: {
        type: Boolean,
        default: false
    },
    isActive: {
        type: Boolean,
        default: true
    }
}, { timestamps: true });

const departmentModel = mongoose.model("Department", departmentSchema);
export default departmentModel;
