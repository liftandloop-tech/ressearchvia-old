import mongoose from "mongoose";

const staffSchema = new mongoose.Schema({
    staffId: {
        type: String,
        require: true
    },
    fullName: {
        type: String,
        require: true
    },
    mobileNumber: {
        type: Number,
        require: true
    },
    emailAddress: {
        type: String,
        require: true
    },
    deparment: {
        type: String,
        default: null
    },

    joiningDate: {
        type: Date,
        default: null
    },
    status: {
        type: String,
        default: 'Active'
    },
    stage: {
        type: String,
        enum: ['Applicant', 'Employee'],
        default: 'Applicant'
    },
    emailOtp: {
        type: Number,
        default: null
    },
    emailOtpExpires: {
        type: Date,
        default: null
    },
    mobileOtp: {
        type: Number,
        default: null
    },
    mobileOtpExpires: {
        type: Date,
        default: null
    },
    isEmailVerified: {
        type: Boolean,
        default: false
    },
    isMobileVerified: {
        type: Boolean,
        default: false
    },
    photoUrl: {
        type: String,
        default: null
    },
    resumeUrl: {
        type: String,
        default: null
    },
    dob: {
        type: Date,
        default: null
    },
    gender: {
        type: String,
        default: null
    },
    currentAddress: {
        street: { type: String, default: null },
        city: { type: String, default: null },
        state: { type: String, default: null },
        zip: { type: String, default: null }
    },
    permanentAddress: {
        street: { type: String, default: null },
        city: { type: String, default: null },
        state: { type: String, default: null },
        zip: { type: String, default: null }
    },
    emergencyContact: {
        name: { type: String, default: null },
        relation: { type: String, default: null },
        phone: { type: String, default: null }
    },
    experienceYears: {
        type: Number,
        default: 0
    },
    previousCompany: {
        type: String,
        default: null
    },
    lastCtc: {
        type: String,
        default: null
    },
    panUrl: {
        type: String,
        default: null
    },
    aadhaarUrl: {
        type: String,
        default: null
    },
    nismUrl: {
        type: String,
        default: null
    },
    highestEducationUrl: {
        type: String,
        default: null
    },
    kycVideoUrl: {
        type: String,
        default: null
    },
    onboardingStatus: {
        type: String,
        enum: ['PENDING', 'DOCUMENTS_UPLOADED', 'VERIFIED'],
        default: 'PENDING'
    },
    otp: {
        type: Number,
    },
    otpExpires: {
        type: Number
    },
    mpin: {
        type: String,
        default: null
    },
    assignedDirector: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'staff',
        default: null
    },
    assignedDirectorName: {
        type: String,
        default: null
    },
    isViewOnly: {
        type: Boolean,
        default: false
    },
    roleId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Role',
        default: null
    },
}, { timestamps: true, versionKey: false });
const staffModel = mongoose.model("staff", staffSchema);
export default staffModel;