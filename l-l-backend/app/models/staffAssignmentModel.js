import mongoose from "mongoose";

const staffAssignmentSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: "users"

    },
    staffId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref:"staffs"
    },
    staffName:{
        type:String,
        required: true
    }
}, { timestamps: true, versionKey: false });
const staffAssigmentModel = mongoose.model("staffAssigment", staffAssignmentSchema);
export default staffAssigmentModel;