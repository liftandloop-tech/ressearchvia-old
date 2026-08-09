import mongoose from "mongoose";

const reportsSchema = new mongoose.Schema({
    title: {
        type: String,
        require: true
    },
    reportId: {
        type: String,
        default: () => 'REP-' + Math.floor(100000 + Math.random() * 900000),
        unique: true
    },
    segment: [{
        type: mongoose.Schema.Types.ObjectId,
        require: true,
        ref: "segments"
    }],
    segmentName: [{
        type: String,
        require: true
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
        require: true
    },
    description: {
        type: String,
        require: true
    },
    updates: [{
        text: String,
        timestamp: {
            type: Date,
            default: Date.now
        }
    }],
    reportPath: {

        type: String,
        require: true
    },
    reportOriginalName: {
        type: String,
        require: true
    },
    reportName: {
        type: String,
        require: true
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