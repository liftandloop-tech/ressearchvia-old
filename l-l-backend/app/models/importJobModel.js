import mongoose from "mongoose";

const importJobSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'staff', required: true },
    companyId: { type: String, default: "default_company", index: true },
    fileName: { type: String, required: true },
    filePath: { type: String, required: true },
    status: {
        type: String,
        enum: ['uploaded', 'mapping_required', 'validating', 'processing', 'completed', 'completed_with_errors', 'failed', 'cancelled'],
        default: 'uploaded'
    },
    totalRows: { type: Number, default: 0 },
    processedRows: { type: Number, default: 0 },
    successfulRows: { type: Number, default: 0 },
    failedRows: { type: Number, default: 0 },
    duplicateRows: { type: Number, default: 0 },
    sheetNames: [String],
    selectedSheet: { type: String, default: null },
    columnPreview: [{
        index: Number, // 1-based index
        letter: String, // A, B, C...
        header: String,
        sampleValues: [String]
    }],
    previewRows: [mongoose.Schema.Types.Mixed],
    mapping: { type: Map, of: mongoose.Schema.Types.Mixed, default: {} },
    errors: [{
        rowNumber: Number,
        errorText: String,
        rawData: mongoose.Schema.Types.Mixed
    }],
    importOptions: {
        duplicateHandling: { type: String, enum: ['skip', 'update', 'create'], default: 'skip' },
        assignedRM: { type: mongoose.Schema.Types.ObjectId, ref: 'staff', default: null },
        stage: { type: String, default: 'New' },
        leadPoolId: { type: mongoose.Schema.Types.ObjectId, ref: 'leadPool', default: null }
    },
    completedAt: { type: Date, default: null }
}, { timestamps: true, versionKey: false, suppressReservedKeysWarning: true });

const importJobModel = mongoose.model("importJob", importJobSchema);
export default importJobModel;
