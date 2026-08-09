import mongoose from "mongoose";

const expiryAlertSettingsSchema = new mongoose.Schema({
    isAutomatedAlertsEnabled: {
        type: Boolean,
        default: true
    },
    alerts: [{
        days: {
            type: Number,
            required: true
        },
        enabled: {
            type: Boolean,
            default: true
        },
        title: {
            type: String,
            default: "Subscription Expiring Soon!"
        },
        body: {
            type: String,
            default: "Your {{planName}} plan expires in {{days}} days. Renew now to continue services."
        }
    }]
}, { timestamps: true, versionKey: false });

const ExpiryAlertSettings = mongoose.model("expiryAlertSettings", expiryAlertSettingsSchema);

export default ExpiryAlertSettings;
