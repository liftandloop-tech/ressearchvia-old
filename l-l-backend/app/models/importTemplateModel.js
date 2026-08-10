import mongoose from "mongoose";

const importTemplateSchema = new mongoose.Schema({
    companyId: { type: String, default: "default_company", index: true },
    name: { type: String, required: true },
    mappings: { type: Map, of: mongoose.Schema.Types.Mixed, required: true }
}, { timestamps: true, versionKey: false });

// Uniqueness scoped to tenant/company
importTemplateSchema.index({ companyId: 1, name: 1 }, { unique: true });

const importTemplateModel = mongoose.model("importTemplate", importTemplateSchema);
export default importTemplateModel;
