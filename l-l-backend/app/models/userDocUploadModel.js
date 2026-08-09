import mongoose from "mongoose";

const userDocUploadSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            required: true,
        },
        pancard: {
            panNumber: { type: String },
            fileOriginalName: { type: String },
            fileName: { type: String },
            filePath: { type: String },
        },
        aadhaar: {
            aadhaarNumber: { type: String },
            front: {
                fileOriginalName: { type: String },
                fileName: { type: String },
                filePath: { type: String },
            },
            back: {
                fileOriginalName: { type: String },
                fileName: { type: String },
                filePath: { type: String },
            }
        },
    },
    { timestamps: true, versionKey: false }
);

const userDocUploadModel = mongoose.model("userDocumentUpload", userDocUploadSchema);

export default userDocUploadModel;