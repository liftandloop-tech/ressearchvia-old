import mongoose from "mongoose";

const notificationLogSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ['push', 'email'],
        required: true
    },
    title: {
        type: String,
        required: true
    },
    message: {
        type: String,
        required: true
    },
    audience: {
        type: String,
        required: true
    },
    audienceId: {
        type: mongoose.Schema.Types.ObjectId,
        refPath: 'audienceModel',
        default: null
    },
    audienceModel: {
        type: String,
        enum: ['Segment', 'SegmentPlan', null],
        default: null
    },
    recipientCount: {
        type: Number,
        default: 0
    },
    successCount: {
        type: Number,
        default: 0
    },
    failureCount: {
        type: Number,
        default: 0
    },
    status: {
        type: String,
        enum: ['sent', 'partially_failed', 'failed', 'queued', 'processing'],
        default: 'sent'
    },
    details: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    imageUrl: {
        type: String,
        default: null
    },
    sentAt: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true });

const NotificationLog = mongoose.model("NotificationLog", notificationLogSchema);

export default NotificationLog;
