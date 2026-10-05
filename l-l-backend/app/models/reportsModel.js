import mongoose from "mongoose";

const reportsSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    reportId: {
        type: String,
        default: () => 'REP-' + Math.floor(100000 + Math.random() * 900000),
        unique: true
    },
    segment: [{
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: "segments"
    }],
    segmentName: [{
        type: String,
        required: true
    }],
    // Chunk 9: Publishing Metadata
    published_by: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'users',
        default: null
    },
    published_at: {
        type: Date,
        default: Date.now
    },
    planArray: [
        {
            type: mongoose.Schema.Types.ObjectId,
            ref: "segmentsplans",
            required: true
        }
    ],
    reportType: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    updates: [{
        text: String,
        status: {
            type: String,
            default: null
        },
        timestamp: {
            type: Date,
            default: Date.now
        }
    }],
    reportPath: {
        type: String,
        required: function () {
            const type = (this.reportType || '').toLowerCase();
            return !type.includes('trading');
        },
        default: ""
    },
    reportOriginalName: {
        type: String,
        required: function () {
            const type = (this.reportType || '').toLowerCase();
            return !type.includes('trading');
        },
        default: ""
    },
    reportName: {
        type: String,
        required: function () {
            const type = (this.reportType || '').toLowerCase();
            return !type.includes('trading');
        },
        default: ""
    },
    publishedStatus: {
        type: String,
        enum: ["published", "draft"],
        default: "published"
    },
    youtubeUrl: {
        type: String,
        default: null
    },
    automatedSignalId: {
        type: String,
        default: null,
        index: true
    }


}, { timestamps: true, versionKey: false });
const reports = mongoose.model("reports", reportsSchema);
export default reports;