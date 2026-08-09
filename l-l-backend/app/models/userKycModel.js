import mongoose from "mongoose";

const userKycSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            required: true,
            ref: "users",
            unique: true
        },
        digioObject: {
            type: Object,
            require: true
        },
        kycStatus: {
            type: String,
            enum: ["pending", "verified", "rejected", "failed"],
            default: "pending",
        },
        webhookHistory: {
            type: [Object],
            default: []
        }
    },
    { timestamps: true, versionKey: false }
);

const userKycModel = mongoose.model("userKyc", userKycSchema);

export default userKycModel;

