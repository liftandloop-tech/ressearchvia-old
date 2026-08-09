import mongoose from "mongoose";

const scheduledNotificationSchema = new mongoose.Schema({
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
        type: String,
        default: null
    },
    imageUrl: {
        type: String,
        default: null
    },
    scheduleTime: {
        type: Date,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'sent', 'failed'],
        default: 'pending'
    }
}, { timestamps: true });

const ScheduledNotification = mongoose.model("ScheduledNotification", scheduledNotificationSchema);

export default ScheduledNotification;
