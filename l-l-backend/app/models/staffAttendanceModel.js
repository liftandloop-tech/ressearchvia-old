import mongoose from "mongoose";

const staffAttendanceSchema = new mongoose.Schema({
    staffId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'staff',
        required: true
    },
    loginTime: {
        type: Date,
        required: true
    },
    logoutTime: {
        type: Date,
        default: null
    },
    totalWorkingMinutes: {
        type: Number,
        default: 0
    },
    isRemote: {
        type: Boolean,
        default: false
    },
    deviceInfo: {
        type: String,
        default: null
    },
    activityLogs: [{
        timestamp: {
            type: Date,
            default: Date.now
        },
        faceDetected: {
            type: Boolean,
            required: true
        }
    }]
}, { timestamps: true, versionKey: false });

const staffAttendanceModel = mongoose.model("staffAttendance", staffAttendanceSchema);
export default staffAttendanceModel;
