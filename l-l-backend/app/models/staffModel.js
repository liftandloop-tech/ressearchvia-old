import mongoose from "mongoose";

const staffSchema = new mongoose.Schema({
    staffId: {
        type: String,
        required: true
    },
    fullName: {
        type: String,
        required: true
    },
    mobileNumber: {
        type: Number,
        required: true
    },
    emailAddress: {
        type: String,
        required: true
    },
    deparment: {
        type: String,
        default: null
    },
    telephonyExtension: {
        type: String,
        default: null
    },
    telephonyType: {
        type: String,
        enum: ['extension', 'device'],
        default: 'extension'
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
        type: mongoose.Schema.Types.Mixed,
        default: null,
        select: false
    },
    emailOtpExpires: {
        type: mongoose.Schema.Types.Mixed,
        default: null,
        select: false
    },
    mobileOtp: {
        type: mongoose.Schema.Types.Mixed,
        default: null,
        select: false
    },
    mobileOtpExpires: {
        type: mongoose.Schema.Types.Mixed,
        default: null,
        select: false
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
    localAddress: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },
    currentAddress: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },
    permanentAddress: {
        type: mongoose.Schema.Types.Mixed,
        default: null
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
        select: false
    },
    otpExpires: {
        type: Number,
        select: false
    },

    mpin: {
        type: String,
        default: null,
        select: false
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
    role: {
        type: String,
        default: null
    },
    departmentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Department',
        default: null
    },
    applicantId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'applicant',
        default: null,
        index: true
    },
    walkInForm: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    agreementStatus: {
        type: String,
        enum: ['NOT_INITIATED', 'PENDING_SIGNATURE', 'PENDING_ADMIN_VERIFICATION', 'VERIFIED', 'REJECTED'],
        default: 'NOT_INITIATED',
        index: true
    },
    hasSignedAgreement: {
        type: Boolean,
        default: false
    },
    agreementSignedAt: {
        type: Date,
        default: null
    },
    agreementSignature: {
        type: String,
        default: null
    },
    agreementIp: {
        type: String,
        default: null
    },
    agreementVersion: {
        type: String,
        default: '1.0'
    },
    agreementPdfUrl: {
        type: String,
        default: null
    },
    digioDocId: {
        type: String,
        default: null
    },
    digioObject: {
        type: mongoose.Schema.Types.Mixed,
        default: null
    },
    digioStatus: {
        type: String,
        enum: ['pending', 'verified', 'rejected', 'failed', null],
        default: null
    },
    agreementVerifiedAt: {
        type: Date,
        default: null
    },
    agreementVerifiedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'staff',
        default: null
    },
    agreementRejectionReason: {
        type: String,
        default: null
    },
    agreementRejectedAt: {
        type: Date,
        default: null
    },
    isDeleted: {
        type: Boolean,
        default: false
    },
}, { timestamps: true, versionKey: false });

staffSchema.index({ status: 1 });
staffSchema.index({ mobileNumber: 1 });
staffSchema.index({ emailAddress: 1 });
staffSchema.index({ role: 1 });
staffSchema.index({ departmentId: 1 });
staffSchema.index({ isDeleted: 1 });

const staffModel = mongoose.model("staff", staffSchema);
export default staffModel;