import mongoose from "mongoose";

const roleSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true },
    code: { type: String, trim: true, default: null },
    level: { type: Number, default: 1 },
    description: { type: String, default: null },
    departmentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Department', default: null },
    permissionGroups: [{ type: mongoose.Schema.Types.ObjectId, ref: 'PermissionGroup' }],
    isActive: { type: Boolean, default: true }
}, { timestamps: true });

const roleModel = mongoose.model("Role", roleSchema);
export default roleModel;
