import mongoose from "mongoose";

const entitlementSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true
    },
    type: {
        type: String,
        enum: ["REGISTRATION", "PLAN"],
        required: true
    },
    resourceId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "segmentsPlan", // CORRECTED Model Name
        default: null
    },
    segmentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "segments",
        default: null
    },
    startDate: {
        type: Date,
        required: true
    },
    endDate: {
        type: Date,
        default: null // null for lifetime
    },
    status: {
        type: String,
        enum: ["ACTIVE", "EXPIRED", "REVOKED", "SUSPENDED"],
        default: "ACTIVE"
    },
    grantedBy: {
        type: String,
        enum: ["SYSTEM", "ADMIN"],
        required: true
    },
    grantReason: {
        type: String,
        enum: ["ONLINE_PAYMENT", "OFFLINE_PAYMENT", "MANUAL", "REGISTRATION_TRIAL", "HNI_CUSTOM_GRANT", "MANUAL_PARTIAL"],
        required: true
    },
    sourceRefId: {
        type: String, // paymentIntentId or adminActionId
        default: null
    },
    remarks: {
        type: String,
        default: ""
    }
}, { timestamps: true, versionKey: false });

// Index for fast lookups
entitlementSchema.index({ userId: 1, type: 1, status: 1 });

const entitlementModel = mongoose.model("Entitlement", entitlementSchema);
export default entitlementModel;
