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
        default: null
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
        enum: ['New', 'Contacted', 'Interested', 'Qualified', 'Demo / Meeting Scheduled', 'Demo / Meeting Completed', 'Proposal Sent', 'Negotiation', 'Follow-up', 'Won', 'Lost', 'On Hold', 'Not Interested', 'Invalid'],
        default: 'New'
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
