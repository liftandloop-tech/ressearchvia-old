import mongoose from "mongoose";

const leadTimelineSchema = new mongoose.Schema({
    leadId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "lead",
        required: true,
        index: true
    },
    companyId: {
        type: String,
        default: "default_company",
        index: true
    },
    eventType: {
        type: String,
        enum: [
            'LEAD_CREATED',
            'LEAD_ASSIGNED',
            'STATUS_UPDATED',
            'FOLLOW_UP_ADDED',
            'FOLLOW_UP_UPDATED',
            'SEGMENT_ASSIGNED',
            'FREE_TRIAL_UPDATED',
            'CALL_LOGGED',
            'LEAD_OVERWRITTEN',
            'REMARKS_UPDATED',
            'APP_ONBOARDED',
            'ORPHANED_TRANSFER'
        ],
        required: true
    },
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        default: ""
    },
    metadata: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    performedBy: {
        staffId: { type: mongoose.Schema.Types.ObjectId, ref: "staff", default: null },
        name: { type: String, default: "System" }
    }
}, { timestamps: true, versionKey: false });

leadTimelineSchema.index({ leadId: 1, createdAt: -1 });

const leadTimelineModel = mongoose.model("leadTimeline", leadTimelineSchema);
export default leadTimelineModel;

