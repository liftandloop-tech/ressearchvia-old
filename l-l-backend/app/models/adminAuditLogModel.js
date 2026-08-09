import mongoose from "mongoose";

const adminAuditLogSchema = new mongoose.Schema({
    adminId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        required: true
    },
    action: {
        type: String,
        required: true,
        enum: ["USER_CREATE", "USER_UPDATE", "PAYMENT_BYPASS", "SUBSCRIPTION_EXTEND", "SUBSCRIPTION_REVOKE", "SUBSCRIPTION_CHANGE", "KYC_UPDATE", "LOGIN", "REPORT_PUBLISH", "SUBSCRIPTION_SUSPEND", "SUBSCRIPTION_ACTIVATE", "SUBSCRIPTION_UPDATE_DATES", "ADMIN_CREATE_PLAN", "ADMIN_CREATE_PLAN_PARTIAL", "PAYMENT_PRE_APPROVAL_EDIT", "HIGH_SENSITIVITY_CORRECTION", "PAYMENT_LEDGER_CORRECTION", "PAYMENT_APPROVAL_REVERTED", "PAYMENT_REJECTION_REVERTED"]
    },
    targetUserId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "users",
        default: null
    },
    entitlementId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Entitlement",
        default: null
    },
    reason: {
        type: String,
        default: ""
    },
    meta: {
        type: Object, // Store snapshot of changes or raw body
        default: {}
    },
    ipAddress: {
        type: String,
        default: "0.0.0.0"
    }


}, { timestamps: true, versionKey: false });

const adminAuditLog = mongoose.model("AdminAuditLog", adminAuditLogSchema);
export default adminAuditLog;
