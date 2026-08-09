import mongoose from "mongoose";
import { type } from "os";

const userSchema = new mongoose.Schema({
    fullName: {
        type: String,
        require: true
    },
    userId: {
        type: String,
        default: () => 'USR-' + Math.floor(100000 + Math.random() * 900000),
        unique: true
    },
    userObject: {
        type: Object,
        require: true
    },
    panNumber: {
        type: String,
        unique: true,
        sparse: true,
        uppercase: true,
        trim: true,
        index: true
    },
    aadhaarNumber: {
        type: String,
        default: null
    },
    dateOfBirth: {
        type: Date,
        default: null
    },
    userType: {
        type: String,
        default: "user"
    },
    phone: {
        type: String,
        require: true,
        unique: true,
        index: true
    },
    otp: {
        type: Number,
    },
    otpExpires: {
        type: Number
    },
    // mPin is replaced by mpinHash
    // status is replaced by userStatus
    termsCondition: {
        type: String,
        default: 'YES'
    },
    fcmToken: {
        type: String,
        default: null
    },
    email: {
        type: String,
        default: null
    },
    registrationSource: {
        type: String,
        enum: ['APP', 'ADMIN'],
        default: 'APP'
    },
    planSource: {
        type: String,
        enum: ['APP', 'ADMIN', 'MIXED'],
        default: 'APP'
    },
    registrationType: {
        type: String,
        enum: ['YEARLY', 'LIFETIME'],
        default: null
    },
    registrationStatus: {
        type: String,
        enum: ['PENDING', 'COMPLETE', 'ACTIVE', 'EXPIRED', 'REJECTED', 'INACTIVE'],
        default: 'PENDING'
    },
    registrationFeePaid: {
        type: Boolean,
        default: false
    },
    adminAccessGranted: {
        type: Boolean,
        default: false
    },
    registrationExpiry: {
        type: Date,
        default: null
    },
    kycStatus: {
        type: String,
        enum: ['NOT_STARTED', 'IN_PROGRESS', 'WAITING_FOR_REVIEW', 'VERIFIED', 'REJECTED'],
        default: 'NOT_STARTED',
        index: true
    },
    kycSubmittedAt: {
        type: Date,
        default: null
    },
    createdBy: {
        type: String,
        enum: ['SELF', 'ADMIN'],
        default: 'SELF'
    },
    mpinHash: {
        type: String,
        default: null
    },
    refreshTokenHash: {
        type: String,
        default: null
    },
    refreshTokenExpiresAt: {
        type: Date,
        default: null
    },
    userStatus: {
        type: String,
        enum: ['ACTIVE', 'SUSPENDED'],
        default: 'ACTIVE'
    },
    suspensionReason: {
        type: String,
        default: null
    },
    sessionDeviceId: {
        type: String,
        default: null
    },
    sessionIssuedAt: {
        type: Date,
        default: null
    },
    kycVideo: {
        type: String, // LEGACY: Use kycDocs.video instead
        default: null
    },
    // --- KYC STATE MACHINE EXTENSIONS ---
    kycRejectionReason: {
        type: String,
        default: null
    },
    kycHistory: [{
        fromStatus: String,
        toStatus: String,
        changedBy: { type: String }, // 'USER', 'ADMIN', 'SYSTEM' or UserID
        reason: String,
        timestamp: { type: Date, default: Date.now }
    }],
    kycDocs: {
        panImage: { type: String, default: null },
        aadhaarFront: { type: String, default: null },
        aadhaarBack: { type: String, default: null },
        video: { type: String, default: null }
    },
    // --- KYC 3-GATE SYSTEM ---
    // Each gate tracks its own status independently.
    // Overall kycStatus is auto-computed from these 3 by the backend.
    // Admin controls these; the mobile app reacts to them.
    kycGates: {
        documents: {
            // Gate 1: PAN Card + Aadhaar images
            status: {
                type: String,
                enum: ['NOT_STARTED', 'PENDING', 'VERIFIED', 'REJECTED'],
                default: 'NOT_STARTED'
            },
            rejectionReason: { type: String, default: null },
            reviewedAt: { type: Date, default: null },    // When admin approved/rejected
            submittedAt: { type: Date, default: null }    // When user uploaded docs
        },
        esign: {
            // Gate 2: Digio e-signed service agreement
            status: {
                type: String,
                enum: ['NOT_STARTED', 'PENDING', 'VERIFIED', 'REJECTED'],
                default: 'NOT_STARTED'
            },
            rejectionReason: { type: String, default: null },
            reviewedAt: { type: Date, default: null },    // When admin or Digio webhook resolved
            submittedAt: { type: Date, default: null }    // When Digio signing was initiated
        },
        video: {
            // Gate 3: Video KYC recording
            status: {
                type: String,
                enum: ['NOT_STARTED', 'PENDING', 'VERIFIED', 'REJECTED'],
                default: 'NOT_STARTED'
            },
            rejectionReason: { type: String, default: null },
            reviewedAt: { type: Date, default: null },    // When admin approved/rejected
            submittedAt: { type: Date, default: null }    // When user uploaded video
        }
    },
    // --------------------------
    mpinStatus: {
        type: String,
        enum: ['TEMP', 'SET', 'RESET_REQUIRED'],
        default: 'SET'
    },
    // New Identity Normalization Fields (Chunk 1)
    account_type: {
        type: String,
        enum: ['SELF_REGISTERED', 'ADMIN_PROVISIONED'],
        default: 'SELF_REGISTERED'
    },
    onboarded_by: {
        type: String,
        enum: ['USER', 'ADMIN'],
        default: 'USER'
    },
    // Disclaimer Gate (Chunk 2)
    disclaimer_acceptance: {
        status: { type: Boolean, default: false },
        accepted_at: { type: Date, default: null },
        ip_address: { type: String, default: null },
        version: { type: String, default: 'v1' }
    },
    // Wallet (Chunk 6)
    wallet_balance: {
        type: Number,
        default: 0
    },
    tempPinHash: {
        type: String,
        default: null
    },
    tempPinCreatedAt: {
        type: Date,
        default: null
    },
    gstin: {
        type: String,
        default: null
    },
    firmName: {
        type: String,
        default: null
    }
}, { timestamps: true, versionKey: false });
const users = mongoose.model("users", userSchema);
export default users;