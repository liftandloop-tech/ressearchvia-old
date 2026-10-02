import mongoose from "mongoose";

const callLogSchema = new mongoose.Schema({
    leadId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'lead',
        required: true,
        index: true
    },
    staffId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'staff',
        default: null,
        index: true
    },
    provider: {
        type: String,
        default: 'airtel_vonage'
    },
    accountId: {
        type: String,
        default: null
    },
    callId: {
        type: String,
        index: true
    },
    legIds: [{
        type: String
    }],
    from: {
        destination: { type: String, required: true },
        type: {
            type: String,
            enum: ['device', 'extension', 'feature_code', 'pstn'],
            default: 'extension'
        }
    },
    to: {
        destination: { type: String, required: true },
        type: {
            type: String,
            enum: ['device', 'extension', 'pstn', 'feature_code'],
            default: 'pstn'
        }
    },
    type: {
        type: String,
        enum: ['click2dial', 'click2dialme', 'odr', 'default'],
        default: 'click2dial'
    },
    status: {
        type: String,
        enum: ['initiated', 'ringing', 'on-call', 'completed', 'busy', 'failed', 'unanswered', 'cancelled'],
        default: 'initiated',
        index: true
    },
    startedAt: {
        type: Date,
        default: Date.now
    },
    answeredAt: {
        type: Date,
        default: null
    },
    endedAt: {
        type: Date,
        default: null
    },
    durationSeconds: {
        type: Number,
        default: 0
    },
    recordingUrl: {
        type: String,
        default: null
    },
    disposition: {
        type: String,
        default: null
    },
    notes: {
        type: String,
        default: null
    },
    rawResponse: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },
    companyId: {
        type: String,
        default: 'default_company',
        index: true
    }
}, { timestamps: true, versionKey: false });

callLogSchema.index({ createdAt: -1 });

const callLogModel = mongoose.model("callLog", callLogSchema);
export default callLogModel;
