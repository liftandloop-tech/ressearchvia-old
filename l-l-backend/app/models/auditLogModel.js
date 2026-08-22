import mongoose from "mongoose";

const auditLogSchema = new mongoose.Schema({
    actorUserId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Staff",
        required: true
    },
    action: {
        type: String,
        required: true,
        uppercase: true
    },
    resourceType: {
        type: String,
        required: true
    },
    resourceId: {
        type: String,
        default: null
    },
    oldValue: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },
    newValue: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },
    metadata: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    ipAddress: {
        type: String,
        default: null
    },
    userAgent: {
        type: String,
        default: null
    },
    correlationId: {
        type: String,
        default: null
    },
    success: {
        type: Boolean,
        default: true
    }
}, { timestamps: { createdAt: true, updatedAt: false } });

const auditLogModel = mongoose.model("AuditLog", auditLogSchema);
export default auditLogModel;
