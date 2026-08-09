import mongoose from "mongoose";

const staffAssignmentSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        require: true,
        ref: "users"

    },
    staffId: {
        type: mongoose.Schema.Types.ObjectId,
        require: true,
        ref:"staffs"
    },
    staffName:{
        type:String,
        require:true
    }
}, { timestamps: true, versionKey: false });
const staffAssigmentModel = mongoose.model("staffAssigment", staffAssignmentSchema);
export default staffAssigmentModel;