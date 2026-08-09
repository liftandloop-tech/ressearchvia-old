import mongoose from "mongoose";

const fileSchema = new mongoose.Schema({
    filesObj: {
        type: Object,
        require: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId
    }

}, { timestamps: true, versionKey: false });
const files = mongoose.model("files", fileSchema);
export default files;