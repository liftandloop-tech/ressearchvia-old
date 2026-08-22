import mongoose from "mongoose";

const permissionSchema = new mongoose.Schema({
    feature: {
        type: String,
        required: true
    },
    actions: {
        type: [String],
        default: []
    }
}, { _id: false });

const permissionGroupSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true },
    description: { type: String, default: null },
    permissions: [permissionSchema]
}, { timestamps: true });

const permissionGroupModel = mongoose.model("PermissionGroup", permissionGroupSchema);
export default permissionGroupModel;
