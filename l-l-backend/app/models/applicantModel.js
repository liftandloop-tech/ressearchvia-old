import mongoose from "mongoose";

const stageHistorySchema = new mongoose.Schema({
  stage: {
    type: String,
    enum: [
      "APPLIED",
      "SCREENING",
      "SHORTLISTED",
      "INTERVIEW",
      "SELECTED",
      "OFFER_SENT",
      "OFFER_ACCEPTED",
      "ONBOARDING",
      "REJECTED",
      "WITHDRAWN"
    ],
    required: true
  },
  note: { type: String, default: "" },
  changedBy: { type: mongoose.Schema.Types.ObjectId, ref: "staff", default: null },
  changedAt: { type: Date, default: Date.now }
}, { _id: false });

const applicantSchema = new mongoose.Schema({
  applicantId: {
    type: String,
    unique: true,
    index: true,
    required: true
  },
  
  // Basic Info
  fullName: {
    type: String,
    trim: true,
    default: ""
  },
  emailAddress: {
    type: String,
    required: true,
    trim: true,
    lowercase: true,
    index: true
  },
  password: {
    type: String,
    select: false,
    default: null
  },
  mobileNumber: {
    type: Number,
    index: true,
    default: null
  },
  countryCode: {
    type: String,
    default: "+91"
  },

  // Structured Personal Information
  title: {
    type: String,
    enum: ["Mr", "Ms", "Mrs", null],
    default: null
  },
  firstName: {
    type: String,
    trim: true,
    default: null
  },
  middleName: {
    type: String,
    trim: true,
    default: null
  },
  lastName: {
    type: String,
    trim: true,
    default: null
  },
  fatherName: {
    type: String,
    trim: true,
    default: null
  },
  alternateEmail: {
    type: String,
    trim: true,
    lowercase: true,
    default: null
  },

  // Identity & Verification Documents
  panNumber: {
    type: String,
    trim: true,
    default: null
  },
  confirmPanNumber: {
    type: String,
    trim: true,
    default: null
  },
  passportNumber: {
    type: String,
    trim: true,
    default: null
  },
  proofOfAddressType: {
    type: String,
    default: "Aadhaar"
  },
  proofOfAddressUrl: {
    type: String,
    default: null
  },
  telephoneResidence: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  },

  // Educational & Professional Qualifications
  highestQualification: {
    type: String,
    default: null
  },
  majorSubject: {
    type: String,
    default: null
  },
  instituteUniversity: {
    type: String,
    default: null
  },
  yearOfPassing: {
    type: Number,
    default: null
  },
  percentageGrade: {
    type: String,
    default: null
  },
  professionalQualifications: {
    type: mongoose.Schema.Types.Mixed,
    default: []
  },

  // Form Progress & Draft Status
  currentStep: {
    type: Number,
    default: 1
  },
  isDraft: {
    type: Boolean,
    default: true
  },

  // Target Role & Department
  jobOpeningId: {
    type: String,
    default: null
  },
  targetDepartment: {
    type: String,
    default: null
  },
  targetRole: {
    type: String,
    default: null
  },
  targetRoleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Role",
    default: null
  },

  // Recruitment Stage Lifecycle
  stage: {
    type: String,
    enum: [
      "APPLIED",
      "SCREENING",
      "SHORTLISTED",
      "INTERVIEW",
      "SELECTED",
      "OFFER_SENT",
      "OFFER_ACCEPTED",
      "ONBOARDING",
      "PROMOTED",
      "REJECTED",
      "WITHDRAWN"
    ],
    default: "APPLIED",
    index: true
  },
  stageHistory: [stageHistorySchema],

  // Sourcing & Recruiter Attribution
  source: {
    type: String,
    default: "WALK_IN"
  },
  assignedRecruiterId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "staff",
    default: null
  },
  rejectionReason: {
    type: String,
    default: null
  },

  // Verification OTPs
  mobileOtp: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  },
  mobileOtpExpires: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  },
  emailOtp: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  },
  emailOtpExpires: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  },
  isMobileVerified: {
    type: Boolean,
    default: false
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  verifiedAt: {
    type: Date,
    default: null
  },
  onboardingStatus: {
    type: String,
    enum: ["PENDING", "DOCUMENTS_UPLOADED", "VERIFIED"],
    default: "PENDING"
  },

  // Candidate Profile & Bio-Data
  dob: {
    type: Date,
    default: null
  },
  gender: {
    type: String,
    default: null
  },
  maritalStatus: {
    type: String,
    default: null
  },
  currentLocation: {
    type: String,
    default: null
  },
  skypeOrLinkedIn: {
    type: String,
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
  academicGap: {
    type: Boolean,
    default: false
  },
  academicGapDetails: {
    type: String,
    default: null
  },
  backlogsCount: {
    type: String,
    default: null
  },
  hasWorkExperience: {
    type: Boolean,
    default: false
  },
  currentDesignation: {
    type: String,
    default: null
  },
  reportingManagerName: {
    type: String,
    default: null
  },
  reportingManagerDesignation: {
    type: String,
    default: null
  },
  reporteesCount: {
    type: Number,
    default: 0
  },
  fixedSalary: {
    type: String,
    default: null
  },
  bonusIncentive: {
    type: String,
    default: null
  },
  expectedSalary: {
    type: String,
    default: null
  },
  noticePeriod: {
    type: String,
    default: null
  },
  careerGapDetails: {
    type: String,
    default: null
  },
  previousEmploymentHistory: {
    type: mongoose.Schema.Types.Mixed,
    default: []
  },
  emergencyContact: {
    name: { type: String, default: null },
    relation: { type: String, default: null },
    phone: { type: String, default: null }
  },

  // Uploaded Documents
  photoUrl: {
    type: String,
    default: null
  },
  resumeUrl: {
    type: String,
    default: null
  },
  aadhaarUrl: {
    type: String,
    default: null
  },
  panUrl: {
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
  documents: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },

  // Walk-In Questionnaire & Screening Declarations
  walkInForm: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
  },

  // Conversion link to Staff once hired
  convertedStaffId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "staff",
    default: null,
    index: true
  },
  hiredAt: {
    type: Date,
    default: null
  }
}, { timestamps: true, versionKey: false });

applicantSchema.index({ stage: 1, createdAt: -1 });
applicantSchema.index({ mobile: 1 });
applicantSchema.index({ email: 1 });
applicantSchema.index({ isDeleted: 1 });

const applicantModel = mongoose.model("applicant", applicantSchema);
export default applicantModel;
