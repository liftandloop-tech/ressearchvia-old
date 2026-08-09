import mongoose from "mongoose";

const deviceSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'users',
        default: null
    },
    deviceId: {
        type: String,
        required: true
    },
    platform: {
        type: String,
        enum: ['android', 'ios'],
        required: true
    },
    pushToken: {
        type: String,
        required: true
    },
    isActive: {
        type: Boolean,
        default: true
    },
    lastSeenAt: {
        type: Date,
        default: Date.now
    }
}, { timestamps: true, versionKey: false });

// Ensure unique combination of deviceId and platform
deviceSchema.index({ deviceId: 1 }, { unique: true });

const devices = mongoose.model("devices", deviceSchema);
export default devices;
