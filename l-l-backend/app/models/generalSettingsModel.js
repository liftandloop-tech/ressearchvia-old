import mongoose from "mongoose";

const generalSettingsSchema = new mongoose.Schema({
    key: {
        type: String,
        required: true,
        unique: true
    },
    value: {
        type: mongoose.Schema.Types.Mixed, // Allows storing any JSON object/structure
        required: true
    }
}, { timestamps: true });

const GeneralSettings = mongoose.model("generalSettings", generalSettingsSchema);

export default GeneralSettings;
