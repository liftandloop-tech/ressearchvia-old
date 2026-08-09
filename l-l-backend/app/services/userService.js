import userModel from "../models/userModel.js";
import filesModel from "../models/fileModel.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import fs from "fs";
import path from "path";
import files from "../models/fileModel.js";
import axios from "axios";
import { solicitPanDetails } from "../config/kraClient.js";
import decryptAES from "../encryption/decrypt.js";
import planPurchaseModel from "../models/planPurchaseModel.js";
import userKycModel from "../models/userKycModel.js";
import segmentsModel from "../models/segmentsModel.js";
import userActiveSegmentsModel from "../models/userActiveSegmentsModel.js";
import segmentsPlanModel from "../models/segmentsPlansModel.js";
import mongoose from "mongoose";
import deviceModel from "../models/deviceModel.js";
import userDocUploadModel from "../models/userDocUploadModel.js";
import paymentIntentModel from "../models/paymentIntentModel.js";
import { logUserLogin, logAppSessionStart, logUserLogout, logAdminProfileEdit, logKycStatusChange, logAccountSuspended, logTempPinGenerated, logAliasLogin } from "./activityLogService.js";

// Helper function for Canonical Onboarding Logic
import { grantEntitlement } from "./entitlementService.js";
import staffService from "./staffService.js";

/* ==========================================================================
   HELPER FUNCTIONS (Refactored to reduce redundancy)
   ========================================================================== */

/**
 * Clean phone number and find user by multiple formats
 */
const findUserByPhone = async (phone) => {
  if (!phone) return null;
  const cleanPhone = phone.toString().replace(/\D/g, "").slice(-10);
  return await userModel.findOne({
    $or: [
      { phone: cleanPhone },
      { phone: "91" + cleanPhone },
      { phone: "+91" + cleanPhone },
    ],
  });
};

/**
 * Send SMS via Gateway
 */
const sendSms = async (phone, messageText) => {
  const username = process.env.SMS_SHORT_SERVICE_USER;
  const apikey = process.env.SMS_SHORT_SERVICE_API_KEY;
  const sender = process.env.SMS_SHORT_SERVICE_SENDER;
  const templateID = process.env.SMS_SHORT_SERVICE_TEMPLATEID;
  const url = process.env.SMS_SHORT_SERVICE_URL;

  // Clean phone number: remove any non-digits and keep last 10
  const cleanPhone = phone.toString().replace(/\D/g, "").slice(-10);

  const message = encodeURIComponent(messageText);
  const smsUrl = `${url}username=${username}&apikey=${apikey}&apirequest=Text&sender=${sender}&mobile=${cleanPhone}&message=${message}sms&route=TRANS&TemplateID=${templateID}&format=JSON`;

  return await axios.get(smsUrl);
};

/**
 * Generate Access and Refresh Tokens
 */
const generateTokens = async (user, nextStep) => {
  const accessToken = jwt.sign(
    {
      _id: user._id,
      userObject: user.userObject,
      fullName: user.fullName,
      phone: user.phone,
      userType: user.userType,
      kycStatus: user.kycStatus,
      registrationStatus: user.registrationStatus,
      nextStep: nextStep,
      type: 'ACCESS'
    },
    process.env.JWT_TOKEN,
    { expiresIn: '7d' }
  );

  const refreshToken = jwt.sign(
    { _id: user._id, type: 'REFRESH' },
    process.env.JWT_TOKEN,
    { expiresIn: '7d' }
  );

  // Hash refresh token
  const refreshTokenHash = await bcrypt.hash(refreshToken, 10);
  user.refreshTokenHash = refreshTokenHash;
  user.refreshTokenExpiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
  await user.save();

  return { accessToken, refreshToken };
};

/**
 * Sync User Device (Single Device Enforcement)
 */
const syncUserDevice = async (user, deviceId, platform = 'android') => {
  if (!deviceId) return;

  user.sessionDeviceId = deviceId;
  user.sessionIssuedAt = new Date();
  await user.save();

  // 1. Mark all devices of this user as Inactive
  await deviceModel.updateMany({ userId: user._id }, { $set: { isActive: false } });

  // 2. Mark current device as Active (Upsert to ensure it exists)
  await deviceModel.findOneAndUpdate(
    { deviceId: deviceId },
    {
      $set: {
        isActive: true,
        userId: user._id,
        platform: platform,
        lastSeenAt: new Date()
      },
      $setOnInsert: {
        pushToken: 'PENDING_UPDATE_' + Date.now()
      }
    },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
};

/**
 * Inject dynamic registration status if user is not ACTIVE but has a pending intent
 */
const injectPendingRegistration = async (userResponse) => {
  if (userResponse.registrationStatus !== "ACTIVE") {
    const pendingReg = await paymentIntentModel.findOne({
      userId: userResponse._id,
      purchaseType: "REGISTRATION",
      status: { $in: ["CREATED", "PENDING_BANK_TRANSFER", "VERIFICATION_PENDING", "PENDING_ADMIN_APPROVAL", "REJECTED"] }
    }).sort({ createdAt: -1 });

    if (pendingReg) {
      userResponse.registrationStatus = pendingReg.status === "REJECTED" ? "REJECTED" : "PENDING";
      // Map packageName ('Gold'/'Silver') or baseAmount back to 'LIFETIME'/'YEARLY'
      if (pendingReg.packageName === "Gold" || [10000].includes(pendingReg.baseAmount)) {
        userResponse.registrationType = "LIFETIME";
      } else {
        userResponse.registrationType = "YEARLY";
      }
    }
  }
  return userResponse;
};

// ------------------------------------------------------------------
// FINAL BACKEND-AUTHORITATIVE RESOLVER (The Hard Truth)
// ------------------------------------------------------------------
const determineNextStep = async ({ user, platform = 'android', context = 'LOGIN' }) => {
  /* ------------------------------------------------ */
  /* GATE 0. SUSPENSION CHECK                         */
  /* ------------------------------------------------ */
  // If user is suspended, send them to DASHBOARD so they can "surf" 
  // but see the suspension popup.
  if (user.userStatus === 'SUSPENDED') {
    return {
      current: context,
      state: "HOME_SUSPENDED",
      next: "DASHBOARD",
      intent: "SUSPENDED_SURFING"
    };
  }

  /* ------------------------------------------------ */
  /* GATE 1. MPIN ENFORCEMENT                         */
  /* ------------------------------------------------ */
  // Condition: mpin set and mpinhash is not null
  if (!user.mpinHash) {
    return {
      current: context,
      state: "SET_MPIN",
      next: "SET_MPIN",
      intent: "CREATE_MPIN"
    };
  }

  // Enhancement: Handle Reset/Temp MPIN status if applicable
  if (user.mpinStatus === "TEMP" || user.mpinStatus === "RESET_REQUIRED") {
    return {
      current: context,
      state: "RESET_MPIN",
      next: "RESET_MPIN",
      intent: "FORCE_MPIN_RESET",
      logoutAfter: true
    };
  }

  /* ------------------------------------------------ */
  /* GATE 2. DOCUMENT UPLOAD CHECK                    */
  /* ------------------------------------------------ */
  // Sub-check 2a: User profile & physical documents must exist first.
  const hasProfile = user.userObject && Object.keys(user.userObject).length > 0;

  const userDocs = await userDocUploadModel.findOne({ userId: user._id });
  const hasDocs = userDocs &&
    userDocs.pancard?.fileName &&
    userDocs.aadhaar?.front?.fileName &&
    userDocs.aadhaar?.back?.fileName;

  if (!hasProfile || !hasDocs) {
    return {
      current: context,
      state: "KYC_DETAILS",
      next: "KYC_DETAILS",
      intent: "COMPLETE_PROFILE_AND_DOCS"
    };
  }

  // Sub-check 2b: Check the Document Gate status (admin decision).
  const docGateStatus = user.kycGates?.documents?.status ?? 'PENDING';

  if (docGateStatus === 'REJECTED') {
    return {
      current: context,
      state: "KYC_DOCUMENT_REJECTED",
      next: "KYC_DOCUMENT_REJECTED",
      intent: "GATE_1_REJECTED",
      rejectionReason: user.kycGates.documents.rejectionReason ?? 'Your KYC documents were rejected. Please re-upload.'
    };
  }

  // If docGateStatus === PENDING but documents are uploaded, we let them proceed to Gate 3!
  // This ensures the continuous KYC funnel.
  // ONLY if they reach the end of the funnel will they get KYC_IN_REVIEW.

  // docGateStatus === 'VERIFIED' → proceed to Gate 3

  /* ------------------------------------------------ */
  /* GATE 3. E-SIGN CHECK (Digio Service Agreement)   */
  /* ------------------------------------------------ */
  const esignGateStatus = user.kycGates?.esign?.status ?? 'NOT_STARTED';
  const userKyc = await userKycModel.findOne({ userId: user._id });

  if (esignGateStatus === 'REJECTED') {
    return {
      current: context,
      state: "DIGIO_ESIGN_REJECTED",
      next: "DIGIO_ESIGN_REJECTED",
      intent: "GATE_2_REJECTED",
      rejectionReason: user.kycGates.esign.rejectionReason ?? 'Your service agreement was rejected. Please re-sign.'
    };
  }

  if (esignGateStatus === 'PENDING' || esignGateStatus === 'NOT_STARTED') {
    if (!userKyc || !userKyc.digioObject) {
      // User has not yet initiated Digio signing — send to Digio Connect screen
      return {
        current: context,
        state: "DIGIO_ESIGN_FLOW",
        next: "DIGIO_ESIGN_FLOW",
        intent: "DIGIO_SIGNING_REQUIRED"
      };
    }
    // userKyc exists with digioObject — user has at least initiated/signed.
    // We let them proceed to Gate 4 (Video)!
  }

  // esignGateStatus === 'VERIFIED' → proceed to Gate 4

  /* ------------------------------------------------ */
  /* GATE 4. VIDEO KYC CHECK                          */
  /* ------------------------------------------------ */
  const videoGateStatus = user.kycGates?.video?.status ?? 'NOT_STARTED';
  const hasVideo = (user.kycVideo && user.kycVideo !== '') ||
    (user.kycDocs?.video && user.kycDocs.video !== '');

  if (videoGateStatus === 'REJECTED') {
    return {
      current: context,
      state: "VIDEO_KYC_REJECTED",
      next: "VIDEO_KYC_REJECTED",
      intent: "GATE_3_REJECTED",
      rejectionReason: user.kycGates.video.rejectionReason ?? 'Your Video KYC was rejected. Please re-record.'
    };
  }

  if (videoGateStatus === 'PENDING' || videoGateStatus === 'NOT_STARTED') {
    if (!hasVideo) {
      // User has not yet recorded a video
      if (user.disclaimer_acceptance && user.disclaimer_acceptance.status === true) {
        return {
          current: context,
          state: "VIDEO_RECORDER",
          next: "VIDEO_RECORDER",
          intent: "RECORD_VIDEO"
        };
      }
      return {
        current: context,
        state: "VIDEO_KYC_INTRO",
        next: "VIDEO_KYC_INTRO",
        intent: "COMPLETE_VIDEO_KYC"
      };
    }
  }

  // At this point, the basic collecting of info (Docs, Digio, Video) is done or in progress.
  // We now check if the user has paid for their registration BEFORE we put them in the final review queue.

  /* ------------------------------------------------ */
  /* GATE 5. REGISTRATION PAYMENT                     */
  /* ------------------------------------------------ */
  // Condition: Registration plan is subscribed (yearly or lifetime)
  const registrationActive = (
    user.registrationFeePaid === true ||
    user.adminAccessGranted === true ||
    user.registrationStatus === 'ACTIVE' ||
    user.registrationStatus === 'COMPLETE' ||
    user.registrationStatus === 'REJECTED' ||
    user.registrationStatus === 'INACTIVE' ||
    user.registrationStatus === 'PENDING'
  ) && (user.registrationType && user.registrationType !== "null");

  if (!registrationActive) {
    // Check if there is a pending or *recently* paid registration payment intent
    const pendingPayment = await paymentIntentModel.findOne({
      userId: user._id,
      purchaseType: "REGISTRATION",
      $or: [
        { status: { $in: ["VERIFICATION_PENDING", "PENDING_ADMIN_APPROVAL"] } },
        { status: "PENDING_BANK_TRANSFER", "partialPaymentsHistory.0": { $exists: true } },
        { status: "PAID" }
      ]
    });

    if (!pendingPayment) {
      if (platform.toLowerCase() === "ios") {
        return {
          current: context,
          state: "HOME_LIMITED",
          next: "DASHBOARD_LIMITED",
          intent: "ACCESS_ONLY"
        };
      }

      return {
        current: context,
        state: "REGISTRATION_REQUIRED",
        next: "REGISTRATION_PAYMENT", // Frontend maps this to registration.screen.dart
        intent: "COLLECT_PAYMENT",
        // CRITICAL: canSkip is always false here because the backend has determined
        // the user genuinely has not paid or initiated registration.
        // The mobile app MUST NOT override this with a local "skip" flag.
        canSkip: false
      };
    }
  }

  // Final Step: Await Admin Approvals
  // If any of the three backend gates are still PENDING or NOT_STARTED (but have docs), hold the user in KYC_IN_REVIEW.
  // This state allows the user to access the Dashboard (Tabs) while verification is in progress.
  if (docGateStatus !== 'VERIFIED' || esignGateStatus !== 'VERIFIED' || videoGateStatus !== 'VERIFIED') {
    return {
      current: context,
      state: "KYC_IN_REVIEW",
      next: "KYC_IN_REVIEW",
      intent: "AWAITING_ADMIN_REVIEW"
    };
  }

  // All three gates are VERIFIED and payment is confirmed!
  return {
    current: context,
    state: "HOME",
    next: "DASHBOARD",
    intent: "NORMAL_ENTRY"
  };
};


const userService = {
  userCreate: async ({ body }) => {
    try {
      const { fullName, phone, email } = body;
      const username = process.env.SMS_SHORT_SERVICE_USER;
      const apikey = process.env.SMS_SHORT_SERVICE_API_KEY;
      const sender = process.env.SMS_SHORT_SERVICE_SENDER;
      const templateID = process.env.SMS_SHORT_SERVICE_TEMPLATEID;
      const url = process.env.SMS_SHORT_SERVICE_URL;

      const existingUser = await findUserByPhone(phone);
      if (existingUser) {
        return {
          status: 400,
          message: "A user with this phone number is already registered.",
          data: { phone: existingUser.phone }
        };
      }

      const otp = Math.floor(1000 + Math.random() * 9000).toString();
      const defaultTemplate = "Your OTP for ResearchVia App is {OTP}\n\n\n\nPlease do not share OTP with anyone.\n\nhttps://researchvia.in\n\n";
      const messageText = defaultTemplate.replaceAll("{OTP}", otp);

      console.log(`[USER_CREATE] Sending OTP to ${phone}`);

      const result = await sendSms(phone, messageText);
      if (result.status == 200) {
        let otpExpires = Date.now() + 5 * 60 * 1000;
        let newUser = new userModel({
          fullName: fullName,
          phone: phone,
          otp: otp,
          otpExpires: otpExpires,
          email: email,
          account_type: 'SELF_REGISTERED',
          onboarded_by: 'USER',
          userObject: {}
        });
        await newUser.save();
        return {
          status: 200,
          message: "OTP has been sent to your phone ",
          data: { user: newUser },
        };
      } else {
        return { status: 400, message: "Failed to send OTP", data: {} };
      }
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  adminCreate: async ({ body }) => {
    try {
      let {
        fullName,
        email,
        phone,
        registrationType,
        paymentMode,
        planIds,
        userType,
        mpin // Added mpin to destructuring
      } = body;

      // 1. Basic Validation
      if (!phone || !fullName) {
        return {
          status: 400,
          message: "Name and Phone are required.",
          data: {},
        };
      }

      // Validate MPIN if provided (it should be for this new flow)
      if (mpin && mpin.toString().length !== 4) {
        return {
          status: 400,
          message: "MPIN must be 4 digits.",
          data: {},
        };
      }

      const cleanPhone = phone.toString().replace(/\D/g, "").slice(-10);

      // 2. Check Existence
      let existingUser = await userModel.findOne({
        $or: [
          { phone: cleanPhone },
          { phone: "91" + cleanPhone },
          { phone: "+91" + cleanPhone },
        ],
      });

      if (existingUser) {
        return {
          status: 400,
          message: "User with this phone already exists.",
          data: {},
        };
      }

      // 3. Generate & Hash MPIN
      // Use provided MPIN or fallback to random (though frontend will enforce it)
      const finalMpin = mpin ? mpin.toString() : Math.floor(1000 + Math.random() * 9000).toString();
      const mpinHash = await bcrypt.hash(finalMpin, 10);

      // 4. Create User
      // Admin Created users are ACTIVE immediately.
      // KYC Status is NOT_STARTED (or PENDING if we want to force them immediately). Plan says NOT_STARTED usually but AccessMiddleware checks it.
      // AccessMiddleware allows App Access if Status=ACTIVE.
      // They need to do KYC on first login.

      let newUser = new userModel({
        fullName,
        phone: cleanPhone,
        userType: userType || "user",
        registrationType: registrationType || "YEARLY", // 'YEARLY' or 'LIFETIME'
        registrationStatus: "ACTIVE", // Changed from ACTIVE to COMPLETE to allow login
        registrationExpiry:
          registrationType === "LIFETIME"
            ? new Date(Date.now() + 10 * 365.25 * 24 * 60 * 60 * 1000)
            : new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // Default 1 year if not Lifetime? Logic can be refined.
        mpinHash: mpinHash,
        createdBy: "ADMIN",
        kycStatus: "NOT_STARTED",
        userStatus: "ACTIVE",
        account_type: "ADMIN_PROVISIONED",
        registrationSource: "ADMIN",
        planSource: planIds && planIds.length > 0 ? "ADMIN" : "APP",
        email: email,
        registrationFeePaid: true, // Auto-mark fee as paid
        adminAccessGranted: true, // Explicit admin grant
        mpinStatus: "TEMP" // Force MPIN change on first login
      });

      // Handle custom plan assignments (Legacy and New structured format)
      let { assignedPlans } = body;
      const plansToProcess = assignedPlans || (planIds && Array.isArray(planIds) ? planIds.map(id => ({ planId: id })) : []);

      if (plansToProcess.length > 0) {
        for (const planEntry of plansToProcess) {
          const {
            planId,
            segmentId, // singular fallback
            segmentIds, // plural for HNI
            isPartial,
            paidAmount,
            remarks,
            isHniGrant, // NEW: HNI specific flag
            customPackageName, // NEW
            customValidity, // NEW
            totalAgreementPrice, // NEW: Full value of bespoke deal
            raId // NEW: Staff/RA ID
          } = planEntry;

          const segmentPlan = await segmentsPlanModel.findById(planId);

          if (segmentPlan) {
            const startDate = new Date();
            let duration = parseInt(segmentPlan.duration) || 30; // Original duration
            const fullPrice = (isHniGrant && totalAgreementPrice) ? totalAgreementPrice : (segmentPlan.price || 0);

            // HNI Custom Validity priority
            if (isHniGrant && customValidity) {
              duration = parseInt(customValidity);
            } else if (isPartial && paidAmount && paidAmount < fullPrice) {
              // DYNAMIC VALIDITY CALCULATION for Partial Payments (Standard)
              const ratio = paidAmount / fullPrice;
              duration = Math.floor(ratio * duration);
              if (duration < 1) duration = 1; // Minimum 1 day
            }

            const endDate = new Date(startDate);
            endDate.setDate(endDate.getDate() + duration);

            const finalPackageName = (isHniGrant && customPackageName)
              ? customPackageName
              : `${segmentPlan.segmentsName || ''} - ${segmentPlan.planName}`;

            await planPurchaseModel.create({
              userId: newUser._id,
              packageName: finalPackageName,
              validity: duration,
              startDate: startDate,
              endDate: endDate,
              status: "active",
              basicAmount: (isHniGrant || isPartial) ? paidAmount : fullPrice,
              totalPlanAmount: fullPrice,
              isPartial: !!isPartial,
              cgstAmount: 0,
              sgstAmount: 0,
              paymentMethod: "OFFLINE",
              expiryReminder: true,
              remarks: remarks || null,
            });

            // CHUNK 7: Grant Entitlement (Linking to specific segment(s) if provided)
            const segmentsToGrant = segmentIds && Array.isArray(segmentIds) && segmentIds.length > 0
              ? segmentIds
              : (segmentId ? [segmentId] : [null]);

            for (const sId of segmentsToGrant) {
              await grantEntitlement({
                userId: newUser._id,
                type: 'PLAN',
                resourceId: segmentPlan._id,
                segmentId: sId,
                days: duration,
                grantedBy: 'ADMIN',
                grantReason: isPartial ? 'MANUAL_PARTIAL' : (isHniGrant ? 'HNI_CUSTOM_GRANT' : 'MANUAL'),
                sourceRefId: newUser._id,
                remarks: remarks || null
              });
            }

            // RA / STAFF ASSIGNMENT (For HNI)
            if (raId) {
              await staffService.StaffAssignment({
                body: {
                  userId: newUser._id,
                  staffId: raId
                },
                user: { userType: 'ADMIN' } // Mocking requestor
              });
            }
          }
        }
      }

      const registrationExpiry = newUser.registrationExpiry;
      const daysUntilExpiry = registrationExpiry
        ? Math.ceil((registrationExpiry - new Date()) / (1000 * 60 * 60 * 24))
        : 365; // Default fallback if null (Lifetime handled by isLifetime flag)

      // CHUNK 7: Grant Entitlement (Registration)
      await grantEntitlement({
        userId: newUser._id,
        type: 'REGISTRATION',
        isLifetime: registrationType === "LIFETIME",
        days: registrationType === "LIFETIME" ? 3652 : daysUntilExpiry,
        grantedBy: 'ADMIN',
        grantReason: 'MANUAL',
        sourceRefId: newUser._id
      });

      await newUser.save();

      // Return generated MPIN so Admin can share it
      return {
        status: 200,
        message: "User created successfully by Admin.",
        data: { user: newUser, mpin: finalMpin },
      };
    } catch (error) {
      console.error("Admin Create Error:", error);
      return { status: 400, message: error.message, data: {} };
    }
  },
  adminUpdateUser: async ({ body, params, req, user: adminUser }) => {
    try {
      const { id } = params;
      const { fullName, phone, email, registrationType, newPlanIds, kycStatus, gstin, firmName } = body;
      console.log(`[DEBUG] adminUpdateUser called for ID: ${id}. Body:`, JSON.stringify(body));

      let user = await userModel.findById(id);
      if (!user) {
        return { status: 404, message: "User not found", data: {} };
      }

      // Track which fields are being changed for the audit log
      const changedFields = [];

      // Ensure userObject exists
      if (!user.userObject) user.userObject = {};

      // 1. Update Basic Info
      if (fullName) {
        user.fullName = fullName;
        user.userObject.APP_NAME = fullName;
        changedFields.push('Full Name');
      }
      if (phone) {
        const cleanPhone = phone.toString().replace(/\D/g, "").slice(-10);
        user.phone = cleanPhone;
        user.userObject.APP_MOB_NO = cleanPhone;
        changedFields.push('Phone');
      }
      if (email) {
        user.userObject.APP_EMAIL = email;
        user.email = email;
        changedFields.push('Email');
      }

      if (gstin !== undefined) {
        user.gstin = gstin;
        changedFields.push('GSTIN');
      }
      if (firmName !== undefined) {
        user.firmName = firmName;
        changedFields.push('Firm Name');
      }

      // 1.5. Update KYC Status (Admin Approval/Rejection)
      if (kycStatus) {
        const validStatuses = ['VERIFIED', 'REJECTED', 'WAITING_FOR_REVIEW', 'NOT_STARTED', 'PENDING'];
        if (validStatuses.includes(kycStatus)) {
          const oldStatus = user.kycStatus;
          user.kycStatus = kycStatus;
          changedFields.push(`KYC (${oldStatus} → ${kycStatus})`);

          // --- SYNC INDIVIDUAL GATES IF SET TO VERIFIED ---
          if (kycStatus === 'VERIFIED') {
              if (!user.kycGates) user.kycGates = {};
              ['documents', 'esign', 'video'].forEach(gate => {
                  if (!user.kycGates[gate]) user.kycGates[gate] = {};
                  user.kycGates[gate].status = 'VERIFIED';
                  user.kycGates[gate].reviewedAt = new Date();
              });
              user.markModified('kycGates'); // CRITICAL: Mark gates as modified
          }

          // Add to KYC history
          if (!user.kycHistory) user.kycHistory = [];
          user.kycHistory.push({
            fromStatus: oldStatus,
            toStatus: kycStatus,
            changedBy: 'ADMIN',
            timestamp: new Date()
          });

          // --- COMPLIANCE LOG: KYC Status Change ---
          logKycStatusChange({
            user,
            fromStatus: oldStatus,
            toStatus: kycStatus,
            changedBy: {
              id: adminUser?._id?.toString(),
              name: adminUser?.fullName || 'Admin',
              role: adminUser?.userType || 'ADMIN'
            },
            req
          });

          // --- SYNC userKycModel ---
          // Ensure Digio flow logic uses the correct status values
          let kycStatusLower = kycStatus.toLowerCase();
          if (kycStatus === 'WAITING_FOR_REVIEW') kycStatusLower = 'pending';
          else if (kycStatus === 'NOT_STARTED') kycStatusLower = 'pending';

          await userKycModel.findOneAndUpdate(
            { userId: user._id },
            { $set: { kycStatus: kycStatusLower, updatedAt: new Date() } },
            { upsert: true }
          );
        }
      }

      // Update Extended Info from body
      const {
        fatherName, dob, gender,
        address1, address2, city, state, pincode
      } = body;

      if (fatherName) { 
        user.userObject.APP_F_NAME = fatherName; 
        changedFields.push('Father Name'); 
      }
      
      if (dob) { 
        user.userObject.APP_DOB_DT = dob; 
        changedFields.push('Date of Birth'); 
        // Sync with top-level dateOfBirth if it's in DD/MM/YYYY format or similar
        try {
          const parts = dob.split('/');
          if (parts.length === 3) {
            const dateObj = new Date(parts[2], parts[1] - 1, parts[0]);
            if (!isNaN(dateObj.getTime())) {
              user.dateOfBirth = dateObj;
            }
          } else if (dob.includes('-')) {
             const partsDash = dob.split('-');
             if (partsDash.length === 3) {
                const dateObj = new Date(partsDash[0], partsDash[1]-1, partsDash[2]);
                if (!isNaN(dateObj.getTime())) {
                  user.dateOfBirth = dateObj;
                }
             }
          }
        } catch (e) {
          console.error("Date parsing error for top-level DOB sync:", e);
        }
      }

      if (gender) { 
        let mappedGender = gender;
        if (gender === 'Male' || gender === 'M') mappedGender = 'M';
        else if (gender === 'Female' || gender === 'F') mappedGender = 'F';
        user.userObject.APP_GEN = mappedGender; 
        changedFields.push('Gender'); 
      }

      if (address1) { 
        user.userObject.APP_COR_ADD1 = address1; 
        changedFields.push('Address'); 
      }
      if (address2) user.userObject.APP_COR_ADD2 = address2;
      if (city) user.userObject.APP_COR_CITY = city;
      if (state) user.userObject.APP_COR_STATE = state;
      if (pincode) user.userObject.APP_COR_PINCD = pincode;

      // Handle account status change (userStatus)
      if (body.userStatus) {
        const oldStatus = user.userStatus;
        user.userStatus = body.userStatus;
        changedFields.push(`Account Status (${oldStatus} → ${body.userStatus})`);
        if (body.userStatus === 'SUSPENDED') {
          if (!body.suspensionReason) {
            return { status: 400, message: "Suspension reason is mandatory." };
          }
          user.suspensionReason = body.suspensionReason;
          logAccountSuspended({
            userId: user._id,
            reason: body.suspensionReason,
            performedBy: {
              id: adminUser?._id?.toString(),
              name: adminUser?.fullName || 'Admin',
              role: adminUser?.userType || 'ADMIN'
            },
            req
          });
        } else if (body.userStatus === 'ACTIVE') {
          user.suspensionReason = null;
        }
      }

      // 2. Assign/Update Registration
      if (registrationType) {
        user.registrationType = registrationType;
        user.registrationStatus = "ACTIVE";
        user.registrationFeePaid = true;
        user.registrationSource = "ADMIN";
        changedFields.push(`Registration (${registrationType})`);

        const isLifetime = registrationType === "LIFETIME";

        if (isLifetime) {
          user.registrationExpiry = new Date(Date.now() + 10 * 365.25 * 24 * 60 * 60 * 1000);
        } else {
          user.registrationExpiry = new Date(
            Date.now() + 365 * 24 * 60 * 60 * 1000,
          );
        }

        await grantEntitlement({
          userId: user._id,
          type: 'REGISTRATION',
          isLifetime,
          days: isLifetime ? 3652 : 365,
          grantedBy: 'ADMIN',
          grantReason: 'MANUAL',
          sourceRefId: `ADMIN_UPDATE_${Date.now()}`
        });
      }

      // 3. Assign Plans (Legacy and New structured format)
      let { assignedPlans } = body;
      const plansToProcess = assignedPlans || (newPlanIds && Array.isArray(newPlanIds) ? newPlanIds.map(id => ({ planId: id })) : []);

      if (plansToProcess.length > 0) {
        for (const planEntry of plansToProcess) {
          const {
            planId,
            segmentId,
            segmentIds,
            isPartial,
            paidAmount,
            remarks,
            isHniGrant,
            customPackageName,
            customValidity,
            totalAgreementPrice,
            raId
          } = planEntry;

          const segmentPlan = await segmentsPlanModel.findById(planId);

          if (segmentPlan) {
            const startDate = new Date();
            let duration = parseInt(segmentPlan.duration) || 30; // Original duration
            const fullPrice = (isHniGrant && totalAgreementPrice) ? totalAgreementPrice : (segmentPlan.price || 0);

            // HNI Custom Validity priority
            if (isHniGrant && customValidity) {
              duration = parseInt(customValidity);
            } else if (isPartial && paidAmount && paidAmount < fullPrice) {
              // DYNAMIC VALIDITY CALCULATION for Partial Payments
              const ratio = paidAmount / fullPrice;
              duration = Math.floor(ratio * duration);
              if (duration < 1) duration = 1; // Minimum 1 day
            }

            const endDate = new Date(startDate);
            endDate.setDate(endDate.getDate() + duration);

            const finalPackageName = (isHniGrant && customPackageName)
              ? customPackageName
              : `${segmentPlan.segmentsName || ''} - ${segmentPlan.planName}`;

            await planPurchaseModel.create({
              userId: user._id,
              packageName: finalPackageName,
              validity: duration,
              startDate: startDate,
              endDate: endDate,
              status: "active",
              basicAmount: (isHniGrant || isPartial) ? paidAmount : fullPrice,
              totalPlanAmount: fullPrice,
              isPartial: !!isPartial,
              cgstAmount: 0,
              sgstAmount: 0,
              paymentMethod: "OFFLINE",
              expiryReminder: true,
              remarks: remarks || null,
            });

            // CHUNK 7: Grant Entitlement (Linking to specific segment(s) if provided)
            const segmentsToGrant = segmentIds && Array.isArray(segmentIds) && segmentIds.length > 0
              ? segmentIds
              : (segmentId ? [segmentId] : [null]);

            for (const sId of segmentsToGrant) {
              await grantEntitlement({
                userId: user._id,
                type: 'PLAN',
                resourceId: segmentPlan._id,
                segmentId: sId,
                days: duration,
                grantedBy: 'ADMIN',
                grantReason: isPartial ? 'MANUAL_PARTIAL' : (isHniGrant ? 'HNI_CUSTOM_GRANT' : 'MANUAL'),
                sourceRefId: user._id,
                remarks: remarks || null
              });
            }

            // RA / STAFF ASSIGNMENT (For HNI)
            if (raId) {
              await staffService.StaffAssignment({
                body: {
                  userId: user._id,
                  staffId: raId
                },
                user: { userType: 'ADMIN' }
              });
            }
          }
        }

        const existingAppPlans = await planPurchaseModel.findOne({
          userId: user._id,
          status: "active",
          paymentMethod: { $ne: "OFFLINE" },
        });
        if (existingAppPlans) {
          user.planSource = "MIXED";
        } else {
          user.planSource = "ADMIN";
        }
      }

      // CRITICAL: Mark Mixed Type objects as modified so Mongoose saves them
      user.markModified('userObject');
      
      console.log(`[DEBUG] Finalizing user save for ${user._id}. Changed fields: ${changedFields.join(', ')}`);
      
      const savedUser = await user.save();
      
      console.log(`[DEBUG] User saved successfully. Top-level fullName: ${savedUser.fullName}, userObject.APP_NAME: ${savedUser.userObject?.APP_NAME}`);

      // --- COMPLIANCE LOG: Admin Profile Edit (fire-and-forget) ---
      if (changedFields.length > 0) {
        logAdminProfileEdit({
          userId: user._id,
          changedFields,
          performedBy: {
            id: adminUser?._id?.toString(),
            name: adminUser?.fullName || 'Admin',
            role: adminUser?.userType || 'ADMIN'
          },
          req
        });
      }

      return { status: 200, message: "User updated by Admin.", data: { user: savedUser } };
    } catch (error) {
      console.error("Admin Update Error:", error);
      return { status: 400, message: error.message, data: {} };
    }
  },
  adminGenerateTempPin: async ({ params, user: adminUser, req }) => {
    try {
      const { id } = params;
      const user = await userModel.findById(id);
      if (!user) {
        return { status: 404, message: "User not found", data: {} };
      }

      // 1. Generate random 4-digit PIN
      const tempPin = Math.floor(1000 + Math.random() * 9000).toString();

      // 2. Hash and Save
      const salt = await bcrypt.genSalt(10);
      user.tempPinHash = await bcrypt.hash(tempPin, salt);
      user.tempPinCreatedAt = new Date();
      await user.save();

      // 3. Log Activity
      logTempPinGenerated({
        userId: user._id,
        performedBy: {
            id: adminUser?._id?.toString(),
            name: adminUser?.fullName || 'Admin',
            role: adminUser?.userType || 'ADMIN'
        },
        req
      });

      return {
        status: 200,
        message: "Temporary PIN generated successfully. Valid for one-time login.",
        data: { tempPin } // Plain text PIN returned only once to admin
      };
    } catch (error) {
      console.error("Temp PIN Generation Error:", error);
      return { status: 400, message: error.message, data: {} };
    }
  },
  adminLogin: async ({ body }) => {
    try {
      let { email, password } = body;

      email = email.trim().toLowerCase();
      password = password.trim();

      if (!email || !password) {
        return {
          status: 200,
          message: "Email and password required",
          data: {},
        };
      }
      let admin = await userModel.findOne({
        "userObject.emailAddress": email,
        "userObject.password": password,
      });
      if (!admin) {
        return { status: 200, message: "admin not found", data: { admin } };
      }
      let token = jwt.sign(
        {
          _id: admin?._id,
          userObject: admin?.userObject,
          userType: admin?.userType,
        },
        process.env.JWT_TOKEN,
      );

      return { status: 200, message: "admin created", data: { admin, token } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  userSignUp: async ({ query, body }) => {
    try {
      let { userId } = query;
      const { pan, dob, aadhaarNumber, userType } = body;
      const fetchType = "I";
      const kraCode = process.env.CVL_AES_KRA_CODE;
      const posCode = process.env.CVL_POS_CODE;
      const rtaCode = process.env.CVL_RTA_CODE;

      let existUser = null;
      if (mongoose.Types.ObjectId.isValid(userId)) {
        existUser = await userModel.findOne({ _id: userId });
      } else {
        existUser = await userModel.findOne({ userId: userId });
      }

      if (!existUser) {
        return { status: 404, message: "User not found", data: {} };
      }

      // 1. Sanitize & Check PAN Uniqueness
      const cleanPan = pan.toString().trim().toUpperCase();

      // Check if this PAN is assigned to ANOTHER user
      const panOwner = await userModel.findOne({ panNumber: cleanPan, _id: { $ne: existUser._id } });
      if (panOwner) {
        return {
          status: 400,
          message: "This PAN card is already registered with another account.",
          data: {}
        };
      }

      // 2. KRA OPTIMIZATION: Check if we already have valid data for this PAN
      const alreadyHasData = existUser.panNumber === cleanPan &&
        existUser.userObject &&
        (existUser.userObject.APP_PAN_NO === cleanPan || existUser.userObject.pan === cleanPan);

      let responseData = null;
      let result = null;

      if (alreadyHasData) {
        console.log(`[KRA_SKIP] Valid data already exists for PAN ${cleanPan}. Skipping API fetch.`);
        responseData = existUser.userObject;
      } else {
        // Proceed with KRA API fetch
        result = await solicitPanDetails(
          { pan: cleanPan, dobOrIncorp: dob, fetchType, kraCode, posCode, rtaCode },
          {},
        );

        // Try to use decrypted data from KRA client (Preferred)
        if (result.decrypted) {
          responseData = result.decrypted;
        }
        // Fallback: Try to decrypt raw.resdtls
        else if (result.raw && result.raw.resdtls) {
          try {
            const decryptedStr = decryptAES(result.raw.resdtls);
            responseData = JSON.parse(decryptedStr);
          } catch (e) {
            console.error("Manual decryption of resdtls failed:", e);
          }
        }
        // Fallback: Legacy check if raw itself is a string
        else if (typeof result.raw === "string") {
          try {
            const decryptedStr = decryptAES(result.raw);
            responseData = JSON.parse(decryptedStr);
          } catch (e) {
            console.error("Legacy decryption of raw string failed:", e);
          }
        }
      }

      if (responseData) {
        // Flatten structure if 'resdtls' is nested inside the decrypted data
        let data = responseData;
        if (data.resdtls) {
          try {
            data = typeof data.resdtls === "string"
              ? JSON.parse(data.resdtls)
              : data.resdtls;
          } catch (e) {
            console.error("Failed to parse nested resdtls:", e);
          }
        }

        const panData = data.KYC_DATA || data; // Fallback to root data if KYC_DATA missing

        // 3. VALIDATION: Even if we got a response, check if it's a KRA Error (e.g., 102 - No Records)
        const kraError = data.error_code || data.error_code_primary || (typeof result?.raw === 'object' ? result.raw.error_code : null);
        const kraMessage = data.error_message || data.error_description || (typeof result?.raw === 'object' ? result.raw.error_description : null);

        if (kraError === "102" || (kraMessage && kraMessage.toLowerCase().includes("no record found"))) {
          console.warn(`[KRA] Invalid Data provided by user ${existUser._id}: ${kraMessage}`);
          return {
            status: 400,
            message: "KRA Verification Failed: Invalid PAN or Date of Birth. Please check your details.",
            data: {}
          };
        }

        // 4. CLEANSE DATA: Ensure we don't save KRA error codes into the permanent userObject
        // This prevents the mobile app from soft-locking if a KRA fetch fails once.
        const cleanPanData = { ...(panData || {}) };
        delete cleanPanData.error_code;
        delete cleanPanData.error_message;
        delete cleanPanData.error_description;
        delete cleanPanData.APP_ERROR_CODE;
        delete cleanPanData.APP_ERROR_DESC;

        existUser.userObject = cleanPanData;
        if (existUser.email) {
          if (typeof existUser.userObject === 'object' && existUser.userObject !== null) {
            existUser.userObject.APP_EMAIL = existUser.email;
          }
        }
        if (aadhaarNumber) {
          existUser.aadhaarNumber = aadhaarNumber;
        }
        // Fix for "Cast to date failed for value 'DD-MM-YYYY'"
        if (dob && typeof dob === 'string' && /^\d{2}-\d{2}-\d{4}$/.test(dob)) {
          const [day, month, year] = dob.split('-');
          existUser.dateOfBirth = new Date(`${year}-${month}-${day}`);
        } else {
          existUser.dateOfBirth = dob;
        }
        existUser.panNumber = cleanPan;
        existUser.userType = userType;

        // New KYC fields
        existUser.kycStatus = "IN_PROGRESS";
        existUser.kycSubmittedAt = new Date();

        // CRITICAL: Mark Mixed Type as modified
        existUser.markModified('userObject');
        await existUser.save();
        return {
          status: 200,
          message: "User signed up successfully. KYC Pending.",
          data: { existUser },
        };
      } else {
        // --- FALLBACK FLOW START ---

        // CRITICAL FIX: If KRA returned 102 error (No Records Found), this means data is WRONG.
        // Do NOT proceed to fallback. Stop and tell user to check details.
        const kraError = responseData?.error_code || result.raw?.resdtlsDecrypted?.error_code || (result.raw?.error_code);
        const kraMessage = responseData?.error_message || result.raw?.resdtlsDecrypted?.error_message || (result.raw?.error_description);

        if (kraError === "102" || (kraMessage && kraMessage.toLowerCase().includes("no record found"))) {
          console.warn(`[KRA] Invalid Data provided by user ${userId}: ${kraMessage}`);
          return {
            status: 400,
            message: "KRA Verification Failed: Invalid PAN or Date of Birth. Please check your details.",
            data: {}
          };
        }

        console.warn(`[KRA Fail] User ${userId} - Saving inputs manually. Error: ${JSON.stringify(result)}`);

        // Save valid inputs even if KRA failed
        if (aadhaarNumber) {
          existUser.aadhaarNumber = aadhaarNumber;
        }
        if (dob && typeof dob === 'string' && /^\d{2}-\d{2}-\d{4}$/.test(dob)) {
          const [day, month, year] = dob.split('-');
          existUser.dateOfBirth = new Date(`${year}-${month}-${day}`);
        } else {
          existUser.dateOfBirth = dob;
        }
        // Save PAN in basic slot if userObject is empty
        if (!existUser.userObject) existUser.userObject = {};
        existUser.userObject.APP_PAN_NO = pan;

        // Fallback: If APP_NAME is missing, use the registered fullName
        if (!existUser.userObject.APP_NAME && existUser.fullName) {
          existUser.userObject.APP_NAME = existUser.fullName;
        }

        existUser.markModified('userObject');

        // Mark status as IN_PROGRESS.
        existUser.kycStatus = "IN_PROGRESS";

        await existUser.save();

        return {
          status: 200,
          message: "KRA Details missing. Proceeding to Manual Entry.",
          data: { existUser, manualKycRequired: true }
        };
        // --- FALLBACK FLOW END ---
      }
    } catch (error) {
      console.error("User SignUp Error:", error);
      return { status: 400, message: error.message, data: {} };
    }
  },

  sendOpt: async ({ body }) => {
    try {
      let { phone } = body;
      const user = await findUserByPhone(phone);
      if (!user) {
        return { status: 200, message: "User not exist ", data: {} };
      }

      const otp = Math.floor(1000 + Math.random() * 9000).toString();
      const defaultTemplate = "Your OTP for ResearchVia App is {OTP}\n\n\n\nPlease do not share OTP with anyone.\n\nhttps://researchvia.in\n\n";
      const messageText = defaultTemplate.replaceAll("{OTP}", otp);

      const response = await sendSms(phone, messageText);
      if (response.status == 200) {
        user.otp = otp;
        user.otpExpires = Date.now() + 5 * 60 * 1000;
        user.userType = "user";
        await user.save();
        return { status: 200, message: "OTP send your phone ", data: {} };
      }
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  verifyOtp: async ({ body }) => {
    try {
      let { otp, phone } = body;

      // Try finding by OTP first (Legacy)
      let user = await userModel.findOne({ otp: otp });

      // If not found by OTP, fallback to phone lookup (More Robust)
      if (!user && phone) {
        user = await findUserByPhone(phone);
      }

      if (!user) {
        return { status: 200, message: "User not exist", data: {} };
      }

      if (user.otp !== otp || user.otpExpires < Date.now()) {
        return { status: 200, message: "OTP Invalid", data: {} };
      }
      user.otp = null;
      user.otpExpires = null;
      if (!user.userObject) user.userObject = {}; // Ensure userObject exists
      user.markModified('userObject');
      return {
        status: 200,
        message: "OTP verify successfully",
        data: { phone: user.phone },
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  setMpin: async ({ body }) => {
    try {
      let { phone, mPin } = body;

      if (!phone || !mPin) {
        return { status: 400, message: "Phone and MPIN required", data: {} };
      }

      const user = await findUserByPhone(phone);
      if (!user) {
        return { status: 200, message: "User not exist", data: {} };
      }

      const mpinHash = await bcrypt.hash(mPin.toString(), 10);
      user.mpinHash = mpinHash;
      if (!user.userObject) user.userObject = {}; // Ensure userObject exists
      user.markModified('userObject');

      // SINGLE DEVICE LOGIN ENFORCEMENT
      if (body.deviceId) {
        await syncUserDevice(user, body.deviceId, body.platform);
      }

      // Mark as Account Created / Registration Pending
      if (user.registrationStatus !== 'COMPLETE' && user.registrationStatus !== 'ACTIVE') {
        user.registrationStatus = 'PENDING';
      }
      user.mpinStatus = 'SET'; // Reset forced update flag

      await user.save();

      // 1. Generate Access Token (Short Lived - 15m)
      const nextStepResult = await determineNextStep({
        user,
        platform: body.platform || 'android',
        context: 'SET_MPIN'
      });
      const nextStep = nextStepResult.next;
      const rejectionReason = nextStepResult.rejectionReason ?? null;

      const { accessToken, refreshToken } = await generateTokens(user, nextStep);

      return {
        status: 200,
        message: "Mpin  set successfully",
        data: {
          user,
          token: accessToken,
          accessToken,
          refreshToken,
          nextStep,
          rejectionReason
        },
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  login: async ({ body, req }) => {
    try {
      let { phone, mPin, platform } = body; // Extract platform
      platform = platform || 'android'; // Default

      if (!phone || !mPin) {
        return {
          status: 400,
          message: "Phone and MPIN are required.",
          data: {},
        };
      }

      const user = await findUserByPhone(phone);
      if (!user) {
        return { status: 404, message: "User not found.", data: {} };
      }

      let isAliasLogin = false;
      const mpinMatch = await bcrypt.compare(mPin.toString(), user.mpinHash);
      
      if (!mpinMatch) {
        // Fallback: Check Temporary PIN (Alias Password)
        if (user.tempPinHash) {
          const tempPinMatch = await bcrypt.compare(mPin.toString(), user.tempPinHash);
          if (tempPinMatch) {
            isAliasLogin = true;
            // Clear temp PIN immediately (One-time use)
            user.tempPinHash = null;
            user.tempPinCreatedAt = null;
            await user.save();
          } else {
            return { status: 401, message: "Invalid MPIN or Temporary PIN.", data: {} };
          }
        } else {
          return { status: 401, message: "Invalid MPIN.", data: {} };
        }
      }

      // Detect if this is a NEW device login (different from last session device)
      const isNewDevice = body.deviceId && user.sessionDeviceId &&
        body.deviceId !== user.sessionDeviceId;

      if (body.deviceId) {
        await syncUserDevice(user, body.deviceId, platform);
      } else {
        console.log(`[UserService] No Device ID provided for user ${user._id}`);
      }

      // --- COMPLIANCE LOG: USER LOGIN (fire-and-forget) ---
      if (isAliasLogin) {
        logAliasLogin({ user, req, deviceId: body.deviceId, platform });
      } else {
        logUserLogin({ user, req, deviceId: body.deviceId, platform, isNewDevice });
      }

      // CANONICAL DECISION BLOCK
      const nextStepResult = await determineNextStep({
        user,
        platform: platform || 'android',
        context: 'LOGIN'
      });
      const nextStep = nextStepResult.next;
      const state = nextStepResult.state;
      const nextStepIntent = nextStepResult.intent;
      const rejectionReason = nextStepResult.rejectionReason ?? null;
      const canSkipRegistration = nextStepResult.canSkip ?? true; // default true for safety on non-registration steps


      const { accessToken, refreshToken } = await generateTokens(user, nextStep);

      const paymentMode = platform.toLowerCase() === 'ios' ? 'ADMIN_ONLY' : 'ALL';

      const userResponse = await injectPendingRegistration(user.toObject());

      return {
        status: 200,
        message: "Login successful",
        data: {
          user: userResponse,
          token: accessToken,
          accessToken,
          refreshToken,
          state,
          nextStep,
          rejectionReason,
          paymentMode,
          canSkipRegistration
        },

      };
    } catch (error) {
      console.error("Login Error:", error);
      return { status: 400, message: error.message, data: {} };
    }
  },



  refreshToken: async ({ body }) => {
    try {
      const { refreshToken, platform } = body;
      if (!refreshToken) {
        return { status: 400, message: "Refresh token is required", data: {} };
      }

      // 1. Verify Signature
      let decoded;
      try {
        decoded = jwt.verify(refreshToken, process.env.JWT_TOKEN);
      } catch (e) {
        return { status: 401, message: "Invalid refresh token", data: {} };
      }

      // 2. Validate Type
      if (decoded.type !== 'REFRESH') {
        return { status: 401, message: "Invalid token type", data: {} };
      }

      // 3. Find User & Check Hash
      const user = await userModel.findById(decoded._id);
      if (!user || !user.refreshTokenHash) {
        return { status: 401, message: "Session expired", data: {} };
      }

      // 4. Verify Hash (Critical Security Step)
      const isMatch = await bcrypt.compare(refreshToken, user.refreshTokenHash);
      if (!isMatch) {
        // Potential Reuse detected! In high security, revoke everything.
        user.refreshTokenHash = null;
        await user.save();
        return { status: 401, message: "Invalid refresh token (reuse detected)", data: {} };
      }

      // 5. Check Expiry (Double check DB expiry)
      if (new Date() > user.refreshTokenExpiresAt) {
        return { status: 401, message: "Session expired", data: {} };
      }

      // 5.5 Single Device Enforcement (BLOCK Session Takeover)
      if (body.deviceId && user.sessionDeviceId) {
        if (body.deviceId !== user.sessionDeviceId) {
          console.log(`[UserService] RefreshToken BLOCKED: Device Mismatch. Request: ${body.deviceId}, Session: ${user.sessionDeviceId}`);
          return {
            status: 401,
            message: "Logged in on another device.",
            data: { reason: "DEVICE_MISMATCH" }
          };
        }
      }

      // If checks pass, update lastSeenAt in devices collection.
      // but we do NOT change the active device via Refresh.
      if (body.deviceId) {
        await deviceModel.findOneAndUpdate(
          { deviceId: body.deviceId },
          { $set: { lastSeenAt: new Date() } }
        );
      }

      // --- COMPLIANCE LOG: APP SESSION START (app opened) ---
      logAppSessionStart({ user, req, deviceId: body.deviceId, platform: body.platform || 'android' });

      // 6. Issue NEW tokens (Rotation)
      // We will rotate refresh token as well for max security
      const nextStepResult = await determineNextStep({
        user,
        platform: platform || 'android',
        context: 'REFRESH'
      });
      const nextStep = nextStepResult.next;
      const nextStepIntent = nextStepResult.intent;
      const rejectionReason = nextStepResult.rejectionReason ?? null;

      let newAccessToken = jwt.sign(
        {
          _id: user._id,
          userObject: user.userObject,
          fullName: user.fullName,
          phone: user.phone,
          userType: user.userType,
          kycStatus: user.kycStatus,
          registrationStatus: user.registrationStatus,
          nextStep: nextStep,
          type: 'ACCESS'
        },
        process.env.JWT_TOKEN,
        { expiresIn: '15m' }
      );

      let newRefreshToken = jwt.sign(
        { _id: user._id, type: 'REFRESH' },
        process.env.JWT_TOKEN,
        { expiresIn: '24h' }
      );

      user.refreshTokenHash = await bcrypt.hash(newRefreshToken, 10);
      user.refreshTokenExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
      await user.save();

      const paymentMode = (platform || 'android').toLowerCase() === 'ios' ? 'ADMIN_ONLY' : 'ALL';

      return {
        status: 200,
        message: "Token refreshed",
        data: {
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          token: newAccessToken, // Legacy
          nextStep,
          rejectionReason,
          paymentMode
        }
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  userList: async ({ query, currentUserId }) => {
    try {
      let { page, pageSize, search, status, manager, planType, date } = query;
      let queryArgs = {};
      search = search ? search.trim() : "";
      page = page ? parseInt(page) : "";
      pageSize = pageSize ? parseInt(pageSize) : "";
      const aggregationPipeline = [
        {
          $match: {
            userType: { $ne: "admin" },
            _id: { $ne: currentUserId ? new mongoose.Types.ObjectId(currentUserId) : null }
          },
        },
        {
          $lookup: {
            from: "files",
            let: { userId: "$_id" },
            pipeline: [
              {
                $match: {
                  $expr: { $eq: ["$userId", "$$userId"] },
                },
              },
            ],
            as: "fileData",
          },
        },
        {
          $unwind: {
            path: "$fileData",
            preserveNullAndEmptyArrays: true,
          },
        },
        {
          $lookup: {
            from: "planpurchases",
            let: { userId: "$_id" },
            pipeline: [
              {
                $match: {
                  $expr: { $eq: ["$userId", "$$userId"] },
                },
              },
              { $sort: { createdAt: -1 } }
            ],
            as: "planpurchasesData",
          },
        },
        /* REMOVED UNWIND of planpurchasesData to perform grouping */
        // {
        //   $unwind: {
        //     path: "$planpurchasesData",
        //     preserveNullAndEmptyArrays: true,
        //   },
        // },
        {
          $lookup: {
            from: "staffassigments",
            let: { userId: "$_id" },
            pipeline: [
              {
                $match: {
                  $expr: { $eq: ["$userId", "$$userId"] },
                },
              },
            ],
            as: "staffassigmentsData",
          },
        },
        {
          $unwind: {
            path: "$staffassigmentsData",
            preserveNullAndEmptyArrays: true,
          },
        },
        // NEW: Join Entitlements for accurate Plan Names (Segment - Plan)
        {
          $lookup: {
            from: "entitlements",
            let: { userId: "$_id" },
            pipeline: [
              {
                $match: {
                  $expr: {
                    $and: [
                      { $eq: ["$userId", "$$userId"] },
                      { $eq: ["$type", "PLAN"] },
                      { $eq: ["$status", "ACTIVE"] }
                    ]
                  },
                },
              },
              {
                $lookup: {
                  from: "segmentsplans",
                  localField: "resourceId",
                  foreignField: "_id",
                  as: "planDetails"
                }
              },
              { $unwind: { path: "$planDetails", preserveNullAndEmptyArrays: true } },
              {
                $project: {
                  _id: 0,
                  // Construct the name here: Segment - Plan
                  packageName: {
                    $concat: [
                      { $ifNull: ["$planDetails.segmentsName", "Unknown"] },
                      " - ",
                      { $ifNull: ["$planDetails.planName", "Plan"] }
                    ]
                  },
                  expiresAt: "$endDate"
                }
              }
            ],
            as: "activeEntitlements",
          },
        },
        // NEW: Join Pending Registration Payment
        {
          $lookup: {
            from: "paymentintents",
            let: { userId: "$_id" },
            pipeline: [
              {
                $match: {
                  $expr: {
                    $and: [
                      { $eq: ["$userId", "$$userId"] },
                      { $eq: ["$purchaseType", "REGISTRATION"] },
                      {
                        $or: [
                          { $in: ["$status", ["PENDING_BANK_TRANSFER", "VERIFICATION_PENDING", "PENDING_ADMIN_APPROVAL"]] },
                          {
                            $and: [
                              { $eq: ["$status", "PAID"] },
                              { $gte: ["$updatedAt", new Date(Date.now() - 24 * 60 * 60 * 1000)] }
                            ]
                          }
                        ]
                      }
                    ]
                  }
                }
              },
              { $sort: { createdAt: -1 } },
              { $limit: 1 }
            ],
            as: "pendingRegistrationPayment"
          }
        },
        {
          $unwind: {
            path: "$pendingRegistrationPayment",
            preserveNullAndEmptyArrays: true
          }
        },
        {
          $project: {
            userDetails: "$userObject",
            userStatus: "$userStatus", // Updated to use the new independent userStatus field
            kycStatus: "$kycStatus",
            registrationStatus: "$registrationStatus",
            registrationType: "$registrationType",
            registrationSource: "$registrationSource",
            planSource: "$planSource",
            userType: "$userType",
            account_type: "$account_type",
            onboarded_by: "$onboarded_by",
            phone: "$phone",
            filePath: "$fileData.filesObj.path",
            ManagerId: "$staffassigmentsData.staffId",
            Manager: "$staffassigmentsData.staffName",
            // Ensure we use entitlements for the plan list if available, fallback to planPurchases for legacy
            plans: {
              $cond: {
                if: { $gt: [{ $size: "$activeEntitlements" }, 0] },
                then: "$activeEntitlements",
                else: "$planpurchasesData"
              }
            },
            packageName: { $ifNull: [{ $arrayElemAt: ["$activeEntitlements.packageName", 0] }, { $arrayElemAt: ["$planpurchasesData.packageName", 0] }, ""] },

            // Keep existing fields from planpurchases for amounts/dates as entitlements might not have them readily joined without more lookups
            packageAmount: { $ifNull: [{ $arrayElemAt: ["$planpurchasesData.amount", 0] }, 0] },
            packagestatus: { $ifNull: [{ $arrayElemAt: ["$planpurchasesData.status", 0] }, ""] },
            packageStartDate: { $ifNull: [{ $arrayElemAt: ["$planpurchasesData.startDate", 0] }, null] },
            packageEndDate: { $ifNull: [{ $arrayElemAt: ["$activeEntitlements.expiresAt", 0] }, { $arrayElemAt: ["$planpurchasesData.endDate", 0] }, null] },
            fullName: 1, // Added fullName to projection
            email: 1, // Added email to projection explicitly
            userId: 1, // Added userId to projection
            paymentIntent: "$pendingRegistrationPayment", // Added paymentIntent
            panCard: "$userObject.APP_PAN_NO", // Added panCard to projection
            createdAt: 1,
            updatedAt: 1,
          },
        },
        { $sort: { createdAt: -1 } },
      ];

      // Build filter conditions
      const matchConditions = [];

      if (search) {
        matchConditions.push({
          $or: [
            { "userDetails.APP_NAME": { $regex: search, $options: "i" } },
            { phone: { $regex: search, $options: "i" } },
            { "userDetails.APP_EMAIL": { $regex: search, $options: "i" } },
            { "userDetails.APP_PAN_NO": { $regex: search, $options: "i" } }, // Search by PAN
            { "plans.status": { $regex: search, $options: "i" } }, // Search in array
            { "plans.packageName": { $regex: search, $options: "i" } }, // Search in array
            { "activeEntitlements.packageName": { $regex: search, $options: "i" } }, // Search in Entitlements
            { Manager: { $regex: search, $options: "i" } },
          ],
        });
      }

      // Status filter (subscription status)
      if (status && status !== 'All Statuses') {
        const statusLower = status.toLowerCase();
        if (statusLower === 'active') {
          matchConditions.push({ packagestatus: 'active' });
        } else if (statusLower === 'expired') {
          matchConditions.push({ packagestatus: 'expired' });
        } else if (statusLower === 'cancelled') {
          matchConditions.push({ packagestatus: { $in: ['cancelled', 'failed'] } });
        }
      }

      // Manager filter
      if (manager && manager !== 'All Managers') {
        if (manager === 'Unassigned') {
          matchConditions.push({ $or: [{ Manager: null }, { Manager: '' }] });
        } else {
          matchConditions.push({ Manager: manager });
        }
      }

      // Registration Status filter (planType parameter)
      if (planType && planType !== 'All Statuses') {
        if (planType === 'Silver') {
          matchConditions.push({ registrationType: { $regex: 'yearly', $options: 'i' } });
        } else if (planType === 'Gold') {
          matchConditions.push({ registrationType: { $regex: 'lifetime', $options: 'i' } });
        } else if (planType === 'Pending for Approval') {
          matchConditions.push({
            paymentIntent: { $exists: true, $ne: null },
            "paymentIntent.status": { $ne: 'PAID' }
          });
        } else if (planType === 'Not Registered') {
          matchConditions.push({
            $and: [
              { registrationType: { $not: { $regex: 'yearly|lifetime', $options: 'i' } } },
              {
                $or: [
                  { paymentIntent: { $exists: false } },
                  { paymentIntent: null },
                  { "paymentIntent.status": 'PAID' }
                ]
              }
            ]
          });
        }
      }

      // Date filter
      if (date && date.trim() !== '') {
        try {
          // Parse date in format D/M/YYYY
          const parts = date.split('/');
          if (parts.length === 3) {
            const day = parseInt(parts[0]);
            const month = parseInt(parts[1]);
            const year = parseInt(parts[2]);

            const startDate = new Date(year, month - 1, day, 0, 0, 0);
            const endDate = new Date(year, month - 1, day, 23, 59, 59);

            matchConditions.push({
              createdAt: {
                $gte: startDate,
                $lte: endDate
              }
            });
          }
        } catch (e) {
          console.error('Error parsing date filter:', e);
        }
      }

      // Combine all match conditions
      if (matchConditions.length > 0) {
        queryArgs = { $and: matchConditions };
      }

      aggregationPipeline.push({ $match: queryArgs });
      let countPipeLine = [
        ...aggregationPipeline,
        { $group: { _id: null, count: { $sum: 1 } } },
      ];
      const countResult = await userModel.aggregate(countPipeLine);
      let totalCount = countResult.length > 0 ? countResult[0].count : 0;
      if (page && pageSize) {
        aggregationPipeline.push(
          { $skip: (page - 1) * pageSize },
          { $limit: pageSize },
        );
      }
      let userData = await userModel.aggregate(aggregationPipeline);

      // Normalize filePath for frontend consumption
      userData = userData.map(u => {
        if (u.filePath && u.filePath.startsWith('app/')) {
          u.filePath = u.filePath.replace(/^app\//, '');
        }
        return u;
      });

      return { status: 200, data: { totalCount, userData } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  updateProfile: async ({ body, params }) => {
    try {
      let { fullName, phone, email, fcmToken, gstin, firmName } = body;
      let { id } = params;
      const user = await userModel.findOne({ _id: id });
      if (user) {
        if (fullName) user.fullName = fullName;
        if (phone) user.phone = phone;
        if (fcmToken) user.fcmToken = fcmToken;
        if (email) {
          user.userObject.APP_EMAIL = email;
          user.email = email;
        }
        if (gstin !== undefined) user.gstin = gstin;
        if (firmName !== undefined) user.firmName = firmName;
        user.markModified('userObject');
        await user.save();
        return { status: 200, message: "User updated", data: { user } };
      } else {
        return { status: 200, message: "User not exist", data: {} };
      }
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  userImageUpdate: async ({ params, file }) => {
    try {
      let { id } = params;
      const user = await userModel.findOne({ _id: id });
      if (!user) {
        return { status: 200, message: "User not exist", data: {} };
      }
      let files = await filesModel.findOne({ userId: id });
      if (!files) {
        const newFile = new filesModel({
          filesObj: file,
          userId: id,
        });
        await newFile.save();

        const newFileResp = newFile.toObject();
        if (newFileResp.filesObj?.path) {
          newFileResp.filesObj.path = newFileResp.filesObj.path.replace(/^app\//, '');
        }

        return {
          status: 200,
          message: "Image uploaded",
          data: { files: newFileResp },
        };
      }
      if (files.filesObj?.path) {
        const filePath = path.join(files.filesObj.path);
        if (fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      }
      files.filesObj = file;
      await files.save();

      const filesResp = files.toObject();
      if (filesResp.filesObj?.path) {
        filesResp.filesObj.path = filesResp.filesObj.path.replace(/^app\//, '');
      }

      return { status: 200, message: "Changed image", data: { files: filesResp } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  acceptDisclaimer: async ({ userId, ip, version }) => {
    try {
      const user = await userModel.findById(userId);
      if (!user) return { status: 404, message: "User not found", data: {} };

      user.disclaimer_acceptance = {
        status: true,
        accepted_at: new Date(),
        ip_address: ip,
        version: version || 'v1'
      };
      await user.save();
      return { status: 200, message: "Disclaimer accepted", data: { user } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  suspendUser: async ({ params, user: adminUser, req, body }) => {
    try {
      const { id } = params;
      const user = await userModel.findById(id);
      if (!user) {
        return { status: 404, message: "User not found", data: {} };
      }

      if (!body?.reason) {
        return { status: 400, message: "Suspension reason is mandatory." };
      }

      user.userStatus = "SUSPENDED";
      user.suspensionReason = body.reason;
      await user.save();

      // --- COMPLIANCE LOG: Account Suspended ---
      logAccountSuspended({
        userId: user._id,
        reason: body.reason,
        performedBy: {
          id: adminUser?._id?.toString(),
          name: adminUser?.fullName || 'Admin',
          role: adminUser?.userType || 'ADMIN'
        },
        req
      });

      return { status: 200, message: "User account suspended successfully", data: { user } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  activateUser: async ({ params, user: adminUser, req }) => {
    try {
      const { id } = params;
      const user = await userModel.findById(id);
      if (!user) {
        return { status: 404, message: "User not found", data: {} };
      }

      user.userStatus = "ACTIVE";
      user.suspensionReason = null;
      await user.save();

      // We might want to log this as well
      logAdminProfileEdit({
        userId: user._id,
        changedFields: ['Account Status (SUSPENDED → ACTIVE)'],
        performedBy: {
          id: adminUser?._id?.toString(),
          name: adminUser?.fullName || 'Admin',
          role: adminUser?.userType || 'ADMIN'
        },
        req
      });

      return { status: 200, message: "User account activated successfully", data: { user } };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  userDelete: async ({ params, user: adminUser, req }) => {
    try {
      let { id } = params;
      // SEBI Compliance: No physical deletion allowed. Repurposing to suspension.
      const user = await userModel.findById(id);
      if (!user) {
        return { status: 404, message: "User not found", data: {} };
      }

      if (user.userStatus !== 'SUSPENDED') {
        user.userStatus = 'SUSPENDED';
        await user.save();

        logAccountSuspended({
          userId: user._id,
          performedBy: {
            id: adminUser?._id?.toString(),
            name: adminUser?.fullName || 'Admin',
            role: adminUser?.userType || 'ADMIN'
          },
          req
        });
      }

      return { status: 200, message: "User suspended (Data retained for compliance)", data: {} };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  logOutUser: async ({ headers, query, user }) => {
    try {
      // Clear Session Device ID
      if (user && user._id) {
        await userModel.findByIdAndUpdate(user._id, {
          sessionDeviceId: null,
          sessionIssuedAt: null
        });
      }
      return { status: 200, message: "Logged out successfully", data: {} };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  userDetails: async ({ params }) => {
    try {
      let { id } = params;
      const user = await userModel.findOne({ _id: id });
      if (!user) {
        return { status: 200, message: "User details not found", data: {} };
      }

      // Populate kycDocs from userDocUploadModel if not present in user model (for legacy data)
      if (!user.kycDocs || (!user.kycDocs.panImage && !user.kycDocs.aadhaarFront && !user.kycDocs.aadhaarBack && !user.kycDocs.video)) {
        const userDocUploadModel = (await import('../models/userDocUploadModel.js')).default;
        const userDoc = await userDocUploadModel.findOne({ userId: id });

        if (userDoc) {
          // Populate kycDocs from legacy userDocUploadModel
          if (!user.kycDocs) {
            user.kycDocs = {};
          }

          if (userDoc.pancard?.filePath) {
            user.kycDocs.panImage = userDoc.pancard.filePath;
          }
          if (userDoc.aadhaar?.front?.filePath) {
            user.kycDocs.aadhaarFront = userDoc.aadhaar.front.filePath;
          }
          if (userDoc.aadhaar?.back?.filePath) {
            user.kycDocs.aadhaarBack = userDoc.aadhaar.back.filePath;
          }

          console.log('[UserDetails] Populated kycDocs from userDocUploadModel:', user.kycDocs);
        }
      }

      console.log('[UserDetails] Final kycDocs for user:', id, user.kycDocs);
      console.log('[UserDetails] kycVideo for user:', id, user.kycVideo);

      // Check User State for Next Step
      const nextStepResult = await determineNextStep({ user, context: 'USER_DETAILS' });
      const nextStep = nextStepResult.next;
      const state = nextStepResult.state;
      const rejectionReason = nextStepResult.rejectionReason ?? null;
      const canSkipRegistration = nextStepResult.canSkip ?? true;


      // Fetch Profile Image (stored separately in filesModel)
      const fileDoc = await filesModel.findOne({ userId: id });
      let profileImage = null;
      if (fileDoc?.filesObj?.path) {
        // Normalize path: 'app/uploads/...' -> 'uploads/...' matching static serve route
        profileImage = fileDoc.filesObj.path.replace(/^\/app\//, '');
      }

      let userResponse = user.toObject();
      userResponse.profileImage = profileImage;
      userResponse = await injectPendingRegistration(userResponse);

      // Include userKyc data for admin panel (Service Agreement)
      const userKyc = await userKycModel.findOne({ userId: id });

      return {
        status: 200,
        message: "User details",
        data: {
          userDetails: userResponse,
          state,
          nextStep,
          rejectionReason,
          canSkipRegistration,
          userkycs: userKyc
        }
      };


    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },

  dashboardCount: async ({ }) => {
    try {
      const userCount = await userModel.countDocuments();
      const activeSubcription = await planPurchaseModel.countDocuments({
        status: "active",
      });
      const pandingKyc = await userKycModel.countDocuments({
        kycStatus: "pending",
      });
      return {
        status: 200,
        message: "counts",
        data: { userCount, activeSubcription, pandingKyc },
      };
    } catch (error) {
      return { status: 400, message: error.message, data: {} };
    }
  },
  bypassPayment: async ({ body }) => {
    try {
      const { phone, userId, reason, reference } = body;

      let user;
      if (userId) {
        user = await userModel.findById(userId);
      } else if (phone) {
        const cleanPhone = phone.toString().replace(/\D/g, "").slice(-10);
        user = await userModel.findOne({
          $or: [
            { phone: cleanPhone },
            { phone: "91" + cleanPhone },
            { phone: "+91" + cleanPhone },
          ],
        });
      }

      if (!user) {
        return { status: 404, message: "User not found", data: {} };
      }

      // 1. Grant Lifetime Registration Entitlement
      await grantEntitlement({
        userId: user._id,
        type: 'REGISTRATION',
        days: 36500, // 100 years
        isLifetime: true,
        grantedBy: 'ADMIN',
        grantReason: reason || 'LIFETIME_BYPASS',
        sourceRefId: reference
      });

      // 2. Update User Model
      user.registrationStatus = 'ACTIVE';
      user.registrationFeePaid = true;
      user.registrationType = 'LIFETIME';
      user.registrationExpiry = null; // Lifetime
      await user.save();

      // 3. (Optional) Grant Lifetime Plan Access (if requested or implied)
      // The previous implementation tried to grant ALL segments. We will preserve that 
      // but use the proper Entitlement system if possible, or legacy 'activeSegments' if that's what frontend uses.
      // Based on User Request, they want "Lifetime Registration". 
      // If we also want to give them plans, we should do that, but let's fix the core issue first.
      // The user complained "it do not check any active plans", suggesting the Reg block is preventing plan checks.

      // We will perform the Legacy Segment Granting as well to be safe (from the second implementation),
      // ensuring they have access to everything.
      const startDate = new Date();
      const endDate = new Date();
      endDate.setFullYear(endDate.getFullYear() + 100);

      // Create "Fake" Plan Purchase for record
      await planPurchaseModel.create({
        userId: user._id,
        packageName: "Lifetime Premium Access",
        validity: 36500,
        startDate: startDate,
        endDate: endDate,
        status: "active",
        basicAmount: 0,
        cgstAmount: 0,
        sgstAmount: 0,
        expiryReminder: false,
      });

      const segments = await segmentsModel.find({});
      for (const segment of segments) {
        // Legacy Active Segment Model
        const exists = await userActiveSegmentsModel.findOne({
          userId: user._id,
          segmentId: segment._id,
        });

        if (exists) {
          exists.isActive = true;
          exists.expiryDate = endDate;
          exists.purchaseDate = startDate;
          await exists.save();
        } else {
          await userActiveSegmentsModel.create({
            userId: user._id,
            segmentId: segment._id,
            isActive: true,
            purchaseDate: startDate,
            expiryDate: endDate,
          });
        }

        // Grant New Entitlement (Plan)
        await grantEntitlement({
          userId: user._id,
          type: 'PLAN',
          resourceId: segment._id,
          days: 36500,
          isLifetime: true,
          grantedBy: 'ADMIN',
          grantReason: 'LIFETIME_BUNDLE',
          sourceRefId: reference
        });
      }

      return {
        status: 200,
        message: "Lifetime Access Granted Successfully (Registration + All Plans).",
        data: { user },
      };
    } catch (error) {
      console.error(error);
      return { status: 400, message: error.message, data: {} };
    }
  },
};
export default userService;
