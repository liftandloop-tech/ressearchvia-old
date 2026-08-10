import mongoose from "mongoose";

const roleSchema = new mongoose.Schema({
    name: { type: String, required: true, unique: true },
    description: { type: String, default: null },
    permissionGroups: [{ type: mongoose.Schema.Types.ObjectId, ref: 'PermissionGroup' }]
}, { timestamps: true });

const roleModel = mongoose.model("Role", roleSchema);
export default roleModel;
