import mongoose from "mongoose";

const leadSchema = new mongoose.Schema({
    fullName: {
        type: String,
        default: ""
    },
    mobileNumber: {
        type: String,
        required: true
    },
    emailAddress: {
        type: String,
        default: null
    },
    assignedRM: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'staff',
        default: null,
        index: true
    },
    leadPoolId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'leadPool',
        default: null
    },
    companyId: {
        type: String,
        default: "default_company",
        index: true
    },
    isRead: {
        type: Boolean,
        default: false
    },
    stage: {
        type: String,
        enum: ['New', 'App Onboarded', 'Contacted', 'Interested', 'Qualified', 'Demo / Meeting Scheduled', 'Demo / Meeting Completed', 'Proposal Sent', 'Negotiation', 'Follow-up', 'Won', 'Lost', 'On Hold', 'Not Interested', 'Invalid'],
        default: 'New'
    },
    leadSource: {
        type: String,
        enum: ['ORGANIC_APP', 'ORGANIC_WEB', 'ORPHANED_STAFF', 'IMPORTED_POOL', 'MANUAL_ENTRY'],
        default: 'IMPORTED_POOL',
        index: true
    },
    isAppUser: {
        type: Boolean,
        default: false,
        index: true
    },
    appUserId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'user',
        default: null
    },
    appOnboardedAt: {
        type: Date,
        default: null
    },
    previousRM: {
        staffId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'staff',
            default: null
        },
        staffName: {
            type: String,
            default: null
        },
        transferredAt: {
            type: Date,
            default: null
        },
        transferReason: {
            type: String,
            default: null
        }
    },
    personalDetails: {
        city: { type: String, default: null },
        state: { type: String, default: null }
    },
    followUps: [{
        notes: { type: String, required: true },
        followUpDate: { type: Date, required: true },
        followUpType: {
            type: String,
            enum: [
                'Call', 'WhatsApp', 'SMS', 'Email', 'Video Call', 'Schedule Meeting',
                'Send Brochure', 'Send Pricing', 'Send Proposal', 'Send Demo',
                'Product Demo', 'Site Visit', 'Payment Follow-up', 'Document Follow-up',
                'Contract Follow-up', 'Check Customer Requirement', 'Manager Follow-up',
                'Renewal Follow-up', 'No Follow-up Required'
            ],
            default: 'Call'
        },
        status: {
            type: String,
            enum: ['Pending', 'Completed', 'Rescheduled', 'Cancelled', 'Skipped'],
            default: 'Pending'
        },
        nextFollowUpDate: { type: Date, default: null },
        createdAt: { type: Date, default: Date.now }
    }]
}, { timestamps: true, versionKey: false });

const leadModel = mongoose.model("lead", leadSchema);
export default leadModel;
